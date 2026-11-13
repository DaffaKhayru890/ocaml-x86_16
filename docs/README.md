# Compiler Bare-Metal x86 16-bit — Phase 00–04

## Tujuan

Proyek ini menghasilkan firmware raw 64 KiB untuk QEMU. Firmware
menginisialisasi real mode; compiler Assembly memvalidasi static IR,
menghasilkan code x86 16-bit langsung ke RAM, lalu menjalankannya. Tidak ada
parser, BIOS service, sistem operasi, UEFI, DOS, syscall, atau interrupt BIOS.

## Rancangan mesin dan reset

Target adalah machine QEMU `pc` melalui `qemu-system-i386` dan opsi `-bios`
dengan citra kustom. CPU x86 modern memasuki alamat fisik `FFFFFFF0h`, bukan
reset vector `FFFF:0000` milik 8086/8088 klasik. QEMU memetakan firmware PC
di bagian atas ruang alamat dan menyediakan alias legacy untuk ROM berukuran
64 KiB mulai `F0000h`. Reset vector menjalankan far jump ke `F000:0000`.
Detail dan cara memverifikasi pemetaan ada di `reset-vector.md`.

## Struktur

- `src/firmware.asm`: perakitan flat binary dan urutan modul.
- `src/boot/*.asm`: entry, inisialisasi, main, dan reset vector; tiap modul
  memiliki README pendamping.
- `src/compiler/*.asm`: reader, dispatcher, tabel alur kontrol, CFG/dataflow,
  relocation, code generator, arithmetic, variables, runtime, dan main; tiap
  modul memiliki README.
- `src/examples/*.asm`: contoh IR arithmetic, variabel, dan comparison.
- `include/*.inc`: konstanta firmware, opcode, layout work memory, serta
  batas tabel CFG.
- `scripts/`: build serta peluncuran QEMU di Linux dan Windows.
- `build/custom_rom.bin`: keluaran 65536 byte.
- `tests/`: fixture emitter, runtime, CFG, branching, relocation, dan error.
- `docs/`: penjelasan firmware, compiler, IR, codegen, runtime, serta debug.

## Build dan jalankan

Linux: `make` atau `scripts/build.sh`; lalu `scripts/run-qemu.sh`.
Windows: `scripts\build.bat`, lalu `scripts\run-qemu.bat`.
QEMU berhenti sebelum instruksi pertama dan membuka GDB remote di port 1234.
Sambungkan dengan `gdb -ex 'target remote :1234'`. Untuk inspeksi instruksi,
gunakan `x/i $cs*16+$eip` setelah berpindah dari reset.

Build memeriksa ukuran ROM, reset vector, dan encoding conditional jump 8086,
serta menghasilkan `build/custom_rom.lst`. `make test` membangun fixture,
menjalankannya di QEMU, lalu memeriksa register, memory, machine code, hasil,
dan error.

## Fitur Phase 04 dan batasan

Opcode yang didukung: ICONST, LOAD_LOCAL, STORE_LOCAL, ADD, SUB, MUL, NEG,
EQ, NE, LT, GT, LABEL, JMP, JZ, JNZ, dan HALT. JMP memakai `E9 rel16`;
JZ/JNZ memakai POP/TEST, short jump pembalik kondisi, lalu JMP near.
Validasi stack serta definite assignment dilakukan pada control-flow graph
(CFG), termasuk merge dan loop. Beberapa HALT diperbolehkan jika setiap
terminal yang reachable menerima tepat satu nilai.

Batas tabel adalah 256 instruksi executable, 64 label, 128 relocation, dan
4096 byte output. Nilai arithmetic berwrap modulo 65536. Implementasi khusus
konfigurasi PC QEMU yang diuji, bukan firmware universal untuk semua machine
atau CPU 8086.

## Dokumentasi terkait

- `compiler-architecture.md`, `code-generation.md`, dan `memory-map.md`:
  pipeline, codegen, dan alamat tabel.
- `control-flow-readme.md`, `cfg-readme.md`, `dataflow-readme.md`,
  `relocation-readme.md`, dan `jump-codegen-readme.md`: modul Phase 04.
- `stack-machine.md`, `arithmetic.md`, `local-variables.md`,
  `comparison.md`, dan `runtime.md`: semantik runtime.
- `debugging.md` dan `qemu-debugging.md`: pemeriksaan QEMU/GDB serta hasil tes.
