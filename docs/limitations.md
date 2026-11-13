# Batasan dan kontrak Phase 05

## Batas ruang lingkup

Proyek ini mengompilasi format IR biner statis yang ditanamkan di ROM. Belum
ada lexer, parser, AST, type checker, frontend bahasa OCaml, loader file,
debug symbol, library runtime, atau compiler OCaml lengkap. IR juga bukan
format executable host dan tidak dijalankan oleh sistem operasi.

Firmware ditujukan untuk konfigurasi QEMU `pc` dan model CPU i386 yang
memetakan reset firmware pada ruang alamat tinggi. Meskipun subset instruksi
generated code sengaja kompatibel dengan 8086, reset ROM dan pemetaan
firmware ini tidak menjadikannya image boot universal untuk perangkat 8086
atau PC fisik.

## Kapasitas dan representasi

| Sumber daya | Kapasitas saat ini |
|---|---:|
| Instruction table | 256 instruksi executable |
| Label table | 64 label |
| Relocation table | 128 record |
| Local slots | 64 word |
| Generated output | 4096 byte |
| Work memory | Segment `6000h`, tabel di offset tetap |

Arithmetic word beroperasi modulo 65536. Comparison LT/GT memakai semantik
signed 16-bit. Overflow aritmetika tidak dilaporkan. Setiap jalur reachable
harus mempunyai kedalaman stack konsisten dan setiap local yang dibaca harus
diinisialisasi pada semua predecessor.

## Jalur error yang tidak dapat dicapai oleh IR normal

- **Virtual stack overflow (`000Bh`)**: instruction cap 256 membatasi
  kedalaman maksimum jauh di bawah batas virtual stack `3FFFh`.
- **Output overflow (`0008h`)**: instruksi terpanjang 13 byte; 256 record
  plus prologue tetap di bawah kapasitas 4096 byte. Emitter self-test menguji
  boundary/overflow primitive, tetapi IR normal tidak dapat memenuhi output.
- **CFG iteration failure (`0020h`)**: CFG maksimum 256 node, dan transfer
  kedalaman/bitmap terbatas. Batas sweep 4096 tidak dapat dicapai fixture
  valid saat ini.
- **Rel16 range (`001Ch`)**: code output maksimum 4096 byte, masih jauh di
  dalam signed rel16.
- **Invalid relocation internal (`0022h`)**: berarti tabel atau patch
  internal rusak; test IR valid tidak dapat menginjeksikan corruption ini.

Limitasi tersebut dicatat agar hasil suite tidak mengklaim menguji kondisi
yang tidak dapat direpresentasikan oleh konfigurasi produksi. Perubahan
kapasitas di masa depan harus meninjau ulang argumen dan menambahkan fixture
yang benar-benar dapat mencapai batas baru.

## Interrupt dan runtime

Compiler menonaktifkan IRQ maskable sebelum loop HLT. HLT bukan shutdown;
NMI atau reset dapat mengubah alur dan tidak disediakan handler firmware.
Tidak ada input/output perangkat, disk, video, keyboard, BIOS call, OS call,
atau syscall.
