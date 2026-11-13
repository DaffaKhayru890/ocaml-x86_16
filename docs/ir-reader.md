# IR reader

`ir_init` menempatkan SI pada `program_ir` dan menginisialisasi remaining
dengan ukuran tabel. Header dibaca melalui prosedur yang sama dengan payload,
sehingga seluruh read memiliki pemeriksaan batas.

| Prosedur | Input | Hasil | Perubahan utama |
|---|---|---|---|
| `ir_check_remaining` | CX = jumlah byte | CF=0 jika cukup; CF=1 jika kurang | Mencatat EOF |
| `ir_read_u8` | SI dan remaining | AL = byte | SI +1, remaining -1 |
| `ir_read_u16` | SI dan remaining >=2 | AX = word little-endian | SI +2, remaining -2 |
| `ir_validate_header` | tabel mulai SI | SI menunjuk payload | Versi/panjang tersimpan |

Reader memakai `[cs:si]` karena tabel berada dalam ROM, sementara DS=`6000h`
menunjuk writable compiler state. Segment override tidak mengubah DS. Reader
memeriksa remaining sebelum akses; u16 ditolak atomik bila hanya satu byte
tersedia. Pada kegagalan, `WORK_STATUS=ERROR`, error code tersimpan, dan CF
diteruskan sampai compiler masuk error loop.

Payload length header dibandingkan dengan byte tabel aktual sesudah header.
Saat tabel dinyatakan valid, remaining menjadi tepat panjang payload.

Untuk inspeksi, SI menunjukkan offset IR, remaining ada di `60004h`, versi di
`6000Ch`, dan payload length di `6000Eh`. Jalankan `make test` untuk kasus
operand imm16 terpotong dan validasi header.
