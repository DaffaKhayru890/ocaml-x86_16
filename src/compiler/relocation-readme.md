# Relocation branch

## Pengantar dan tujuan

Operand branch dalam IR adalah ID label, bukan alamat code. Ukuran instruksi
berbeda-beda, sehingga alamat label baru diketahui ketika seluruh code
ditulis. Modul ini menyimpan patch site sementara dan mengisinya setelah
generation.

## Hubungan, register, dan alamat

`relocation.asm` memakai ID label hasil decoder, label table di
`DS=6000h:1400h`, relocation table di `DS=6000h:1600h`, serta output di
`ES=2000h`. AX menyimpan indeks/target/displacement, BX menunjuk record, DX
menyimpan patch offset, dan DI menunjuk akhir output. Setiap relocation
record 6 byte berisi label-table index, patch offset, dan source instruction
index.

## Prosedur

- `relocation_add` mencari label, memeriksa kapasitas 128 record, lalu
  menyimpan patch offset tepat setelah opcode `E9`.
- `relocation_apply_all` mencari code offset label, memeriksa patch berada di
  batas output dan byte sebelum patch benar-benar `E9`, kemudian menghitung
  displacement.

Rumus rel16 adalah:

```text
displacement = target_code_offset - (patch_offset + 2)
```

`patch_offset` menunjuk byte displacement pertama; CPU menambahkan displacement
ke IP setelah dua byte displacement dibaca. Word ditulis little-endian ke
ES:patch. Kapasitas output 4096 byte memastikan seluruh patch dapat
direpresentasikan sebagai signed 16-bit; pemeriksaan rentang tetap
dipertahankan sebagai pertahanan.

## Build dan debugging

Jalankan `make test`; case 40 menguji forward relocation, sedangkan case 41
menguji backward relocation pada loop. Bandingkan byte hasil di `20000h`
dengan referensi test dan periksa record menggunakan `xp /32bx 0x61600`.
Build juga memastikan tidak ada conditional near-jump 386 di firmware.
