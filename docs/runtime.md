# Runtime generated program

Compiler mengeksekusi output RAM hanya setelah pass validasi, codegen, dan
validasi bentuk code berhasil. Transfer dilakukan dengan far jump ke
`2000:0000`, bukan CALL; compiler tidak memerlukan return setelah runtime
mengganti segment stack.

## Prologue

Prologue sepanjang 14 byte:

```text
FA B8 00 30 8E D8 B8 00 40 8E D0 BC FE FF
```

Urutannya CLI; AX=`3000h`; DS=AX; AX=`4000h`; SS=AX; SP=`FFFEh`. MOV SS dan
MOV SP berurutan dan tidak ada akses stack di antaranya. CLI tetap aktif.
CS sudah menjadi `2000h` akibat far jump dan tidak diubah prologue.

## Data, slot lokal, stack, dan hasil

Generated code memakai PUSH/POP pada runtime stack `4000h`. HALT mengambil
satu word hasil ke AX, menyimpannya dengan `A3 00 00` pada DS:0000 (`30000h`),
lalu menjalankan `F4 EB FD`. Untuk hasil 36, word di RAM adalah `0024h`.

Slot lokal dimulai dari DS:`0002h`; slot 0 diakses dengan `A1 02 00` untuk
load dan `A3 02 00` untuk store. Slot 63 berada di DS:`0080h`. Data lokal
berada pada segment runtime, tidak bertumpang tindih dengan hasil di `0000h`.
Bitmap inisialisasi hanya hidup di work memory compiler dan tidak ikut
runtime.

ES tetap `2000h`; DS menjadi `3000h`; SS:SP menjadi `4000:FFFE`. Tidak ada
BIOS/OS output. Generated program tidak pernah kembali ke compiler.
