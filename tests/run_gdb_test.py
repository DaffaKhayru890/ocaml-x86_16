#!/usr/bin/env python3
"""Memeriksa entry generated code dan jalur menuju instruksi HLT dengan GDB."""

import os
import re
import socket
import subprocess
import tempfile
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
QEMU = os.environ.get("QEMU", "qemu-system-i386")
GDB = os.environ.get("GDB", "gdb")


def register_value(section, name):
    match = re.search(rf"(?m)^{name}\s+0x([0-9a-f]+)", section.lower())
    return None if match is None else match.group(1)


def main():
    rom = ROOT / "build" / "custom_rom.bin"
    if not rom.is_file() or rom.stat().st_size != 65536:
        raise SystemExit("Galat: ROM 64 KiB belum dibangun.")

    with socket.socket() as reserve:
        reserve.bind(("127.0.0.1", 0))
        port = reserve.getsockname()[1]

    qemu = subprocess.Popen(
        [
            QEMU,
            "-machine",
            "pc",
            "-m",
            "16M",
            "-bios",
            str(rom),
            "-display",
            "none",
            "-serial",
            "none",
            "-monitor",
            "none",
            "-no-reboot",
            "-no-shutdown",
            "-S",
            "-gdb",
            f"tcp:127.0.0.1:{port}",
        ],
        cwd=ROOT,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    try:
        time.sleep(0.2)
        if qemu.poll() is not None:
            raise RuntimeError("QEMU berhenti sebelum GDB terhubung.")
        commands = [
            "set pagination off",
            "set confirm off",
            "set architecture i386",
            f"target remote 127.0.0.1:{port}",
            "info registers",
            "x/5bx 0xfffffff0",
            "stepi",
            "info registers",
            "hbreak *0x20000",
            "continue",
            "info registers",
            "x/1hx 0x60000",
            "set $length = *(unsigned short *)0x6000a",
            "set $halt = 0x20000 + $length - 3",
            'printf "ROM-ENTRY-CODE-LENGTH=%u HLT-ADDRESS=%x\\n", $length, $halt',
            "delete 1",
            "hbreak *$halt",
            "continue",
            "info registers",
            "x/1bx $halt",
            "x/1hx 0x30000",
            "disconnect",
            "quit",
        ]
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", suffix=".gdb", delete=False
        ) as command_file:
            command_file.write("\n".join(commands) + "\n")
            command_path = Path(command_file.name)
        try:
            result = subprocess.run(
                [GDB, "-q", "-batch", "-x", str(command_path)],
                cwd=ROOT,
                capture_output=True,
                text=True,
                timeout=20,
            )
        finally:
            command_path.unlink()

        output = result.stdout + result.stderr
        if result.returncode:
            raise RuntimeError(f"GDB gagal ({result.returncode}):\n{output}")
        if output.count("Hardware assisted breakpoint") < 2:
            raise AssertionError(f"GDB tidak mencapai dua breakpoint:\n{output}")
        reset = output.split("Hardware assisted breakpoint 1 at", 1)[0]
        entry = output.split("Hardware assisted breakpoint 1 at", 1)[1].split(
            "Hardware assisted breakpoint 2 at", 1
        )[0]
        runtime = output.split("Hardware assisted breakpoint 2 at", 1)[1]
        if re.search(
            r"0xfffffff0:\s+0xea\s+0x00\s+0x00\s+0x00\s+0xf0",
            reset.lower(),
        ) is None:
            raise AssertionError(f"Reset vector tidak cocok:\n{output}")
        if register_value(reset, "eip") != "fff0" or register_value(reset, "cs") != "f000":
            raise AssertionError(f"Register reset tidak sesuai:\n{output}")
        if "ROM-ENTRY-CODE-LENGTH=" not in entry or "HLT-ADDRESS=" not in entry:
            raise AssertionError(f"GDB tidak mencetak alamat HLT:\n{output}")
        expected = {
            "entry": {
                "cs": "2000",
                "ds": "6000",
                "es": "2000",
                "ss": "5000",
                "esp": "fffa",
            },
            "runtime": {
                "cs": "2000",
                "ds": "3000",
                "es": "2000",
                "ss": "4000",
                "esp": "fffe",
            },
        }
        for section, state in (("entry", entry), ("runtime", runtime)):
            for name, value in expected[section].items():
                if register_value(state, name) != value:
                    raise AssertionError(
                        f"Register {name.upper()} salah pada {section}:\n{output}"
                    )
        if re.search(r"0x30000:\s+0x0024", runtime.lower()) is None:
            raise AssertionError(f"Hasil program default bukan 36:\n{output}")
        length = re.search(r"ROM-ENTRY-CODE-LENGTH=(\d+)", entry)
        address = re.search(r"HLT-ADDRESS=([0-9a-f]+)", entry)
        if length is None or address is None:
            raise AssertionError(f"Informasi panjang output tidak valid:\n{output}")
        halt_address = int(address.group(1), 16)
        if re.search(rf"0x{halt_address:x}:\s+0xf4", runtime.lower()) is None:
            raise AssertionError(f"Breakpoint akhir tidak berada pada byte HLT:\n{output}")
        if re.search(r"0x60000:\s+0x0002", entry.lower()) is None:
            raise AssertionError(f"Status compiler bukan STATUS_SUCCESS:\n{output}")
        print(
            "LULUS: reset FFFFFFF0 -> entry 2000:0000 "
            "(DS=6000, ES=2000, SS:SP=5000:FFFA) -> "
            f"HLT 2000:{halt_address - 0x20000:04X} "
            "(DS=3000, ES=2000, SS:SP=4000:FFFE); "
            f"panjang={length.group(1)}, hasil=0024."
        )
    finally:
        qemu.terminate()
        try:
            qemu.wait(timeout=3)
        except subprocess.TimeoutExpired:
            qemu.kill()
            qemu.wait()


if __name__ == "__main__":
    main()
