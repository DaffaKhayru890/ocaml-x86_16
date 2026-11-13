# Runtime code generator

## Konsep dan tujuan

Runtime module menghasilkan prologue dan result/halt sequence sebagai byte
ke output RAM. Ia tidak dijalankan saat emit; CPU mengeksekusinya hanya
setelah validasi sukses dan compiler melakukan far jump.

## Register dan alamat

ES=`2000h`, DI menunjuk offset akhir output; DS=`6000h` tetap menunjuk work
memory selama proses emit. Generated code mulai pada fisik `20000h`. Saat
dijalankan, CS=`2000h`, hasil ditulis ke `DS:0000` dengan DS=`3000h`, dan
stack runtime memakai SS:SP=`4000:FFFE`.

## Prosedur dan instruksi

`runtime_emit_prologue` emit secara berurutan: CLI (`FA`); MOV AX,3000h
(`B8 00 30`); MOV DS,AX (`8E D8`); MOV AX,4000h (`B8 00 40`); MOV SS,AX
(`8E D0`); MOV SP,FFFEh (`BC FE FF`). Setelah sukses, ia menandai flag
prologue.

`runtime_emit_halt` emit POP AX (`58`); MOV moffs16,AX untuk offset nol
(`A3 00 00`); HLT (`F4`); JMP short (`EB FD`) kembali ke HLT. Ia menandai
flag suffix hanya setelah semua byte berhasil ditulis.

MOV SS lalu MOV SP berurutan tanpa akses stack perantara. CLI menonaktifkan
IRQ maskable; HLT masih dapat dibangunkan NMI dan loop mengulang HLT.

## Build dan debugging

`make test` memeriksa prologue, suffix, register, hasil, dan HLT. Untuk
alamat dan GDB, lihat `docs/runtime.md` dan `docs/debugging.md`.
