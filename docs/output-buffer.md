# Output buffer dan work memory

Output buffer adalah RAM pada segment ES=`2000h`, offset `0000h`, kapasitas
`1000h` byte (4096 byte), alamat fisik `20000h–20FFFh`. DI merupakan offset
berikutnya. Segmen 3000h disisihkan untuk runtime data; stack compiler ada di
5000h dan work memory ada di 6000h.

`emit8` menerima penulisan hanya jika DI kurang dari kapasitas. `emit16`
memeriksa `DI <= kapasitas-2` sebelum store word. Karena itu kasus satu byte
tersisa tidak dapat menulis byte low terlebih dahulu lalu gagal pada byte
high. Panjang berubah hanya sesudah penulisan lengkap.

self-test Phase 01 memakai offset di luar kapasitas sebagai sentinel uji pada
RAM QEMU, tetapi sentinel itu bukan bagian dari buffer yang diizinkan. Tes
memastikan byte sentinel dan byte terakhir tidak berubah pada jalur overflow.
Sesudah tes, codegen mengatur DI dan panjang kembali nol sebelum menghasilkan
runtime prologue dan program.

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

Work memory memakai 40 byte, termasuk bitmap slot lokal pada `60020h–60027h`.
Di GDB, setelah CPU mencapai loop HLT, baca:

```gdb
x/64bx 0x20000
x/40bx 0x60000
x/hx 0x30000
x/hx 0x30002
```

Untuk program `(7+5)*3`, output machine code berukuran 43 byte dan hasil
`0024h` disimpan di `30000h`. Slot lokal 0, bila dipakai, berada pada
`30002h`; bitmap compile-time dapat dibaca pada `60020h`.
