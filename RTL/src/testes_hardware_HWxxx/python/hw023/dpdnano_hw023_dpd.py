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
CMD_RUN = 0x60
CMD_STATUS = 0x61
CMD_METRIC = 0x62
CMD_CHECKPOINT = 0x63

METRICS = {
    0: "samples_sent",
    1: "samples_received",
    2: "latency_min",
    3: "latency_max",
    4: "latency_sum",
    5: "total_cycles",
    6: "overflow_events",
    7: "saturation_positive",
    8: "saturation_negative",
    9: "coefficient_updates",
    10: "high_amplitude_samples",
    11: "fifo_errors",
    12: "losses",
    13: "duplicates",
    14: "reorder",
    15: "input_signature",
    16: "output_signature",
}

CLOCK_HZ = 27_000_000


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
        raise RuntimeError("SOF inválido")

    if checksum(response[:8]) != response[8]:
        raise RuntimeError("Checksum inválido")

    return (
        response[1],
        (response[2] << 8) | response[3],
        (response[4] << 24)
        | (response[5] << 16)
        | (response[6] << 8)
        | response[7],
    )


def wait_until_finished(uart, timeout_s):
    deadline = time.time() + timeout_s

    while time.time() < deadline:
        _, _, status = transact(
            uart,
            CMD_STATUS,
            0,
            0,
        )

        busy = (status >> 1) & 0x01
        error = (status >> 3) & 0x01

        if error:
            raise RuntimeError("Engine de stress sinalizou erro")

        if not busy:
            return

        time.sleep(0.01)

    raise RuntimeError("Timeout esperando teste de stress")


def read_metrics(uart):
    result = {}

    for address, name in METRICS.items():
        command, response_address, value = transact(
            uart,
            CMD_METRIC,
            address,
            0,
        )

        if command != CMD_METRIC or response_address != address:
            raise RuntimeError(
                f"Resposta inválida da métrica {name}"
            )

        result[name] = value

    return result


def read_checkpoints(uart):
    values = []

    for index in range(10):
        command, response_address, value = transact(
            uart,
            CMD_CHECKPOINT,
            index,
            0,
        )

        if command != CMD_CHECKPOINT or response_address != index:
            raise RuntimeError(
                f"Resposta inválida do checkpoint {index}"
            )

        values.append(value)

    return values


parser = argparse.ArgumentParser(
    description=(
        "HW023_dpd - stress dinâmico com até "
        "1.000.000 de amostras"
    )
)

parser.add_argument("--port", required=True)

parser.add_argument(
    "--samples",
    type=int,
    default=1_000_000,
)

parser.add_argument(
    "--output-dir",
    default="../../results/hw023",
)

parser.add_argument(
    "--timeout",
    type=float,
    default=15.0,
)

args = parser.parse_args()

if not 1000 <= args.samples <= 1_000_000:
    raise SystemExit(
        "--samples deve estar entre 1000 e 1000000"
    )

output_dir = Path(args.output_dir)
output_dir.mkdir(parents=True, exist_ok=True)

with serial.Serial(
    args.port,
    115200,
    timeout=2.0,
    write_timeout=1.0,
) as uart:
    time.sleep(0.1)

    print("DPDnano-Lite HW023_dpd - Stress Dinâmico")
    print(f"Porta                 : {args.port}")
    print(f"Amostras              : {args.samples}")
    print("Clock                 : 27 MHz")
    print("Fluxo                 : contínuo")
    print("Coeficientes          : 5 perfis dinâmicos")
    print("Atualização           : a cada 256 amostras")
    print("Entrada               : I/Q pseudoaleatória")
    print("Alta amplitude        : aproximadamente 10%")
    print()

    if transact(
        uart,
        CMD_PING,
        0,
        0,
    ) != (CMD_PING, 0, 0):
        raise RuntimeError("Falha no PING")

    command, address, response = transact(
        uart,
        CMD_RUN,
        0,
        args.samples,
    )

    if (
        command != CMD_RUN
        or address != 0
        or response != args.samples
    ):
        raise RuntimeError("Falha ao iniciar o teste")

    wall_start = time.perf_counter()

    wait_until_finished(
        uart,
        timeout_s=args.timeout,
    )

    wall_elapsed = time.perf_counter() - wall_start

    metrics = read_metrics(uart)
    checkpoints = read_checkpoints(uart)

received = metrics["samples_received"]

latency_average = (
    metrics["latency_sum"] / received
    if received
    else 0.0
)

jitter = (
    metrics["latency_max"]
    - metrics["latency_min"]
)

hardware_time_s = (
    metrics["total_cycles"] / CLOCK_HZ
    if metrics["total_cycles"]
    else 0.0
)

hardware_throughput = (
    received / hardware_time_s
    if hardware_time_s
    else 0.0
)

wall_throughput = (
    received / wall_elapsed
    if wall_elapsed
    else 0.0
)

expected_updates = args.samples // 256

checkpoint_rows = []

for index, cycle in enumerate(checkpoints, start=1):
    sample_mark = index * 100_000

    checkpoint_rows.append({
        "checkpoint": index,
        "samples": sample_mark,
        "cycle": cycle,
        "time_seconds": cycle / CLOCK_HZ,
        "average_samples_per_cycle": (
            sample_mark / cycle
            if cycle
            else 0.0
        ),
        "throughput_samples_per_second": (
            sample_mark * CLOCK_HZ / cycle
            if cycle
            else 0.0
        ),
    })

checkpoint_csv = (
    output_dir
    / "hw023_dpd_checkpoints.csv"
)

with checkpoint_csv.open(
    "w",
    newline="",
    encoding="utf-8",
) as csv_file:
    writer = csv.DictWriter(
        csv_file,
        fieldnames=list(checkpoint_rows[0].keys()),
    )
    writer.writeheader()
    writer.writerows(checkpoint_rows)

summary_row = {
    **metrics,
    "target_samples": args.samples,
    "latency_average": latency_average,
    "jitter": jitter,
    "hardware_time_seconds": hardware_time_s,
    "hardware_throughput_samples_per_second": hardware_throughput,
    "wall_time_seconds": wall_elapsed,
    "wall_throughput_samples_per_second": wall_throughput,
    "expected_coefficient_updates": expected_updates,
}

summary_csv = (
    output_dir
    / "hw023_dpd_stress_summary.csv"
)

with summary_csv.open(
    "w",
    newline="",
    encoding="utf-8",
) as csv_file:
    writer = csv.DictWriter(
        csv_file,
        fieldnames=list(summary_row.keys()),
    )
    writer.writeheader()
    writer.writerow(summary_row)

passed = (
    metrics["samples_sent"] == args.samples
    and metrics["samples_received"] == args.samples
    and metrics["fifo_errors"] == 0
    and metrics["losses"] == 0
    and metrics["duplicates"] == 0
    and metrics["reorder"] == 0
    and jitter == 0
    and metrics["coefficient_updates"] == expected_updates
    and metrics["high_amplitude_samples"] > 0
    and (
        metrics["saturation_positive"]
        + metrics["saturation_negative"]
    ) > 0
)

print("==============================================")
print("HW023_dpd - RESUMO")
print("==============================================")
print(f"Amostras enviadas       : {metrics['samples_sent']}")
print(f"Amostras recebidas      : {metrics['samples_received']}")
print(f"Latência mínima         : {metrics['latency_min']} ciclos")
print(f"Latência máxima         : {metrics['latency_max']} ciclos")
print(f"Latência média          : {latency_average:.6f} ciclos")
print(f"Jitter                  : {jitter} ciclos")
print(f"Perdas                  : {metrics['losses']}")
print(f"Duplicações             : {metrics['duplicates']}")
print(f"Reordenação             : {metrics['reorder']}")
print(f"Erros da fila           : {metrics['fifo_errors']}")
print(f"Atualizações coef.      : {metrics['coefficient_updates']}")
print(f"Amostras alta amplitude : {metrics['high_amplitude_samples']}")
print(f"Overflow                : {metrics['overflow_events']}")
print(f"Saturações positivas    : {metrics['saturation_positive']}")
print(f"Saturações negativas    : {metrics['saturation_negative']}")
print(f"Assinatura de entrada   : 0x{metrics['input_signature']:08X}")
print(f"Assinatura de saída     : 0x{metrics['output_signature']:08X}")
print(f"Ciclos totais           : {metrics['total_cycles']}")
print(f"Tempo no hardware       : {hardware_time_s:.6f} s")
print(f"Throughput do hardware  : {hardware_throughput/1e6:.6f} MS/s")
print(f"Tempo observado Python  : {wall_elapsed:.6f} s")
print(f"Resumo CSV              : {summary_csv.resolve()}")
print(f"Checkpoints CSV         : {checkpoint_csv.resolve()}")
print("==============================================")

for row in checkpoint_rows:
    print(
        f"{row['samples']:7d} amostras  "
        f"ciclo={row['cycle']:8d}  "
        f"throughput={row['throughput_samples_per_second']/1e6:.6f} MS/s"
    )

print("==============================================")

if passed:
    print(
        "RESULTADO: PASS - stress dinâmico de "
        "longa duração validado"
    )
else:
    print("RESULTADO: FAIL")
    raise SystemExit(1)
