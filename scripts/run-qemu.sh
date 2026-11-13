#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
if ! command -v "${QEMU:-qemu-system-i386}" >/dev/null 2>&1; then
    printf '%s\n' "Galat: QEMU tidak ditemukan pada PATH." >&2
    exit 1
fi
if [[ ! -f build/custom_rom.bin ]]; then
    printf '%s\n' "Galat: build/custom_rom.bin belum ada; jalankan scripts/build.sh." >&2
    exit 1
fi

exec "${QEMU:-qemu-system-i386}" \
    -machine pc -m 16M -bios build/custom_rom.bin \
    -display none -serial none -monitor none \
    -no-reboot -no-shutdown -S -s
