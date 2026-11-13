# Build, QEMU, dan GDB

## Build

Linux (NASM harus tersedia di PATH):

```sh
make
# atau
./scripts/build.sh
```

Windows:

```bat
scripts\build.bat
```

Build menghasilkan `build/custom_rom.bin`, menolak ukuran selain 65536 byte,
dan memeriksa byte reset vector `EA 00 00 00 F0`. `make clean` menghapus
binary keluaran.

## Jalankan

Linux: `./scripts/run-qemu.sh`. Windows: `scripts\run-qemu.bat`.
Perintah memakai machine PC, RAM 16 MiB, citra ROM kustom dengan `-bios`,
dan opsi `-S -s`. `-S` menahan CPU sebelum eksekusi; `-s` menyediakan GDB
remote TCP port 1234. Tidak ada opsi boot disk atau firmware BIOS default.

## GDB

Di terminal lain:

```sh
gdb
(gdb) set architecture i386
(gdb) target remote :1234
(gdb) info registers
(gdb) x/5bx 0xfffffff0
(gdb) stepi
(gdb) info registers
```

Instruksi pada reset seharusnya byte `EA 00 00 00 F0`. Setelah single-step
far jump, CS:IP seharusnya `F000:0000`. Untuk melihat instruksi di mode
real-mode normal:

```gdb
x/16i $cs*16+$eip
```

Alamat fisik reset tinggi mungkin tidak ditampilkan dengan benar oleh
ekspresi yang hanya mengalikan CS terlihat dan EIP: reset memakai basis CS
tersembunyi khusus. Periksa byte `0xfffffff0` atau hentikan pada entry setelah
far jump.

Untuk pemeriksaan breakpoint dengan simbol, bangun listing/simbol terpisah
atau pasang breakpoint alamat entry setelah far jump (`0xf0000`). Tanpa
simbol debug, gunakan `stepi` dan inspeksi disassembly. Register yang
diperiksa pada entry inisialisasi meliputi CS, IP/EIP, DS, ES, SS, SP/ESP.
Pada `halt_loop`, DS/ES harus `F000`, SS `5000`, dan SP kembali `FFFE`
setelah CALL/RET selesai.

## Perilaku HLT

Loop CLI/HLT menonaktifkan IRQ maskable dan menunggu event, lalu melompat
kembali ke HLT jika dibangunkan. HLT bukan shutdown. NMI dapat membangunkan
CPU dan tidak ada handler NMI yang disiapkan.

## Hasil aktual

Catat hasil build serta inspeksi QEMU/GDB yang benar-benar dijalankan saat
validasi. Keberadaan perintah dan dokumentasi bukan bukti bahwa QEMU/GDB
berhasil dijalankan; jangan menandai tes runtime berhasil tanpa observasi.
