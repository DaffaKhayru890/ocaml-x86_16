# Contoh static IR

## Konsep dan tujuan

Tabel ini adalah bytecode IR statis di dalam ROM, bukan source OCaml.
Compiler membaca header/opcode pada pass pertama, lalu membaca ulang tabel
untuk menghasilkan machine code pada pass kedua.

## Format dan layout

`program_ir` berisi empat byte magic `IR16`, versi `IR_VERSION`, panjang
payload word little-endian, lalu payload. Panjang dihitung assembler dari
`program_ir_end - program_ir_payload`. Seluruh label merupakan offset flat
binary yang dibaca dengan CS:SI.

## Isi payload

Contoh default menghitung `(7+5)*3`: memasukkan 7 dan 5, ADD, memasukkan 3,
MUL, HALT, IR_END. IR_ICONST memuat imm16; arithmetic menggunakan stack
virtual. IR_HALT menyebabkan hasil runtime disimpan ke `3000:0000`. Label,
branch, local, comparison, dan opcode yang belum didukung ditolak.

Saat pengujian, `IR_TEST_CASE` memilih program arithmetic tambahan atau
fixture error di `tests/runtime/program-fixtures.asm`. Nilai default nol
menyusun contoh `(7+5)*3`.

## Build dan debugging

Build ROM dengan `make`; jalankan program dan fixture dengan `make test`.
SI setelah setiap pass menunjuk tepat setelah IR_END dan remaining bernilai
nol.
