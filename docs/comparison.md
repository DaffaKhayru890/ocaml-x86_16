# Perbandingan integer signed

## Semantik

IR menyimpan operand di virtual stack dengan operand kiri didorong lebih
dahulu dan operand kanan sesudahnya. Codegen mengambil kanan ke BX, kiri ke
AX, kemudian menjalankan `CMP AX,BX`, yang mengatur FLAGS seolah menghitung
`AX - BX` tanpa menyimpan selisih.

| IR | Semantik | Jcc untuk melewati nilai true |
|---|---|---|
| `IR_EQ` (`20h`) | kiri = kanan | JNE (`75h`) |
| `IR_NE` (`21h`) | kiri ≠ kanan | JE (`74h`) |
| `IR_LT` (`22h`) | kiri < kanan signed | JGE (`7Dh`) |
| `IR_GT` (`23h`) | kiri > kanan signed | JLE (`7Eh`) |

Setiap operator mengambil dua operand dan mendorong satu nilai Boolean,
sehingga efek depth adalah -1.

## FLAGS dan signed jump

`CMP` memperbarui ZF, SF, OF, dan flag aritmetika lain. ZF bernilai satu
jika operand sama. SF menunjukkan bit tanda hasil pengurangan. OF menunjukkan
overflow signed pada pengurangan. Untuk perbandingan signed, kondisi
berdasarkan hubungan SF dan OF:

- JGE: `SF = OF`, artinya kiri ≥ kanan.
- JLE: `ZF = 1` atau `SF ≠ OF`, artinya kiri ≤ kanan.

Karena itu LT melewati true ketika JGE terpenuhi; GT melewati true ketika
JLE terpenuhi. EQ/NE menggunakan ZF melalui JE/JNE. Instruksi unsigned
JA/JB tidak digunakan, dan tidak ada SETcc atau instruksi di atas 8086.

## Bentuk kode bersama

Untuk semua operator, `codegen_compare` mengeluarkan:

```text
5B 58 39 D8 B8 00 00 Jcc 03 B8 01 00 50
```

Urutannya POP BX, POP AX, CMP AX,BX, MOV AX,0, conditional jump pendek
melewati tiga byte MOV AX,1 jika hasil false, MOV AX,1, lalu PUSH AX.
Displacement `03h` dihitung dari alamat setelah Jcc dan melompati tepat
instruksi immediate tiga byte.

Boolean yang dihasilkan selalu 0000h atau 0001h. Pengujian positif, negatif,
benar, dan salah tersedia di `make test`; hasil serta FLAGS dapat diperiksa
dengan GDB di breakpoint sebelum HLT.
