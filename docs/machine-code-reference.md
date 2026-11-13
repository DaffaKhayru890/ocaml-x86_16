# Referensi encoding machine code

Semua byte dihasilkan langsung ke ES:DI melalui emit8/emit16. Word disimpan
little-endian; tidak digunakan assembler pada runtime.

| Instruksi 8086 | Encoding | Catatan |
|---|---|---|
| `cli` | `FA` | Menonaktifkan IRQ maskable |
| `mov ax,imm16` | `B8 lo hi` | Immediate little-endian |
| `mov ds,ax` | `8E D8` | Segment data runtime |
| `mov ss,ax` | `8E D0` | Segment stack runtime |
| `mov sp,imm16` | `BC lo hi` | SP runtime |
| `push ax` | `50` | Mendorong word |
| `pop ax` | `58` | Mengambil word |
| `pop bx` | `5B` | Mengambil operand kanan |
| `add ax,bx` | `01 D8` | left+right |
| `sub ax,bx` | `29 D8` | left-right |
| `imul bx` | `F7 EB` | signed DX:AX; gunakan AX |
| `neg ax` | `F7 D8` | Negasi two's complement |
| `mov [0000h],ax` | `A3 00 00` | Offset DS absolut |
| `hlt` | `F4` | Menunggu event |
| `jmp short -3` | `EB FD` | Kembali ke opcode HLT |

Contoh ICONST `1234h`: `B8 34 12 50`. Runtime prologue:
`FA B8 00 30 8E D8 B8 00 40 8E D0 BC FE FF`. Sequence result/HLT:
`58 A3 00 00 F4 EB FD`.

Encoding ini adalah subset instruksi 8086, termasuk immediate register,
stack, arithmetic, moffs store, far JMP firmware, dan short JMP.
