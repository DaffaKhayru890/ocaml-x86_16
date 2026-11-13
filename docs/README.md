# Compiler Bare-Metal x86 16-bit — Phase 00/01/02

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
64 KiB mulai `F0000h`. Reset vector mengandung far jump ke `F000:0000`,
sehingga eksekusi beralih ke alias tersebut dan CS menjadi segmen real-mode
yang dapat dipakai. Detail dan cara memverifikasi pemetaan ada di
`reset-vector.md`.

## Struktur

- `src/firmware.asm`: perakitan flat binary dan urutan modul.
- `src/boot/*.asm`: entry, inisialisasi, main, dan reset vector; tiap modul
  memiliki README pendamping.
- `src/compiler/*.asm`: reader, dispatcher, stack validator, code generator,
  arithmetic, emitter, runtime, dan compiler main; tiap modul memiliki README.
- `src/examples/program_ir.asm`: contoh IR statis yang disertakan dalam ROM.
- `include/*.inc`: konstanta firmware dan peta region.
- `scripts/`: build serta peluncuran QEMU di Linux dan Windows.
- `build/custom_rom.bin`: keluaran 65536 byte.
- `tests/`: fixture arithmetic/stack/runtime, emitter self-test, pengujian QEMU.
- `docs/`: penjelasan firmware, compiler, IR, codegen, runtime, dan debugging.

## Build dan jalankan

Linux: `make` atau `scripts/build.sh`; lalu `scripts/run-qemu.sh`.
Windows: `scripts\build.bat`, lalu `scripts\run-qemu.bat`.
QEMU berhenti sebelum instruksi pertama dan membuka GDB remote di port 1234.
Sambungkan dengan `gdb -ex 'target remote :1234'`. Untuk melanjutkan gunakan
`continue`; untuk inspeksi instruksi gunakan `x/i $cs*16+$eip` pada mode
real yang telah berpindah dari reset.

Build memeriksa ukuran ROM dan reset vector, menghasilkan `build/custom_rom.lst`
untuk pemetaan source ke offset. `make test` menguji arithmetic, generated
bytes, error stack/IR, hasil runtime, dan HLT di QEMU.

## Batasan phase

Phase 02 mendukung ICONST, ADD, SUB, MUL, NEG, dan HALT. Local, comparison,
branch/label relocation, dan overflow exception belum didukung. Arithmetic
berwrap modulo 65536. CPU dapat dibangunkan NMI meskipun IRQ dimatikan.
Implementasi ini khusus konfigurasi PC QEMU yang diuji, bukan firmware
universal untuk semua machine atau CPU 8086.

## Rujukan Phase 02

- `compiler-architecture.md` dan `code-generation.md`: alur compiler dua pass.
- `stack-machine.md` dan `arithmetic.md`: aturan stack virtual dan operasi.
- `machine-code-reference.md`: byte encoding instruksi yang dihasilkan.
- `runtime.md` dan `memory-map.md`: prologue, hasil, stack, dan peta alamat.
- `debugging.md` dan `qemu-debugging.md`: pemeriksaan GDB/QEMU serta hasil tes.
