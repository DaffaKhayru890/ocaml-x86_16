# Proses boot

1. QEMU membuat machine `pc` dan memasang `build/custom_rom.bin` melalui
   opsi `-bios`, menggantikan ROM firmware default.
2. CPU mulai fetch dari alamat fisik `FFFFFFF0h`, offset `FFF0h` di dalam
   mapping ROM atas.
3. Byte reset vector menjalankan far jump `F000:0000`. Machine PC QEMU
   menyediakan alias firmware pada rentang `F0000h–FFFFFh`.
4. `firmware_entry` menonaktifkan IRQ maskable dengan CLI dan menghapus DF
   dengan CLD. Ia belum memakai stack.
5. `initialize_segments` mengatur DS/ES ke `F000h`, SS ke `5000h`, dan SP ke
   `FFFEh`. Setelah itu CALL/RET aman.
6. `firmware_main` memanggil compiler. Pass 1 memvalidasi header, opcode,
   operand, terminator, virtual stack, indeks slot, dan inisialisasi local
   tanpa menghasilkan code.
7. Compiler menjalankan self-test emitter secara terpisah, lalu mereset
   pointer/output dan mengulangi pembacaan IR untuk Pass 2.
8. Code generator menghasilkan prologue, arithmetic, akses local, comparison
   signed, dan urutan halt/hasil lewat emit8/emit16 ke RAM `2000:0000`.
9. Compiler memvalidasi code, menyimpan `STATUS_SUCCESS`, lalu far jump ke
   `2000:0000`. Jika ada error, ia tidak melompat dan berhenti di firmware.
10. Prologue mengatur DS=`3000h`, SS:SP=`4000:FFFE`; program memakai slot
    lokal di DS:`0002h–0081h`, menyimpan hasil di `3000:0000`, lalu HLT.

Tidak ada BIOS interrupt, syscall, atau layanan OS. Tidak ada IDT/handler
interrupt yang dipasang. IF tetap nol; NMI bukan IRQ maskable dan masih
dapat membangunkan HLT. Perangkat virtual tidak dikonfigurasi untuk menjadi
bagian dari antarmuka firmware. Generated instructions sepenuhnya berasal
dari IR statis dan tidak memanggil BIOS atau OS.

Reset vector 8086 klasik berada di alamat fisik `FFFF0h` melalui
`FFFF:0000`, berbeda dari reset PC modern QEMU yang dituju di sini.
