# Perakitan firmware

## Pengantar dan tujuan

`firmware.asm` adalah berkas utama NASM yang menyatukan modul Phase 00 menjadi
satu citra flat binary. NASM tidak melakukan link atau memasang image pada
alamat fisik; QEMU yang memetakan keluaran 64 KiB sebagai firmware.

## Hubungan dengan modul lain

Berkas ini memuat konstanta dari `include/`, lalu memasukkan modul entry,
inisialisasi, firmware main, work memory, reader, dispatcher, emitter, tes
emitter, compiler main, tabel IR, dan reset vector. Urutan ini penting:
routine harus berada sebelum tabel IR; tabel IR harus berada sebelum padding
reset vector; vector menjadi byte terakhir sebelum padding citra.

## Register dan alamat

`BITS 16` meminta NASM menyusun instruksi dalam mode 16-bit. `ORG 0`
menjadikan offset label dihitung relatif terhadap awal file. Ia tidak
mengubah CS, alamat fisik, atau pemetaan QEMU. Nilai segment dan alamat stack
berasal dari `include/constants.inc` dan `include/memory_map.inc`.

## Urutan perakitan dan alur

1. `BITS 16` memilih default operand/address 16-bit.
2. `ORG 0` menetapkan origin label flat binary.
3. `%include` konstanta dan macro `FIRMWARE_FAR_JUMP` sebagai interface
   instruksi transfer antar-segmen.
4. `%include` modul reset entry; label `firmware_entry` berada di offset 0.
5. Modul compiler dan self-test emitter menyediakan routine yang dipanggil
   firmware.
6. Static IR ditempatkan di ROM dan labelnya menjadi sumber pointer reader.
7. Modul reset vector mengisi sampai offset `FFF0h`, menulis far jump, dan
   mengisi hingga ukuran ROM `10000h`.

Flat binary tidak menyimpan header, tabel relokasi, atau metadata linker.
Nilai `FIRMWARE_SEGMENT:firmware_entry` di-encode pada reset vector sebagai
offset/segment little-endian. Build memverifikasi ukuran dan lima byte
instruksi jump.

## Build dan debugging

Dari root proyek jalankan `make` atau `scripts/build.sh`; pada Windows
gunakan `scripts\build.bat`. Untuk debugging gunakan `scripts/run-qemu.sh`
atau `.bat`, lalu hubungkan GDB ke port 1234. Periksa reset vector tinggi,
far jump, register segmen, SP, serta HLT sesuai `docs/qemu-debugging.md`.
