# Code generator

## Konsep dan tujuan

Modul ini menjadi Pass 2 setelah seluruh IR dan stack tervalidasi. Ia
menginisialisasi pembacaan IR dan emitter kembali, mengirim setiap opcode ke
generator terkait, lalu memeriksa bentuk executable buffer sebelum compiler
melakukan far jump.

## Hubungan dan register

`codegen_init` memakai reader (`CS:SI`), work memory (`DS=6000h`) dan emitter
(`ES:DI`, `ES=2000h`). `codegen_generate_program` memakai AX/BX/CX untuk
dispatch/validasi, SI sebagai pointer IR, dan DI sebagai output offset.
Prosedur mempertahankan DS/ES; register lain tidak dijanjikan tetap.

## Urutan prosedur

- `codegen_init`: bersihkan virtual stack/flags; status RUNNING; ulangi
  `ir_init` serta header validation; inisialisasi emitter.
- `codegen_dispatch`: pilih ICONST, ADD, SUB, MUL, NEG, atau HALT; opcode
  tanpa generator mencatat `ERR_UNSUPPORTED_OPCODE`.
- `codegen_generate_program`: baca opcode, validasi efek stack, emit, dan
  ulang sampai IR_END; lalu validasi akhir dan buffer.
- `codegen_validate_generated_code`: periksa flag prologue/HALT/IR_END,
  stack kosong, kapasitas/panjang, 14 byte prologue dan tujuh byte suffix.

Pemeriksaan word memakai little-endian x86; contoh word di offset nol
`B8FAh` mewakili byte `FA B8`. Prosedur validasi membaca kembali RAM output,
bukan mengubahnya.

## Build dan debugging

`make test` menguji hasil dan error. Periksa DI/panjang di `6000Ah` dan byte
output di `20000h` menggunakan GDB; rincian ada di `docs/debugging.md`.
