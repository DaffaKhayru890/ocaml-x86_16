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
| Runtime data | `3000h` | `0000h` | `FFFFh` | `30000h–3FFFFh` | 64 KiB | Hasil program di `3000:0000` |
| Runtime stack | `4000h` | `0000h` | `FFFFh` | `40000h–4FFFFh` | 64 KiB | Stack generated program |
| Compiler stack | `5000h` | `0000h` | `FFFFh` | `50000h–5FFFFh` | 64 KiB | Stack aktif, tumbuh ke bawah |
| Work memory compiler | `6000h` | `0000h` | `001Eh` | `60000h–6001Eh` | 31 byte dipakai | Status, reader, codegen, dan stack depth |
| Firmware alias | `F000h` | `0000h` | `FFFFh` | `F0000h–FFFFFh` | 64 KiB | Alias legacy ROM; entry `F000:0000`, vector `F000:FFF0` |
| Firmware reset mapping | — | — | — | `FFFF0000h–FFFFFFFFh` | 64 KiB | Pemetaan firmware atas; reset fisik `FFFFFFF0h` |

Output buffer menempati `2000:0000–0FFF`, kapasitas 4096 byte. Compiler
menggunakan DS=`6000h`, ES=`2000h`, SS:SP=`5000:FFFE` selama dua pass.
Sebelum far jump, compiler memvalidasi hasil. Generated prologue lalu
mengubah DS menjadi `3000h` dan SS:SP menjadi `4000:FFFE`; CS menjadi
`2000h`. Nilai di `3000:0000` adalah hasil akhir program.

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

SP dimulai dari `FFFEh`. CALL 16-bit menyimpan word di
`SS:FFFC = 5000:FFFC`, alamat fisik `5FFFCh`. Stack tumbuh turun; SP awal
adalah batas atas eksklusif praktis, bukan byte terakhir yang ditulis.

Semua segment tersebut berada dalam RAM QEMU 16 MiB kecuali firmware ROM.
Compiler stack dan runtime stack terpisah; far jump tidak membutuhkan
`CALL`/`RET`, sehingga generated program aman mengganti SS:SP.
