# Modul variabel lokal dan codegen

## Konsep dan hubungan

`variables.asm` mengelola indeks slot dan bitmap inisialisasi di work memory,
serta membuat instruksi akses slot pada runtime. Validator stack memanggil
helper bitmap pada Pass 1 dan Pass 2; code generator memanggil helper alamat
untuk membuat instruksi. Nilai variabel tetap berada di DS runtime=`3000h`,
tidak di compiler work memory.

## Prosedur validasi dan bitmap

- `clear_local_init_bitmap`: menulis nol ke `6000:0020–0027`. BX/CX
  disimpan di stack compiler lalu dipulihkan; SI dan AX tidak diubah.
- `validate_local_slot`: AL harus lebih kecil dari `MAX_LOCAL_SLOTS`.
  Slot tidak valid mencatat `ERR_INVALID_LOCAL_SLOT` dan CF=1.
- `calculate_local_address`: menerima indeks di AL, memvalidasi batas,
  membersihkan AH, menggeser AX satu bit untuk ukuran word, lalu menambah
  `LOCAL_SLOT_BASE`. Mengembalikan offset di AX; rentang tak aman mencatat
  `ERR_LOCAL_MEMORY_OVERFLOW`.
- `set_local_initialized`: menerima slot di AL. Byte bitmap dipilih dengan
  indeks dibagi delapan; masker bit dibentuk dengan SHL dan digabung memakai
  OR. AX/BX/CX dipulihkan.
- `check_local_initialized`: memakai indeks byte dan masker yang sama,
  memeriksa bit memakai TEST, dan mencatat `ERR_UNINITIALIZED_LOCAL` jika
  bit nol. AX/BX/CX dipulihkan.

`SHR`/`SHL` dengan CL, TEST, OR, CMP, dan LOOP adalah instruksi 8086.
Tidak ada instruksi bitset modern. Compiler stack saat helper bitmap
dipanggil adalah SS:SP=`5000:FFFE`.

## Code generation

- `codegen_load_local`: membaca slot dari `WORK_DECODED_OPERAND`, memeriksa
  bitmap, menghitung offset, lalu mengirim `A1 lo hi 50` melalui emitter.
  Ini `MOV AX,[disp16]; PUSH AX`; A1 memakai DS implisit.
- `codegen_store_local`: menghitung offset dan mengirim
  `58 A3 lo hi` melalui emitter. Ini `POP AX; MOV [disp16],AX`.

Offset disimpan sementara di BX karena macro emitter memakai AL/AX; emitter
mempertahankan BX. Panjang dan DI diperbarui hanya oleh emit8/emit16.
Kegagalan emitter memulangkan CF=1 dan compiler tidak melakukan far jump.
Stack depth diperbarui terpusat oleh `codegen_validate_stack`, bukan lagi
oleh prosedur emit.

## Build dan debugging

`make test` menguji slot 0, slot 1, slot 63, tulis/baca/penimpaan, serta slot
64 invalid. Periksa `x/8bx 0x60020`, `x/hx 0x30002`,
`x/hx 0x30080`, dan code di `0x20000`. Peta lengkap ada di
`docs/local-memory-layout.md`.
