# Fixture IR tidak valid

Kasus magic, versi, panjang, EOF operand, opcode asing, terminator hilang,
dan data setelah terminator disusun melalui
`tests/ir/ir_fixtures.asm`. Jalankan `make test` untuk merakit dan
memverifikasi kode error masing-masing melalui QEMU.
