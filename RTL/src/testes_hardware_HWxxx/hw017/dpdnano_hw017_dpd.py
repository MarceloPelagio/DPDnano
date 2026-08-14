#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import math
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
POS_LIMIT = 32767


def checksum(values):
    result = 0
    for value in values:
        result ^= value
    return result & 0xFF


def frame(command, address, data):
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
    uart.write(frame(command, address, data))
    uart.flush()
    response = uart.read(9)
    if len(response) != 9 or response[0] != SOF_RSP or checksum(response[:8]) != response[8]:
        raise RuntimeError("Resposta invalida ou timeout")
    return (
        response[1],
        (response[2] << 8) | response[3],
        (response[4] << 24) | (response[5] << 16) | (response[6] << 8) | response[7],
    )


def s16(value):
    value &= 0xFFFF
    return value - 0x10000 if value & 0x8000 else value


def pack(i_value, q_value=0):
    return ((i_value & 0xFFFF) << 16) | (q_value & 0xFFFF)


def unpack(word):
    return s16(word >> 16), s16(word)


def wait_done(uart):
    deadline = time.time() + 3.0
    while time.time() < deadline:
        _, _, status = transact(uart, CMD_STATUS, 0, 0)
        if (status >> 2) & 1:
            raise RuntimeError("Erro DPD")
        if not (status & 1):
            return (status >> 3) & 1
        time.sleep(0.005)
    raise RuntimeError("Timeout esperando DPD")


parser = argparse.ArgumentParser()
parser.add_argument("--port", required=True)
parser.add_argument("--points", type=int, default=256)
parser.add_argument("--max-amplitude", type=int, default=32767)
parser.add_argument("--output-dir", default=".")
args = parser.parse_args()

output_dir = Path(args.output_dir)
output_dir.mkdir(parents=True, exist_ok=True)

vectors = [round(index * args.max_amplitude / (args.points - 1)) for index in range(args.points)]
rows = []

with serial.Serial(args.port, 115200, timeout=2, write_timeout=1) as uart:
    time.sleep(0.1)
    print("DPDnano-Lite HW017_dpd - Saturacao, Overflow e Compressao")
    print("coef1=0x6666 (0,80) | coef3=0x6666 (0,80)\n")

    transact(uart, CMD_PING, 0, 0)
    for index, sample in enumerate(vectors):
        transact(uart, CMD_WRITE_IN, index, pack(sample))
    transact(uart, CMD_START_DPD, 0, len(vectors))
    overflow = wait_done(uart)

    saturation_onset = None
    saturation_count = 0
    previous_output = -1
    monotonicity_failures = 0
    small_signal_gain = None
    p1db = None
    linear_crossing = None
    previous_delta = None

    for index, sample in enumerate(vectors):
        _, _, word = transact(uart, CMD_READ_OUT, index, 0)
        out_i, out_q = unpack(word)
        gain = out_i / sample if sample else 0.0

        if small_signal_gain is None and sample >= 1000 and out_i > 0:
            small_signal_gain = gain

        compression_db = 0.0
        if small_signal_gain and gain > 0:
            compression_db = 20.0 * math.log10(gain / small_signal_gain)
            if p1db is None and compression_db <= -1.0:
                p1db = sample

        delta_linear = out_i - sample
        if sample > 0 and linear_crossing is None and previous_delta is not None:
            if previous_delta < 0 <= delta_linear:
                linear_crossing = sample
        previous_delta = delta_linear

        saturated = out_i == POS_LIMIT
        if saturated:
            saturation_count += 1
            if saturation_onset is None:
                saturation_onset = sample

        if out_i < previous_output:
            monotonicity_failures += 1
        previous_output = out_i

        rows.append(
            {
                "index": index,
                "input_i": sample,
                "output_i": out_i,
                "output_q": out_q,
                "gain_linear": gain,
                "compression_db": compression_db,
                "delta_linear": delta_linear,
                "saturated": int(saturated),
            }
        )

        print(
            f"[{index:03d}] IN={sample:6d} OUT={out_i:6d} "
            f"GAIN={gain:8.5f} COMP={compression_db:8.4f} dB "
            f"SAT={'SIM' if saturated else 'NAO'}"
        )

csv_path = output_dir / "hw017_dpd_saturation_compression.csv"
with csv_path.open("w", newline="", encoding="utf-8") as csv_file:
    writer = csv.DictWriter(csv_file, fieldnames=list(rows[0].keys()))
    writer.writeheader()
    writer.writerows(rows)

print("\n================================================")
print("HW017_dpd - RESUMO")
print("================================================")
print(f"Overflow visto            : {'SIM' if overflow else 'NAO'}")
print(f"Cruzamento com y = x      : {linear_crossing}")
print(f"Inicio da saturacao       : {saturation_onset}")
print(f"Amostras saturadas        : {saturation_count}")
print(f"Ponto de compressao 1 dB  : {p1db}")
print(f"Falhas de monotonicidade  : {monotonicity_failures}")
print(f"Arquivo CSV               : {csv_path.resolve()}")
print("================================================")

if overflow and saturation_onset is not None and saturation_count > 0 and monotonicity_failures == 0:
    if p1db is None:
        print("RESULTADO: PASS - saturacao e overflow caracterizados; compressao de 1 dB nao observada")
    else:
        print("RESULTADO: PASS - saturacao, overflow e compressao caracterizados")
else:
    print("RESULTADO: FAIL")
    raise SystemExit(1)
