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
| Generated code (reserved) | `2000h` | `0000h` | `FFFFh` | `20000h–2FFFFh` | 64 KiB | Cadangan phase selanjutnya |
| Runtime data (reserved) | `3000h` | `0000h` | `FFFFh` | `30000h–3FFFFh` | 64 KiB | Cadangan phase selanjutnya |
| Runtime stack (reserved) | `4000h` | `0000h` | `FFFFh` | `40000h–4FFFFh` | 64 KiB | Cadangan phase selanjutnya |
| Compiler stack | `5000h` | `0000h` | `FFFFh` | `50000h–5FFFFh` | 64 KiB | Stack aktif, tumbuh ke bawah |
| Work memory compiler | `6000h` | `0000h` | `0015h` | `60000h–60015h` | 22 byte dipakai | Status, error, reader, dan penghitung |
| Firmware alias | `F000h` | `0000h` | `FFFFh` | `F0000h–FFFFFh` | 64 KiB | Alias legacy ROM; entry `F000:0000`, vector `F000:FFF0` |
| Firmware reset mapping | — | — | — | `FFFF0000h–FFFFFFFFh` | 64 KiB | Pemetaan firmware atas; reset fisik `FFFFFFF0h` |

Output buffer menempati `2000:0000–0FFF`, yaitu alamat fisik
`20000h–20FFFh`, kapasitas 4096 byte. Region 64 KiB segmen `2000h` lainnya
tetap tidak digunakan. Work memory dialamatkan dengan DS=`6000h`; tabel IR
tetap berada dalam ROM dan dibaca melalui CS override; ES=`2000h` digunakan
untuk output. SS:SP compiler tetap `5000:FFFE`.

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

SP dimulai dari `FFFEh`. CALL 16-bit menyimpan word di
`SS:FFFC = 5000:FFFC`, alamat fisik `5FFFCh`. Stack tumbuh turun; SP awal
adalah batas atas eksklusif praktis, bukan byte terakhir yang ditulis.

Region firmware adalah ROM dan tidak sama dengan area RAM. Region stack
berada dalam RAM QEMU 16 MiB. Compiler stack adalah satu-satunya stack yang
digunakan pada Phase 00; kode, data, dan stack runtime hanya didefinisikan
sebagai cadangan.
