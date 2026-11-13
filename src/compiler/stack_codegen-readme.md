# Pencatatan error stack dan CFG

## Konsep dan fungsi

Stack validation tidak lagi berjalan linear di file ini. `dataflow.asm`
menganalisis stack per node CFG; file ini hanya menyediakan jalur pencatatan
error khusus agar status error juga tersimpan pada `WORK_STACK_ERROR`.

## Register dan alamat

DS=`6000h` menunjuk `WORK_STACK_ERROR` pada offset `001Ah` dan
`WORK_ERROR_CODE` pada offset `0002h`. AX membawa kode error; CF=1
menyatakan kegagalan. Pemanggil menggunakan stack compiler
SS:SP=`5000:FFFE`.

## Prosedur dan alur

`codegen_record_stack_error` menyalin AX ke `WORK_STACK_ERROR`, memanggil
`compiler_record_error` untuk menetapkan status/kode umum, lalu kembali
dengan CF=1. Kode yang sama dipakai untuk underflow/overflow, merge depth
yang berbeda, fallthrough invalid, dan kegagalan dataflow.

## Build dan debugging

Jalankan `make test`; fixtures 11/12 dan 44 memeriksa error stack. Periksa
`x/2hx 0x6001a` untuk error stack dan `x/2hx 0x60002` untuk status/error
umum. Analisis per opcode dijelaskan di `dataflow-readme.md`.
