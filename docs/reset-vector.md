# Reset vector dan pemetaan ROM

## CPU reset state

Pada 8086/8088 klasik, pasangan reset adalah CS:IP `FFFF:0000`, alamat
fisik `FFFF0h`. Pada x86 modern, reset memakai basis tersembunyi CS
`FFFF0000h` dan EIP `FFF0h`, alamat fisik `FFFFFFF0h`. Register CS yang
terlihat dapat dilaporkan sebagai `F000h` sementara cache basis tersembunyi
tetap berbeda. Karena itu jangan menyimpulkan alamat reset hanya dengan
mengalikan CS yang terlihat.

## Konfigurasi QEMU

Target adalah `qemu-system-i386 -machine pc -m 16M -bios build/custom_rom.bin`.
Opsi `-bios` mengarahkan QEMU memakai citra pengguna sebagai firmware PC;
SeaBIOS tidak dipakai. QEMU PC memetakan firmware ke bagian teratas ruang
alamat dan alias ROM legacy. ROM 64 KiB yang disusun di sini menempatkan
offset `FFF0h` pada reset fetch tinggi dan entry di alias `F0000h`.

Reset vector berisi:

```text
EA 00 00 00 F0
```

`EA` adalah far JMP immediate, diikuti offset `0000h` dan segment `F000h`
dalam urutan little-endian. Tujuan real-mode adalah
`F000h * 10h + 0000h = F0000h`. Di reset, sumbernya
`FFFF0000h + FFF0h = FFFFFFF0h`.

QEMU dan versi machine adalah bagian dari kontrak pemetaan ini. Validasi
runtime dilakukan dengan GDB pada reset, lalu single-step far jump. Jangan
menganggap sembarang mesin QEMU, `-kernel`, atau ROM yang hanya diletakkan
di `F0000h` otomatis menyediakan reset mapping yang sama.

## Padding dan alamat NASM

Flat binary dimulai dari offset nol (`ORG 0`). `times 0xFFF0-($-$$)` mengisi
ruang hingga reset vector; `times 0x10000-($-$$)` mengisi ROM menjadi
tepat 65536 byte. Alamat ORG memengaruhi ekspresi label, bukan pemetaan
firmware fisik QEMU. Build juga menolak ukuran dan opcode/operand vector yang
tidak sesuai.
