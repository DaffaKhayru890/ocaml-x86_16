# Fixture untuk header rusak, EOF operand, opcode asing, IR_END hilang, stack
underflow, stack depth final, opcode belum didukung, HALT ganda, instruksi
setelah HALT, dan virtual-stack overflow disusun melalui
`tests/runtime/program-fixtures.asm`. Jalankan `make test` untuk merakit dan
memverifikasi kode error masing-masing melalui QEMU.
