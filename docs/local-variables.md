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

Tahap analisis menghapus bitmap delapan byte pada work memory `6000:0020`.
Setiap `STORE_LOCAL` memeriksa stack dan slot, lalu menandai bit pada state
transfer. `LOAD_LOCAL` memerlukan bit aktif pada state masuk node. Pada merge,
bitmap predecessor di-intersect sehingga slot dianggap initialized hanya
bila setiap jalur reachable telah menulisnya. Instruksi 8086 `SHR`, `SHL`,
`TEST`, dan `OR` digunakan tanpa fitur bitset modern.

Codegen memakai state bitmap per instruksi, tetapi tidak mengulang validasi
definite-assignment. Instruksi unreachable tetap dapat diemits tanpa
menjadikannya jalur runtime. Slot dengan indeks di luar 0–63 tetap ditolak
saat decode untuk semua instruksi.

## Contoh dan debugging

IR `ICONST 10; STORE_LOCAL 0; LOAD_LOCAL 0; HALT` menghasilkan 10. Code
akses slot nol adalah `58 A3 02 00` untuk store dan `A1 02 00 50` untuk load.
Di GDB periksa slot dengan `x/hx 0x30002`, bitmap dengan `x/8bx 0x60020`,
serta hasil akhir dengan `x/hx 0x30000`.

Layout lengkap dan alamat fisik dijelaskan di `local-memory-layout.md`;
alur modul Assembly dijelaskan pada README masing-masing.
