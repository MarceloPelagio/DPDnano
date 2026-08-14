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
CMD_PROFILE = 0x42

PROFILES = {
    "A": {"id": 0, "coef3_im": "0x0000", "label": "Linear"},
    "B": {"id": 1, "coef3_im": "0x0CCD", "label": "AM/PM leve"},
    "C": {"id": 2, "coef3_im": "0x199A", "label": "AM/PM média"},
    "D": {"id": 3, "coef3_im": "0x2CCD", "label": "AM/PM forte"},
}


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
        active_profile = (status >> 4) & 0x03

        if error:
            raise RuntimeError(
                "Controlador DPD sinalizou erro"
            )

        if not busy:
            return overflow, active_profile

        time.sleep(0.005)

    raise RuntimeError(
        "Timeout esperando processamento DPD"
    )


def run_profile(
    uart,
    profile_name,
    vectors,
    output_dir,
    eps_phase,
):
    profile = PROFILES[profile_name]

    command, address, data = transact(
        uart,
        CMD_PROFILE,
        0,
        profile["id"],
    )

    if (
        command != CMD_PROFILE
        or address != 0
        or data != profile["id"]
    ):
        raise RuntimeError(
            f"Falha ao selecionar perfil {profile_name}"
        )

    for index, (input_i, input_q) in enumerate(vectors):
        response = transact(
            uart,
            CMD_WRITE_IN,
            index,
            pack_iq(input_i, input_q),
        )

        if response != (
            CMD_WRITE_IN,
            index,
            0,
        ):
            raise RuntimeError(
                f"Falha ao escrever vetor {index}"
            )

    response = transact(
        uart,
        CMD_START_DPD,
        0,
        len(vectors),
    )

    if response != (
        CMD_START_DPD,
        0,
        len(vectors),
    ):
        raise RuntimeError(
            f"Falha no START_DPD do perfil {profile_name}"
        )

    overflow, active_profile = wait_done(uart)

    if active_profile != profile["id"]:
        raise RuntimeError(
            f"Perfil ativo divergente: "
            f"esperado {profile['id']}, recebido {active_profile}"
        )

    rows = []

    for index, (input_i, input_q) in enumerate(vectors):
        command, address, output_word = transact(
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
                f"Resposta inválida ao ler endereço {index}"
            )

        output_i, output_q = unpack_iq(output_word)

        input_magnitude = math.hypot(
            input_i,
            input_q,
        )

        output_magnitude = math.hypot(
            output_i,
            output_q,
        )

        phase_shift = math.degrees(
            math.atan2(
                output_q,
                output_i,
            )
        )

        rows.append({
            "profile": profile_name,
            "profile_label": profile["label"],
            "coef1_re": "0x3333",
            "coef1_im": "0x0000",
            "coef3_re": "0x0000",
            "coef3_im": profile["coef3_im"],
            "index": index,
            "input_i": input_i,
            "input_q": input_q,
            "input_magnitude": input_magnitude,
            "output_i": output_i,
            "output_q": output_q,
            "output_magnitude": output_magnitude,
            "phase_shift_deg": phase_shift,
        })

    phase_values = [
        float(row["phase_shift_deg"])
        for row in rows
    ]

    monotonic_failures = sum(
        1
        for current_phase, next_phase in zip(
            phase_values,
            phase_values[1:],
        )
        if next_phase < current_phase - eps_phase
    )

    if profile_name == "A":
        passed = (
            not overflow
            and max(abs(value) for value in phase_values) <= 0.1
        )
    else:
        passed = (
            not overflow
            and max(phase_values) > min(phase_values) + 1.0
            and monotonic_failures == 0
        )

    csv_path = output_dir / f"hw016_profile_{profile_name}.csv"

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

    print()
    print("----------------------------------------------")
    print(f"Perfil {profile_name} - {profile['label']}")
    print("----------------------------------------------")
    print(f"coef3_im                  : {profile['coef3_im']}")
    print(f"Desvio de fase mínimo     : {min(phase_values):.6f}°")
    print(f"Desvio de fase máximo     : {max(phase_values):.6f}°")
    print(
        f"Falhas monotonicidade "
        f"(> {eps_phase:.1f}°): {monotonic_failures}"
    )
    print(f"Overflow                   : {'SIM' if overflow else 'NÃO'}")
    print(f"CSV                        : {csv_path.resolve()}")
    print(
        f"RESULTADO                  : "
        f"{'PASS' if passed else 'FAIL'}"
    )

    return passed, rows


parser = argparse.ArgumentParser(
    description=(
        "HW016_dpd vr02 - executa perfis A/B/C/D "
        "com um único bitstream"
    )
)

parser.add_argument("--port", required=True)
parser.add_argument(
    "--points",
    type=int,
    default=256,
)
parser.add_argument(
    "--max-amplitude",
    type=int,
    default=30000,
)
parser.add_argument(
    "--eps-phase",
    type=float,
    default=0.5,
)
parser.add_argument(
    "--output-dir",
    default=".",
)

args = parser.parse_args()

if not 8 <= args.points <= 256:
    raise SystemExit(
        "--points deve estar entre 8 e 256"
    )

if not 1000 <= args.max_amplitude <= 30000:
    raise SystemExit(
        "--max-amplitude deve estar entre 1000 e 30000"
    )

output_dir = Path(args.output_dir)
output_dir.mkdir(
    parents=True,
    exist_ok=True,
)

vectors = [
    (
        round(
            (index + 1)
            * args.max_amplitude
            / args.points
        ),
        0,
    )
    for index in range(args.points)
]

all_rows = []
results = {}

with serial.Serial(
    args.port,
    115200,
    timeout=2.0,
    write_timeout=1.0,
) as uart:
    time.sleep(0.1)

    print(
        "DPDnano-Lite HW016_dpd vr02 - "
        "Multi-Profile One Run"
    )
    print(f"Porta              : {args.port}")
    print(f"Pontos por perfil  : {args.points}")
    print(f"Amplitude máxima   : {args.max_amplitude}")
    print(f"Tolerância de fase : {args.eps_phase:.1f}°")
    print()

    if transact(
        uart,
        CMD_PING,
        0,
        0,
    ) != (CMD_PING, 0, 0):
        raise RuntimeError(
            "Falha no PING inicial"
        )

    for profile_name in ("A", "B", "C", "D"):
        passed, rows = run_profile(
            uart=uart,
            profile_name=profile_name,
            vectors=vectors,
            output_dir=output_dir,
            eps_phase=args.eps_phase,
        )

        results[profile_name] = passed
        all_rows.extend(rows)

combined_csv = (
    output_dir
    / "hw016_dpd_all_profiles.csv"
)

with combined_csv.open(
    "w",
    newline="",
    encoding="utf-8",
) as csv_file:
    writer = csv.DictWriter(
        csv_file,
        fieldnames=list(all_rows[0].keys()),
    )
    writer.writeheader()
    writer.writerows(all_rows)

print()
print("==============================================")
print("HW016_dpd vr02 - RESUMO FINAL")
print("==============================================")

for profile_name in ("A", "B", "C", "D"):
    print(
        f"Perfil {profile_name}: "
        f"{'PASS' if results[profile_name] else 'FAIL'}"
    )

print(f"CSV consolidado: {combined_csv.resolve()}")
print("==============================================")

if all(results.values()):
    print(
        "RESULTADO: PASS - quatro perfis AM/PM "
        "validados em uma execução"
    )
else:
    print(
        "RESULTADO: FAIL - um ou mais perfis "
        "fora do esperado"
    )
    raise SystemExit(1)
