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
| `mov ax,[disp16]` | `A1 lo hi` | Membaca slot melalui DS |
| `mov [disp16],ax` | `A3 lo hi` | Menulis slot melalui DS |
| `add ax,bx` | `01 D8` | left+right |
| `sub ax,bx` | `29 D8` | left-right |
| `imul bx` | `F7 EB` | signed DX:AX; gunakan AX |
| `neg ax` | `F7 D8` | Negasi two's complement |
| `cmp ax,bx` | `39 D8` | Memperbarui FLAGS tanpa menyimpan selisih |
| `je rel8` | `74 rel8` | Jcc jika sama |
| `jne rel8` | `75 rel8` | Jcc jika tidak sama |
| `jge rel8` | `7D rel8` | Signed: kiri ≥ kanan |
| `jle rel8` | `7E rel8` | Signed: kiri ≤ kanan |
| `jmp rel16` | `E9 lo hi` | Near relative jump 8086 |
| `jz label` | `58 85 C0 75 03 E9 lo hi` | POP/TEST, JNZ melewati JMP, lalu near jump |
| `jnz label` | `58 85 C0 74 03 E9 lo hi` | POP/TEST, JZ melewati JMP, lalu near jump |
| `mov [0000h],ax` | `A3 00 00` | Offset DS absolut |
| `hlt` | `F4` | Menunggu event |
| `jmp short -3` | `EB FD` | Kembali ke opcode HLT |

Contoh ICONST `1234h`: `B8 34 12 50`. Runtime prologue:
`FA B8 00 30 8E D8 B8 00 40 8E D0 BC FE FF`. Sequence result/HLT:
`58 A3 00 00 F4 EB FD`.

Comparison menghasilkan pola `5B 58 39 D8 B8 00 00 Jcc 03 B8 01 00 50`.
Jcc dipilih per opcode; offset `03h` melompati `MOV AX,1`.
Conditional branch IR tidak menggunakan opcode near-conditional 386:
trampoline di atas tetap memakai instruksi yang tersedia pada 8086. Untuk
near jump, displacement dihitung `target_offset - (offset sesudah rel16)`;
word ditulis little-endian. Validator firmware memeriksa setiap byte template,
setiap HALT, offset record, dan hasil relocation sebelum transfer kontrol.
Encoding ini adalah subset instruksi 8086, termasuk immediate register,
stack, arithmetic, moffs load/store, CMP, conditional short jump, far JMP
firmware, near JMP, dan short JMP.
