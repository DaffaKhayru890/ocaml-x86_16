# Pembaca IR

## Konsep dan fungsi

IR reader mengonsumsi byte secara berurutan dari tabel read-only di ROM.
`SI` menunjukkan posisi berikutnya dan `WORK_IR_REMAINING` membatasi jumlah
byte yang boleh dibaca. Pembacaan dilakukan dengan segment override `CS:SI`
karena DS sengaja menunjuk work memory, bukan ROM.

## Prosedur dan kontrak

- `ir_init`: mengatur SI ke `program_ir`, menghitung panjang tabel melalui
  label NASM, serta mengosongkan penghitung dan penanda terminator.
- `ir_check_remaining`: menerima CX sebagai jumlah byte minimum. CF=0 jika
  tersedia; jika tidak, mencatat `ERR_UNEXPECTED_EOF` dan CF=1.
- `ir_read_u8`: mengembalikan byte di AL, menaikkan SI satu, dan mengurangi
  remaining satu.
- `ir_read_u16`: mengembalikan word little-endian di AX. Pemeriksaan dua byte
  dilakukan sebelum pembacaan, sehingga tidak ada pembacaan parsial.
- `ir_validate_header`: membaca magic, versi, dan panjang melalui reader,
  lalu membandingkan panjang deklarasi dengan byte yang benar-benar tersisa.

Setiap prosedur menggunakan DS untuk mengakses `WORK_*`; hanya pembacaan
static IR yang menggunakan `[cs:si]`. Prosedur reader mengubah SI, AX/CX
sesuai kontrak, dan mengembalikan CF. Error disimpan pada work memory; caller
utama mengalihkan CPU ke error loop.

## Format dan alur

Header tujuh byte adalah `IR16`, versi satu byte, lalu panjang payload dua
byte little-endian. Setelah tujuh byte dibaca, remaining berisi ukuran
payload. Panjang pada header wajib sama dengan nilai itu. `IR_END` menjadi
byte terakhir payload dan diperiksa dispatcher.

## Build dan debugging

Jalankan `make test` untuk validasi u8, u16, versi, panjang, serta EOF.
Saat berhenti di QEMU/GDB, periksa SI, remaining di `60004h`, versi di
`6000Ch`, dan payload length di `6000Eh`.
