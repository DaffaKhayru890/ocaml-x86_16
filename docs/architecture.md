# Arsitektur firmware dan compiler

## Jalur eksekusi

```text
Reset CPU (FFFFFFF0h)
        |
        v
ROM reset vector (offset FFF0h)
        |
        | far jump F000:0000
        v
firmware_entry (CLI, CLD)
        |
        v
initialize_segments (DS, ES, SS, SP)
        |
        | CALL / RET
        v
firmware_main
        |
        v
compiler_main
        |
        +--> Decode IR -> instruction/label tables -> resolve branch
        |                     -> CFG + stack/local fixed-point
        |
        +--> Emitter self-test terisolasi
        |
        +--> Emission table -> codegen -> relocation rel16
        |
        +--> validasi code -> far jump 2000:0000 -> runtime -> HLT
```

Perintah `qemu-system-i386 -machine pc -bios ...` memuat firmware yang
disediakan sebagai pengganti citra BIOS bawaan. Pemetaan reset pada machine
PC modern ini menempatkan pengambilan instruksi reset di bagian atas ruang
alamat fisik 32-bit. Firmware 64 KiB yang sama juga dapat diakses melalui
jendela legacy `F0000h`, sehingga far jump 16-bit dapat beralih ke alamat
real-mode biasa. Proyek ini memverifikasi byte dan eksekusi nyata dengan
QEMU/GDB, bukan menganggap opsi `-bios` saja sebagai bukti.

## Batas 8086 dan CPU modern

8086/8088 klasik memulai dari CS:IP `FFFF:0000`, ekuivalen fisik `FFFF0h`.
CPU x86 modern yang ditiru QEMU memulai dari alamat fisik `FFFFFFF0h`,
dengan basis CS tersembunyi di `FFFF0000h` dan EIP `FFF0h`. Keduanya tidak
boleh dianggap sebagai reset mapping yang sama. Firmware ini memilih target
machine PC modern; instruksi kodenya sendiri tetap subset 16-bit sederhana.

## Bentuk citra

NASM memakai `BITS 16` dan `ORG 0` untuk menghasilkan offset label di dalam
file flat. Modul entry berada di awal citra. Padding `FFh` menempatkan
instruksi far jump lima byte pada offset `FFF0h`, lalu padding akhir
menghasilkan panjang tepat `10000h`. `ORG` tidak memetakan ROM ke alamat
fisik dan tidak menambahkan prefix ke file.

Sesudah inisialisasi stack Phase 00, firmware menjalankan compiler Phase 04.
Tahap analisis memakai DS=`6000h` dan CS override untuk membaca IR, membangun
tabel, menyelesaikan branch, serta memvalidasi stack/local pada CFG tanpa
output. Self-test emitter dijalankan terpisah. Emission berikutnya membaca
instruction table dan mengeluarkan instruksi dengan ES=`2000h`; relocation
menambal rel16 sebelum validasi akhir dan far jump. Generated code memakai
DS=`3000h` untuk hasil dan 64 slot lokal, serta SS:SP=`4000:FFFE` untuk
stack. EQ/NE/LT/GT menghasilkan Boolean 0/1 melalui CMP dan Jcc 8086.

Dokumen detail: `compiler-architecture.md`, `code-generation.md`,
`stack-machine.md`, `arithmetic.md`, `local-variables.md`,
`local-memory-layout.md`, `comparison.md`, `boolean-representation.md`,
`machine-code-reference.md`, `runtime.md`, dan `debugging.md`.
