# Fixture IR valid

Tabel valid yang mencakup seluruh opcode berada di
`src/examples/program_ir.asm` dan digunakan pada build default
(`IR_TEST_CASE=0`). `make test` memvalidasi jumlah instruksi, terminator,
remaining length, dan output self-test emitter.
