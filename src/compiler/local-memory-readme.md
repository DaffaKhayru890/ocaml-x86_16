# Area memori variabel lokal

## Konsep dan tujuan

Modul ini menjelaskan pembagian runtime data; implementasi akses dan bitmap
berada pada `variables.asm`. DS runtime menunjuk segment `3000h`; hasil akhir
menguasai dua byte pertama, lalu 64 local slot menggunakan dua byte per slot.

## Layout dan alamat

`LOCAL_SLOT_BASE=0002h`, `LOCAL_SLOT_SIZE=2`, `MAX_LOCAL_SLOTS=64`, dan
`LOCAL_SLOT_END=0082h` (batas eksklusif) didefinisikan di
`include/variables.inc`. Rumusnya `offset=base+indeks*ukuran`. Slot 0
berada pada `3000:0002` (fisik `30002h`); slot 5 pada `3000:000C`
(`3000Ch` fisik); slot 63 pada `3000:0080` (`30080h–30081h`).

Hasil final tetap pada `3000:0000`. Work bitmap berbeda segmen di
`6000:0020–0027`; ia menyimpan keadaan inisialisasi saja, bukan nilai
variabel.

## Prosedur dan register

- `clear_local_init_bitmap` mengosongkan byte `60020h–60027h`. BX dan CX
  disimpan/dipulihkan; SI tetap menunjuk IR.
- `validate_local_slot` menerima indeks AL dan memastikan kurang dari 64.
  Slot invalid mencatat `ERR_INVALID_LOCAL_SLOT`.
- `calculate_local_address` mengembalikan offset di AX dengan rumus
  `base + indeks*2`; batas memori yang terlampaui mencatat
  `ERR_LOCAL_MEMORY_OVERFLOW`.
- `set_local_initialized` menghitung byte/bit lalu mengatur bit dengan OR.
- `check_local_initialized` menguji bit dengan TEST dan melaporkan
  `ERR_UNINITIALIZED_LOCAL` jika belum ditulis.

Bitmap diakses melalui DS=`6000h`, sedangkan alamat hasil perhitungan
menunjuk DS runtime=`3000h`. Helper bitmap memulihkan AX/BX/CX, sehingga
pemanggil dapat mempertahankan status operand yang diperlukan.

## Hubungan modul dan urutan

`clear_local_init_bitmap`, `set_local_initialized`, dan
`check_local_initialized` dipanggil validator secara linear. `calculate_local_address`
memvalidasi indeks dan batas sebelum codegen. Runtime load memakai A1
(`MOV AX,[disp16]`), sedangkan store memakai A3 (`MOV [disp16],AX`).
Keduanya memakai DS implisit yang sudah diset ke `3000h`.

Prosedur emission `codegen_load_local` dan `codegen_store_local` berada pada
`variables.asm`; semua byte ditulis lewat emitter. Debugger dapat membaca
word slot dengan `x/hx 0x30002`, dan bitmap dengan `x/8bx 0x60020`.
