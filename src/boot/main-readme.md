# Entry utama firmware dan penghentian CPU

## Pengantar dan tujuan

Entry utama firmware memanggil `compiler_main` setelah stack siap.
`compiler_main` tidak kembali pada sukses: ia melakukan far jump ke generated
code di RAM. Pada error compiler, CPU berhenti pada error loop firmware.

## Hubungan dengan modul lain

`initialize_segments` memanggil `firmware_main`; `firmware_main` memanggil
compiler. Setelah far jump, compiler tidak lagi aktif. Label `halt_loop`
firmware menjadi jalur yang tidak digunakan pada sukses Phase 05; generated
runtime mempunyai HLT loop sendiri.

## Register dan alamat

CALL dan RET menggunakan pasangan SS:SP yang telah disiapkan (`5000:FFFE`).
Compiler kemudian mengatur DS=`6000h` dan ES=`2000h`, sedangkan CS tetap
`F000h`. Generated runtime kemudian mengubah CS/DS/SS ke
`2000h/3000h/4000h`.

## Urutan instruksi dan alur

1. `firmware_main` memanggil compiler.
2. Pada sukses compiler melakukan far jump, bukan CALL, ke segment `2000h`.
3. Runtime prologue menyiapkan DS dan SS:SP runtime.
4. Generated HALT menyimpan hasil lalu menjalankan HLT/JMP loop.
5. Error compiler berhenti di error loop pada segment firmware.

`CLI` telah dijalankan sebelumnya, sehingga IRQ maskable tidak membangunkan
CPU. NMI tetap dapat membangunkannya; tidak ada IDT atau handler interrupt
yang dipasang pada phase ini. HLT bukan shutdown permanen.

## Build dan debugging

Jalankan `make test` untuk memeriksa code generation dan runtime melalui
QEMU. Petunjuk inspeksi tersedia di `docs/debugging.md`.
