# Reset vector

## Pengantar dan tujuan

Prosesor x86 modern memulai reset di alamat fisik `FFFFFFF0h`. Pada reset,
CS memiliki basis tersembunyi `FFFF0000h` dan EIP bernilai `FFF0h`; pasangan
yang terlihat sering dilaporkan sebagai `F000:FFF0`. Isi ROM pada offset
`FFF0h` harus tersedia melalui pemetaan firmware QEMU di alamat tersebut.

## Hubungan dengan modul lain

`reset_vector.asm` ditempatkan setelah kode firmware. Ia mengisi ruang
sebelum offset `FFF0h` dengan `FFh`, memasang far jump, lalu mengisi sisa ROM.
Tujuan `F000:0000` adalah alias firmware pada alamat fisik `F0000h` yang
disediakan oleh machine PC QEMU untuk firmware berukuran 64 KiB.

## Register dan perhitungan alamat

Far jump memuat `CS=F000h` dan `IP=0000h`. Dalam mode real, alamat dihitung
sebagai `segment * 16 + offset`, sehingga alamat tujuan adalah `F0000h`.
Alamat sumber reset adalah `FFFF0000h + FFF0h = FFFFFFF0h`. Ini dua lokasi
yang dipetakan QEMU ke byte-byte yang sesuai dalam citra firmware.

Byte reset vector dimulai dengan `EA 00 00 00 F0`: opcode `JMP ptr16:16`,
offset little-endian `0000h`, lalu segment little-endian `F000h`.
Far jump memuat ulang CS:IP dan membuang basis CS tersembunyi saat reset.

## Urutan dan layout

1. NASM memulai flat binary pada offset `ORG 0`.
2. `times` mengisi sampai offset `FFF0h`.
3. Instruksi far jump lima byte mengalihkan kendali ke entry point.
4. `times` mengisi hingga tepat `10000h` byte.

`ORG` hanya memengaruhi nilai alamat label dalam assembly; ia tidak membuat
file berlubang sampai alamat fisik tinggi. Pemetaan alamat fisik adalah tugas
machine QEMU.

## Build dan debugging

`make` membangun dan memeriksa ukuran serta lima byte awal vector.
Dengan QEMU berhenti pada reset (`-S`), GDB dapat memeriksa `CS:EIP` dan
memori `0xFFFFFFF0`. Instruksi tunggal berikutnya harus mencapai
`F000:0000`. Lihat `docs/qemu-debugging.md`.
