# Code generation dan relocation

## Tahap analisis

`ir_init`, `ir_validate_header`, dan `ir_validate_program` membaca IR melalui
CS:SI, memeriksa opcode/operand/terminator, serta membangun instruction dan
label tables. Branch di-resolve ke indeks instruksi executable; CFG/dataflow
memvalidasi stack dan definite assignment sebelum emitter menulis code.
Instruction table dimulai di DS:`0100h`; label table dimulai di DS:`1400h`.

Emitter self-test dijalankan secara terisolasi. `codegen_init` menyiapkan
buffer tanpa menghapus hasil analisis. Byte self-test tidak menjadi bagian
generated program.

## Tahap emission

Compiler menulis runtime prologue, lalu mengiterasi instruction table.
Setiap label memperoleh code offset saat indeks targetnya dicapai.
`codegen_dispatch` menerjemahkan arithmetic, local variable, comparison,
branch, dan HALT melalui emit8/emit16.

JMP menghasilkan `E9 rel16`. JZ/JNZ mengonsumsi kondisi melalui
`POP AX; TEST AX,AX`, memakai conditional short jump pembalik kondisi untuk
melewati JMP near, lalu menulis placeholder rel16. Setelah seluruh instruksi
di-emits, relocation menerapkan rumus:

```text
rel16 = target_code_offset - (patch_offset + 2)
```

IR_END bukan record executable. Setiap HALT menghasilkan sequence terminal
`POP AX; MOV [0000h],AX; HLT; JMP short` sehingga multi-HALT tidak memerlukan
suffix khusus pada akhir buffer. Compiler memvalidasi ukuran, prologue,
status terminator, dan seluruh patch sebelum far jump `2000:0000`.

## Encoding operand

ICONST menghasilkan `B8`, immediate word little-endian, lalu `50`.
Operasi aritmetika memakai POP/operation/PUSH. Operand IR disimpan di
`WORK_DECODED_OPERAND`; machine bytes dikeluarkan per instruksi oleh emitter.
Build memastikan firmware tidak menggunakan conditional near-jump 386.

Generated code default berada di `20000h`, panjang 43 byte, dan hasil
`(7+5)*3` ditulis ke `30000h` sebagai word `0024h`. Jalankan `make test`
untuk memeriksa bytes, hasil, branch, dan fixture error.
