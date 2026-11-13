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
| Firmware alias | `F000h` | `0000h` | `FFFFh` | `F0000h–FFFFFh` | 64 KiB | Alias legacy ROM; entry `F000:0000`, vector `F000:FFF0` |
| Firmware reset mapping | — | — | — | `FFFF0000h–FFFFFFFFh` | 64 KiB | Pemetaan firmware atas; reset fisik `FFFFFFF0h` |

SP dimulai dari `FFFEh`. CALL 16-bit menyimpan word di
`SS:FFFC = 5000:FFFC`, alamat fisik `5FFFCh`. Stack tumbuh turun; SP awal
adalah batas atas eksklusif praktis, bukan byte terakhir yang ditulis.

Region firmware adalah ROM dan tidak sama dengan area RAM. Region stack
berada dalam RAM QEMU 16 MiB. Compiler stack adalah satu-satunya stack yang
digunakan pada Phase 00; kode, data, dan stack runtime hanya didefinisikan
sebagai cadangan.
