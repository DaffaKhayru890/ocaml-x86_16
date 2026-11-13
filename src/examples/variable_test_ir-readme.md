# Fixture IR variabel

## Tujuan dan format

`variable_test_ir.asm` menyusun payload IR statis yang dipilih melalui
`IR_TEST_CASE`; file ini bukan instruksi x86 yang dieksekusi. Header dan
panjang payload dibuat oleh `program_ir.asm`. Dispatcher membaca byte
payload melalui CS:SI.

## Kasus dan alamat

Kasus 21 menguji store/load slot 0; 22 menyimpan dua variabel dan
menjumlahkannya; 23 menimpa slot 0; 36 memakai local pada LT; 37 menghitung
`(x+y)*z` dari tiga slot; 38 menyentuh batas slot 63. Nilai runtime
disimpan di DS=`3000h`, sementara bit inisialisasi berada di DS compiler
`6000h`, offset `0020h–0027h`.

Setiap `db IR_STORE_LOCAL` atau `IR_LOAD_LOCAL` diikuti indeks satu byte.
Immediate ICONST memakai `dw` little-endian. Urutan selanjutnya ialah
IR_HALT dan IR_END; tidak ada label atau parser.

Build ROM dengan `make`, jalankan setiap kasus melalui `make test`. GDB
memeriksa slot di `30002h` atau `30080h`, bitmap di `60020h`, dan hasil
akhir di `30000h`.
