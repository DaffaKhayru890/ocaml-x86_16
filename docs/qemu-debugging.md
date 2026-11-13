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
simbol debug, gunakan `stepi` dan inspeksi disassembly. Sebelum codegen transfer kontrol, DS=`6000`, ES=`2000`, SS=`5000`, SP
`FFFE`; SI menunjuk IR dan DI menunjuk output. Setelah far jump runtime,
CS=`2000`, DS=`3000`, SS=`4000`, SP kembali `FFFE`. Status, output, dan hasil
dijelaskan rinci pada `docs/debugging.md`.

## Perilaku HLT

Loop CLI/HLT menonaktifkan IRQ maskable dan menunggu event, lalu melompat
kembali ke HLT jika dibangunkan. HLT bukan shutdown. NMI dapat membangunkan
CPU dan tidak ada handler NMI yang disiapkan.

## Hasil aktual

Validasi Linux aktual: NASM menghasilkan ROM 65.536 byte dan reset vector
`EA 00 00 00 F0`. `make test` lulus untuk 43 program runtime dan 27 fixture
error. Seluruh output valid dibandingkan byte-per-byte dan dibaca oleh
`ndisasm -b 16`; seluruh fixture mencapai HLT firmware melalui HMP.

`make test-gdb` memeriksa CPU reset pada `CS:F000 EIP:FFF0`, lima byte di
`FFFFFFF0h`, lalu entry generated code `CS:IP=2000:0000`. Di entry compiler
telah menyimpan `STATUS_SUCCESS`; `DS=6000`, `ES=2000`, `SS:SP=5000:FFFA`.
Untuk program default, breakpoint pada `2000:0028` berhenti tepat sebelum
byte HLT `F4`; panjang generated code 43 byte, runtime `DS=3000`,
`ES=2000`, `SS:SP=4000:FFFE`, `EAX=0024`, dan hasil `30000h=0024`.
QEMU HMP secara terpisah memastikan instruksi HLT benar-benar dieksekusi.

Tes Windows disediakan tetapi belum dijalankan pada lingkungan ini.
