# Dispatcher IR

`ir_dispatch_opcode` mengambil satu opcode, menyimpan nilainya ke
`WORK_CURRENT_OPCODE`, lalu meminta `ir_validate_instruction` memvalidasi
instruksi. Dispatcher hanya mengenali bentuk/ukuran operand; ia tidak
menghasilkan byte machine code dan tidak menjalankan instruksi. Sesudahnya
compiler orchestration memanggil stack validator pada pass pertama, lalu
generator pada pass kedua.

## Ukuran operand

- Dua byte: ICONST, LABEL, JMP, JZ, JNZ.
- Satu byte: LOAD_LOCAL, STORE_LOCAL.
- Nol byte: ADD, SUB, MUL, NEG, EQ, NE, LT, GT, HALT.
- END: terminator tanpa operand, tidak dihitung sebagai instruksi.

Operand terakhir disimpan pada `WORK_DECODED_OPERAND`; ukurannya pada
`WORK_OPERAND_SIZE`. `WORK_DECODED_COUNT` bertambah setelah instruksi yang
valid. LABEL dan target jump hanya dibaca sebagai word; referensi tidak
diselesaikan pada Phase 01.

`ir_validate_program` mengulang sampai END ditemukan dengan remaining nol.
Setiap opcode non-END diteruskan ke `codegen_validate_stack`, yang pass
pertama hanya mengubah compile-time depth dan tidak memanggil emitter.
Payload habis lebih dulu menghasilkan MISSING_END. Remaining bukan nol
setelah END menghasilkan TRAILING_DATA. Opcode tak dikenal, unsupported,
dan operand terpotong mempunyai error tersendiri. Semua error disimpan di DS
work memory dan menghentikan alur utama.

Jalankan `make test` untuk menguji opcode aritmetika, slot lokal,
perbandingan, opcode belum didukung, stack, terminator, dan operand rusak.
