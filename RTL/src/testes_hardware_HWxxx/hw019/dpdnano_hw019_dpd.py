#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import math
import time
from pathlib import Path

import serial

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


def derivative_central(x_prev: float, y_prev: float, x_next: float, y_next: float) -> float:
    delta_x = x_next - x_prev
    if delta_x == 0:
        raise RuntimeError("Dois pontos possuem a mesma entrada.")
    return (y_next - y_prev) / delta_x


parser = argparse.ArgumentParser(
    description="HW019_dpd - adquire nova curva na FPGA e calcula o ganho incremental."
)
parser.add_argument("--port", required=True)
parser.add_argument("--points", type=int, default=256)
parser.add_argument("--max-amplitude", type=int, default=30000)
parser.add_argument("--output-dir", default=".")
args = parser.parse_args()

output_dir = Path(args.output_dir)
output_dir.mkdir(parents=True, exist_ok=True)

base_csv_path = output_dir / "hw019_dpd_compression_base.csv"
incremental_csv_path = output_dir / "hw019_dpd_incremental_gain.csv"

vectors = [round(index * args.max_amplitude / (args.points - 1)) for index in range(args.points)]
base_rows = []

with serial.Serial(args.port, 115200, timeout=2, write_timeout=1) as uart:
    time.sleep(0.1)

    print("DPDnano-Lite HW019_dpd - Ganho Incremental")
    print("Porta                   :", args.port)
    print("Base AM/AM medida       : nova aquisicao na FPGA")
    print("coef1 = 0x7333 (~ +0,90)")
    print("coef3 = 0xA667 (~ -0,70)")
    print()

    if transact(uart, CMD_PING, 0, 0) != (CMD_PING, 0, 0):
        raise RuntimeError("Falha no PING")

    for index, sample in enumerate(vectors):
        if transact(uart, CMD_WRITE_IN, index, pack(sample)) != (CMD_WRITE_IN, index, 0):
            raise RuntimeError(f"Falha ao escrever {index}")

    if transact(uart, CMD_START_DPD, 0, len(vectors)) != (CMD_START_DPD, 0, len(vectors)):
        raise RuntimeError("Falha no START_DPD")

    overflow = wait_done(uart)

    small_signal_gain = None
    p1db_input = None
    p1db_output = None
    descending_points = 0
    previous_output = -1

    for index, sample in enumerate(vectors):
        command, address, word = transact(uart, CMD_READ_OUT, index, 0)
        if command != CMD_READ_OUT or address != index:
            raise RuntimeError(f"Leitura invalida em {index}")

        out_i, out_q = unpack(word)
        gain = (out_i / sample) if sample else 0.0

        if small_signal_gain is None and sample >= 1000 and out_i > 0:
            small_signal_gain = gain

        compression_db = 0.0
        if small_signal_gain and gain > 0:
            compression_db = 20.0 * math.log10(gain / small_signal_gain)
            if p1db_input is None and compression_db <= -1.0:
                p1db_input = sample
                p1db_output = out_i

        if out_i < previous_output:
            descending_points += 1
        previous_output = out_i

        base_rows.append(
            {
                "index": index,
                "input_i": sample,
                "output_i": out_i,
                "output_q": out_q,
                "gain_linear": gain,
                "gain_db": 20.0 * math.log10(gain) if gain > 0 else float("-inf"),
                "compression_db": compression_db,
            }
        )

        print(
            f"[{index:03d}] IN={sample:6d} OUT={out_i:6d} "
            f"GAIN={gain:8.5f} COMP={compression_db:8.4f} dB"
        )

with base_csv_path.open("w", newline="", encoding="utf-8") as csv_file:
    writer = csv.DictWriter(csv_file, fieldnames=list(base_rows[0].keys()))
    writer.writeheader()
    writer.writerows(base_rows)

incremental_rows = []
for index, row in enumerate(base_rows):
    if index == 0:
        delta_x = base_rows[1]["input_i"] - base_rows[0]["input_i"]
        incremental_gain = (base_rows[1]["output_i"] - base_rows[0]["output_i"]) / delta_x
    elif index == len(base_rows) - 1:
        delta_x = base_rows[-1]["input_i"] - base_rows[-2]["input_i"]
        incremental_gain = (base_rows[-1]["output_i"] - base_rows[-2]["output_i"]) / delta_x
    else:
        incremental_gain = derivative_central(
            base_rows[index - 1]["input_i"],
            base_rows[index - 1]["output_i"],
            base_rows[index + 1]["input_i"],
            base_rows[index + 1]["output_i"],
        )

    incremental_rows.append(
        {
            "index": int(row["index"]),
            "input_i": row["input_i"],
            "output_i": row["output_i"],
            "static_gain": row["gain_linear"],
            "compression_db": row["compression_db"],
            "incremental_gain": incremental_gain,
        }
    )

with incremental_csv_path.open("w", newline="", encoding="utf-8") as csv_file:
    writer = csv.DictWriter(csv_file, fieldnames=list(incremental_rows[0].keys()))
    writer.writeheader()
    writer.writerows(incremental_rows)

zero_crossing_input = None
for previous, current in zip(incremental_rows, incremental_rows[1:]):
    previous_gain = previous["incremental_gain"]
    current_gain = current["incremental_gain"]
    if zero_crossing_input is None and previous_gain > 0 and current_gain <= 0:
        zero_crossing_input = current["input_i"]

peak_row = max(incremental_rows, key=lambda row: row["output_i"])
peak_output_input = peak_row["input_i"]
peak_output_value = peak_row["output_i"]
minimum_incremental_gain = min(row["incremental_gain"] for row in incremental_rows)
maximum_incremental_gain = max(row["incremental_gain"] for row in incremental_rows)
negative_gain_points = sum(1 for row in incremental_rows if row["incremental_gain"] < 0)

delta_zero_to_peak = None
if zero_crossing_input is not None:
    delta_zero_to_peak = abs(zero_crossing_input - peak_output_input)

passed = (
    not overflow
    and small_signal_gain is not None
    and p1db_input is not None
    and zero_crossing_input is not None
    and negative_gain_points > 0
    and delta_zero_to_peak is not None
    and delta_zero_to_peak <= 300
)

print()
print("==============================================")
print("HW019_dpd - RESUMO")
print("==============================================")
print(f"Overflow visto            : {'SIM' if overflow else 'NAO'}")
print(f"Ganho de pequeno sinal    : {small_signal_gain:.6f}")
print(f"Ponto de compressao 1 dB  : {p1db_input}")
print(f"Saida no ponto de 1 dB    : {p1db_output}")
print(f"Pontos em descida         : {descending_points}")
print(f"CSV base medido           : {base_csv_path.resolve()}")
print(f"CSV ganho incremental     : {incremental_csv_path.resolve()}")
print(f"Ganho incremental maximo  : {maximum_incremental_gain:.6f}")
print(f"Ganho incremental minimo  : {minimum_incremental_gain:.6f}")
print(f"Cruzamento por zero       : {zero_crossing_input}")
print(f"Entrada no pico de saida  : {peak_output_input}")
print(f"Valor maximo de saida     : {peak_output_value}")
print(f"Pontos com ganho negativo : {negative_gain_points}")
print(f"Diferenca zero/pico       : {delta_zero_to_peak}")
print("==============================================")

if passed:
    print("RESULTADO: PASS - aquisicao real e ganho incremental caracterizados")
else:
    print("RESULTADO: FAIL")
    raise SystemExit(1)
