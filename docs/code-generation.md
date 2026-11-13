# Code generation dua pass

## Pass pertama: validasi

`ir_init`, `ir_validate_header`, dan `ir_validate_program` membaca IR melalui
CS:SI, memeriksa opcode/operand/terminator, serta memanggil
`codegen_validate_stack`. Pass ini hanya memperbarui work memory; DI tetap
tidak dipakai untuk executable output.

Setelah validasi, self-test emitter Phase 01 dijalankan secara terisolasi.
Pass kedua memanggil `codegen_init`, yang mengulang header, mereset SI,
remaining, stack depth, DI, dan panjang output. Karena itu byte self-test
tidak menjadi bagian generated program.

## Pass kedua: generation

Compiler menulis runtime prologue, membaca ulang tiap instruksi, memvalidasi
efek stack sekali lagi, lalu `codegen_dispatch` memanggil routine khusus.
Routine codegen hanya memanggil emit8/emit16 melalui macro helper. IR_END
mengakhiri pass; hasil diperiksa untuk panjang, prefix prologue, stack akhir,
dan suffix halt.

Jika seluruhnya valid, status compiler menjadi SUCCESS dan far jump
`2000:0000` memindahkan kendali ke RAM. Jika reader, stack, atau emitter
gagal, compiler berhenti di error loop dan tidak menjalankan buffer.

## Encoding operand

ICONST menghasilkan opcode `B8`, immediate word little-endian, lalu `50`.
Operasi aritmetika memakai POP/operation/PUSH. Code generator membaca nilai
operand IR dari `WORK_DECODED_OPERAND`; machine bytes tidak di-hardcode
sebagai satu hasil program. Instruksi dan prologue dirakit byte per byte oleh
emitter saat firmware berjalan.

Generated code default berada di `20000h`, panjang 43 byte, dan hasil
`(7+5)*3` ditulis ke `30000h` sebagai word `0024h`.
