#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import serial
import time
from pathlib import Path

SOF_REQ = 0xA5
SOF_RSP = 0x5A

CMD_PING = 0x01
CMD_WRITE_IN = 0x20
CMD_READ_OUT = 0x31
CMD_START_DPD = 0x40
CMD_STATUS = 0x41


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

    if len(response) != 9:
        raise RuntimeError("Resposta incompleta ou timeout")
    if response[0] != SOF_RSP:
        raise RuntimeError("SOF de resposta invalido")
    if checksum(response[:8]) != response[8]:
        raise RuntimeError("Checksum de resposta invalido")

    return (
        response[1],
        (response[2] << 8) | response[3],
        (response[4] << 24)
        | (response[5] << 16)
        | (response[6] << 8)
        | response[7],
    )


def signed_16(value):
    value &= 0xFFFF
    return value - 0x10000 if value & 0x8000 else value


def pack_iq(i_value, q_value):
    return ((i_value & 0xFFFF) << 16) | (q_value & 0xFFFF)


def unpack_iq(word):
    return signed_16(word >> 16), signed_16(word)


def wait_done(uart, timeout_s=3.0):
    deadline = time.time() + timeout_s

    while time.time() < deadline:
        _, _, status = transact(uart, CMD_STATUS, 0, 0)
        busy = status & 0x01
        error = (status >> 2) & 0x01
        overflow = (status >> 3) & 0x01

        if error:
            raise RuntimeError("Controlador DPD sinalizou erro")

        if not busy:
            return overflow

        time.sleep(0.005)

    raise RuntimeError("Timeout esperando processamento DPD")


parser = argparse.ArgumentParser(
    description="DPDnano-Lite HW013_dpd - Saturacao e Overflow"
)
parser.add_argument("--port", required=True)
parser.add_argument("--points", type=int, default=256)
parser.add_argument("--max-amplitude", type=int, default=32767)
parser.add_argument(
    "--csv",
    default="hw013_dpd_saturation_overflow.csv",
)
args = parser.parse_args()

if not 8 <= args.points <= 256:
    raise SystemExit("--points deve estar entre 8 e 256")
if not 1000 <= args.max_amplitude <= 32767:
    raise SystemExit("--max-amplitude deve estar entre 1000 e 32767")

vectors = []
for index in range(args.points):
    amplitude = round(
        -args.max_amplitude
        + (2 * args.max_amplitude * index / (args.points - 1))
    )
    vectors.append((amplitude, 0))

rows = []

with serial.Serial(
    args.port,
    115200,
    timeout=2.0,
    write_timeout=1.0,
) as uart:
    time.sleep(0.1)

    print("DPDnano-Lite HW013_dpd - Saturacao e Overflow")
    print(f"Porta             : {args.port}")
    print(f"Pontos            : {args.points}")
    print(f"Amplitude maxima  : {args.max_amplitude}")
    print("coef1             : 0x3333 = 0,40")
    print("coef3             : 0x5333 = 0,65")
    print()

    if transact(uart, CMD_PING, 0, 0) != (CMD_PING, 0, 0):
        raise RuntimeError("Falha no PING")

    for index, (input_i, input_q) in enumerate(vectors):
        response = transact(
            uart,
            CMD_WRITE_IN,
            index,
            pack_iq(input_i, input_q),
        )
        if response != (CMD_WRITE_IN, index, 0):
            raise RuntimeError(f"Falha ao escrever vetor {index}")

    if transact(uart, CMD_START_DPD, 0, len(vectors)) != (
        CMD_START_DPD,
        0,
        len(vectors),
    ):
        raise RuntimeError("Falha no START_DPD")

    overflow_seen = wait_done(uart)

    saturation_count = 0

    for index, (input_i, input_q) in enumerate(vectors):
        command, address, word = transact(uart, CMD_READ_OUT, index, 0)
        if command != CMD_READ_OUT or address != index:
            raise RuntimeError(f"Resposta invalida no endereco {index}")

        output_i, output_q = unpack_iq(word)
        saturated = abs(output_i) >= 32767 or abs(output_q) >= 32768
        if saturated:
            saturation_count += 1

        rows.append(
            {
                "index": index,
                "input_i": input_i,
                "input_q": input_q,
                "output_i": output_i,
                "output_q": output_q,
                "saturated": int(saturated),
            }
        )

        print(
            f"[{index:03d}] IN=({input_i:6d},{input_q:6d}) "
            f"OUT=({output_i:6d},{output_q:6d}) "
            f"SAT={'SIM' if saturated else 'NAO'}"
        )

csv_path = Path(args.csv)
with csv_path.open("w", newline="", encoding="utf-8") as csv_file:
    writer = csv.DictWriter(csv_file, fieldnames=list(rows[0].keys()))
    writer.writeheader()
    writer.writerows(rows)

max_output = max(row["output_i"] for row in rows)
min_output = min(row["output_i"] for row in rows)

print()
print("==============================================")
print("HW013_dpd - RESUMO")
print("==============================================")
print(f"Pontos processados      : {len(rows)}")
print(f"Overflow visto          : {'SIM' if overflow_seen else 'NAO'}")
print(f"Amostras saturadas      : {saturation_count}")
print(f"Maior saida I observada : {max_output}")
print(f"Menor saida I observada : {min_output}")
print(f"Arquivo CSV             : {csv_path.resolve()}")
print("==============================================")

if overflow_seen and saturation_count > 0:
    print("RESULTADO: PASS - saturacao e overflow validados")
else:
    print("RESULTADO: FAIL - saturacao/overflow nao confirmados")
    raise SystemExit(1)
