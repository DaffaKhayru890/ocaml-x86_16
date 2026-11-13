# Pengujian comparison dan Boolean

Program tes 24–35 berada di `src/examples/comparison_test_ir.asm`.
`make test` memeriksa hasil machine code secara byte-per-byte dan nilai
akhir pada alamat fisik `30000h`.

EQ/NE dan LT/GT masing-masing diuji untuk true dan false. LT/GT juga
menguji operand negatif untuk memastikan JGE/JLE signed digunakan, bukan
jump unsigned. Kasus 36 memeriksa comparison atas nilai yang dibaca dari
slot lokal; kasus 111 memastikan underflow comparison ditolak sebelum
codegen. Hasil Boolean sah hanya `0000h` atau `0001h`.
