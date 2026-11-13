# Pengendali utama compiler

## Konsep dan fungsi

Modul ini mengurutkan inisialisasi work memory, pembacaan header IR, validasi
payload, dan self-test emitter. Reader dan emitter tetap jalur terpisah:
opcode IR hanya divalidasi dan tidak diterjemahkan menjadi instruksi.

## Hubungan dengan modul lain

`firmware_main` dari `src/boot/main.asm` memanggil `compiler_main` setelah
stack siap. `compiler_main` memanggil `compiler_initialize`, `ir_init`,
`ir_validate_header`, `ir_validate_program`, lalu `emitter_self_test`.
Kegagalan apa pun melompat ke `compiler_error_loop`; sukses mengembalikan
kendali ke firmware dan mencatat `STATUS_SUCCESS`.

## Register dan alamat

Compiler menetapkan `DS=6000h` untuk work memory dan `ES=2000h` untuk output.
`SS:SP` tetap `5000:FFFE`. `CS` tetap menunjuk firmware dan static IR.
`SI` digunakan reader, `DI` digunakan emitter; `AX` dan `CX` menjadi register
sementara.

## Urutan kode

1. Muat `WORK_SEGMENT` ke DS.
2. Muat `OUTPUT_SEGMENT` ke ES.
3. Bersihkan status dan field compiler.
4. Inisialisasi IR, lalu validasi header.
5. Dispatch setiap instruksi sampai IR_END.
6. Jalankan penulisan, verifikasi, dan tes batas emitter yang terisolasi.
7. Simpan status sukses dan kembali.

## Build dan debugging

Jalankan `make` untuk membuat ROM. `make test` menjalankan variasi IR sukses
dan rusak melalui QEMU. GDB/QEMU dapat memeriksa status di alamat fisik
`60000h` dan output di `20000h`; rincian ada di `docs/debugging.md`.
