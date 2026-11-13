# Peta memori

## Perhitungan alamat

Dalam real mode, alamat fisik biasa dihitung dengan
`segment * 16 + offset`. Segment bukan wilayah yang eksklusif: setiap
pasangan segment:offset dapat saling overlap. Tabel berikut mendefinisikan
rentang logis 64 KiB per segmen untuk proyek ini; rentang fisik stack dan
region reserved tidak bertumpang tindih. Firmware ROM mempunyai alias
tambahan di area alamat reset tinggi yang disediakan oleh QEMU PC.

| Region | Segment | Offset awal | Offset akhir | Alamat fisik | Ukuran | Fungsi |
|---|---:|---:|---:|---:|---:|---|
| Generated code | `2000h` | `0000h` | `0FFFh` | `20000h–20FFFh` | 4 KiB | Output compiler dan code yang dieksekusi |
| Hasil program | `3000h` | `0000h` | `0001h` | `30000h–30001h` | 2 byte | Nilai akhir pada `3000:0000` |
| Slot lokal | `3000h` | `0002h` | `0081h` | `30002h–30081h` | 128 byte | 64 slot nilai 16-bit |
| Runtime reserved | `3000h` | `0082h` | `FFFFh` | `30082h–3FFFFh` | Sisa segmen | Area runtime yang belum digunakan |
| Runtime stack | `4000h` | `0000h` | `FFFFh` | `40000h–4FFFFh` | 64 KiB | Stack generated program |
| Compiler stack | `5000h` | `0000h` | `FFFFh` | `50000h–5FFFFh` | 64 KiB | Stack aktif, tumbuh ke bawah |
| Work state compiler | `6000h` | `0000h` | `0047h` | `60000h–60047h` | 72 byte | Status, reader, codegen, CFG, temporary, dan bitmap |
| Instruction table | `6000h` | `0100h` | `13FFh` | `60100h–613FFh` | 4.864 byte | Maksimal 256 record executable berukuran 19 byte |
| Label table | `6000h` | `1400h` | `15BFh` | `61400h–615BFh` | 448 byte | Maksimal 64 record label berukuran 7 byte |
| Relocation table | `6000h` | `1600h` | `18FFh` | `61600h–618FFh` | 768 byte | Maksimal 128 record patch berukuran 6 byte |
| Firmware alias | `F000h` | `0000h` | `FFFFh` | `F0000h–FFFFFh` | 64 KiB | Alias legacy ROM; entry `F000:0000`, vector `F000:FFF0` |
| Firmware reset mapping | — | — | — | `FFFF0000h–FFFFFFFFh` | 64 KiB | Pemetaan firmware atas; reset fisik `FFFFFFF0h` |

Output buffer menempati `2000:0000–0FFF`, kapasitas 4096 byte. Compiler
menggunakan DS=`6000h`, ES=`2000h`, SS:SP=`5000:FFFE` selama dua pass.
Sebelum far jump, compiler memvalidasi hasil. Generated prologue lalu
mengubah DS menjadi `3000h` dan SS:SP menjadi `4000:FFFE`; CS menjadi
`2000h`. Nilai di `3000:0000` adalah hasil akhir; slot 0 mulai di `3000:0002`.

| Region data runtime | Offset | Alamat fisik | Ukuran | Kegunaan |
|---|---:|---:|---:|---|
| Hasil akhir | `0000h–0001h` | `30000h–30001h` | 2 byte | Word yang disimpan saat HALT |
| Slot lokal 0–63 | `0002h–0081h` | `30002h–30081h` | 128 byte | 64 nilai word tetap |
| Cadangan | `0082h–FFFFh` | `30082h–3FFFFh` | 65406 byte | Belum dipakai |

Alamat slot dihitung `0002h + indeks * 2`. Contohnya slot 5 berada pada
offset `000Ch`, alamat fisik `3000Ch`; slot 63 berada di `30080h–30081h`.

| Offset work | Ukuran | Nama | Fungsi |
|---:|---:|---|---|
| `0000h` | 2 | `WORK_STATUS` | Status compiler |
| `0002h` | 2 | `WORK_ERROR_CODE` | Kode error terakhir |
| `0004h` | 2 | `WORK_IR_REMAINING` | Sisa byte IR |
| `0006h` | 1 | `WORK_CURRENT_OPCODE` | Opcode aktif |
| `0007h` | 1 | Reserved | Cadangan |
| `0008h` | 2 | `WORK_DECODED_COUNT` | Instruksi yang dikenali, tanpa IR_END |
| `000Ah` | 2 | `WORK_EMIT_LENGTH` | Panjang output |
| `000Ch` | 1 | `WORK_IR_VERSION` | Versi header tervalidasi |
| `000Dh` | 1 | Reserved | Cadangan |
| `000Eh` | 2 | `WORK_IR_PAYLOAD_LENGTH` | Panjang payload header |
| `0010h` | 1 | `WORK_IR_END_SEEN` | Penanda terminator |
| `0011h` | 1 | `WORK_OPERAND_SIZE` | Ukuran operand terakhir |
| `0012h` | 2 | `WORK_DECODED_OPERAND` | Nilai operand terakhir |
| `0014h` | 2 | `WORK_IR_TOTAL_LENGTH` | Ukuran total tabel IR |
| `0016h` | 2 | `WORK_STACK_DEPTH` | Kedalaman virtual stack saat validasi |
| `0018h` | 2 | `WORK_MAX_STACK_DEPTH` | Kedalaman terbesar yang dicapai |
| `001Ah` | 2 | `WORK_STACK_ERROR` | Error stack/alur |
| `001Ch` | 1 | `WORK_IR_HALT_SEEN` | Penanda HALT IR |
| `001Dh` | 1 | `WORK_CODEGEN_HALT_EMITTED` | Penanda suffix runtime |
| `001Eh` | 1 | `WORK_CODEGEN_PROLOGUE_EMITTED` | Penanda prologue runtime |
| `001Fh` | 1 | `WORK_RESERVED_1F` | Cadangan, dibersihkan saat init |
| `0020h–0027h` | 8 | `WORK_LOCAL_INIT_BITMAP` | Satu bit inisialisasi untuk setiap slot lokal |
| `0028h–003Eh` | 23 | State CFG tambahan | Jumlah tabel, iterasi, indeks aktif, dan depth sementara |
| `0040h–0047h` | 8 | `WORK_TEMP_BITMAP` | Bitmap keluaran sementara untuk transfer dataflow |
| `0100h–13FFh` | 4.864 | Instruction table | Opcode, operand, offset IR, target, code offset, input depth, dan bitmap |
| `1400h–15BFh` | 448 | Label table | ID label, indeks target, code offset, dan flag |
| `1600h–18FFh` | 768 | Relocation table | Indeks label, offset displacement, dan indeks instruksi sumber |

SP dimulai dari `FFFEh`. CALL 16-bit menyimpan word di
`SS:FFFC = 5000:FFFC`, alamat fisik `5FFFCh`. Stack tumbuh turun; SP awal
adalah batas atas eksklusif praktis, bukan byte terakhir yang ditulis.

Semua segment tersebut berada dalam RAM QEMU 16 MiB kecuali firmware ROM.
Instruction table berakhir pada `13FFh`, label table mulai `1400h`, dan
relocation table mulai `1600h`; tabel tidak saling overlap. Alamat fisiknya
diperoleh dengan menambahkan offset ke basis `60000h`. Compiler stack dan
runtime stack terpisah; far jump tidak membutuhkan
`CALL`/`RET`, sehingga generated program aman mengganti SS:SP.
