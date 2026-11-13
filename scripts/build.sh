#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v nasm >/dev/null 2>&1; then
    printf '%s\n' "Galat: NASM tidak ditemukan pada PATH." >&2
    exit 1
fi

mkdir -p build
nasm -f bin -I . src/firmware.asm -o build/custom_rom.bin

size="$(wc -c < build/custom_rom.bin | tr -d '[:space:]')"
if [[ "$size" != "65536" ]]; then
    printf 'Galat: ukuran ROM %s byte, seharusnya 65536 byte.\n' "$size" >&2
    exit 1
fi

vector="$(od -An -tx1 -j 65520 -N 5 build/custom_rom.bin | tr -d ' \n')"
if [[ "$vector" != "ea000000f0" ]]; then
    printf 'Galat: byte reset vector tidak cocok: %s\n' "$vector" >&2
    exit 1
fi

printf '%s\n' "ROM berhasil dibangun: build/custom_rom.bin (65536 byte)"
printf 'Reset vector: %s\n' "$vector"
