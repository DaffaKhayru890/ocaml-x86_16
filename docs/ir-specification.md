# Spesifikasi Static IR16

## Header

| Field | Ukuran | Format |
|---|---:|---|
| Magic | 4 byte | ASCII `IR16` |
| Version | 1 byte | `01h` |
| Payload length | 2 byte | Unsigned little-endian |

Header berukuran tujuh byte. Payload length harus sama dengan jumlah byte
payload yang berada setelah header di dalam tabel ROM.

## Operand dan opcode

| Opcode | Nilai | Operand |
|---|---:|---|
| IR_END | `00h` | Tidak ada |
| IR_ICONST | `01h` | imm16 |
| IR_LOAD_LOCAL | `02h` | slot8 |
| IR_STORE_LOCAL | `03h` | slot8 |
| IR_ADD | `10h` | Tidak ada |
| IR_SUB | `11h` | Tidak ada |
| IR_MUL | `12h` | Tidak ada |
| IR_NEG | `13h` | Tidak ada |
| IR_EQ | `20h` | Tidak ada |
| IR_NE | `21h` | Tidak ada |
| IR_LT | `22h` | Tidak ada |
| IR_GT | `23h` | Tidak ada |
| IR_LABEL | `30h` | label16 |
| IR_JMP | `31h` | label16 |
| IR_JZ | `32h` | label16 |
| IR_JNZ | `33h` | label16 |
| IR_HALT | `40h` | Tidak ada |

`imm16` dan `label16` adalah dua byte little-endian; `slot8` satu byte.
Contoh `IR_ICONST 1234h` disimpan sebagai `01 34 12`. Tabel menyertakan
`IR_END` satu byte sebagai instruksi terakhir payload.

`IR_LOAD_LOCAL slot8` membaca slot lalu mendorong word ke stack; efek depth
`+1`. `IR_STORE_LOCAL slot8` mengambil word dan menyimpan ke slot; efeknya
`-1`. Indeks sah 0–63. `IR_EQ`, `IR_NE`, `IR_LT`, dan `IR_GT` mengambil dua
word dan mendorong Boolean, sehingga efek stack masing-masing `-1`.
Perbandingan LT/GT memakai semantik signed 16-bit. Boolean false adalah
`0000h`, true adalah `0001h`.

## Validasi

Magic harus tepat, versi harus didukung, dan panjang payload harus sesuai.
Opcode harus berada dalam daftar di atas. Operand diperiksa sebelum dibaca.
IR_END bukan IR_HALT: IR_END mengakhiri tabel dan wajib byte terakhir;
IR_HALT hanyalah opcode semantik yang divalidasi tanpa dieksekusi. Payload
kosong/tanpa END, operand terpotong, dan data setelah END menghasilkan error.

Tidak ada lexer, parser, atau source OCaml. IR merupakan data statis yang
dimasukkan ke ROM pada saat assembly.
