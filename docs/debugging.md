# Debugging compiler dan runtime Phase 02

## Jalankan build dan tes

```sh
make
make test
```

`make test` merakit ROM untuk setiap fixture, menjalankannya di QEMU dengan
monitor HMP lokal, lalu memeriksa register dan RAM. Build membuat listing
`build/custom_rom.lst` untuk menghubungkan offset instruksi dengan source.

## Debug firmware/compiler dengan GDB

Jalankan `scripts/run-qemu.sh`, kemudian:

```gdb
set architecture i386
target remote :1234
info registers
x/5bx 0xfffffff0
stepi
```

Reset vector harus berisi `EA 00 00 00 F0`; single-step far jump menuju
`F000:0000`. Untuk berhenti di titik compiler/runtime gunakan offset label
dari listing. Far jump ke generated code terjadi hanya setelah seluruh
validasi lulus.

## Register dan alamat akhir

Sebelum compiler transfer kontrol: CS=`F000h`, DS=`6000h`, ES=`2000h`,
SS:SP=`5000:FFFE`. Ketika generated program mencapai HLT:

- CS=`2000h`, DS=`3000h`, ES=`2000h`, SS:SP=`4000:FFFE`.
- EIP berada tepat setelah HLT pada akhir buffer.
- HLT flag aktif; jalur program tidak kembali ke compiler.
- Status compiler tetap di alamat fisik `60000h`; sukses=`0002h`.
- SI menunjuk akhir IR, DI dan `WORK_EMIT_LENGTH` memuat code length.
- `WORK_STACK_DEPTH=0`; `WORK_MAX_STACK_DEPTH` mencatat puncak compile-time.

Periksa status, stack, dan hasil:

```gdb
x/31bx 0x60000
x/64bx 0x20000
x/hx 0x30000
```

QEMU HMP dapat memakai perintah `info registers`, `xp /64bx 0x20000`, dan
`xp /1hx 0x30000`. Nilai hasil adalah word little-endian; contoh hasil 36
tersimpan sebagai `24 00`. Nilai negatif memakai two's complement, misalnya
-14 adalah `F2 FF` dan dapat dibaca sebagai `FFFEh` serta ditafsirkan signed
`-14`.

## Generated code

Codegen default `(7+5)*3` menghasilkan 43 byte:

```text
FA B8 00 30 8E D8 B8 00 40 8E D0 BC FE FF
B8 07 00 50 B8 05 00 50 5B 58 01 D8 50
B8 03 00 50 5B 58 F7 EB 50
58 A3 00 00 F4 EB FD
```

Output berada di RAM fisik `20000h`; code dieksekusi langsung dengan
`CS:IP=2000:0000`. Tidak ada file machine-code host atau BIOS output.

## Kode error

| Kode | Arti |
|---:|---|
| `0001h–0009h` | Error header/IR/emitter dari Phase 01 |
| `000Ah` | Stack underflow |
| `000Bh` | Virtual stack overflow |
| `000Ch` | Final stack depth bukan satu |
| `000Dh` | Opcode dikenal tetapi belum didukung |
| `000Eh` | Code generation gagal |
| `000Fh` | Runtime generated code tidak valid |
| `0010h` | Program kosong atau HALT tanpa hasil |
| `0011h` | HALT bukan instruksi semantik terakhir |

Error compiler berhenti di HLT loop firmware dengan CS=`F000h`; tidak ada far
jump. Kesalahan emitter saat codegen juga mencegah eksekusi buffer parsial.
