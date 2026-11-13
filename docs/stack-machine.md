# Semantik stack virtual

Setiap nilai adalah pola bit signed 16-bit. `IR_ICONST` mendorong nilai,
ADD/SUB/MUL mengambil dua nilai dan mendorong satu hasil, NEG mengganti
nilai teratas, dan HALT mengharuskan tepat satu hasil lalu mengonsumsinya.
Nilai teratas adalah operand yang paling akhir didorong.

| Instruksi | Syarat awal | Efek depth |
|---|---:|---:|
| ICONST | — | +1 |
| ADD, SUB, MUL | minimal 2 | -1 |
| NEG | minimal 1 | 0 |
| HALT | tepat 1 | -1 |

`WORK_STACK_DEPTH`, `WORK_MAX_STACK_DEPTH`, dan `WORK_STACK_ERROR` berada di
work memory. Validator membatasi kedalaman maksimum pada `3FFFh` word
(konservatif terhadap kapasitas stack runtime 64 KiB). Ini compile-time
counter, bukan SP. Runtime SP hanya berubah saat generated PUSH/POP.

Pass pertama menolak underflow, overflow, HALT dengan hasil nol/lebih dari
satu, program kosong, HALT ganda, dan instruksi semantik sesudah HALT.
IR_END harus langsung mengikuti satu HALT yang valid. Branch/label dan
variable stack semantics belum didukung.

Untuk `(7+5)*3`, depth bergerak `0,1,2,1,2,1,0`; maksimum dua dan depth akhir
nol sesudah HALT mengambil hasil akhir untuk disimpan.
