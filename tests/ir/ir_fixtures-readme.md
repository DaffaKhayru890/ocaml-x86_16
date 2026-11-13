# Fixture IR untuk pengujian error

## Tujuan

`ir_fixtures.asm` menyediakan payload alternatif saat ROM dirakit dengan
`IR_TEST_CASE` bernilai 1 sampai 7. Berkas ini dimasukkan oleh contoh IR
sehingga tiap fixture benar-benar melewati reader dan dispatcher firmware.

## Fixture

| Nilai | Kerusakan | Error yang diharapkan |
|---:|---|---:|
| 1 | Magic salah | `0001h` |
| 2 | Versi tidak didukung | `0002h` |
| 3 | Panjang header tidak cocok | `0003h` |
| 4 | Operand imm16 terpotong | `0004h` |
| 5 | Opcode asing | `0005h` |
| 6 | IR_END hilang | `0006h` |
| 7 | Byte setelah IR_END | `0007h` |

Header fixture 1–3 dibentuk di `src/examples/program_ir.asm`; payload rusak
dibentuk di berkas ini. Fixture tidak disertakan pada ROM produksi default.

## Build dan debugging

Jalankan `make test`. Pengujian membangun ROM terpisah untuk setiap nilai,
memastikan reset vector tetap benar, lalu memeriksa status dan error pada
work memory QEMU.
