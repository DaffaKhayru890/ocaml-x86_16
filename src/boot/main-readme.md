# Entry utama firmware dan penghentian CPU

## Pengantar dan tujuan

Entry utama firmware memanggil `compiler_main` setelah stack siap, lalu
kembali ke inisialisasi firmware. Setelah compiler sukses, firmware masuk ke
loop `hlt`. Tidak ada layanan perangkat atau output BIOS.

## Hubungan dengan modul lain

`initialize_segments` memanggil `firmware_main`; `firmware_main` memanggil
compiler dan kembali setelah sukses. Sesudah RET, kendali berpindah ke
`halt_loop`, yang tidak kembali. Error compiler mempunyai error loop sendiri.

## Register dan alamat

CALL dan RET menggunakan pasangan SS:SP yang telah disiapkan (`5000:FFFE`).
Compiler kemudian mengatur DS=`6000h` dan ES=`2000h`, sedangkan CS tetap
`F000h`. `HLT` tidak mengubah segment register.

## Urutan instruksi dan alur

1. `firmware_main` memanggil compiler Phase 01.
2. Pada sukses, `ret` memulangkan kendali ke inisialisasi.
3. `jmp halt_loop` memasuki penghentian terkontrol.
4. `hlt` menghentikan eksekusi sampai ada interrupt atau reset.
5. `jmp halt_loop` memastikan CPU kembali tidur jika suatu event
   membangunkannya.

`CLI` telah dijalankan sebelumnya, sehingga IRQ maskable tidak membangunkan
CPU. NMI tetap dapat membangunkannya; tidak ada IDT atau handler interrupt
yang dipasang pada phase ini. HLT bukan shutdown permanen.

## Build dan debugging

Jalankan `make test` untuk memeriksa compiler dan emitter melalui QEMU.
Petunjuk inspeksi status/output tersedia di `docs/debugging.md`.
