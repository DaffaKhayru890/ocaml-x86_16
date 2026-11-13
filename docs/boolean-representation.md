# Representasi Boolean

Boolean menggunakan word integer 16-bit agar dapat disimpan pada virtual
stack, slot lokal, maupun hasil akhir tanpa tipe mesin khusus.

| Nilai | Representasi |
|---|---:|
| false | `0000h` |
| true | `0001h` |

Nol lazim dipakai untuk kondisi salah dan memudahkan pemeriksaan dengan
`CMP AX,0`. Nilai benar dibatasi ke satu, bukan semua bit satu, sehingga
hasil comparison mempunyai bentuk konsisten dan mudah diuji.

`CMP` tidak menghasilkan nilai Boolean secara langsung. Instruksi itu
mengatur FLAGS; Jcc yang sesuai memilih apakah codegen melewati
`MOV AX,1`. Codegen lebih dahulu menghasilkan nol, lalu menggantinya dengan
satu hanya pada kondisi true. Nilai tersebut didorong ke virtual stack.
Opcode HALT mengambil word terakhir dan menyimpannya pada DS:`0000h`, sama
seperti hasil integer. Maka hasil Boolean akhirnya tetap dapat diperiksa di
alamat fisik `30000h`.

Modul `boolean.asm` hanya mengizinkan konstanta nol atau satu. Tidak ada
operator logika, percabangan program, atau evaluasi short-circuit pada fase
ini.
