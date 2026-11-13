# Pengujian compiler Phase 05

Jalankan `make test` untuk seluruh suite atau `make test-control-flow`,
`make test-codegen`, `make test-arithmetic`, `make test-variables`,
`make test-errors`, `make test-ir-errors`, dan `make test-emitter` untuk
memilih kategori. `python3 tests/run_qemu_tests.py --list` menampilkan
manifest. GDB dijalankan terpisah dengan `make test-gdb`.

Kasus arithmetic 0–10 menjaga regresi sebelumnya. Program 21–23 dan 36–38
menguji akses slot, overwrite, batas slot, serta penggunaan variabel dalam
ekspresi. Program 24–35 dan 56–59 menguji EQ/NE/LT/GT, signed comparison,
dan batas min/max. Kasus 40–43, 49–50, dan 54–55 menguji JMP/JZ/JNZ, loop,
multiple HALT, dan rel16 branch yang lebih jauh dari jangkauan rel8.
Kasus 44–48, 51–53 menguji merge, label invalid, definite assignment,
kapasitas tabel, dan label akhir yang tidak mempunyai instruksi. Fixture
11–20 dan 101–111 menguji error IR, stack, local, dan kapasitas.

Pemeriksaan runtime mencakup register, stack, hasil, bitmap local, slot,
panjang dan seluruh machine code. Setiap output sukses juga divalidasi
dengan `ndisasm -b 16`; byte template diperiksa lagi oleh compiler Assembly
sebelum far jump.

Fixture error harus berhenti pada firmware `CS=F000h` dengan status/kode
yang diharapkan; generated code tidak boleh dieksekusi. QEMU dihentikan
setelah setiap kasus. Tidak ada disk image, OS, BIOS service, atau dependency
Python pihak ketiga. Penjelasan validasi dan limitasi ada di
`docs/testing.md` dan `docs/limitations.md`.
