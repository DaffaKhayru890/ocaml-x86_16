# Tabel instruksi, label, dan generator

## Pengantar

Instruksi branch memakai ID label, tetapi machine code memerlukan alamat
offset yang baru diketahui setelah seluruh code dihasilkan. Modul ini
memisahkan decoding IR dari emission dengan menyimpan instruksi executable
dan deklarasi label di DS=`6000h`.

## Tujuan dan hubungan

`control_flow.asm` menghubungkan reader/dispatcher dengan CFG, dataflow,
codegen, dan relocation. Label tidak menjadi record instruksi. Saat label
dibaca, modul menyimpan indeks executable saat ini; operand branch kemudian
diterjemahkan menjadi indeks target. `cfg.asm` menganalisis record tersebut,
sedangkan `control_flow_generate_code` menjadi sumber tunggal untuk Pass
emission.

## Register dan alamat

| Register | Fungsi |
|---|---|
| AX | Indeks tabel, ID label, operand, atau code offset |
| BX | Pointer record tabel |
| CX | Penghitung tabel/bitmap dan scratch offset |
| DX | Temporary ID/offset |
| SI | Reader IR saat decode; sumber bitmap ketika emission |
| DI | Code offset berikutnya di ES |

Instruction table dimulai di `6000:0100`, berkapasitas 256 × 19 byte.
Label table dimulai di `6000:1400`, berkapasitas 64 × 7 byte. Record
instruction memuat opcode, operand, IR source offset, target index, code
offset, stack input, dan bitmap local input. Record label memuat ID, target
index, code offset, dan flag defined.

## Prosedur dan urutan

- `control_flow_instruction_offset`: menghitung `0100h + index * 19`.
- `control_flow_label_offset`: menghitung `1400h + index * 7`.
- `control_flow_find_label`: mencari ID label dan mengembalikan indeks record.
- `control_flow_add_label`: menolak ID duplikat/capacity overflow dan
  menyimpan indeks executable saat deklarasi.
- `control_flow_add_instruction`: memvalidasi operand local dan menambahkan
  record executable. `IR_LABEL` tidak dipanggil pada prosedur ini.
- `control_flow_resolve_labels`: memvalidasi bahwa setiap deklarasi label
  menunjuk instruksi executable, mencari target setiap JMP/JZ/JNZ, dan
  menolak label di akhir tabel termasuk label yang tidak direferensikan.
- `control_flow_validate_program`: decode hingga IR_END, resolve labels, lalu
  memanggil analisis CFG.
- `control_flow_set_label_offsets`: mencatat DI untuk semua label pada indeks
  yang akan diemits, termasuk label di akhir yang tidak direferensikan.
- `control_flow_generate_code`: mengambil setiap record, memulihkan bitmap
  input, menyimpan `CF_INST_CODE_OFFSET` sebelum dispatch, mengatur offset
  akhir, menerapkan relocation, lalu memvalidasi output.

Untuk index `i`, instruction-table address adalah
`6000h:0100h + i * 19`; label-table address adalah `6000h:1400h + i * 7`.
Perhitungan tersebut adalah offset di segment work, bukan physical address;
alamat fisiknya diperoleh dengan `60000h + offset`.

## Build dan debugging

Jalankan `make test`. Breakpoint pada `control_flow_resolve_labels` dapat
memeriksa operand label sebelum target index ditulis. Periksa tabel melalui
`xp /64bx 0x60100` dan label melalui `xp /32bx 0x61400`. Detail seluruh
field ada di `docs/memory-map.md` dan `docs/debugging.md`.
