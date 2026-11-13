# Code generator

## Konsep dan tujuan

Modul ini menjadi tahap emission setelah IR dan CFG tervalidasi. Ia
menginisialisasi emitter, mengambil record dari instruction table, mengirim
opcode ke generator terkait, lalu memeriksa buffer sebelum far jump.

## Hubungan dan register

`codegen_init` memakai work memory (`DS=6000h`) dan emitter (`ES:DI`,
`ES=2000h`). `codegen_generate_program` mengambil data dari record DS,
menggunakan SI untuk menyalin bitmap state, dan DI sebagai output offset.
Prosedur mempertahankan DS/ES; register lain tidak dijanjikan tetap.

## Urutan prosedur

- `codegen_init`: atur status codegen, bersihkan bitmap sementara, dan
  inisialisasi emitter tanpa menghapus hasil analisis.
- `codegen_dispatch`: pilih ICONST, local, arithmetic, comparison, branch,
  atau HALT; opcode
  tanpa generator mencatat `ERR_UNSUPPORTED_OPCODE`.
- `codegen_generate_program`: delegasikan ke generator instruction table,
  catat label offsets, terapkan relocation, lalu validasi buffer.
- `codegen_validate_generated_code`: periksa flag prologue/HALT/IR_END,
  stack compile-time, kapasitas/panjang, dan 14 byte prologue, lalu panggil
  validator machine code.
- `machine_code_validate_generated_program`: cocokkan setiap opcode dengan
  template byte, periksa offset record berurutan, HALT, status relocation,
  dan target/displacement branch sebelum compiler melakukan far jump.

Pemeriksaan word memakai little-endian x86; contoh word di offset nol
`B8FAh` mewakili byte `FA B8`. Prosedur validasi membaca kembali RAM output,
bukan mengubahnya.

## Build dan debugging

`make test-codegen` menguji byte aktual dan disassembly `ndisasm`; `make
test-gdb` memeriksa entry dan breakpoint HLT. Periksa DI/panjang di `6000Ah`,
tabel mulai `60100h`, serta output di `20000h` menggunakan GDB; rincian ada
di `docs/debugging.md`.
