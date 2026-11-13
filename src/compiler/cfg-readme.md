# Control-flow graph

## Pengantar

Validasi linear tidak cukup untuk branch: instruksi setelah HALT dapat
reachable dari jump lain, dan merge dapat menerima stack depth berbeda.
CFG mendeskripsikan successor setiap instruksi executable sehingga analisis
hanya menganggap state yang benar-benar dapat dicapai dari entry.

## Tujuan dan hubungan

`cfg.asm` menginisialisasi state awal tabel dan memulai fixed-point pada
`dataflow.asm`. Successor disimpan secara ringkas: target index ada pada
record JMP/JZ/JNZ; fallthrough dihitung sebagai indeks berikutnya. Opcode
menentukan apakah edge target, fallthrough, keduanya, atau tidak ada yang
dipakai.

## Register dan alamat

DS=`6000h` menunjuk instruction table di offset `0100h`; AX membawa indeks
instruksi; BX menunjuk record 19-byte. CX/DX dipakai penghitung dan
temporary oleh helper tabel. Stack compiler `5000:FFFE` menampung CALL/RET.
`CF_INST_STACK_IN=FFFFh` menandakan node belum reachable.

## Prosedur dan aturan successor

`cfg_analyze_program` menghapus state input semua record, memberi instruksi
pertama stack depth nol dan bitmap kosong, lalu memanggil
`dataflow_fixed_point`.

| Opcode | Successor |
|---|---|
| JMP | Target saja |
| JZ/JNZ | Target dan indeks sesudah branch |
| Instruksi biasa | Indeks sesudah instruksi |
| HALT | Tidak ada |

Target branch sudah divalidasi pada tahap resolusi. Fallthrough yang
reachable harus kurang dari jumlah instruction; jika tidak, error
`ERR_CFG_INVALID_FALLTHROUGH`. Node yang tidak menerima state entry tetap
unreachable. CFG tetap mengeluarkan code untuk node tersebut agar alamat
semua record stabil, tetapi dataflow tidak memberinya state runtime.

## Alur dan debugging

Entry state memulai propagasi. Setiap successor yang belum memiliki input
menerima state pertama; successor yang sudah ada wajib memiliki stack depth
yang sama dan bitmap definite-assignment di-intersect. Sweep berulang hingga
tidak ada perubahan atau batas iterasi tercapai. Semua HALT reachable
dihitung dan harus ada paling sedikit satu.

Jalankan `make test`; case 40–43 dan 49 memeriksa forward/backward edge serta
branch conditional; case 44 memeriksa merge stack yang invalid. Lihat
`docs/debugging.md` untuk membaca target index dan stack state dari tabel.
