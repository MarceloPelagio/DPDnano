#!/usr/bin/env python3
from __future__ import annotations

import argparse
import serial
import time

SOF_REQ = 0xA5
SOF_RSP = 0x5A

CMD_PING = 0x01
CMD_WRITE_IN = 0x20
CMD_READ_OUT = 0x31
CMD_START_DPD = 0x40
CMD_STATUS = 0x41

COEF1_RE = 0x6000
COEF3_RE = 0x1000

def checksum(values):
    result = 0
    for value in values:
        result ^= value
    return result & 0xFF

def make_frame(command, address, data):
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

def transact(uart, command, address, data):
    uart.reset_input_buffer()
    uart.write(make_frame(command, address, data))
    uart.flush()
    response = uart.read(9)

    if (
        len(response) != 9
        or response[0] != SOF_RSP
        or checksum(response[:8]) != response[8]
    ):
        raise RuntimeError(
            "Resposta inválida: "
            + (
                " ".join(f"{value:02X}" for value in response)
                if response
                else "TIMEOUT"
            )
        )

    response_command = response[1]
    response_address = (response[2] << 8) | response[3]
    response_data = (
        (response[4] << 24)
        | (response[5] << 16)
        | (response[6] << 8)
        | response[7]
    )

    return response_command, response_address, response_data

def signed_16(value):
    value &= 0xFFFF
    return value - 0x10000 if value & 0x8000 else value

def saturate_16(value):
    if value > 32767:
        return 32767
    if value < -32768:
        return -32768
    return value

def arithmetic_shift(value, amount):
    return value >> amount

def model_component(x_value, y_value):
    """
    Fixed-point reference for real coefficients only.

    Input:
      x/y integer representation of Q1.15.

    Linear branch:
      x * coef1 -> Q2.30.

    Cubic branch:
      mag2 = x^2 + y^2 -> Q3.30.
      term = x * mag2 -> Q4.45.
      term * coef3 -> Q?.60.
      shift by 30 -> branch Q?.30.

    Accumulator remains in Q?.30 and is converted to Q1.15
    by an arithmetic shift of 15 bits.

    A small tolerance is retained because the frozen RTL rounding stage
    may apply a one-LSB correction at negative values.
    """
    magnitude_squared = x_value * x_value + y_value * y_value

    linear = x_value * COEF1_RE
    cubic_term = x_value * magnitude_squared
    cubic = arithmetic_shift(cubic_term * COEF3_RE, 30)

    accumulator = linear + cubic
    output = arithmetic_shift(accumulator, 15)

    return saturate_16(output)

def reference_dpd(i_value, q_value):
    return (
        model_component(i_value, q_value),
        model_component(q_value, i_value),
    )

def pack_iq(i_value, q_value):
    return ((i_value & 0xFFFF) << 16) | (q_value & 0xFFFF)

def unpack_iq(word):
    return signed_16(word >> 16), signed_16(word)

vectors = [
    (0, 0),
    (100, 0),
    (-100, 0),
    (0, 100),
    (100, 100),
    (-100, 100),
    (1000, 0),
    (-1000, 0),
    (0, 1000),
    (1000, 1000),
    (-1000, 1000),
    (4000, 0),
    (0, 4000),
    (3000, 3000),
    (-3000, 3000),
    (6000, -3000),
    (-6000, 3000),
    (8000, 0),
    (0, -8000),
    (7000, 7000),
]

parser = argparse.ArgumentParser()
parser.add_argument("--port", required=True)
parser.add_argument(
    "--tolerance",
    type=int,
    default=4,
    help="Tolerância em LSB para diferenças de arredondamento",
)
args = parser.parse_args()

with serial.Serial(
    args.port,
    115200,
    timeout=2.0,
    write_timeout=1.0,
) as uart:
    time.sleep(0.1)

    print("DPDnano-Lite HW010_dpd - Cubic Model")
    print(f"Porta      : {args.port}")
    print("Baud       : 115200")
    print(f"Amostras   : {len(vectors)}")
    print("coef1      : 0x6000 = 0,75")
    print("coef3      : 0x1000 = 0,125")
    print(f"Tolerância : {args.tolerance} LSB")
    print()

    transact(uart, CMD_PING, 0, 0)

    for index, (i_value, q_value) in enumerate(vectors):
        transact(
            uart,
            CMD_WRITE_IN,
            index,
            pack_iq(i_value, q_value),
        )

    transact(
        uart,
        CMD_START_DPD,
        0,
        len(vectors),
    )

    deadline = time.time() + 2.0
    overflow = 0

    while time.time() < deadline:
        _, _, status = transact(uart, CMD_STATUS, 0, 0)

        busy = status & 0x01
        error = (status >> 2) & 0x01
        overflow = (status >> 3) & 0x01

        if error:
            raise RuntimeError("Controlador DPD sinalizou erro")

        if not busy:
            break

        time.sleep(0.01)
    else:
        raise RuntimeError("Timeout esperando término do DPD")

    failures = 0

    for index, (input_i, input_q) in enumerate(vectors):
        expected_i, expected_q = reference_dpd(input_i, input_q)

        _, _, output_word = transact(
            uart,
            CMD_READ_OUT,
            index,
            0,
        )

        actual_i, actual_q = unpack_iq(output_word)

        error_i = actual_i - expected_i
        error_q = actual_q - expected_q

        passed = (
            abs(error_i) <= args.tolerance
            and abs(error_q) <= args.tolerance
        )

        print(
            f"{'PASS' if passed else 'FAIL'} [{index:02d}] "
            f"IN=({input_i:6d},{input_q:6d}) "
            f"REF=({expected_i:6d},{expected_q:6d}) "
            f"FPGA=({actual_i:6d},{actual_q:6d}) "
            f"ERR=({error_i:+d},{error_q:+d})"
        )

        if not passed:
            failures += 1

    print()
    print(f"Overflow visto: {'SIM' if overflow else 'NÃO'}")

    if failures == 0:
        print(
            "RESULTADO: PASS - ramo cúbico e modelo Python validados"
        )
    else:
        print(
            f"RESULTADO: FAIL - {failures} amostra(s) divergente(s)"
        )
        raise SystemExit(1)
