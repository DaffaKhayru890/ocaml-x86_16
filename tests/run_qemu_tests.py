#!/usr/bin/env python3
"""Menguji ROM, code generation, runtime, dan jalur error melalui QEMU HMP."""

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
RUNTIME_PROLOGUE = bytes.fromhex(
    "fa b8 00 30 8e d8 b8 00 40 8e d0 bc fe ff"
)
HALT_SEQUENCE = bytes.fromhex("58 a3 00 00 f4 eb fd")
EXPECTED_ERRORS = {
    11: 0x000A,
    12: 0x000C,
    13: 0x000D,
    14: 0x0011,
    15: 0x0011,
    16: 0x0010,
    17: 0x000B,
    18: 0x0011,
    19: 0x0010,
    20: 0x0008,
    101: 0x0001,
    102: 0x0002,
    103: 0x0003,
    104: 0x0004,
    105: 0x0005,
    106: 0x0006,
    107: 0x0007,
}
PROGRAMS = {
    0: ([("iconst", 7), ("iconst", 5), ("add",), ("iconst", 3), ("mul",)], 36),
    1: ([("iconst", 42)], 42),
    2: ([("iconst", 10), ("iconst", 20), ("add",)], 30),
    3: ([("iconst", 30), ("iconst", 10), ("sub",)], 20),
    4: ([("iconst", 7), ("iconst", 6), ("mul",)], 42),
    5: ([("iconst", 25), ("neg",)], -25),
    6: (
        [
            ("iconst", -10),
            ("iconst", 3),
            ("add",),
            ("iconst", 2),
            ("mul",),
        ],
        -14,
    ),
    7: ([("iconst", 32767)], 32767),
    8: ([("iconst", -32768)], -32768),
    9: ([("iconst", 32767), ("iconst", 1), ("add",)], -32768),
    10: ([("iconst", -32768), ("neg",)], -32768),
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


def read_values(output):
    values = []
    for line in output.splitlines():
        if ":" not in line:
            continue
        _, data = line.split(":", 1)
        values.extend(
            int(match, 16)
            for match in re.findall(r"0x([0-9a-fA-F]+)(?=\s|$)", data)
        )
    return values


def encode_operation(operation):
    name = operation[0]
    if name == "iconst":
        value = operation[1] & 0xFFFF
        return bytes((0xB8, value & 0xFF, value >> 8, 0x50))
    return {
        "add": bytes.fromhex("5b 58 01 d8 50"),
        "sub": bytes.fromhex("5b 58 29 d8 50"),
        "mul": bytes.fromhex("5b 58 f7 eb 50"),
        "neg": bytes.fromhex("58 f7 d8 50"),
    }[name]


def expected_code(case):
    operations, _ = PROGRAMS[case]
    return (
        RUNTIME_PROLOGUE
        + b"".join(encode_operation(operation) for operation in operations)
        + HALT_SEQUENCE
    )


def maximum_stack_depth(operations):
    depth = 0
    maximum = 0
    for operation in operations:
        if operation[0] == "iconst":
            depth += 1
            maximum = max(maximum, depth)
        elif operation[0] in ("add", "sub", "mul"):
            depth -= 1
    return maximum


def assemble_case(case, output_path):
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
            str(output_path),
        ],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )


def run_case(case, expected_error=None):
    with tempfile.TemporaryDirectory(prefix="phase02-") as directory:
        rom = (
            ROOT / "build" / "custom_rom.bin"
            if case == 0
            else Path(directory) / "test.bin"
        )
        monitor_path = str(Path(directory) / "monitor.sock")
        if case:
            assemble_case(case, rom)

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
            deadline = time.monotonic() + 10
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
            deadline = time.monotonic() + 10
            while "HLT=1" not in registers:
                registers = monitor_command(connection, "info registers")
                if time.monotonic() >= deadline:
                    raise AssertionError(f"Fixture {case}: CPU belum mencapai HLT.")
                time.sleep(0.02)
            work = read_values(
                monitor_command(connection, "xp /31bx 0x60000")
            )
            if len(work) < 31:
                raise AssertionError(f"Fixture {case}: work memory tidak terbaca.")

            status = work[0] | (work[1] << 8)
            error = work[2] | (work[3] << 8)
            if expected_error is not None:
                if status != 0xFFFF or error != expected_error:
                    raise AssertionError(
                        f"Fixture {case}: status={status:04X}, error={error:04X}; "
                        f"seharusnya FFFF:{expected_error:04X}."
                    )
                if "cs =f000" not in registers.lower():
                    raise AssertionError(
                        f"Fixture {case}: compiler gagal tetapi kontrol pindah ke runtime."
                    )
                return

            operations, expected_result = PROGRAMS[case]
            code = expected_code(case)
            if status != 0x0002 or error != 0:
                raise AssertionError(
                    f"Program {case}: status={status:04X}, error={error:04X}."
                )
            if "CS =2000" not in registers or "DS =3000" not in registers:
                raise AssertionError(f"Program {case}: segment runtime salah.")
            if "SS =4000" not in registers or "ESP=0000fffe" not in registers:
                raise AssertionError(f"Program {case}: runtime stack salah.")
            if work[4:6] != [0, 0] or work[28] != 1:
                raise AssertionError(f"Program {case}: IR tidak berakhir valid.")
            if work[22:24] != [0, 0] or work[29:31] != [1, 1]:
                raise AssertionError(f"Program {case}: validasi stack/runtime gagal.")
            maximum = maximum_stack_depth(operations)
            if work[24:26] != [maximum & 0xFF, maximum >> 8]:
                raise AssertionError(f"Program {case}: maksimum virtual stack salah.")
            instruction_count = len(operations) + 1
            if work[8:10] != [instruction_count & 0xFF, instruction_count >> 8]:
                raise AssertionError(f"Program {case}: jumlah instruksi salah.")
            code_length = work[10] | (work[11] << 8)
            if code_length != len(code) or f"EDI={code_length:08x}" not in registers:
                raise AssertionError(f"Program {case}: panjang generated code salah.")
            generated = read_values(
                monitor_command(connection, f"xp /{code_length}bx 0x20000")
            )
            if bytes(generated) != code:
                raise AssertionError(
                    f"Program {case}: machine code berbeda.\n"
                    f"aktual={bytes(generated).hex(' ')}\n"
                    f"harapan={code.hex(' ')}"
                )
            result = read_values(monitor_command(connection, "xp /1hx 0x30000"))
            expected_word = expected_result & 0xFFFF
            if result != [expected_word]:
                raise AssertionError(
                    f"Program {case}: hasil {result}, harapan {expected_word:04X}."
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
    for case in PROGRAMS:
        run_case(case)
        print(f"LULUS: program arithmetic {case}.")
    for case, error in EXPECTED_ERRORS.items():
        run_case(case, error)
        print(f"LULUS: fixture error {case}, kode {error:04X}.")


if __name__ == "__main__":
    main()
