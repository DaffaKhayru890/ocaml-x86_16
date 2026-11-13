# Compiler main

## Konsep dan hubungan modul

`compiler_main` mengatur kompilasi setelah firmware menyiapkan stack. Pass
analisis membaca IR sekali, menyimpan record executable dan label dalam
tabel, menyelesaikan branch, lalu menganalisis stack serta inisialisasi lokal
pada CFG tanpa menghasilkan code. Pass emission menggunakan tabel tersebut,
melakukan relocation, lalu far jump ke executable bytes. Emitter self-test
dijalankan terpisah sebelum emission.

## Register dan alamat

Compiler memakai DS=`6000h` untuk state, ES=`2000h` untuk output, SI untuk
IR, DI untuk panjang output, dan SS:SP compiler=`5000:FFFE`. Setelah far jump,
generated prologue mengganti CS=`2000h`, DS=`3000h`, SS:SP=`4000:FFFE`.

## Urutan kode

1. Muat DS/ES dan panggil `compiler_initialize`.
2. Jalankan `ir_init`, validasi header, lalu decode payload ke instruction
   table. Label disimpan sebagai indeks instruksi executable.
3. Resolve target branch; tolak label duplikat/tidak ditemukan dan target
   yang berada sesudah instruksi executable terakhir.
4. Bentuk edge fallthrough/branch dan propagasikan stack depth serta bitmap
   definite-assignment sampai fixed-point; setiap HALT reachable harus
   menerima tepat satu nilai.
5. Jalankan emitter self-test; setiap error berhenti sebelum generation.
6. `codegen_init` mereset emitter, lalu prologue runtime ditulis.
7. Generator mengiterasi instruction table, mencatat posisi label, menulis
   instruksi 8086, dan menambal displacement rel16.
8. Validasi generated prologue, panjang, kapasitas, dan flag HALT.
8. Simpan SUCCESS lalu far jump ke `OUTPUT_SEGMENT:0000`.

Semua kegagalan masuk `compiler_error_loop`, menyimpan status/error, dan
tidak melompat. Compiler tidak menunggu RET dari generated program.

## Build dan debugging

Jalankan `make` dan `make test`. Status compiler tetap di `60000h`; generated
code di `20000h`, result runtime di `30000h`. Lihat `docs/debugging.md`.
