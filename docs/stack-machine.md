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

Pass pertama menolak underflow, overflow, HALT dengan hasil nol/lebih dari
satu, program kosong, HALT ganda, instruksi setelah HALT, slot lokal di luar
batas, dan pemuatan slot sebelum diinisialisasi. LOAD_LOCAL menambah depth;
STORE_LOCAL menguranginya; perbandingan menghasilkan satu Boolean dari dua
operand. IR_END harus langsung mengikuti satu HALT yang valid.

Bitmap inisialisasi diperiksa secara linear. Karena branch/label belum
didukung, belum ada penggabungan keadaan variabel dari beberapa jalur kontrol.

Untuk `(7+5)*3`, depth bergerak `0,1,2,1,2,1,0`; maksimum dua dan depth akhir
nol sesudah HALT mengambil hasil akhir untuk disimpan.
