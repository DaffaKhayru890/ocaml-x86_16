# Analisis stack dan definite assignment

## Pengantar

Compiler perlu membuktikan dua sifat pada setiap node reachable: kedalaman
virtual stack sama pada semua predecessor, dan setiap LOAD_LOCAL membaca slot
yang telah ditulis pada semua jalur menuju instruksi itu. Analisis ini
menggunakan transfer function per opcode dan iterasi fixed-point pada CFG.

## Tujuan dan hubungan

`dataflow.asm` menghitung state keluar node dan menggabungkannya ke state
masuk successor. Ia menggunakan instruction table dari `control_flow.asm`,
successor dari `cfg.asm`, bitmap helper `local_memory.asm`, dan error stack
compiler. Stage ini tidak menghasilkan machine code.

## State dan register

State tiap record berisi word `stack_in` dan delapan byte `init_in`. Depth
`FFFFh` berarti unreachable; bitmap memiliki satu bit per 64 slot lokal.
`WORK_TEMP_DEPTH` (`6000:003Dh`) dan `WORK_TEMP_BITMAP`
(`6000:0040h–0047h`) menyimpan state transfer sementara. AX/BX/SI menunjuk
record atau operand, CX menghitung byte/iterasi, dan DL menyimpan opcode.

## Transfer opcode

- ICONST dan LOAD_LOCAL menaikkan depth satu; LOAD memerlukan bit slot aktif.
- STORE_LOCAL memerlukan satu nilai, menurunkan depth, dan mengaktifkan bit.
- ADD/SUB/MUL/EQ/NE/LT/GT memerlukan dua nilai lalu menurunkan depth satu.
- NEG memerlukan satu nilai tanpa mengubah depth.
- JZ/JNZ memerlukan satu kondisi dan mengonsumsinya.
- JMP tidak mengubah state.
- HALT harus menerima tepat satu nilai dan tidak memiliki successor.

Setiap push diperiksa terhadap `VIRTUAL_STACK_MAX_DEPTH`. Merge predecessor
menolak depth berbeda; bitmap menggunakan intersection bitwise, sebab slot
hanya dianggap definite-assigned bila aktif pada seluruh jalur reachable.
Perubahan bitmap memicu sweep ulang agar hasil merge diterapkan ke LOAD_LOCAL
dan loop.

## Prosedur dan pengujian

- `dataflow_copy_bitmap`: menyalin delapan byte bitmap.
- `dataflow_transfer`: menghitung state keluar dan memvalidasi underflow,
  overflow, local load/store, serta HALT.
- `dataflow_propagate`: menetapkan state pertama atau menggabungkan state
  predecessor.
- `dataflow_fixed_point`: mengulang sweep, memeriksa fallthrough dan
  reachable HALT, lalu menetapkan `WORK_IR_HALT_SEEN`.

Jalankan `make test`. Case 41 menguji state loop yang kembali ke label; case
44 menguji stack mismatch; case 48 membuktikan LOAD ditolak saat hanya satu
jalur menginisialisasi local. Case 50 membuktikan code unreachable sesudah
HALT tetap dapat diemits tanpa ikut dianalisis sebagai jalur runtime.
