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
CMD_COEFS = 0x43

COEF1_VALUES = [0.68, 0.69, 0.70, 0.71, 0.72]
COEF3_VALUES = [0.18, 0.19, 0.20, 0.21, 0.22]
NOMINAL_COEF1_INDEX = 2
NOMINAL_COEF3_INDEX = 2


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
    if len(response) != 9:
        raise RuntimeError("Resposta incompleta ou timeout")
    if response[0] != SOF_RSP:
        raise RuntimeError("SOF invalido")
    if checksum(response[:8]) != response[8]:
        raise RuntimeError("Checksum invalido")
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
        busy = status & 1
        error = (status >> 2) & 1
        overflow = (status >> 3) & 1
        coef1_index = (status >> 4) & 0x7
        coef3_index = (status >> 7) & 0x7
        if error:
            raise RuntimeError("Erro DPD")
        if not busy:
            return overflow, coef1_index, coef3_index
        time.sleep(0.005)
    raise RuntimeError("Timeout esperando DPD")


def find_small_signal_gain(rows):
    for row in rows:
        if row["input_i"] >= 1000 and row["output_i"] > 0:
            return row["gain_linear"]
    return None


parser = argparse.ArgumentParser()
parser.add_argument("--port", required=True)
parser.add_argument("--points", type=int, default=128)
parser.add_argument("--max-amplitude", type=int, default=30000)
parser.add_argument("--output-dir", default=".")
args = parser.parse_args()

if not 32 <= args.points <= 256:
    raise SystemExit("--points deve estar entre 32 e 256")

output_dir = Path(args.output_dir)
output_dir.mkdir(parents=True, exist_ok=True)
vectors = [round(index * args.max_amplitude / (args.points - 1)) for index in range(args.points)]

summary_rows = []
all_curve_rows = []

with serial.Serial(args.port, 115200, timeout=2, write_timeout=1) as uart:
    time.sleep(0.1)
    print("DPDnano-Lite HW021_dpd - Sensibilidade aos Coeficientes")
    print(f"Porta                : {args.port}")
    print(f"Pontos por curva     : {args.points}")
    print(f"Amostras por familia : {args.points * 5}")
    print("Familia coef1        : coef3 fixo em 0x199A (+0,20)")
    print("Familia coef3        : coef1 fixo em 0x599A (+0,70)")
    print()

    if transact(uart, CMD_PING, 0, 0) != (CMD_PING, 0, 0):
        raise RuntimeError("Falha no PING")

    families = [
        ("coef1", [(coef1_index, NOMINAL_COEF3_INDEX) for coef1_index in range(len(COEF1_VALUES))]),
        ("coef3", [(NOMINAL_COEF1_INDEX, coef3_index) for coef3_index in range(len(COEF3_VALUES))]),
    ]

    for family_name, combinations in families:
        for coef1_index, coef3_index in combinations:
            command, address, _ = transact(uart, CMD_COEFS, 0, (coef3_index << 4) | coef1_index)
            if command != CMD_COEFS or address != 0:
                raise RuntimeError("Falha ao selecionar coeficientes")

            coef1_value = COEF1_VALUES[coef1_index]
            coef3_value = COEF3_VALUES[coef3_index]

            for sample_index, input_value in enumerate(vectors):
                if transact(uart, CMD_WRITE_IN, sample_index, pack(input_value)) != (CMD_WRITE_IN, sample_index, 0):
                    raise RuntimeError(f"Falha ao escrever {sample_index}")

            if transact(uart, CMD_START_DPD, 0, len(vectors)) != (CMD_START_DPD, 0, len(vectors)):
                raise RuntimeError("Falha no START_DPD")

            overflow, active_coef1_index, active_coef3_index = wait_done(uart)
            if active_coef1_index != coef1_index or active_coef3_index != coef3_index:
                raise RuntimeError("Indices ativos divergentes")

            rows = []
            for sample_index, input_value in enumerate(vectors):
                command, address, word = transact(uart, CMD_READ_OUT, sample_index, 0)
                if command != CMD_READ_OUT or address != sample_index:
                    raise RuntimeError(f"Leitura invalida {sample_index}")

                output_i, output_q = unpack(word)
                gain = (output_i / input_value) if input_value else 0.0
                delta_from_nominal = None

                row = {
                    "family": family_name,
                    "coef1_index": coef1_index,
                    "coef3_index": coef3_index,
                    "coef1": coef1_value,
                    "coef3": coef3_value,
                    "index": sample_index,
                    "input_i": input_value,
                    "output_i": output_i,
                    "output_q": output_q,
                    "gain_linear": gain,
                    "overflow": int(overflow),
                    "delta_from_nominal": delta_from_nominal,
                }
                rows.append(row)

            summary_rows.append(
                {
                    "family": family_name,
                    "coef1_index": coef1_index,
                    "coef3_index": coef3_index,
                    "coef1": coef1_value,
                    "coef3": coef3_value,
                    "overflow": int(overflow),
                    "small_signal_gain": find_small_signal_gain(rows),
                    "peak_output": max(row["output_i"] for row in rows),
                    "final_output": rows[-1]["output_i"],
                }
            )

            all_curve_rows.extend(rows)

            print(
                f"familia={family_name:5s} coef1={coef1_value:+.2f} coef3={coef3_value:+.2f} "
                f"OVF={'SIM' if overflow else 'NAO'} peak={max(row['output_i'] for row in rows):6d}"
            )

nominal_curve = None
for key_row in summary_rows:
    if key_row["coef1_index"] == NOMINAL_COEF1_INDEX and key_row["coef3_index"] == NOMINAL_COEF3_INDEX:
        nominal_curve = [
            row for row in all_curve_rows
            if row["coef1_index"] == NOMINAL_COEF1_INDEX and row["coef3_index"] == NOMINAL_COEF3_INDEX
        ]
        break

if nominal_curve is None:
    raise RuntimeError("Curva nominal nao encontrada")

nominal_by_input = {row["input_i"]: row["output_i"] for row in nominal_curve}
for row in all_curve_rows:
    row["delta_from_nominal"] = row["output_i"] - nominal_by_input[row["input_i"]]

summary_csv_path = output_dir / "hw021_dpd_sensitivity_summary.csv"
with summary_csv_path.open("w", newline="", encoding="utf-8") as csv_file:
    writer = csv.DictWriter(csv_file, fieldnames=list(summary_rows[0].keys()))
    writer.writeheader()
    writer.writerows(summary_rows)

curves_csv_path = output_dir / "hw021_dpd_sensitivity_curves.csv"
with curves_csv_path.open("w", newline="", encoding="utf-8") as csv_file:
    writer = csv.DictWriter(csv_file, fieldnames=list(all_curve_rows[0].keys()))
    writer.writeheader()
    writer.writerows(all_curve_rows)

overflow_count = sum(row["overflow"] for row in summary_rows)
print()
print("==============================================")
print("HW021_dpd - RESUMO")
print("==============================================")
print(f"Curvas avaliadas       : {len(summary_rows)}")
print(f"Overflow observado     : {overflow_count}")
print(f"Resumo CSV             : {summary_csv_path.resolve()}")
print(f"Curvas CSV             : {curves_csv_path.resolve()}")
print("==============================================")
print("RESULTADO: PASS - sensibilidade local aos coeficientes caracterizada")
