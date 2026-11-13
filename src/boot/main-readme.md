# Program utama dan penghentian CPU

## Pengantar dan tujuan

Program utama Phase 00 sengaja minimal: ia kembali ke pemanggil dengan `ret`.
Setelah itu firmware masuk ke loop `hlt`. Tidak ada compiler atau layanan
perangkat dalam phase ini.

## Hubungan dengan modul lain

`initialize_segments` memanggil `firmware_main` setelah stack siap. Sesudah
RET, kendali berpindah ke `halt_loop`, yang tidak kembali.

## Register dan alamat

CALL dan RET menggunakan pasangan SS:SP yang telah disiapkan (`5000:FFFE`).
`HLT` tidak mengubah segment register; alamat instruksi berikutnya berada
di loop firmware pada segmen CS `F000h`.

## Urutan instruksi dan alur

1. `firmware_main: ret` memulangkan kendali melalui alamat balik di stack.
2. `jmp halt_loop` memasuki penghentian terkontrol.
3. `hlt` menghentikan eksekusi sampai ada interrupt atau reset.
4. `jmp halt_loop` memastikan CPU kembali tidur jika suatu event
   membangunkannya.

`CLI` telah dijalankan sebelumnya, sehingga IRQ maskable tidak membangunkan
CPU. NMI tetap dapat membangunkannya; tidak ada IDT atau handler interrupt
yang dipasang pada phase ini. HLT bukan shutdown permanen.

## Build dan debugging

Jalankan `make`, lalu gunakan GDB untuk berhenti pada label `halt_loop`.
Periksa disassembly dan register untuk memastikan CALL/RET selesai sebelum
HLT. Petunjuk rinci tersedia di `docs/qemu-debugging.md`.
