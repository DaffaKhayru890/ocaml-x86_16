# Pengujian Phase 05

## Prasyarat dan perintah

Tes regresi membutuhkan NASM, QEMU, `ndisasm`, dan Python 3 standard library.
Pemeriksaan GDB terpisah membutuhkan GDB. Tooling host hanya mengompilasi
fixture, menjalankan QEMU, membaca register/memori, dan membandingkan hasil;
compiler dan runtime tetap Assembly bare-metal.

```sh
make test
python3 tests/run_qemu_tests.py --list
python3 tests/run_qemu_tests.py --suite control-flow
make test-gdb
```

Di Windows gunakan `scripts\test.bat --suite all` dan
`scripts\test-gdb.bat`. Suite QEMU dan tes GDB memeriksa dependencies sebelum
menjalankan build.

## Suite dan manifest

| Suite | Tujuan |
|---|---|
| `all` | Semua program valid dan semua fixture error |
| `runtime` | Semua program valid melalui CPU QEMU |
| `codegen` | Seluruh output machine code dan disassembly 16-bit |
| `arithmetic` | Arithmetic, wrap 16-bit, comparison signed, nilai batas |
| `variables` | Akses local, overwrite, batas slot, dan ekspresi |
| `control-flow` | Forward/backward branch, loop, relocation, target jauh, label invalid |
| `errors` | Semua jalur error compiler |
| `ir-errors` | Header, opcode, operand, panjang, dan terminator IR |
| `emitter` | Self-test emitter byte/word, batas buffer, overflow |

Manifest rinci ID dan tujuan fixture ada di
[regression-testing.md](regression-testing.md). `tests/run_qemu_tests.py`
menjadi sumber ekspektasi untuk hasil runtime dan status error.

## Validasi yang dijalankan

Setiap ROM fixture diperiksa berukuran 65.536 byte dan memiliki lima byte
reset vector `EA 00 00 00 F0`. QEMU memulai CPU tanpa boot disk dan test
harness menunggu `HLT=1` melalui HMP. Fixture sukses memeriksa status,
segment register, stack, panjang output, bytes yang diambil dari RAM,
hasil runtime, local bitmap, dan local slots. `ndisasm -b 16` membaca bytes
generated aktual; expected bytes dicocokkan terpisah dengan template IR.

Tes statis juga memastikan nilai kode error unik, kapasitas tabel tidak
overlap, dan tabel berada dalam segment work. Compiler sendiri memeriksa
prologue, ukuran, batas buffer, record instruction/code offset, encoding
setiap instruksi, semua sequence HALT, status relocation, serta target dan
displacement branch sebelum far jump.

`tests/run_gdb_test.py` menjalankan satu program default dengan QEMU `-S`,
menginspeksi reset vector melalui GDB, berhenti di generated entry dan byte
HLT, lalu memeriksa segment register, stack pointer, status compiler, dan
hasil program. Tes ini berhenti tepat sebelum instruksi HLT; tes HMP suite
terpisah membuktikan CPU benar-benar masuk keadaan HLT.

## Batas pengujian

Tes error stack overflow, generated output overflow, CFG iteration limit,
dan rel16 range tidak dapat dicapai melalui IR normal pada batas kapasitas
saat ini. Emitter tetap menguji overflow secara langsung. Alasan dan batas
konfigurasi dibahas pada [limitations.md](limitations.md); kode error tidak
dianggap lulus hanya karena nilainya didefinisikan.

Tes Windows disediakan tetapi belum dieksekusi pada lingkungan Linux ini.
