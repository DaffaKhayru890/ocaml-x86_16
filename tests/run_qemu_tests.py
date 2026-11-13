#!/usr/bin/env python3
"""Menguji ROM dan state compiler melalui QEMU HMP lokal."""

import os
import re
import socket
import subprocess
import tempfile
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
NASM = os.environ.get("NASM", "nasm")
QEMU = os.environ.get("QEMU", "qemu-system-i386")
EXPECTED_ERRORS = {
    1: 0x0001,
    2: 0x0002,
    3: 0x0003,
    4: 0x0004,
    5: 0x0005,
    6: 0x0006,
    7: 0x0007,
}


def read_prompt(connection):
    data = bytearray()
    while b"(qemu)" not in data:
        chunk = connection.recv(4096)
        if not chunk:
            raise RuntimeError("Koneksi monitor QEMU ditutup.")
        data.extend(chunk)
    return data.decode(errors="replace")


def monitor_command(connection, command):
    connection.sendall(command.encode() + b"\n")
    return read_prompt(connection)


def read_memory(output):
    values = []
    for line in output.splitlines():
        if ":" not in line:
            continue
        _, data = line.split(":", 1)
        values.extend(
            int(match, 16)
            for match in re.findall(r"0x([0-9a-fA-F]{2})(?=\s|$)", data)
        )
    return values


def run_case(case, expected_error):
    with tempfile.TemporaryDirectory(prefix="phase01-") as directory:
        rom = ROOT / "build" / "custom_rom.bin" if case == 0 else Path(directory) / "test.bin"
        monitor_path = str(Path(directory) / "monitor.sock")
        if case:
            subprocess.run(
                [
                    NASM,
                    "-f",
                    "bin",
                    "-I",
                    ".",
                    "-D",
                    f"IR_TEST_CASE={case}",
                    "src/firmware.asm",
                    "-o",
                    str(rom),
                ],
                cwd=ROOT,
                check=True,
                capture_output=True,
                text=True,
            )

        image = rom.read_bytes()
        if len(image) != 65536:
            raise AssertionError(f"Fixture {case}: ukuran ROM {len(image)} byte.")
        if image[0xFFF0:0xFFF5] != bytes.fromhex("ea000000f0"):
            raise AssertionError(f"Fixture {case}: reset vector tidak cocok.")

        process = subprocess.Popen(
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
                f"unix:{monitor_path},server,nowait",
                "-no-reboot",
                "-no-shutdown",
            ],
            cwd=ROOT,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        connection = socket.socket(socket.AF_UNIX)
        try:
            deadline = time.monotonic() + 5
            while True:
                try:
                    connection.connect(monitor_path)
                    break
                except OSError:
                    if process.poll() is not None:
                        raise RuntimeError(f"QEMU berhenti pada fixture {case}.")
                    if time.monotonic() >= deadline:
                        raise TimeoutError(f"Monitor QEMU fixture {case} tidak siap.")
                    time.sleep(0.05)

            connection.settimeout(3)
            read_prompt(connection)
            registers = ""
            deadline = time.monotonic() + 5
            while "HLT=1" not in registers:
                registers = monitor_command(connection, "info registers")
                if time.monotonic() >= deadline:
                    raise AssertionError(f"Fixture {case}: CPU belum mencapai HLT.")
                time.sleep(0.02)
            work = read_memory(monitor_command(connection, "xp /22bx 0x60000"))
            if len(work) < 22:
                raise AssertionError(f"Fixture {case}: work memory tidak terbaca.")

            status = work[0] | (work[1] << 8)
            error = work[2] | (work[3] << 8)
            if expected_error is None:
                if status != 0x0002 or error != 0:
                    raise AssertionError(
                        f"IR valid: status={status:04X}, error={error:04X}."
                    )
                if work[4:6] != [0, 0]:
                    raise AssertionError("IR valid: remaining bukan nol.")
                if work[8:10] != [17, 0]:
                    raise AssertionError("IR valid: jumlah instruksi bukan 17.")
                if work[10:12] != [5, 0] or work[16] != 1:
                    raise AssertionError("IR valid: panjang output atau END salah.")
                output = read_memory(
                    monitor_command(connection, "xp /5bx 0x20000")
                )
                if output[:5] != [0xB8, 0x34, 0x12, 0x50, 0x58]:
                    raise AssertionError(f"Emitter menghasilkan byte {output[:5]}.")
            elif status != 0xFFFF or error != expected_error:
                raise AssertionError(
                    f"Fixture {case}: status={status:04X}, error={error:04X}; "
                    f"seharusnya FFFF:{expected_error:04X}."
                )
        finally:
            connection.close()
            process.terminate()
            try:
                process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()


def main():
    run_case(0, None)
    print("LULUS: IR valid, seluruh opcode, emitter, dan overflow.")
    for case, error in EXPECTED_ERRORS.items():
        run_case(case, error)
        print(f"LULUS: fixture IR {case}, kode error {error:04X}.")


if __name__ == "__main__":
    main()
