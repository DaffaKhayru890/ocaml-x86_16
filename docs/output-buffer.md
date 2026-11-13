# Output buffer dan work memory

Output buffer adalah RAM pada segment ES=`2000h`, offset `0000h`, kapasitas
`1000h` byte (4096 byte), alamat fisik `20000h–20FFFh`. DI merupakan offset
berikutnya. Segmen 3000h disisihkan untuk runtime data; stack compiler ada di
5000h dan work memory ada di 6000h.

`emit8` menerima penulisan hanya jika DI kurang dari kapasitas. `emit16`
memeriksa `DI <= kapasitas-2` sebelum store word. Karena itu kasus satu byte
tersisa tidak dapat menulis byte low terlebih dahulu lalu gagal pada byte
high. Panjang berubah hanya sesudah penulisan lengkap.

Self-test memakai offset di luar kapasitas sebagai sentinel uji pada RAM
QEMU, tetapi sentinel itu bukan bagian dari buffer yang diizinkan. Tes
memastikan byte sentinel dan byte terakhir tidak berubah pada jalur overflow.
Panjang output akhir kembali menjadi lima byte.

Work memory compiler adalah segment DS=`6000h`; field penting:

| Alamat fisik | Field |
|---:|---|
| `60000h` | Status |
| `60002h` | Kode error |
| `60004h` | Remaining IR |
| `60008h` | Jumlah instruksi tervalidasi |
| `6000Ah` | Panjang output |
| `6000Ch` | Versi IR |
| `6000Eh` | Panjang payload |

Di GDB, setelah CPU mencapai loop HLT, baca:

```gdb
x/16bx 0x20000
x/22bx 0x60000
```

Lima byte yang diharapkan di output adalah `b8 34 12 50 58`.
