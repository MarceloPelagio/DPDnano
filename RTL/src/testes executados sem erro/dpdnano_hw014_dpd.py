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

PHASES_DEG = [0, 45, 90, 135, 180, -135, -90, -45]


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
        raise RuntimeError("SOF de resposta inválido")

    if checksum(response[:8]) != response[8]:
        raise RuntimeError("Checksum de resposta inválido")

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


def wrap_phase_deg(value):
    while value > 180.0:
        value -= 360.0

    while value <= -180.0:
        value += 360.0

    return value


def wait_done(uart, timeout_s=3.0):
    deadline = time.time() + timeout_s

    while time.time() < deadline:
        _, _, status = transact(
            uart,
            CMD_STATUS,
            0,
            0,
        )

        busy = status & 0x01
        error = (status >> 2) & 0x01
        overflow = (status >> 3) & 0x01

        if error:
            raise RuntimeError(
                "Controlador DPD sinalizou erro"
            )

        if not busy:
            return overflow

        time.sleep(0.005)

    raise RuntimeError(
        "Timeout esperando processamento DPD"
    )


def build_vectors(amplitude_points, max_amplitude):
    vectors = []

    for amplitude_index in range(amplitude_points):
        amplitude = round(
            (amplitude_index + 1)
            * max_amplitude
            / amplitude_points
        )

        for phase_deg in PHASES_DEG:
            phase_rad = math.radians(phase_deg)

            input_i = round(
                amplitude * math.cos(phase_rad)
            )

            input_q = round(
                amplitude * math.sin(phase_rad)
            )

            vectors.append({
                "requested_amplitude": amplitude,
                "requested_phase_deg": phase_deg,
                "input_i": input_i,
                "input_q": input_q,
            })

    return vectors


parser = argparse.ArgumentParser(
    description=(
        "DPDnano-Lite HW014_dpd - "
        "Complex response and AM/PM"
    )
)

parser.add_argument("--port", required=True)

parser.add_argument(
    "--amplitude-points",
    type=int,
    default=32,
)

parser.add_argument(
    "--max-amplitude",
    type=int,
    default=28000,
)

parser.add_argument(
    "--csv",
    default="hw014_dpd_am_pm_complex.csv",
)

args = parser.parse_args()

if not 2 <= args.amplitude_points <= 32:
    raise SystemExit(
        "--amplitude-points deve estar entre 2 e 32"
    )

if not 1000 <= args.max_amplitude <= 30000:
    raise SystemExit(
        "--max-amplitude deve estar entre 1000 e 30000"
    )

vectors = build_vectors(
    args.amplitude_points,
    args.max_amplitude,
)

rows = []

with serial.Serial(
    args.port,
    115200,
    timeout=2.0,
    write_timeout=1.0,
) as uart:
    time.sleep(0.1)

    print("DPDnano-Lite HW014_dpd - Validação da Resposta Complexa")
    print(f"Porta              : {args.port}")
    print(f"Total de vetores   : {len(vectors)}")
    print(f"Fases por amplitude: {len(PHASES_DEG)}")
    print(f"Amplitude máxima   : {args.max_amplitude}")
    print("coef1              : 0x3333 + j0x0000")
    print("coef3              : 0x4666 + j0x199A")
    print()

    if transact(
        uart,
        CMD_PING,
        0,
        0,
    ) != (CMD_PING, 0, 0):
        raise RuntimeError("Falha no PING")

    for index, vector in enumerate(vectors):
        response = transact(
            uart,
            CMD_WRITE_IN,
            index,
            pack_iq(
                vector["input_i"],
                vector["input_q"],
            ),
        )

        if response != (
            CMD_WRITE_IN,
            index,
            0,
        ):
            raise RuntimeError(
                f"Falha ao escrever vetor {index}"
            )

    if transact(
        uart,
        CMD_START_DPD,
        0,
        len(vectors),
    ) != (
        CMD_START_DPD,
        0,
        len(vectors),
    ):
        raise RuntimeError(
            "Falha no START_DPD"
        )

    overflow_seen = wait_done(uart)

    max_abs_phase_error_between_angles = 0.0

    for index, vector in enumerate(vectors):
        command, address, word = transact(
            uart,
            CMD_READ_OUT,
            index,
            0,
        )

        if (
            command != CMD_READ_OUT
            or address != index
        ):
            raise RuntimeError(
                f"Resposta inválida no endereço {index}"
            )

        output_i, output_q = unpack_iq(word)

        input_magnitude = math.hypot(
            vector["input_i"],
            vector["input_q"],
        )

        output_magnitude = math.hypot(
            output_i,
            output_q,
        )

        input_phase_deg = math.degrees(
            math.atan2(
                vector["input_q"],
                vector["input_i"],
            )
        )

        output_phase_deg = math.degrees(
            math.atan2(
                output_q,
                output_i,
            )
        )

        phase_shift_deg = wrap_phase_deg(
            output_phase_deg
            - input_phase_deg
        )

        gain = (
            output_magnitude / input_magnitude
            if input_magnitude > 0
            else 0.0
        )

        rows.append({
            "index": index,
            "requested_amplitude": vector[
                "requested_amplitude"
            ],
            "requested_phase_deg": vector[
                "requested_phase_deg"
            ],
            "input_i": vector["input_i"],
            "input_q": vector["input_q"],
            "input_magnitude": input_magnitude,
            "input_phase_deg": input_phase_deg,
            "output_i": output_i,
            "output_q": output_q,
            "output_magnitude": output_magnitude,
            "output_phase_deg": output_phase_deg,
            "phase_shift_deg": phase_shift_deg,
            "gain": gain,
        })

        print(
            f"[{index:03d}] "
            f"|IN|={input_magnitude:9.3f} "
            f"PH_IN={input_phase_deg:8.3f}° "
            f"|OUT|={output_magnitude:9.3f} "
            f"PH_OUT={output_phase_deg:8.3f}° "
            f"DELTA={phase_shift_deg:8.3f}°"
        )

csv_path = Path(args.csv)

with csv_path.open(
    "w",
    newline="",
    encoding="utf-8",
) as csv_file:
    writer = csv.DictWriter(
        csv_file,
        fieldnames=list(rows[0].keys()),
    )

    writer.writeheader()
    writer.writerows(rows)

phase_by_amplitude = {}

for row in rows:
    amplitude = row["requested_amplitude"]

    phase_by_amplitude.setdefault(
        amplitude,
        [],
    ).append(
        float(row["phase_shift_deg"])
    )

phase_spread_max = 0.0

for values in phase_by_amplitude.values():
    spread = max(values) - min(values)

    if spread > phase_spread_max:
        phase_spread_max = spread

minimum_phase_shift = min(
    float(row["phase_shift_deg"])
    for row in rows
)

maximum_phase_shift = max(
    float(row["phase_shift_deg"])
    for row in rows
)

print()
print("================================================")
print("HW014_dpd - RESUMO")
print("================================================")
print(f"Vetores processados       : {len(rows)}")
print(f"Overflow visto            : {'SIM' if overflow_seen else 'NÃO'}")
print(f"Desvio de fase mínimo     : {minimum_phase_shift:.6f}°")
print(f"Desvio de fase máximo     : {maximum_phase_shift:.6f}°")
print(f"Variação entre quadrantes : {phase_spread_max:.6f}°")
print(f"Arquivo CSV               : {csv_path.resolve()}")
print("================================================")

MAX_PHASE_SPREAD_DEG = 0.50

passed = (
    not overflow_seen
    and maximum_phase_shift > minimum_phase_shift
    and phase_spread_max <= MAX_PHASE_SPREAD_DEG
)

if passed:
    print(
        "RESULTADO: PASS - HW014_dpd - Multiplicação Complexa validada"
    )
    print(f"Limite entre quadrantes  : {MAX_PHASE_SPREAD_DEG:.3f}°")
else:
    print(
        "RESULTADO: FAIL - comportamento complexo inesperado"
    )
    print(f"Limite entre quadrantes  : {MAX_PHASE_SPREAD_DEG:.3f}°")

    raise SystemExit(1)
