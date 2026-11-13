# Contoh static IR

## Konsep dan tujuan

Tabel ini adalah bytecode IR statis di dalam ROM, bukan source OCaml.
Compiler membaca header/opcode, membangun instruction/label tables, lalu
menghasilkan machine code dari tabel setelah CFG tervalidasi.

## Format dan layout

`program_ir` berisi empat byte magic `IR16`, versi `IR_VERSION`, panjang
payload word little-endian, lalu payload. Panjang dihitung assembler dari
`program_ir_end - program_ir_payload`. Seluruh label merupakan offset flat
binary yang dibaca dengan CS:SI.

## Isi payload

Contoh default menghitung `(7+5)*3`: memasukkan 7 dan 5, ADD, memasukkan 3,
MUL, HALT, IR_END. IR_ICONST memuat imm16; arithmetic menggunakan stack
virtual. IR_HALT menyebabkan hasil runtime disimpan ke `3000:0000`. Label,
STORE_LOCAL dan LOAD_LOCAL menggunakan indeks slot 0–63; EQ, NE, LT, dan GT
menghasilkan Boolean 0/1. LABEL memetakan ID ke instruksi executable;
JMP/JZ/JNZ menghasilkan branch 8086 dan displacement rel16.

Saat pengujian, `IR_TEST_CASE` memilih program arithmetic, variabel,
comparison, atau fixture error. Variabel dan comparison berada di
`variable_test_ir.asm` dan `comparison_test_ir.asm`; fixture error berada di
`tests/runtime/program-fixtures.asm` dan `tests/runtime/branching-fixtures.asm`.
Nilai default nol menyusun contoh
`(7+5)*3`.

## Build dan debugging

Build ROM dengan `make`; jalankan program dan fixture dengan `make test`.
SI setelah tahap decode menunjuk tepat setelah IR_END dan remaining bernilai
nol; tahap emission memakai instruction table, bukan membaca ulang IR.
