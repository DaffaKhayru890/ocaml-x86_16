# Pengujian compiler Phase 04

Jalankan `make test`. Python standard library hanya menjadi pengendali host
untuk merakit fixture, meluncurkan QEMU, membaca HMP monitor, dan memeriksa
RAM; reader, dispatcher, status, bitmap, codegen, serta runtime tetap
sepenuhnya Assembly.

Kasus arithmetic 0–10 menjaga regresi sebelumnya. Program 21–23 dan 36–38
menguji akses slot, overwrite, batas slot, serta penggunaan variabel dalam
ekspresi. Program 24–35 menguji EQ/NE/LT/GT true/false dan operand negatif.
Kasus 40–43 dan 49 menguji jump forward/backward, JZ/JNZ, loop, merge valid,
dan beberapa terminal HALT. Kasus 44–48 menguji merge depth, label invalid,
serta definite assignment; 51–52 menguji batas relocation dan label.
Fixture 11–20 dan 101–111 menguji error IR, stack, local, comparison, dan
kapasitas tabel. Pemeriksaan mencakup code bytes, panjang, hasil, register
runtime, bitmap, serta nilai slot.

Fixture error harus berhenti pada firmware `CS=F000h` dengan status/kode
yang diharapkan; generated code tidak boleh dieksekusi. QEMU dihentikan
setelah setiap kasus. Tidak ada disk image, OS, BIOS service, atau dependency
Python pihak ketiga.
