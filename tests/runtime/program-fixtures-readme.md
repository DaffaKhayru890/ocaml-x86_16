# Fixture program IR dan arithmetic

## Tujuan dan hubungan

File assembly ini menyusun payload IR alternatif berdasarkan `IR_TEST_CASE`.
`src/examples/program_ir.asm` menyertakan fixture ini hanya pada build test;
script pengujian memilih fixture, merakit ROM, lalu memeriksa hasil QEMU.
Fixture valid menguji operasi runtime, sedangkan nomor 11 ke atas menguji
error validator/compiler atau kapasitas tabel. Kasus 108–111 menguji slot
invalid, STORE_LOCAL tanpa nilai, dan comparison dengan operand kurang.

## Register dan alamat

Fixture adalah data ROM, bukan kode yang dieksekusi. Label dan payload
dibaca melalui `CS:SI`; header mengukur payload, sementara compiler memakai
`DS=6000h`, `ES=2000h`, dan work memory. Tidak ada stack/address yang
diakses langsung oleh definisi `db`/`dw`.

## Urutan dan kasus

Setiap `db IR_ICONST` diikuti word immediate little-endian. Opcode ADD/SUB/
MUL/NEG dan HALT membentuk program stack-based; `IR_END` menutup payload.
Kasus valid arithmetic 1–10 mencakup nilai positif/negatif dan wraparound.
kasus error 11–20 serta 101–111 sengaja memicu underflow, depth salah, opcode
belum didukung, flow invalid, IR terpotong, data sesudah END, overflow tabel,
slot invalid, uninitialized local, atau comparison underflow.

Assembler directive `%if/%elif` memilih satu kasus dan `dw` menulis nilai
16-bit little-endian; tidak ada routine atau instruksi runtime dalam file
fixture. Jalankan `make test` untuk membangun dan menjalankan kasus yang
dipilih. Detail semantik ada di `docs/stack-machine.md`.
