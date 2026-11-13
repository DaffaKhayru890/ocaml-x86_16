# Compiler main

## Konsep dan hubungan modul

`compiler_main` mengatur dua-pass compilation setelah firmware menyiapkan
stack. Pass pertama memanggil reader, dispatcher, dan stack validator tanpa
menghasilkan code. Pass kedua mengulang IR, memanggil code generator, lalu
far jump ke executable bytes. Emitter self-test dijalankan terpisah di antara
dua pass dan output-nya di-reset.

## Register dan alamat

Compiler memakai DS=`6000h` untuk state, ES=`2000h` untuk output, SI untuk
IR, DI untuk panjang output, dan SS:SP compiler=`5000:FFFE`. Setelah far jump,
generated prologue mengganti CS=`2000h`, DS=`3000h`, SS:SP=`4000:FFFE`.

## Urutan kode

1. Muat DS/ES dan panggil `compiler_initialize`.
2. Jalankan `ir_init`, validasi header, serta `ir_validate_program`.
3. Validasi stack depth, slot lokal, bitmap inisialisasi, dan posisi HALT.
4. Jalankan emitter self-test; setiap error berhenti sebelum generation.
5. `codegen_init` mereset reader, stack, DI, dan emitter length.
6. Emit prologue runtime, lalu hasilkan arithmetic, local, dan comparison
   pada lintasan kedua.
7. Validasi generated prologue, panjang, HALT suffix, dan terminator.
8. Simpan SUCCESS lalu far jump ke `OUTPUT_SEGMENT:0000`.

Semua kegagalan masuk `compiler_error_loop`, menyimpan status/error, dan
tidak melompat. Compiler tidak menunggu RET dari generated program.

## Build dan debugging

Jalankan `make` dan `make test`. Status compiler tetap di `60000h`; generated
code di `20000h`, result runtime di `30000h`. Lihat `docs/debugging.md`.
