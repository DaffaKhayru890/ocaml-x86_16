# Contoh static IR

## Konsep dan tujuan

Tabel ini adalah bytecode IR statis di dalam ROM, bukan source OCaml.
Compiler Phase 01 membaca header lalu memvalidasi setiap opcode dan operand.
Tidak ada lexer, parser, label resolution, translasi instruksi, atau eksekusi.

## Format dan layout

`program_ir` berisi empat byte magic `IR16`, versi `IR_VERSION`, panjang
payload word little-endian, lalu payload. Panjang dihitung assembler dari
`program_ir_end - program_ir_payload`. Seluruh label merupakan offset flat
binary yang dibaca dengan CS:SI.

## Isi payload

Contoh memasukkan immediate 42, menyimpan dan memuat slot lokal nol,
memasukkan 10, memuat opcode aritmetika/perbandingan tanpa operand, lalu
label dan jump dengan operand word, HALT, dan IR_END. Label sengaja tidak
di-resolve pada phase ini. IR_HALT adalah opcode data; CPU tidak mengeksekusi
instruksi tersebut.

Saat pengujian, `IR_TEST_CASE` memilih fixture rusak dalam
`tests/ir/ir_fixtures.asm`. Nilai default nol menyusun tabel valid.

## Build dan debugging

Build ROM dengan `make`; jalankan fixture dengan `make test`. SI setelah
validasi menunjuk tepat setelah IR_END dan remaining bernilai nol.
