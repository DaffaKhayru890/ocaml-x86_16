# Entry point firmware

## Pengantar dan tujuan

Sesudah reset, CPU mulai mengambil instruksi dari reset vector. Modul ini
menyediakan entry point firmware yang dituju oleh far jump di akhir ROM.
Firmware bukan BIOS: ia tidak menyediakan layanan perangkat, tabel BIOS,
atau antarmuka untuk sistem operasi.

## Hubungan dengan modul lain

`reset_vector.asm` melompat ke `firmware_entry` dengan pasangan
`F000:0000`. Entry point menonaktifkan interrupt maskable, membersihkan arah
string, lalu berpindah ke `initialize_segments`. Perpindahan pertama memakai
`jmp`, bukan `call`, sebab stack belum disiapkan.

## Register dan alamat

- `CS:IP` sesudah far jump adalah `F000:0000`; alamat linear real-mode-nya
  `F0000h`.
- `CLI` tidak mengubah register umum; instruksi ini menghapus flag IF.
- `CLD` menghapus DF agar operasi string berikutnya bergerak maju.
- Tidak ada stack yang digunakan sebelum inisialisasi stack.

## Urutan instruksi dan alur

1. `cli` mencegah IRQ maskable saat lingkungan awal belum siap.
2. `cld` menetapkan arah operasi string ke arah alamat yang bertambah.
3. `jmp initialize_segments` memindahkan kendali tanpa menaruh alamat balik
   pada stack.
4. Modul inisialisasi menyiapkan DS, ES, SS, dan SP, baru kemudian memanggil
   program utama.

## Build dan debugging

Jalankan `make` atau `scripts/build.sh` dari root proyek. Untuk debugging,
jalankan `scripts/run-qemu.sh`, lalu hubungkan GDB ke `localhost:1234`.
Petunjuk lengkap dan batasan reset CPU dijelaskan dalam
`docs/qemu-debugging.md` dan `docs/reset-vector.md`.
