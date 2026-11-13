# Dispatcher IR

`ir_dispatch_opcode` mengambil satu opcode, menyimpan nilainya ke
`WORK_CURRENT_OPCODE`, lalu meminta `ir_validate_instruction` memvalidasi
instruksi. Dispatcher hanya mengenali bentuk/ukuran operand; ia tidak
menghasilkan byte machine code dan tidak menjalankan instruksi. Sesudahnya
compiler orchestration mengisi instruction/label tables, resolve target,
dan menganalisis CFG sebelum emission dari tabel pada tahap berikutnya.

## Ukuran operand

- Dua byte: ICONST, LABEL, JMP, JZ, JNZ.
- Satu byte: LOAD_LOCAL, STORE_LOCAL.
- Nol byte: ADD, SUB, MUL, NEG, EQ, NE, LT, GT, HALT.
- END: terminator tanpa operand, tidak dihitung sebagai instruksi.

Operand terakhir disimpan pada `WORK_DECODED_OPERAND`; ukurannya pada
`WORK_OPERAND_SIZE`. `WORK_DECODED_COUNT` bertambah setelah instruksi yang valid, termasuk LABEL.
LABEL tidak masuk instruction table executable; `control_flow.asm`
menyimpan indeks executable saat deklarasi dan menyelesaikan semua referensi
JMP/JZ/JNZ setelah seluruh IR ter-decode.

`ir_validate_program` meneruskan ke `control_flow_validate_program`, yang
mengulang sampai END ditemukan dengan remaining nol, membangun tabel,
resolve branch, lalu memulai analisis CFG. Dispatcher tidak memanggil
emitter.
Payload habis lebih dulu menghasilkan MISSING_END. Remaining bukan nol
setelah END menghasilkan TRAILING_DATA. Opcode tak dikenal, unsupported,
dan operand terpotong mempunyai error tersendiri. Semua error disimpan di DS
work memory dan menghentikan alur utama.

Jalankan `make test` untuk menguji opcode aritmetika, slot lokal,
perbandingan, opcode belum didukung, stack, terminator, dan operand rusak.
