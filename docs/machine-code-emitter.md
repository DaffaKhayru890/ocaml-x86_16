# Machine Code Emitter

Emitter adalah primitive byte-to-RAM yang dipakai code generator. `emit8`
menerima AL, sedangkan `emit16` menerima AX dan menulis representasi
little-endian. Keduanya menulis melalui ES:DI serta memperbarui panjang di
work memory. Tidak ada textual Assembly atau assembler host saat runtime.

| Prosedur | Input | Sukses | Error |
|---|---|---|---|
| `emitter_init` | ES menunjuk buffer | DI dan panjang nol | Tidak ada |
| `emit8` | AL | Tulis 1 byte, DI +1, CF=0 | CF=1, overflow tercatat, DI tetap |
| `emit16` | AX | Tulis 2 byte little-endian, DI +2, CF=0 | CF=1 tanpa penulisan parsial |

AX dipertahankan oleh emitter, termasuk pada jalur overflow; DI berubah hanya
ketika berhasil. Register umum lain dipertahankan. Status/error berada pada
DS:WORK dan panjang output adalah `WORK_EMIT_LENGTH`.

Self-test terpisah Phase 01 menulis `B8 34 12 50 58` dan menguji batas
buffer. Phase 02 menjalankannya sebelum pass kedua, lalu mereset DI dan
panjang output agar self-test tidak masuk ke generated program. Codegen
menggunakan emitter untuk setiap opcode runtime dan tidak melanjutkan saat
CF menandakan overflow.

Machine bytes kemudian diverifikasi dan dijalankan dari RAM hanya setelah
kedua pass valid. Lihat `docs/output-buffer.md` untuk batas kapasitas dan
alamat.
