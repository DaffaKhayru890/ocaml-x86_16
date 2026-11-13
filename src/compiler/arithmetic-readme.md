# Generator instruksi aritmetika

## Konsep dan hubungan

Modul mengubah IR_ICONST, ADD, SUB, MUL, NEG, dan HALT menjadi byte x86
8086-compatible. Ia bekerja pada output emitter; ia tidak menghitung nilai
saat compile time. Stack virtual sudah diperiksa oleh validator.

## Register dan alamat

Operand ICONST datang dari `WORK_DECODED_OPERAND` pada `DS=6000h`.
Emitter menulis melalui `ES:DI` dengan ES=`2000h`. AX dipakai oleh emitter
untuk immediate/opcode; DI dan flag berubah. Stack runtime generated code
menggunakan `SS:SP=4000:FFFE`.

## Prosedur dan instruksi

- `codegen_iconst`: emit `B8`, immediate word little-endian, `50`
  (`mov ax,imm16; push ax`).
- `codegen_add`: emit POP BX (`5B`), POP AX (`58`), ADD AX,BX (`01 D8`),
  PUSH AX (`50`).
- `codegen_sub`: susunan POP sama, lalu `29 D8` menghitung left-right.
- `codegen_mul`: susunan POP sama, `F7 EB` signed IMUL BX, PUSH AX;
  hasil 16-bit menggunakan low word.
- `codegen_neg`: POP AX, `F7 D8` NEG AX, PUSH AX.
- `codegen_halt`: delegasikan ke `runtime_emit_halt`.

Macro `CODEGEN_EMIT8/16` berhenti segera saat CF menunjukkan overflow,
sehingga tidak ada byte lanjutan setelah gagal. Urutan byte dan arithmetic
wraparound dijelaskan di `docs/arithmetic.md` dan
`docs/machine-code-reference.md`.

## Build dan debugging

Jalankan `make test`; inspeksi output di `20000h` dan hasil di `30000h`.
QEMU/GDB perintahnya ada di `docs/debugging.md`.
