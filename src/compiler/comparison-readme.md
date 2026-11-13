# Generator comparison

## Konsep dan hubungan

`comparison.asm` mengubah EQ, NE, LT, GT menjadi sequence 8086 yang
menghasilkan word Boolean. Validator stack memastikan dua operand tersedia
dan memperbarui kedalaman net -1 sebelum modul ini dijalankan. Modul
`boolean.asm` mengeluarkan immediate 0/1; emitter menulis byte ke ES:DI.

## Prosedur dan register

- `comparison_select_jump`: membaca `WORK_CURRENT_OPCODE`; mengembalikan
  JNE/JE/JGE/JLE di AL. AX dan flags berubah; opcode lain mencatat
  `ERR_COMPARISON_FAILED`.
- `codegen_compare`: POP kanan ke BX, POP kiri ke AX, CMP AX,BX, emit
  Boolean false, conditional short jump +3, emit true, lalu PUSH AX.
  AX/BX/DI/flags dapat berubah.

Input operand berada di runtime stack SS:SP=`4000:FFFE`. Kode ditulis ke
ES:DI=`2000:offset`; perbandingan tidak mengakses variabel lokal secara
langsung. Semua byte ditulis lewat CODEGEN_EMIT8/16. Overflow dipulangkan
oleh emitter dan mencegah transfer kontrol ke buffer.

## Encoding dan FLAGS

Prefix sequence: `5B 58 39 D8`. Setelahnya tiap operator memilih:
EQ `75 03`, NE `74 03`, LT `7D 03`, GT `7E 03`. Urutan nilai adalah
`B8 00 00`, Jcc, `B8 01 00`, `50`. Semua instruksi berada pada subset 8086.
JGE memakai relasi SF=OF; JLE memakai ZF=1 atau SF≠OF, sehingga LT/GT
berlaku untuk bilangan negatif juga.

## Build dan debugging

`make test` menguji semua comparison true/false dan operand negatif.
Periksa byte code di `20000h`, nilai final di `30000h`, dan FLAGS tepat
setelah CMP dengan breakpoint pada listing. Detail semantik ada di
`docs/comparison.md`.
