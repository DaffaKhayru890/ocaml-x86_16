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
    13: 0x0013,
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
    108: 0x0012,
    109: 0x0012,
    110: 0x000A,
    111: 0x000A,
}
PASS_ONE_ERRORS = {13, 108, 109, 110, 111}
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
    21: ([("iconst", 10), ("store", 0), ("load", 0)], 10),
    22: (
        [
            ("iconst", 10),
            ("store", 0),
            ("iconst", 20),
            ("store", 1),
            ("load", 0),
            ("load", 1),
            ("add",),
        ],
        30,
    ),
    23: (
        [
            ("iconst", 10),
            ("store", 0),
            ("iconst", 25),
            ("store", 0),
            ("load", 0),
        ],
        25,
    ),
    24: ([("iconst", 10), ("iconst", 10), ("eq",)], 1),
    25: ([("iconst", 10), ("iconst", 20), ("eq",)], 0),
    26: ([("iconst", 10), ("iconst", 20), ("ne",)], 1),
    27: ([("iconst", 10), ("iconst", 10), ("ne",)], 0),
    28: ([("iconst", 10), ("iconst", 20), ("lt",)], 1),
    29: ([("iconst", 20), ("iconst", 10), ("lt",)], 0),
    30: ([("iconst", -5), ("iconst", 3), ("lt",)], 1),
    31: ([("iconst", 3), ("iconst", -5), ("lt",)], 0),
    32: ([("iconst", 20), ("iconst", 10), ("gt",)], 1),
    33: ([("iconst", 10), ("iconst", 20), ("gt",)], 0),
    34: ([("iconst", 5), ("iconst", -5), ("gt",)], 1),
    35: ([("iconst", -5), ("iconst", 5), ("gt",)], 0),
    36: (
        [
            ("iconst", 10),
            ("store", 0),
            ("iconst", 20),
            ("store", 1),
            ("load", 0),
            ("load", 1),
            ("lt",),
        ],
        1,
    ),
    37: (
        [
            ("iconst", 7),
            ("store", 0),
            ("iconst", 5),
            ("store", 1),
            ("iconst", 3),
            ("store", 2),
            ("load", 0),
            ("load", 1),
            ("add",),
            ("load", 2),
            ("mul",),
        ],
        36,
    ),
    38: ([("iconst", 77), ("store", 63), ("load", 63)], 77),
}
EXPECTED_LOCALS = {
    21: {0: 10},
    22: {0: 10, 1: 20},
    23: {0: 25},
    36: {0: 10, 1: 20},
    37: {0: 7, 1: 5, 2: 3},
    38: {63: 77},
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
    if name in ("load", "store"):
        address = 2 + operation[1] * 2
        low, high = address & 0xFF, address >> 8
        if name == "load":
            return bytes((0xA1, low, high, 0x50))
        return bytes((0x58, 0xA3, low, high))
    if name in ("eq", "ne", "lt", "gt"):
        jump = {"eq": 0x75, "ne": 0x74, "lt": 0x7D, "gt": 0x7E}[name]
        return bytes(
            (0x5B, 0x58, 0x39, 0xD8, 0xB8, 0, 0, jump, 3, 0xB8, 1, 0, 0x50)
        )
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
        elif operation[0] == "load":
            depth += 1
            maximum = max(maximum, depth)
        elif operation[0] == "store":
            depth -= 1
        elif operation[0] in ("add", "sub", "mul", "eq", "ne", "lt", "gt"):
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
                monitor_command(connection, "xp /40bx 0x60000")
            )
            if len(work) < 40:
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
                if case in PASS_ONE_ERRORS and work[10:12] != [0, 0]:
                    raise AssertionError(
                        f"Fixture {case}: pass pertama menghasilkan byte code."
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
            expected_bitmap = bytearray(8)
            for operation in operations:
                if operation[0] == "store":
                    slot = operation[1]
                    expected_bitmap[slot // 8] |= 1 << (slot % 8)
            if work[32:40] != list(expected_bitmap):
                raise AssertionError(
                    f"Program {case}: bitmap lokal {work[32:40]}, "
                    f"harapan {list(expected_bitmap)}."
                )
            result = read_values(monitor_command(connection, "xp /1hx 0x30000"))
            expected_word = expected_result & 0xFFFF
            if result != [expected_word]:
                raise AssertionError(
                    f"Program {case}: hasil {result}, harapan {expected_word:04X}."
                )
            for slot, expected_value in EXPECTED_LOCALS.get(case, {}).items():
                address = 0x30000 + 2 + slot * 2
                value = read_values(
                    monitor_command(connection, f"xp /1hx {address:#x}")
                )
                if value != [expected_value & 0xFFFF]:
                    raise AssertionError(
                        f"Program {case}: slot {slot} berisi {value}, "
                        f"harapan {expected_value & 0xFFFF:04X}."
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
        print(f"LULUS: program runtime {case}.")
    for case, error in EXPECTED_ERRORS.items():
        run_case(case, error)
        print(f"LULUS: fixture error {case}, kode {error:04X}.")


if __name__ == "__main__":
    main()
