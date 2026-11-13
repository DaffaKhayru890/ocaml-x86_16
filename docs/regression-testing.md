# Manifest regresi

Fixture adalah byte IR statis; ID diteruskan ke NASM dengan
`IR_TEST_CASE`. Harness menguji ROM yang sama di QEMU dan membandingkan
hasil aktual dengan expected result yang terpisah.

| ID | Kategori | Tujuan |
|---|---|---|
| 0–10 | Arithmetic | Dasar, signed value, wrap 16-bit, negasi |
| 14–15 | Runtime | Banyak HALT dan instruksi sesudah HALT yang unreachable |
| 21–23 | Variables | Store/load, dua slot, overwrite |
| 24–35 | Comparison | EQ/NE/LT/GT true/false dan operand negatif |
| 36–38 | Integration | Local pada ekspresi, slot lokal batas atas |
| 40 | Control flow | JMP forward melewati instruksi unreachable |
| 41 | Control flow | Loop counter dan JNZ backward |
| 42–43 | Control flow | JZ/JNZ forward dan merge |
| 44 | Error | Stack-depth mismatch pada merge |
| 45 | Error | Label branch tidak didefinisikan |
| 46 | Error | ID label duplicate |
| 47 | Error | Branch menunjuk label setelah instruction terakhir |
| 48 | Error | Local hanya diinisialisasi pada satu jalur |
| 49 | Control flow | Dua terminal HALT reachable |
| 50 | Control flow | LOAD_LOCAL unreachable setelah HALT |
| 51 | Error | Relocation table overflow |
| 52 | Error | Label table overflow |
| 53 | Error | Label akhir tanpa instruksi executable, walau tidak direferensikan |
| 54 | Relocation | JZ forward ke target lebih dari 127 byte |
| 55 | Relocation | JZ backward ke target lebih dari 127 byte |
| 56–59 | Comparison | Signed 16-bit min/max, EQ dan NE di batas |
| 101–111 | IR error | Header, panjang, EOF, opcode, terminator, local, dan stack |

Semua program sukses juga dibandingkan byte generated output dengan
referensi test dan diproses oleh `ndisasm -b 16`. HMP memeriksa status,
segment register, stack, hasil, bitmap, dan slot. Test 53 memastikan semua
label tabel harus menunjuk record executable; bukan hanya label yang
direferensikan branch.

`scripts/test.sh --suite NAME` memilih kategori dari `TEST_SUITES` pada
`tests/run_qemu_tests.py`. Kategori tersedia juga melalui
`python3 tests/run_qemu_tests.py --list`. GDB reset-to-HLT diperiksa terpisah
dengan `scripts/test-gdb.sh`, karena membutuhkan GDB dan remote server TCP.

Stack overflow, output codegen overflow, batas iterasi, dan rel16 range tidak
memiliki fixture produksi yang dapat dicapai karena batas kapasitas saat ini.
Emitter self-test langsung menguji write boundary dan overflow primitive;
lihat [limitations.md](limitations.md).
