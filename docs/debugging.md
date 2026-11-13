# Debugging compiler Phase 01

## Jalankan

Build dan tes:

```sh
make
make test
```

Jalankan ROM berhenti sebelum instruksi pertama:

```sh
./scripts/run-qemu.sh
```

Hubungkan GDB:

```gdb
set architecture i386
target remote :1234
info registers
x/5bx 0xfffffff0
stepi
info registers
```

Byte reset vector seharusnya `ea 00 00 00 f0`; far jump mencapai `CS:IP =
F000:0000`. Untuk breakpoint setelah far jump, gunakan offset label dari
`build/custom_rom.lst` dan alamat linear alias `0xF0000 + offset`. Sesudah
breakpoint, `continue` menuju HLT bisa menunggu tanpa batas karena HLT
memang menidurkan CPU. Jika perlu menginspeksi state akhir secara mudah,
jalankan QEMU tanpa `-S` dengan HMP monitor aktif lalu gunakan `info
registers` dan `xp`.

Pada build saat ini, `halt_loop` berada pada offset `001Ch`, sehingga
breakpoint dapat dipasang sebelum melanjutkan dari reset:

```gdb
break *0xf001c
continue
info registers cs eip ds es ss esp si di
x/22bx 0x60000
x/5bx 0x20000
```

Listing dapat berubah jika kode berubah; gunakan offset `halt_loop` yang
tertera di listing build terbaru.

## Register dan memori

Pada jalur sukses yang sudah selesai:

- CS=`F000h`, DS=`6000h`, ES=`2000h`, SS=`5000h`.
- SI menunjuk akhir tabel IR; remaining di `60004h` bernilai nol.
- DI bernilai lima; panjang output di `6000Ah` bernilai lima.
- Status pada `60000h` bernilai `0002h` (SUCCESS); error `60002h` nol.
- Output berada di alamat fisik `20000h` dan harus `B8 34 12 50 58`.

Perintah GDB untuk memeriksa buffer/status:

```gdb
x/22bx 0x60000
x/5bx 0x20000
```

QEMU HMP dapat membaca alamat fisik secara langsung, contohnya
`xp /5bx 0x20000` dan `xp /22bx 0x60000`. `make test` menjalankan monitor
otomatis untuk memeriksa status success/error, HLT, panjang IR, dan output.
Tidak ada output BIOS atau OS.

## Kode status dan error

`WORK_STATUS=0002h` berarti sukses; `FFFFh` berarti error. Kode error:

| Kode | Arti |
|---:|---|
| `0001h` | Magic tidak valid |
| `0002h` | Versi tidak didukung |
| `0003h` | Panjang payload salah |
| `0004h` | Operand/IR berakhir sebelum waktunya |
| `0005h` | Opcode tidak dikenal |
| `0006h` | IR_END hilang |
| `0007h` | Ada data setelah IR_END |
| `0008h` | Output overflow |
| `0009h` | Self-test emitter gagal |

## Listing assembler

Build menghasilkan `build/custom_rom.lst`, yang menghubungkan source dan
offset machine code untuk mencari alamat breakpoint. Binary ROM tetap tepat
65536 byte dan reset vector tetap diperiksa oleh build script.
