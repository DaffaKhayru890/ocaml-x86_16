# Modul pembentukan Boolean

## Konsep dan tujuan

Boolean pada compiler direpresentasikan sebagai word: salah=`0000h`,
benar=`0001h`. Modul ini memusatkan validasi nilai dan emission immediate
untuk dipakai oleh code generator comparison.

## Prosedur dan register

`codegen_emit_boolean_value` menerima nilai di AX. Nilai selain
`BOOLEAN_FALSE_VALUE` atau `BOOLEAN_TRUE_VALUE` mencatat
`ERR_BOOLEAN_GENERATION_FAILED`. Nilai sah disalin ke BX, kemudian emitter
menulis `B8` dan immediate word melalui CODEGEN_EMIT8/16. BX dan DI dapat
berubah; flag menyatakan keberhasilan, dan kesalahan emitter diteruskan.

## Encoding dan alur

Nilai salah menghasilkan `B8 00 00` (`MOV AX,0000h`); nilai benar
menghasilkan `B8 01 00`. Comparison lebih dulu menulis false, Jcc melewati
instruksi pembentuk true bila kondisi salah, lalu PUSH AX. Dengan cara itu
hanya nol/satu yang didorong.

Nilai akhir diperlakukan sama seperti integer: HALT menyimpan AX ke
DS:`0000h` pada segment data runtime. Pengujian Boolean tersedia pada
`make test`; GDB membaca hasil di alamat fisik `30000h`. Lihat
`docs/boolean-representation.md`.
