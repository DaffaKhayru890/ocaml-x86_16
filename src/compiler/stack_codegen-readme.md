# Validasi virtual stack

## Konsep dan tujuan

Validator menjaga kedalaman stack semantik sebelum dan selama codegen.
Counter pada work memory bukan stack hardware; stack hardware compiler
berada pada `5000:FFFE`, sedangkan program menggunakan `4000:FFFE`.

## Register dan prosedur

DS=`6000h` menunjuk `WORK_STACK_DEPTH`, `WORK_MAX_STACK_DEPTH`,
`WORK_STACK_ERROR`, opcode, dan status IR. AX membawa kode error; flag CF
menyatakan berhasil/gagal. `codegen_validate_stack` memvalidasi setiap
instruksi; `codegen_validate_end` memastikan program berakhir setelah
satu HALT dengan depth nol; `codegen_record_stack_error` mencatat error
stack/alur melalui compiler.

## Alur instruksi

1. Tolak instruksi setelah HALT.
2. ICONST memastikan batas kapasitas, menaikkan depth, lalu memperbarui
   maksimum.
3. ADD/SUB/MUL mensyaratkan dua nilai dan mengurangi depth satu.
4. NEG mensyaratkan satu nilai dan tidak mengubah depth.
5. HALT mensyaratkan tepat satu nilai, mengonsumsinya, dan menandai terminator.
6. IR_END mensyaratkan program berisi instruksi, satu HALT, dan depth nol.

Instruksi unsupported menghasilkan error tersendiri. Jika gagal, AX berisi
kode, stack error disimpan pada `6001Ah`, dan compiler tidak menjalankan
output parsial.

## Build dan debugging

`make test` menguji underflow, overflow, depth akhir, serta urutan HALT.
Lihat depth saat akhir di `60016h`, maksimum di `60018h`, dan error stack di
`6001Ah`.
