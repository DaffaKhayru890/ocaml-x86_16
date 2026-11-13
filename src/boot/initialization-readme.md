# Inisialisasi segmen dan stack

## Pengantar dan tujuan

Alamat real-mode dibentuk dari segment dan offset. Setiap unit segment
bernilai 16 byte: alamat fisik adalah `segment * 16 + offset`. Inisialisasi
register membuat akses memori dan stack firmware dapat diprediksi.

## Hubungan dengan modul lain

`firmware_entry` melompat ke `initialize_segments` tanpa memakai stack.
Modul ini menetapkan DS dan ES ke segmen firmware, kemudian SS dan SP ke
stack compiler. Setelah itu ia memanggil `firmware_main`; instruksi `ret`
di sana menguji stack sebelum alur menuju loop HLT.

## Register dan alamat

- `AX` menjadi register sementara untuk nilai segment.
- `DS=ES=F000h` menunjuk alias ROM pada alamat `F0000h` untuk data firmware.
- `SS=5000h` memberi basis stack fisik `50000h`.
- `SP=FFFEh` adalah posisi awal stack. CALL 16-bit menurunkan SP menjadi
  `FFFCh`, menyimpan alamat balik, lalu RET mengembalikan SP ke `FFFEh`.
- SS ditulis tepat sebelum SP ketika interrupt maskable dinonaktifkan.

Stack tumbuh ke alamat yang lebih rendah. Posisi awalnya berarti word pertama
berada pada `50000h + FFFCh = 5FFFCh`; region stack yang dicadangkan adalah
`50000h–5FFFFh`.

## Urutan instruksi dan alur

1. `mov ax, FIRMWARE_SEGMENT` menyiapkan nilai untuk DS dan ES.
2. `mov ds, ax` lalu `mov es, ax` menetapkan segmen data.
3. `mov ax, STACK_SEGMENT` memuat segmen stack.
4. `mov ss, ax` menetapkan basis stack; interrupt maskable tetap mati.
5. `mov sp, STACK_TOP` menetapkan stack pointer sebelum pemanggilan pertama.
6. `call firmware_main` menaruh alamat balik pada stack.
7. `ret` mengonsumsi alamat balik dan membuktikan pasangan CALL/RET berfungsi.

## Build dan debugging

Bangun dengan `make`. Pada breakpoint GDB di `halt_loop`, periksa DS, ES,
SS, dan SP. Setelah CALL/RET kembali, SP harus `FFFEh`. Gunakan
`docs/qemu-debugging.md` untuk perintah GDB.
