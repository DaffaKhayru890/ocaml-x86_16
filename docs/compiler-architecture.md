# Arsitektur compiler Phase 05

## Ruang lingkup

Compiler ditulis seluruhnya dalam Assembly 16-bit. Setelah firmware
menyiapkan stack, compiler membaca static IR, menganalisis control-flow graph
(CFG), menghasilkan instruksi x86 ke RAM, lalu melakukan far jump ke hasil.
Tidak ada parser, assembler host untuk program runtime, atau OS service.

```text
Reset ROM -> firmware -> compiler_main
                         |
                         +-- Decode IR -> instruction/label tables
                         |                -> resolve label/branch
                         |                -> CFG + stack/local fixed-point
                         |
                         +-- Emitter self-test
                         |
                         +-- Emit dari tabel -> label code offsets
                                              -> relocation rel16
                                              -> relocation validation
                                              -> validasi template dan target
                                                      |
                                              far jump 2000:0000
                                                      |
                              runtime prologue -> arithmetic/branch -> result
                                                      |
                                                   HLT loop
```

IR_LABEL mendeklarasikan ID tanpa menjadi instruksi executable. Target label
dipetakan ke indeks executable pertama setelah deklarasi. JMP memiliki satu
successor target; JZ/JNZ memiliki successor target dan fallthrough; instruksi
biasa memiliki fallthrough; HALT tidak memiliki successor. Branch yang
reachable tidak boleh jatuh melewati akhir tabel.

## Register dan alamat

| Register | Penggunaan |
|---|---|
| CS:SI | Membaca byte IR statis di ROM |
| DS | State compiler dan tabel pada segment `6000h` |
| ES:DI | Output code pada segment `2000h` |
| SS:SP | Stack compiler `5000:FFFE` |
| AX | Operand, displacement, dan nilai emitter |
| BX | Pointer record atau alamat slot |
| CX | Penghitung tabel/bitmap |
| DX | Temporary offset/target |

Alamat fisik real mode dihitung `segment * 16 + offset`. Instruction table
berada pada `6000:0100`, label table pada `6000:1400`, dan relocation table
pada `6000:1600`; detail field serta physical address ada di
`memory-map.md`.

## Tahap compiler

1. `ir_init` dan `ir_validate_header` memvalidasi magic, versi, dan panjang.
2. `ir_dispatch_opcode` mengambil operand dan memvalidasi opcode.
   `control_flow_validate_program` menambahkan instruksi executable ke tabel,
   mencatat label, memvalidasi slot, lalu resolve semua operand branch.
3. `cfg_analyze_program` menyetel state entry. `dataflow_fixed_point`
   mempropagasikan kedalaman stack dan bitmap slot initialized pada setiap
   edge hingga stabil. Kedalaman merge wajib sama; bitmap merge memakai
   intersection agar local definite-assignment berlaku pada semua jalur.
4. Setiap HALT reachable harus menerima satu word. Banyak HALT diizinkan;
   jalur normal yang melewati akhir IR dan CFG tanpa terminal reachable
   ditolak.
5. Setelah emitter self-test, pass emission menulis prologue dan melakukan
   iterasi instruction table. Untuk tiap indeks, semua label terkait
   memperoleh code offset saat ini.
6. JMP ditulis sebagai `E9 rel16`. JZ/JNZ mengonsumsi kondisi melalui
   `POP AX; TEST AX,AX`, memakai conditional short jump pembalik kondisi
   sepanjang tiga byte, lalu `JMP rel16`.
7. `relocation_apply_all` memvalidasi source record, label, patch site,
   opcode E9, dan menambal displacement little-endian:
   `target_offset - (patch_offset + 2)`.
8. `machine_code_validate_generated_program` mencocokkan setiap instruksi
   dengan template, memastikan offset kontigu, semua HALT lengkap, semua
   branch menunjuk instruksi executable, dan seluruh relocation diterapkan.
   Compiler baru far jump setelah panjang, kapasitas, prologue, terminator,
   dan machine code tervalidasi.

## Batas dan pengujian

Kapasitas: 256 instruksi executable, 64 label, 128 relocation, dan output
4096 byte. Record instruction berukuran 19 byte, label 7 byte, relocation 6
byte. `make test` mencakup runtime, bytes hasil codegen, disassembly, nilai
signed batas, branch forward/backward lebih dari rel8, label akhir invalid,
merge valid/invalid, definite assignment, dan error IR.

## Build dan debugging

Jalankan `make` dan `make test`; untuk tes GDB jalankan `make test-gdb`.
Status compiler berada di `60000h`; tabel dimulai di `60100h`; generated code
berada di `20000h`; result runtime di `30000h`. Perintah inspeksi memori dan
GDB ada di `debugging.md`.
