# Machine Code Emitter

## Konsep dan fungsi

Emitter menulis byte langsung ke RAM. Ia menerima nilai register dan
menyimpan representasi little-endian pada output buffer; ia tidak membuat
teks Assembly dan tidak mengubah IR menjadi code generation.

## Prosedur dan kontrak

- `emitter_init`: mengatur DI dan panjang output ke nol.
- `emit8`: menerima AL, menulis satu byte ke ES:DI, menaikkan DI dan panjang.
- `emit16`: menerima AX, menulis word little-endian dan menaikkan DI dua.
  Sebelum menulis, ia memastikan dua byte tersedia sehingga tidak ada
  penulisan parsial.

Pada sukses, kedua emitter mengembalikan CF=0 dan memperbarui
`WORK_EMIT_LENGTH`. Pada overflow, DI dan data buffer tidak berubah, status
serta kode `ERR_OUTPUT_OVERFLOW` disimpan, dan CF=1. Register selain DI
dipertahankan; AX dipertahankan termasuk pada jalur error.

## Alur self-test

`tests/emitter/emitter-test.asm` menulis `B8 34 12 50 58`, memeriksa tiap
byte, menguji byte terakhir buffer, satu byte berlebih, serta `emit16`
dengan ruang satu byte. Overflow yang sengaja dipicu hanya ditangkap dan
dibersihkan oleh tes terisolasi; kegagalan tak terduga diteruskan ke error
loop. Tidak ada generated code yang dijalankan.

## Build dan debugging

Build dengan `make`, jalankan pengujian dengan `make test`. Output berada di
`ES:0000` (`2000:0000`, alamat fisik `20000h`), panjangnya di
`WORK_EMIT_LENGTH` pada alamat fisik `6000Ah`.
