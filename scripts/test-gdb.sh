#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

for tool in nasm qemu-system-i386 gdb python3; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'Galat: %s tidak ditemukan pada PATH.\n' "$tool" >&2
        exit 1
    fi
done

./scripts/build.sh
python3 tests/run_gdb_test.py
