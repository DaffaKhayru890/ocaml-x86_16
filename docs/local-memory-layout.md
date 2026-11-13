# Layout memori variabel lokal

## Segment data runtime

Alamat real mode dihitung `segment * 16 + offset`. Generated program
menggunakan DS=`3000h`, sehingga alamat fisik slot adalah `30000h + offset`.

| Area | Offset | Alamat fisik | Ukuran | Isi |
|---|---:|---:|---:|---|
| Hasil akhir | `0000h–0001h` | `30000h–30001h` | 2 byte | Word hasil program |
| Slot lokal | `0002h–0081h` | `30002h–30081h` | 128 byte | 64 slot, masing-masing 2 byte |
| Cadangan | `0082h–FFFFh` | `30082h–3FFFFh` | 65406 byte | Tidak dipakai Phase 03 |

Konstanta berada di `include/variables.inc`:

```text
LOCAL_SLOT_BASE = 0002h
LOCAL_SLOT_SIZE = 2
MAX_LOCAL_SLOTS = 64
LOCAL_SLOT_END  = 0082h (batas eksklusif)
```

Alamat slot dihitung `0002h + indeks * 2`. Contoh: slot 0 berada di
`3000:0002` (fisik `30002h`); slot 5 di `3000:000Ch` (fisik `3000Ch`);
slot 63 di `3000:0080` (fisik `30080h–30081h`). Tidak ada slot yang menimpa
hasil akhir.

## Work memory bitmap

Bitmap compiler berada di segment DS=`6000h`, bukan di runtime data dan
bukan di slot nilai. `WORK_LOCAL_INIT_BITMAP` mulai offset `0020h` dan
memakai delapan byte sampai `0027h`. Bit nol berarti belum ditulis; bit satu
berarti pernah disimpan dalam alur IR yang divalidasi.

```text
WORK segment 6000h:
0020h  byte 0: slot 0..7
0021h  byte 1: slot 8..15
...
0027h  byte 7: slot 56..63
```

## Alasan penyimpanan tetap

Penyimpanan tetap deterministik, mudah diperiksa lewat GDB, dan tidak
membutuhkan allocator atau heap. Batas 64 slot membatasi ruang menjadi 128
byte dan memberi batas pemeriksaan statis yang sederhana. Tidak ada
garbage collector; semua slot hidup sampai program berhenti.
