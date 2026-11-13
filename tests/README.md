# Pengujian compiler Phase 03

Jalankan `make test`. Python standard library hanya menjadi pengendali host
untuk merakit fixture, meluncurkan QEMU, membaca HMP monitor, dan memeriksa
RAM; reader, dispatcher, status, bitmap, codegen, serta runtime tetap
sepenuhnya Assembly.

Kasus arithmetic 0–10 menjaga regresi Phase 02. Program 21–23 dan 36–38
menguji akses slot, overwrite, batas slot, serta penggunaan variabel dalam
ekspresi. Program 24–35 menguji EQ/NE/LT/GT true/false dan operand negatif.
Fixture 11–20 dan 101–111 menguji error IR, stack, local, comparison, dan
overflow codegen. Pemeriksaan mencakup code bytes, panjang, hasil,
register runtime, bitmap, serta nilai slot.

Fixture error harus berhenti pada firmware `CS=F000h` dengan status/kode
yang diharapkan; generated code tidak boleh dieksekusi. QEMU dihentikan
setelah setiap kasus. Tidak ada disk image, OS, BIOS service, atau dependency
Python pihak ketiga.
