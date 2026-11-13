# Machine Code Emitter

Emitter adalah primitive byte-to-RAM, bukan code generator. `emit8`
menerima AL, sedangkan `emit16` menerima AX dan menulis representasi
little-endian. Keduanya menulis melalui ES:DI serta memperbarui panjang di
work memory. Tidak ada textual Assembly atau penggunaan assembler saat
runtime.

| Prosedur | Input | Sukses | Error |
|---|---|---|---|
| `emitter_init` | ES menunjuk buffer | DI dan panjang nol | Tidak ada |
| `emit8` | AL | Tulis 1 byte, DI +1, CF=0 | CF=1, overflow tercatat, DI tetap |
| `emit16` | AX | Tulis 2 byte little-endian, DI +2, CF=0 | CF=1 tanpa penulisan parsial |

AX dipertahankan oleh emitter, termasuk pada jalur overflow; DI berubah hanya
ketika berhasil. Register umum lain dipertahankan. Status/error berada pada
DS:WORK dan panjang output adalah `WORK_EMIT_LENGTH`.

Self-test terpisah menulis `B8 34 12 50 58`, yang *sebagai data* merupakan
encoding `mov ax,1234h; push ax; pop ax`. Tes membandingkan byte, mengisi
byte terakhir buffer, menguji byte berlebih, serta memastikan emit16 gagal
tanpa menulis parsial saat hanya satu byte tersisa. Tidak satu pun byte
tersebut dijalankan.

Lihat `docs/output-buffer.md` untuk batas kapasitas dan alamat.
