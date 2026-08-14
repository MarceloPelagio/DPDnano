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

COEF1_RE = 0x6000
COEF3_RE = 0x1000


def checksum(values) -> int:
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


def transact(
    uart: serial.Serial,
    command: int,
    address: int,
    data: int,
) -> tuple[int, int, int]:
    uart.reset_input_buffer()
    uart.write(make_frame(command, address, data))
    uart.flush()
    response = uart.read(9)

    if len(response) != 9:
        raise RuntimeError(
            "Resposta incompleta: "
            + (
                " ".join(f"{value:02X}" for value in response)
                if response
                else "TIMEOUT"
            )
        )

    if response[0] != SOF_RSP:
        raise RuntimeError(
            f"SOF de resposta inválido: 0x{response[0]:02X}"
        )

    if checksum(response[:8]) != response[8]:
        raise RuntimeError("Checksum de resposta inválido")

    response_command = response[1]
    response_address = (response[2] << 8) | response[3]
    response_data = (
        (response[4] << 24)
        | (response[5] << 16)
        | (response[6] << 8)
        | response[7]
    )

    return response_command, response_address, response_data


def signed_16(value: int) -> int:
    value &= 0xFFFF
    return value - 0x10000 if value & 0x8000 else value


def pack_iq(i_value: int, q_value: int) -> int:
    return (
        ((i_value & 0xFFFF) << 16)
        | (q_value & 0xFFFF)
    )


def unpack_iq(word: int) -> tuple[int, int]:
    return signed_16(word >> 16), signed_16(word)


def magnitude(i_value: int, q_value: int) -> float:
    return math.sqrt(
        float(i_value * i_value + q_value * q_value)
    )


def wait_for_completion(
    uart: serial.Serial,
    timeout_s: float,
) -> tuple[int, int, int, int]:
    deadline = time.time() + timeout_s

    while time.time() < deadline:
        _, _, status = transact(
            uart,
            CMD_STATUS,
            0,
            0,
        )

        busy = status & 0x01
        done = (status >> 1) & 0x01
        error = (status >> 2) & 0x01
        overflow = (status >> 3) & 0x01

        if error:
            raise RuntimeError(
                "Controlador DPD sinalizou erro"
            )

        if not busy:
            return busy, done, error, overflow

        time.sleep(0.005)

    raise RuntimeError(
        "Timeout esperando término do processamento DPD"
    )


def build_sweep(
    points: int,
    max_amplitude: int,
) -> list[tuple[int, int]]:
    if points < 2:
        raise ValueError("points deve ser >= 2")

    vectors: list[tuple[int, int]] = []

    for index in range(points):
        amplitude = round(
            index * max_amplitude / (points - 1)
        )
        vectors.append((amplitude, 0))

    return vectors


parser = argparse.ArgumentParser(
    description=(
        "DPDnano-Lite HW012_dpd - "
        "Amplitude Sweep AM/AM"
    )
)

parser.add_argument("--port", required=True)
parser.add_argument(
    "--points",
    type=int,
    default=256,
    help="Quantidade de pontos da varredura",
)
parser.add_argument(
    "--max-amplitude",
    type=int,
    default=30000,
    help="Amplitude máxima da componente I",
)
parser.add_argument(
    "--csv",
    default="hw012_dpd_amplitude_sweep.csv",
    help="Arquivo CSV de saída",
)

args = parser.parse_args()

if not 2 <= args.points <= 256:
    raise SystemExit(
        "--points deve estar entre 2 e 256"
    )

if not 1 <= args.max_amplitude <= 32767:
    raise SystemExit(
        "--max-amplitude deve estar entre 1 e 32767"
    )

vectors = build_sweep(
    points=args.points,
    max_amplitude=args.max_amplitude,
)

rows: list[dict[str, object]] = []

with serial.Serial(
    args.port,
    115200,
    timeout=2.0,
    write_timeout=1.0,
) as uart:
    time.sleep(0.1)

    print("DPDnano-Lite HW012_dpd - Amplitude Sweep")
    print(f"Porta          : {args.port}")
    print("Baud           : 115200")
    print(f"Pontos         : {len(vectors)}")
    print(f"Amplitude max. : {args.max_amplitude}")
    print()

    command, address, data = transact(
        uart,
        CMD_PING,
        0,
        0,
    )

    if (command, address, data) != (
        CMD_PING,
        0,
        0,
    ):
        raise RuntimeError(
            "Falha no PING inicial"
        )

    for index, (i_value, q_value) in enumerate(vectors):
        command, address, data = transact(
            uart,
            CMD_WRITE_IN,
            index,
            pack_iq(i_value, q_value),
        )

        if (command, address, data) != (
            CMD_WRITE_IN,
            index,
            0,
        ):
            raise RuntimeError(
                f"Falha ao escrever amostra {index}"
            )

    command, address, data = transact(
        uart,
        CMD_START_DPD,
        0,
        len(vectors),
    )

    if (command, address, data) != (
        CMD_START_DPD,
        0,
        len(vectors),
    ):
        raise RuntimeError(
            "Resposta inválida ao START_DPD"
        )

    _, _, _, overflow = wait_for_completion(
        uart,
        timeout_s=3.0,
    )

    saturation_onset = None
    previous_output_mag = -1.0

    for index, (input_i, input_q) in enumerate(vectors):
        command, address, output_word = transact(
            uart,
            CMD_READ_OUT,
            index,
            0,
        )

        if command != CMD_READ_OUT or address != index:
            raise RuntimeError(
                f"Resposta inválida ao ler endereço {index}"
            )

        output_i, output_q = unpack_iq(output_word)

        input_mag = magnitude(input_i, input_q)
        output_mag = magnitude(output_i, output_q)

        gain = (
            output_mag / input_mag
            if input_mag > 0
            else 0.0
        )

        saturated = (
            abs(output_i) >= 32767
            or abs(output_q) >= 32767
        )

        if (
            saturation_onset is None
            and saturated
        ):
            saturation_onset = input_mag

        monotonic = output_mag >= previous_output_mag
        previous_output_mag = output_mag

        rows.append({
            "index": index,
            "input_i": input_i,
            "input_q": input_q,
            "input_magnitude": input_mag,
            "output_i": output_i,
            "output_q": output_q,
            "output_magnitude": output_mag,
            "gain": gain,
            "saturated": int(saturated),
            "monotonic": int(monotonic),
        })

        print(
            f"[{index:03d}] "
            f"IN={input_mag:9.3f} "
            f"OUT={output_mag:9.3f} "
            f"GAIN={gain:8.6f} "
            f"SAT={'SIM' if saturated else 'NÃO'}"
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

monotonic_failures = sum(
    1 for row in rows
    if not bool(row["monotonic"])
)

print()
print("==============================================")
print("HW012_dpd - RESUMO")
print("==============================================")
print(f"Pontos processados        : {len(rows)}")
print(f"Overflow visto            : {'SIM' if overflow else 'NÃO'}")
print(f"Falhas de monotonicidade  : {monotonic_failures}")
print(
    "Início da saturação      : "
    + (
        f"{saturation_onset:.3f}"
        if saturation_onset is not None
        else "não observado"
    )
)
print(f"Arquivo CSV               : {csv_path.resolve()}")
print("==============================================")

if monotonic_failures == 0:
    print(
        "RESULTADO: PASS - sweep de amplitude AM/AM validado"
    )
else:
    print(
        "RESULTADO: FAIL - curva não monotônica"
    )
    raise SystemExit(1)
