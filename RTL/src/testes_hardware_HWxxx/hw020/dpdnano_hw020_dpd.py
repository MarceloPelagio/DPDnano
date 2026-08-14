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

COEF1_VALUES = [0.40, 0.55, 0.70, 0.85, 1.00]
COEF3_VALUES = [-0.70, -0.35, 0.00, 0.35, 0.70]


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


def classify(overflow, saturation_input, p1db_input, peak_input, last_output, first_gain, last_gain):
    if overflow:
        return "OVERFLOW"
    if saturation_input is not None:
        return "SATURADO"
    if p1db_input is not None:
        return "COMPRESSIVO"
    if last_gain > first_gain + 0.02:
        return "EXPANSIVO"
    if peak_input is not None and peak_input < 29000 and last_output < 0:
        return "NAO MONOTONICO"
    return "SEGURO"


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
    print("DPDnano-Lite HW020_dpd - Janela Operacional de Coeficientes")
    print(f"Porta                : {args.port}")
    print(f"Combinacoes          : {len(COEF1_VALUES) * len(COEF3_VALUES)}")
    print(f"Pontos por curva     : {args.points}")
    print(f"Amostras totais      : {args.points * len(COEF1_VALUES) * len(COEF3_VALUES)}")
    print("Varredura de coef1   : 0x3333 (0,40) ate 0x7FFF (1,00)")
    print("Varredura de coef3   : 0xA667 (-0,70) ate 0x599A (+0,70)")
    print()

    if transact(uart, CMD_PING, 0, 0) != (CMD_PING, 0, 0):
        raise RuntimeError("Falha no PING")

    for coef1_index, coef1_value in enumerate(COEF1_VALUES):
        for coef3_index, coef3_value in enumerate(COEF3_VALUES):
            data = (coef3_index << 4) | coef1_index
            command, address, _ = transact(uart, CMD_COEFS, 0, data)
            if command != CMD_COEFS or address != 0:
                raise RuntimeError("Falha ao selecionar coeficientes")

            for sample_index, input_value in enumerate(vectors):
                if transact(uart, CMD_WRITE_IN, sample_index, pack(input_value)) != (CMD_WRITE_IN, sample_index, 0):
                    raise RuntimeError(f"Falha ao escrever {sample_index}")

            if transact(uart, CMD_START_DPD, 0, len(vectors)) != (CMD_START_DPD, 0, len(vectors)):
                raise RuntimeError("Falha no START_DPD")

            overflow, active_coef1_index, active_coef3_index = wait_done(uart)
            if active_coef1_index != coef1_index or active_coef3_index != coef3_index:
                raise RuntimeError("Indices ativos divergentes")

            curve_rows = []
            small_signal_gain = None
            p1db_input = None
            saturation_input = None

            for sample_index, input_value in enumerate(vectors):
                command, address, word = transact(uart, CMD_READ_OUT, sample_index, 0)
                if command != CMD_READ_OUT or address != sample_index:
                    raise RuntimeError(f"Leitura invalida {sample_index}")

                output_i, output_q = unpack(word)
                gain = (output_i / input_value) if input_value else 0.0

                if small_signal_gain is None and input_value >= 1000 and output_i > 0:
                    small_signal_gain = gain

                compression_db = 0.0
                if small_signal_gain and gain > 0:
                    compression_db = 20 * math.log10(gain / small_signal_gain)
                    if p1db_input is None and compression_db <= -1.0:
                        p1db_input = input_value

                if saturation_input is None and output_i == 32767:
                    saturation_input = input_value

                row = {
                    "coef1_index": coef1_index,
                    "coef3_index": coef3_index,
                    "coef1": coef1_value,
                    "coef3": coef3_value,
                    "index": sample_index,
                    "input_i": input_value,
                    "output_i": output_i,
                    "output_q": output_q,
                    "gain_linear": gain,
                    "compression_db": compression_db,
                    "saturated": int(output_i == 32767),
                }
                curve_rows.append(row)
                all_curve_rows.append(row)

            peak_row = max(curve_rows, key=lambda row: row["output_i"])
            first_gain = next((row["gain_linear"] for row in curve_rows if row["input_i"] >= 1000), 0.0)
            last_gain = curve_rows[-1]["gain_linear"]

            status = classify(
                overflow,
                saturation_input,
                p1db_input,
                peak_row["input_i"],
                curve_rows[-1]["output_i"],
                first_gain,
                last_gain,
            )

            summary_rows.append(
                {
                    "coef1_index": coef1_index,
                    "coef3_index": coef3_index,
                    "coef1": coef1_value,
                    "coef3": coef3_value,
                    "status": status,
                    "overflow": int(overflow),
                    "p1db_input": p1db_input,
                    "saturation_input": saturation_input,
                    "peak_input": peak_row["input_i"],
                    "peak_output": peak_row["output_i"],
                    "final_output": curve_rows[-1]["output_i"],
                    "small_signal_gain": small_signal_gain,
                    "final_gain": last_gain,
                }
            )

            print(
                f"coef1={coef1_value:+.2f} coef3={coef3_value:+.2f} "
                f"STATUS={status:14s} P1dB={str(p1db_input):>6s} "
                f"SAT={str(saturation_input):>6s} OVF={'SIM' if overflow else 'NAO'}"
            )

summary_csv_path = output_dir / "hw020_dpd_operational_window_summary.csv"
with summary_csv_path.open("w", newline="", encoding="utf-8") as csv_file:
    writer = csv.DictWriter(csv_file, fieldnames=list(summary_rows[0].keys()))
    writer.writeheader()
    writer.writerows(summary_rows)

curves_csv_path = output_dir / "hw020_dpd_all_curves.csv"
with curves_csv_path.open("w", newline="", encoding="utf-8") as csv_file:
    writer = csv.DictWriter(csv_file, fieldnames=list(all_curve_rows[0].keys()))
    writer.writeheader()
    writer.writerows(all_curve_rows)

safe_count = sum(1 for row in summary_rows if row["status"] == "SEGURO")
compressive_count = sum(1 for row in summary_rows if row["status"] == "COMPRESSIVO")
expansive_count = sum(1 for row in summary_rows if row["status"] == "EXPANSIVO")
saturated_count = sum(1 for row in summary_rows if row["status"] == "SATURADO")
overflow_count = sum(1 for row in summary_rows if row["status"] == "OVERFLOW")

print()
print("==============================================")
print("HW020_dpd - RESUMO")
print("==============================================")
print(f"Combinacoes avaliadas : {len(summary_rows)}")
print(f"Seguras               : {safe_count}")
print(f"Compressivas          : {compressive_count}")
print(f"Expansivas            : {expansive_count}")
print(f"Saturadas             : {saturated_count}")
print(f"Com overflow          : {overflow_count}")
print(f"Resumo CSV            : {summary_csv_path.resolve()}")
print(f"Curvas CSV            : {curves_csv_path.resolve()}")
print("==============================================")
print("RESULTADO: PASS - janela operacional de coeficientes caracterizada")
