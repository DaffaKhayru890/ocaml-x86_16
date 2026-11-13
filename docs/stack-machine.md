# Semantik stack virtual

Setiap nilai adalah pola bit signed 16-bit. `IR_ICONST` mendorong nilai,
ADD/SUB/MUL mengambil dua nilai dan mendorong satu hasil, NEG mengganti
nilai teratas, dan HALT mengharuskan tepat satu hasil lalu mengonsumsinya.
Nilai teratas adalah operand yang paling akhir didorong.

| Instruksi | Syarat awal | Efek depth |
|---|---:|---:|
| ICONST, LOAD_LOCAL | sesuai opcode | +1 |
| STORE_LOCAL | minimal 1 | -1 |
| ADD, SUB, MUL, EQ, NE, LT, GT | minimal 2 | -1 |
| NEG | minimal 1 | 0 |
| HALT | tepat 1 | -1 |

`WORK_STACK_DEPTH`, `WORK_MAX_STACK_DEPTH`, dan `WORK_STACK_ERROR` berada di
work memory. Validator membatasi kedalaman maksimum pada `3FFFh` word
(konservatif terhadap kapasitas stack runtime 64 KiB). Ini compile-time
counter, bukan SP. Runtime SP hanya berubah saat generated PUSH/POP.

Analisis CFG menolak underflow, overflow, stack depth berbeda pada merge,
HALT dengan hasil nol/lebih dari satu, jalur reachable yang jatuh melewati
akhir, slot di luar batas, dan LOAD_LOCAL yang belum definite-assigned.
LOAD_LOCAL menambah depth; STORE_LOCAL menguranginya; perbandingan
menghasilkan satu Boolean dari dua operand. Setiap HALT reachable menerima
tepat satu hasil dan menjadi terminal; beberapa HALT diperbolehkan.

Bitmap di-intersect pada merge. Bila STORE_LOCAL hanya terjadi pada salah
satu predecessor, bit slot hilang dan LOAD_LOCAL di node merge ditolak.
JZ/JNZ mengonsumsi kondisi, dengan satu edge ke target dan satu edge
fallthrough; JMP hanya memiliki edge target. Instruksi setelah HALT dapat
tetap reachable dari branch lain, tetapi tidak menerima state dari HALT.

Untuk `(7+5)*3`, depth bergerak `0,1,2,1,2,1,0`; maksimum dua dan depth akhir
nol sesudah HALT mengambil hasil akhir untuk disimpan.
