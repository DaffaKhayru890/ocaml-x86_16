# Arithmetic signed 16-bit

Compiler menyimpan setiap nilai pada word x86. Operasi berjalan dalam mode
real 16-bit; hasil low word dipertahankan sehingga arithmetic berperilaku
modulo `10000h`. Overflow tidak menghasilkan exception.

| IR | Instruksi generated | Encoding |
|---|---|---|
| ICONST imm16 | `mov ax,imm16; push ax` | `B8 iw 50` |
| ADD | `pop bx; pop ax; add ax,bx; push ax` | `5B 58 01 D8 50` |
| SUB | `pop bx; pop ax; sub ax,bx; push ax` | `5B 58 29 D8 50` |
| MUL | `pop bx; pop ax; imul bx; push ax` | `5B 58 F7 EB 50` |
| NEG | `pop ax; neg ax; push ax` | `58 F7 D8 50` |

Untuk SUB, stack berisi `[left,right]`; POP BX mengambil right lebih dulu,
POP AX mengambil left, lalu `sub ax,bx` menghitung left-right. IMUL BX
menghasilkan signed DX:AX, tetapi hasil representasi 16-bit memakai AX.
Negasi `8000h` tetap `8000h` dalam modulo 16-bit.

Compiler tidak melakukan operasi arithmetic pada nilai saat compile-time.
Ia hanya menghasilkan byte yang menjalankan operasi tersebut di CPU target.
