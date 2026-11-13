# Pengujian variabel lokal

Fixture dipilih melalui `IR_TEST_CASE` dan didefinisikan di
`src/examples/variable_test_ir.asm` serta `tests/runtime/program-fixtures.asm`.
`make test` memeriksa byte code, slot runtime, bitmap, hasil akhir, dan
register runtime.

Kasus 21–23 mencakup store/load, dua slot, dan overwrite. Kasus 36
menggabungkan variabel dengan LT; 37 menguji ekspresi `(x+y)*z`; 38
menggunakan slot batas 63. Error 13/108/109/110 memeriksa uninitialized
load, indeks 64, dan underflow tanpa mengeksekusi output. Slot dapat diperiksa
dengan `x/hx 0x30002` atau `x/hx 0x30080`; bitmap ada di `0x60020`.
