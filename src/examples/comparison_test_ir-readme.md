# Fixture IR perbandingan

## Tujuan dan format

File ini menyusun payload statis untuk EQ, NE, LT, dan GT. `IR_TEST_CASE`
memilih satu kasus; `program_ir.asm` menyediakan header serta panjang.
Operand didorong kiri dahulu lalu kanan, sehingga codegen mengambil kanan
ke BX dan kiri ke AX.

## Kasus dan alamat

Kasus 24–27 mencakup EQ/NE true dan false; 28–31 menguji LT positif dan
negatif; 32–35 menguji GT positif dan negatif. Kasus 56–59 menguji signed
minimum `-32768`, maksimum `32767`, kesamaan minimum, dan ketidaksamaan
minimum/maksimum. Semua comparison mendorong Boolean 0000h atau 0001h ke
stack runtime SS:SP=`4000:FFFE`. HALT menyimpan word hasil ke DS:`0000h`,
alamat fisik `30000h`.

Opcode comparison tidak memiliki operand tambahan. Nilai `dw -5` disimpan
sebagai `FFFBh` little-endian. Build dan uji seluruh varian dengan
`make test-arithmetic`; generated Jcc dan hasil dapat diperiksa lewat GDB.
