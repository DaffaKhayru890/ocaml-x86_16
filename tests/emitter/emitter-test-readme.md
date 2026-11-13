# Pengujian emitter

## Tujuan

Modul ini menguji primitive emitter secara terpisah dari IR. Ia dipanggil
oleh `compiler_main`, tetapi tidak menerima atau menerjemahkan opcode IR.

## Prosedur

`emitter_self_test` menulis B8h dengan emit8, 1234h dengan emit16, lalu 50h
dan 58h dengan emit8. `emitter_verify_test` membandingkan panjang dan tiap
byte. `emitter_overflow_test` menulis pada byte terakhir buffer, mencoba
melewati batas, lalu mencoba word ketika hanya satu byte tersisa.

## Register dan alamat

DS menunjuk work memory `6000h`; ES menunjuk buffer RAM `2000h`; DI adalah
offset tulis. AX/AL menjadi input emitter. Hasil yang diharapkan berada pada
alamat fisik `20000h–20004h` sebagai `B8 34 12 50 58`.

## Build dan debugging

`make test` menjalankan tes pada QEMU. Tidak ada generated code yang
dieksekusi. Periksa panjang lima byte, sentinel di luar batas buffer, status
akhir sukses, dan error code overflow yang sengaja diuji lalu dibersihkan.
