#!/usr/bin/env python3
from __future__ import annotations

import argparse
import random
import serial
import statistics
import time

SOF_REQ = 0xA5
SOF_RSP = 0x5A

CMD_PING = 0x01
CMD_WRITE_IN = 0x20
CMD_READ_OUT = 0x31
CMD_START_DPD = 0x40
CMD_STATUS = 0x41

# Same static coefficients used in HW010_dpd.
COEF1_RE = 0x6000  # 0.75 in Q1.15
COEF3_RE = 0x1000  # 0.125 in Q1.15


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


def saturate_16(value: int) -> int:
    return max(-32768, min(32767, value))


def model_component(x_value: int, y_value: int) -> int:
    magnitude_squared = (
        x_value * x_value
        + y_value * y_value
    )

    linear = x_value * COEF1_RE

    cubic_term = x_value * magnitude_squared
    cubic = (cubic_term * COEF3_RE) >> 30

    accumulator = linear + cubic

    # Conversion from accumulator Q?.30 to output Q1.15.
    output = accumulator >> 15

    return saturate_16(output)


def reference_dpd(i_value: int, q_value: int) -> tuple[int, int]:
    return (
        model_component(i_value, q_value),
        model_component(q_value, i_value),
    )


def pack_iq(i_value: int, q_value: int) -> int:
    return (
        ((i_value & 0xFFFF) << 16)
        | (q_value & 0xFFFF)
    )


def unpack_iq(word: int) -> tuple[int, int]:
    return signed_16(word >> 16), signed_16(word)


def generate_vectors(
    count: int,
    amplitude: int,
    seed: int,
) -> list[tuple[int, int]]:
    deterministic = [
        (0, 0),
        (1, 0),
        (-1, 0),
        (0, 1),
        (0, -1),
        (100, 100),
        (-100, 100),
        (1000, -1000),
        (-1000, -1000),
        (amplitude, 0),
        (-amplitude, 0),
        (0, amplitude),
        (0, -amplitude),
        (amplitude, amplitude),
        (-amplitude, amplitude),
        (amplitude, -amplitude),
        (-amplitude, -amplitude),
    ]

    rng = random.Random(seed)
    vectors = deterministic[:count]

    while len(vectors) < count:
        vectors.append((
            rng.randint(-amplitude, amplitude),
            rng.randint(-amplitude, amplitude),
        ))

    return vectors


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


parser = argparse.ArgumentParser(
    description=(
        "DPDnano-Lite HW011_dpd - "
        "Random FPGA vs Python comparison"
    )
)

parser.add_argument("--port", required=True)
parser.add_argument(
    "--count",
    type=int,
    default=256,
    help="Quantidade de vetores, entre 1 e 256",
)
parser.add_argument(
    "--amplitude",
    type=int,
    default=12000,
    help="Amplitude máxima absoluta dos componentes I/Q",
)
parser.add_argument(
    "--seed",
    type=int,
    default=11011,
)
parser.add_argument(
    "--tolerance",
    type=int,
    default=1,
    help="Tolerância máxima por componente, em LSB",
)
parser.add_argument(
    "--show-all",
    action="store_true",
    help="Exibe também as amostras com erro zero",
)

args = parser.parse_args()

if not 1 <= args.count <= 256:
    raise SystemExit(
        "--count deve estar entre 1 e 256"
    )

if not 1 <= args.amplitude <= 20000:
    raise SystemExit(
        "--amplitude deve estar entre 1 e 20000"
    )

if args.tolerance < 0:
    raise SystemExit(
        "--tolerance não pode ser negativa"
    )

vectors = generate_vectors(
    count=args.count,
    amplitude=args.amplitude,
    seed=args.seed,
)

errors_i: list[int] = []
errors_q: list[int] = []
failures = 0
exact_matches = 0

with serial.Serial(
    args.port,
    115200,
    timeout=2.0,
    write_timeout=1.0,
) as uart:
    time.sleep(0.1)

    print(
        "DPDnano-Lite HW011_dpd - "
        "Random Comparison"
    )
    print(f"Porta      : {args.port}")
    print("Baud       : 115200")
    print(f"Amostras   : {len(vectors)}")
    print(f"Amplitude  : ±{args.amplitude}")
    print(f"Seed       : {args.seed}")
    print(f"Tolerância : {args.tolerance} LSB")
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
            "Resposta inválida ao comando START_DPD"
        )

    _, done, _, overflow = wait_for_completion(
        uart,
        timeout_s=3.0,
    )

    for index, (input_i, input_q) in enumerate(vectors):
        expected_i, expected_q = reference_dpd(
            input_i,
            input_q,
        )

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

        actual_i, actual_q = unpack_iq(output_word)

        error_i = actual_i - expected_i
        error_q = actual_q - expected_q

        errors_i.append(error_i)
        errors_q.append(error_q)

        passed = (
            abs(error_i) <= args.tolerance
            and abs(error_q) <= args.tolerance
        )

        if error_i == 0 and error_q == 0:
            exact_matches += 1

        if not passed:
            failures += 1

        if args.show_all or not passed:
            print(
                f"{'PASS' if passed else 'FAIL'} "
                f"[{index:03d}] "
                f"IN=({input_i:6d},{input_q:6d}) "
                f"REF=({expected_i:6d},{expected_q:6d}) "
                f"FPGA=({actual_i:6d},{actual_q:6d}) "
                f"ERR=({error_i:+d},{error_q:+d})"
            )

all_errors = errors_i + errors_q
max_abs_error = max(abs(value) for value in all_errors)
mean_abs_error = statistics.mean(
    abs(value) for value in all_errors
)

histogram = {}
for value in all_errors:
    histogram[value] = histogram.get(value, 0) + 1

print()
print("==============================================")
print("HW011_dpd - RESUMO")
print("==============================================")
print(f"Amostras processadas : {len(vectors)}")
print(f"Componentes avaliados: {len(all_errors)}")
print(f"Coincidência I/Q exata: {exact_matches}")
print(f"Erro absoluto máximo : {max_abs_error} LSB")
print(f"Erro absoluto médio  : {mean_abs_error:.6f} LSB")
print(f"Overflow visto       : {'SIM' if overflow else 'NÃO'}")
print("Distribuição dos erros:")

for error_value in sorted(histogram):
    print(
        f"  {error_value:+d} LSB : "
        f"{histogram[error_value]}"
    )

print("==============================================")

if failures == 0:
    print(
        "RESULTADO: PASS - comparação aleatória "
        "FPGA x Python validada"
    )
else:
    print(
        f"RESULTADO: FAIL - {failures} "
        "amostra(s) fora da tolerância"
    )
    raise SystemExit(1)
