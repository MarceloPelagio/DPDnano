#!/usr/bin/env python3
from __future__ import annotations

import argparse
import random
import serial
import time

SOF_REQ = 0xA5
SOF_RSP = 0x5A

CMD_PING = 0x01
CMD_VERSION = 0x02
CMD_WRITE = 0x20
CMD_READ = 0x21

ERR_ADDR = 0x000000E3

def checksum(values: list[int]) -> int:
    result = 0
    for value in values:
        result ^= value
    return result & 0xFF

def make_frame(command: int, address: int, data: int) -> bytes:
    body = [
        SOF_REQ,
        command,
        (address >> 8) & 0xFF,
        address & 0xFF,
        (data >> 24) & 0xFF,
        (data >> 16) & 0xFF,
        (data >> 8) & 0xFF,
        data & 0xFF,
    ]
    return bytes(body + [checksum(body)])

def decode_response(frame: bytes):
    if len(frame) != 9:
        return None

    if frame[0] != SOF_RSP:
        return None

    if checksum(list(frame[:8])) != frame[8]:
        return None

    command = frame[1]
    address = (frame[2] << 8) | frame[3]
    data = (
        (frame[4] << 24) |
        (frame[5] << 16) |
        (frame[6] << 8) |
        frame[7]
    )

    return command, address, data

def transact(
    uart: serial.Serial,
    title: str,
    command: int,
    address: int,
    data: int,
    expected_data: int,
) -> bool:
    request = make_frame(command, address, data)

    uart.reset_input_buffer()
    uart.write(request)
    uart.flush()

    response = uart.read(9)
    decoded = decode_response(response)

    passed = (
        decoded is not None and
        decoded[0] == command and
        decoded[1] == address and
        decoded[2] == expected_data
    )

    print(f"{'PASS' if passed else 'FAIL'} {title}")
    print("  TX:", " ".join(f"{byte:02X}" for byte in request))
    print(
        "  RX:",
        " ".join(f"{byte:02X}" for byte in response)
        if response else "TIMEOUT"
    )

    return passed

parser = argparse.ArgumentParser(
    description="DPDnano-Lite HW006 - Input Memory"
)
parser.add_argument("--port", required=True)
parser.add_argument(
    "--random",
    type=int,
    default=32,
    help="Quantidade de endereços aleatórios adicionais",
)
args = parser.parse_args()

tests: list[bool] = []

patterns = {
    0x0000: 0x00000000,
    0x0001: 0x55555555,
    0x0002: 0xAAAAAAAA,
    0x0003: 0xFFFFFFFF,
    0x007F: 0x12345678,
    0x0080: 0x89ABCDEF,
    0x00FE: 0x7FFF8000,
    0x00FF: 0x80007FFF,
}

random.seed(32)
for _ in range(args.random):
    address = random.randrange(0x0000, 0x0100)
    value = random.randrange(0x00000000, 0x100000000)
    patterns[address] = value

with serial.Serial(
    args.port,
    115200,
    timeout=1.0,
    write_timeout=1.0,
) as uart:
    time.sleep(0.1)

    print("DPDnano-Lite HW006 - Input Memory")
    print(f"Porta: {args.port}")
    print("Baud : 115200")
    print(f"Palavras testadas: {len(patterns)}")
    print()

    tests.append(transact(
        uart,
        "PING",
        CMD_PING,
        0x0000,
        0x00000000,
        0x00000000,
    ))

    tests.append(transact(
        uart,
        "VERSION",
        CMD_VERSION,
        0x0000,
        0x00000000,
        0x00000302,
    ))

    for address, value in sorted(patterns.items()):
        tests.append(transact(
            uart,
            f"WRITE M[{address:04X}]",
            CMD_WRITE,
            address,
            value,
            0x00000000,
        ))

    for address, value in sorted(patterns.items()):
        tests.append(transact(
            uart,
            f"READ M[{address:04X}]",
            CMD_READ,
            address,
            0x00000000,
            value,
        ))

    tests.append(transact(
        uart,
        "INVALID ADDRESS",
        CMD_READ,
        0x0100,
        0x00000000,
        ERR_ADDR,
    ))

print()

if all(tests):
    print("RESULTADO: PASS - memória de entrada validada")
else:
    failures = len([result for result in tests if not result])
    print(f"RESULTADO: FAIL - {failures} falha(s)")
    raise SystemExit(1)
