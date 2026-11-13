# Arsitektur compiler Phase 01

## Ruang lingkup

Firmware Phase 00 tetap menjadi entry point. Setelah stack disiapkan,
`firmware_main` memanggil compiler yang seluruhnya ditulis dengan Assembly
16-bit. Compiler membaca tabel IR statis di ROM, memvalidasi format dan
operand, lalu menjalankan tes emitter mandiri. Kedua jalur belum menjadi
pipeline code generation.

```text
Reset ROM -> Inisialisasi segmen/stack -> compiler_main
                                      |
                    +----------------+----------------+
                    |                                 |
                 IR reader                      Emitter test
                    |                                 |
              IR dispatcher                     emit8/emit16
                    |                                 |
            Status dan error                    RAM: 2000:0000
                    +---------------+-----------------+
                                    |
                              HLT success/error
```

IR_ADD dan opcode lainnya hanya dikenali; tidak ada operasi aritmetika,
penerjemahan, label resolution, atau eksekusi data hasil emitter.

## Register dan alamat

| Register | Penggunaan |
|---|---|
| CS | Firmware dan tabel IR di ROM |
| DS | Work memory pada `6000h` |
| ES | Output buffer pada `2000h` |
| SS:SP | Stack compiler `5000:FFFE` |
| SI | Pointer byte IR |
| DI | Offset output |
| AX | Byte/word operand dan nilai emitter |
| CX | Jumlah byte minimum pada pemeriksaan reader |

Alamat fisik real mode dihitung `segment * 16 + offset`. Karena DS tidak
menunjuk ROM, setiap load IR memakai override `[cs:si]`. Output memakai
`[es:di]`; status hanya ditulis ke RAM pada DS.

## Alur compiler

1. Muat DS=`6000h`, ES=`2000h`; bersihkan work memory.
2. Set SI ke `program_ir`, sisa awal ke ukuran header + payload.
3. Baca empat byte magic, versi, dan panjang payload dengan reader.
4. Cocokkan panjang deklarasi terhadap panjang byte yang tersisa.
5. Dispatch opcode sampai IR_END; validasi operand dan terminator.
6. Jalankan emitter self-test terpisah dan tes batas buffer.
7. Simpan SUCCESS atau ERROR; kegagalan berhenti di HLT loop.

## Build dan debugging

`make` membangun ROM dan listing. `make test` menguji satu IR valid dan tujuh
fixture error dengan QEMU. Peta register dan perintah GDB ada di
`docs/debugging.md`.
