# Fixture header rusak, EOF operand, opcode asing, IR_END hilang, stack
underflow/depth, dan kapasitas tabel disusun melalui
`tests/runtime/program-fixtures.asm`. Fixture CFG, branch, label, merge, serta
definite-assignment berada di `tests/runtime/branching-fixtures.asm`. Jalankan
`make test` untuk memverifikasi kode error serta hasil runtime melalui QEMU.
