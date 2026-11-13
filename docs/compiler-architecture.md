# Arsitektur compiler Phase 03

## Ruang lingkup

Firmware Phase 00 tetap menjadi entry point. Setelah stack disiapkan,
`firmware_main` memanggil compiler yang seluruhnya ditulis dengan Assembly
16-bit. Compiler menjalankan pass validasi dan pass code generation, lalu
far jump ke code yang ditulis langsung ke RAM. Tidak ada parser, textual
Assembly, atau compiler host.

```text
Reset ROM -> firmware -> compiler_main
                         |
                         +-- Pass 1: reader + dispatcher + stack/local validation
                         |
                         +-- Emitter self-test terisolasi
                         |
                         +-- Pass 2: baca IR ulang -> codegen -> emit
                                                      |
                                                      v
                                            validasi runtime code
                                                      |
                                             far jump 2000:0000
                                                      |
                                   runtime prologue -> arithmetic -> result
                                                      |
                                                  HLT loop
```

Virtual stack menyimpan nilai 16-bit. ADD, SUB, MUL, NEG, EQ, NE, LT, GT,
LOAD_LOCAL, dan STORE_LOCAL diterjemahkan langsung ke encoding 8086. Nilai
akhir disimpan ke `3000:0000`, sedangkan slot lokal menempati `3000:0002`
sampai `3000:0081`. Branch, label relocation, dan operasi lain yang belum
didukung ditolak sebelum kode hasil dijalankan.

## Register dan alamat

| Register | Penggunaan |
|---|---|
| CS | Firmware dan tabel IR di ROM |
| DS | Work memory pada `6000h` |
| ES | Output buffer pada `2000h` |
| SS:SP | Stack compiler `5000:FFFE` |
| SI | Pointer byte IR |
| DI | Offset output |
| AX | Byte/word operand dan nilai emitter |
| CX | Jumlah byte minimum pada pemeriksaan reader |

Alamat fisik real mode dihitung `segment * 16 + offset`. Karena DS tidak
menunjuk ROM, setiap load IR memakai override `[cs:si]`. Output memakai
`[es:di]`; status hanya ditulis ke RAM pada DS.

## Alur compiler

1. Muat DS=`6000h`, ES=`2000h`; bersihkan work memory.
2. Set SI ke `program_ir`, sisa awal ke ukuran header + payload.
3. Baca empat byte magic, versi, dan panjang payload dengan reader.
4. Cocokkan panjang deklarasi terhadap panjang byte yang tersisa.
5. Dispatch opcode sambil memvalidasi stack, slot, dan bitmap; belum ada emission.
6. Jalankan emitter self-test, lalu reset output buffer.
7. Reset reader dan stack state; emit runtime prologue dan hasil pass kedua.
8. Validasi panjang, prologue, terminator, stack, dan halt suffix.
9. Simpan SUCCESS, lalu far jump ke CS=`2000h`; error berhenti di firmware.
10. Program hasil menyiapkan DS=`3000h`, SS:SP=`4000:FFFE`, membaca/menulis
    slot lokal, menyimpan hasil dan menjalankan HLT loop.

## Build dan debugging

`make` membangun ROM dan listing. `make test` menguji program arithmetic,
local, comparison, bitmap, dan fixture error. Peta register dan perintah GDB
ada di `docs/debugging.md`.
