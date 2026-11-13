# Work memory compiler

## Konsep dan fungsi

ROM tidak dapat dipakai untuk writable state. Work memory berada di RAM
segment `6000h`; DS diarahkan ke segment ini sebelum field compiler diakses.
Modul ini menginisialisasi field tersebut serta menyediakan pencatatan error
dan error loop.

## Prosedur

- `compiler_initialize` menandai status RUNNING, membersihkan kode error,
  penghitung, operand, stack depth, codegen flags, panjang, dan DI.
- `compiler_record_error` menerima kode di AX, menyimpan status ERROR dan
  kode, lalu mengembalikan CF=1.
- `compiler_error_loop` menjalankan CLI/HLT berulang agar state gagal tetap
  dapat diperiksa tanpa BIOS atau OS.

## Register dan alamat

DS harus sama dengan `WORK_SEGMENT=6000h`. Field pada offset `0000h–0027h`
berada pada alamat fisik `60000h–60027h`. DS berubah ke `3000h` hanya setelah
far jump generated code; alamat work memory tetap dapat diperiksa secara
fisik. Bitmap lokal berukuran delapan byte berada pada `60020h–60027h`.
ES dan DI bukan milik modul ini; ES menunjuk output segment `2000h`.

## Build dan debugging

Jalankan `make test`. Gunakan GDB untuk memeriksa status pada `0x60000`,
kode error di `0x60002`, remaining di `0x60004`, jumlah instruksi di
`0x60008`, panjang generated code di `0x6000A`, stack depth di `0x60016`,
dan bitmap lokal di `0x60020`.
