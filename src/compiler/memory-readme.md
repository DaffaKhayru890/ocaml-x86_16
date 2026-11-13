# Work memory compiler

## Konsep dan fungsi

ROM tidak dapat dipakai untuk writable state. Work memory berada di RAM
segment `6000h`; DS diarahkan ke segment ini sebelum field compiler diakses.
Modul ini menginisialisasi field tersebut serta menyediakan pencatatan error
dan error loop.

## Prosedur

- `compiler_initialize` menandai status RUNNING, membersihkan kode error,
  penghitung, operand, panjang, dan DI.
- `compiler_record_error` menerima kode di AX, menyimpan status ERROR dan
  kode, lalu mengembalikan CF=1.
- `compiler_error_loop` menjalankan CLI/HLT berulang agar state gagal tetap
  dapat diperiksa tanpa BIOS atau OS.

## Register dan alamat

DS harus sama dengan `WORK_SEGMENT=6000h`. Field pada offset `0000h–0015h`
berada pada alamat fisik `60000h–60015h`. ES dan DI bukan milik modul ini;
ES menunjuk output segment `2000h`.

## Build dan debugging

Jalankan `make test`. Gunakan GDB untuk memeriksa status pada `0x60000`,
kode error di `0x60002`, remaining di `0x60004`, jumlah instruksi di
`0x60008`, dan panjang emitter di `0x6000A`.
