# Compiler bare-metal x86 16-bit

Proyek ini adalah compiler berbasis IR statis yang ditulis dalam Assembly
NASM 16-bit dan dijalankan langsung oleh firmware kustom QEMU. Compiler
memvalidasi IR, menganalisis control flow, menghasilkan machine code 8086 ke
RAM, lalu memindahkan kendali ke program hasil. Ini bukan compiler OCaml
lengkap: belum ada parser, lexer, frontend OCaml, atau dukungan OS.

## Status dan ruang lingkup

Phase 00 menyediakan reset ROM 64 KiB, entry firmware, inisialisasi segmen
dan stack, serta HLT loop. Phase 01–04 menambahkan reader dan validasi IR,
emitter, arithmetic, local variable, comparison, branch, CFG, relocation,
stack validation, dan definite assignment. Phase 05 mengintegrasikan
validasi machine code, suite regresi, disassembly, pemeriksaan GDB, dan
dokumentasi. Tidak ada fitur Phase 06.

## Persyaratan perangkat

- NASM untuk menghasilkan flat binary.
- QEMU `qemu-system-i386` untuk menjalankan ROM custom pada machine `pc`.
- `ndisasm` dan Python 3 standard library untuk suite regresi.
- GDB untuk tes debugging otomatis opsional.

QEMU diberi firmware sendiri melalui `-bios build/custom_rom.bin`; SeaBIOS,
UEFI, disk boot, OS, syscall, dan BIOS interrupt tidak digunakan. CPU QEMU
modern memulai pada `FFFFFFF0h`; stub ROM di sana melakukan far jump ke
`F000:0000`. Ini berbeda dari reset state 8086 klasik `FFFF:0000`.

## Build, jalankan, dan tes

Linux:

```sh
make
make run
make test
make test-control-flow
make test-gdb
```

Windows:

```bat
scripts\build.bat
scripts\run-qemu.bat
scripts\test.bat --suite all
scripts\test-gdb.bat
```

Build menghasilkan `build/custom_rom.bin` tepat 65.536 byte dan memeriksa
reset vector serta encoding yang tidak kompatibel dengan 8086. `make test`
menjalankan seluruh fixture melalui QEMU, memeriksa register/memori, byte
machine code dan disassembly 16-bit. `make test-gdb` memeriksa reset vector,
entry generated code, register, hasil program, dan alamat instruksi HLT.

## Struktur penting

- `src/boot/` dan `src/firmware.asm`: reset ROM dan firmware.
- `src/compiler/`: reader, analisis, emitter, relocation, dan codegen.
- `include/`: opcode, memory map, kapasitas, dan status.
- `tests/`: fixture statis dan harness QEMU/GDB.
- `scripts/`: build, run, dan test Linux/Windows.
- `docs/`: arsitektur, memory map, encoding, debugging, test, error, dan limitasi.
- `build/custom_rom.bin`: ROM hasil build.

Mulai dari [arsitektur compiler](docs/compiler-architecture.md),
[peta memori](docs/memory-map.md), [pengujian](docs/testing.md), dan
[debugging QEMU/GDB](docs/qemu-debugging.md).
