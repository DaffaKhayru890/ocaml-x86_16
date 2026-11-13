# Variabel lokal

## Konsep

Tanpa parser dan nama simbol, IR mengidentifikasi variabel menggunakan
indeks slot 8-bit. Setiap slot menyimpan satu word 16-bit pada segment data
runtime `DS=3000h`. Area ini berbeda dari stack evaluator, sehingga nilai
tetap tersimpan saat operasi lain mendorong atau mengambil operand.

## Opcode dan codegen

| Opcode | Operand | Efek stack | Instruksi sasaran |
|---|---|---:|---|
| `IR_STORE_LOCAL` (`03h`) | indeks slot 0–63 | -1 | `POP AX; MOV [disp16],AX` |
| `IR_LOAD_LOCAL` (`02h`) | indeks slot 0–63 | +1 | `MOV AX,[disp16]; PUSH AX` |

Alamat slot dihitung `LOCAL_SLOT_BASE + indeks * LOCAL_SLOT_SIZE`. Slot 0
berada pada offset `0002h`; slot 63 pada `0080h`. Register AX menjadi
penampung saat akses, dan moffs16 (`A3`/`A1`) memakai DS implisit. Karena
prologue runtime menetapkan DS=`3000h`, akses langsung menuju runtime data.

## Validasi dan bitmap

Pass pertama menghapus bitmap delapan byte pada work memory `6000:0020`.
Setiap `STORE_LOCAL` memeriksa stack dan indeks slot, lalu menandai bit.
`LOAD_LOCAL` menolak slot yang bit-nya masih nol. Dengan 64 slot, byte bitmap
adalah `slot / 8` dan posisi bit adalah `slot % 8`. Instruksi 8086 `SHR`,
`SHL`, `TEST`, dan `OR` digunakan tanpa fitur bitset modern.

Pass kedua menghapus bitmap dan mengulang validasi stack/slot secara linear
sambil membuat code. Fitur branch belum tersedia, jadi belum ada alur
kontrol yang memerlukan penggabungan keadaan inisialisasi dari beberapa jalur.
Kesalahan pada pass pertama menghentikan compiler sebelum emitter berjalan.

## Contoh dan debugging

IR `ICONST 10; STORE_LOCAL 0; LOAD_LOCAL 0; HALT` menghasilkan 10. Code
akses slot nol adalah `58 A3 02 00` untuk store dan `A1 02 00 50` untuk load.
Di GDB periksa slot dengan `x/hx 0x30002`, bitmap dengan `x/8bx 0x60020`,
serta hasil akhir dengan `x/hx 0x30000`.

Layout lengkap dan alamat fisik dijelaskan di `local-memory-layout.md`;
alur modul Assembly dijelaskan pada README masing-masing.
