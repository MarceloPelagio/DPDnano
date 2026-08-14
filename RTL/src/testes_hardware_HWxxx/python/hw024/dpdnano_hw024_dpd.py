#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import serial
import statistics
import time
from pathlib import Path

SOF_REQ, SOF_RSP = 0xA5, 0x5A
CMD_PING, CMD_RUN, CMD_STATUS, CMD_METRIC, CMD_CHECKPOINT = (
    0x01, 0x60, 0x61, 0x62, 0x63
)
CLOCK_HZ = 100_000_000

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


def checksum(values):
    value = 0
    for item in values:
        value ^= item
    return value & 0xFF


def frame(command, address, data):
    body = [
        SOF_REQ, command,
        (address >> 8) & 0xFF, address & 0xFF,
        (data >> 24) & 0xFF, (data >> 16) & 0xFF,
        (data >> 8) & 0xFF, data & 0xFF,
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
        raise RuntimeError("SOF inválido")
    if checksum(response[:8]) != response[8]:
        raise RuntimeError("Checksum inválido")

    return (
        response[1],
        (response[2] << 8) | response[3],
        (response[4] << 24) | (response[5] << 16)
        | (response[6] << 8) | response[7],
    )


def wait_done(uart, timeout_s):
    deadline = time.time() + timeout_s

    while time.time() < deadline:
        _, _, status = transact(uart, CMD_STATUS, 0, 0)
        busy = (status >> 1) & 1
        error = (status >> 3) & 1

        if error:
            raise RuntimeError("Engine de stress sinalizou erro")
        if not busy:
            return

        time.sleep(0.01)

    raise RuntimeError("Timeout esperando execução")


def read_metrics(uart):
    result = {}

    for address, name in METRICS.items():
        command, response_address, value = transact(
            uart, CMD_METRIC, address, 0
        )

        if command != CMD_METRIC or response_address != address:
            raise RuntimeError(f"Resposta inválida da métrica {name}")

        result[name] = value

    return result


def read_checkpoints(uart):
    values = []

    for index in range(10):
        command, response_address, value = transact(
            uart, CMD_CHECKPOINT, index, 0
        )

        if command != CMD_CHECKPOINT or response_address != index:
            raise RuntimeError(
                f"Resposta inválida do checkpoint {index}"
            )

        values.append(value)

    return values


parser = argparse.ArgumentParser()
parser.add_argument("--port", required=True)
parser.add_argument("--runs", type=int, default=10)
parser.add_argument("--samples", type=int, default=1_000_000)
parser.add_argument("--timeout", type=float, default=15.0)
parser.add_argument("--output-dir", default="../../results/hw024")
args = parser.parse_args()

if not 2 <= args.runs <= 100:
    raise SystemExit("--runs deve estar entre 2 e 100")
if not 1_000 <= args.samples <= 1_000_000:
    raise SystemExit("--samples deve estar entre 1000 e 1000000")

output_dir = Path(args.output_dir)
output_dir.mkdir(parents=True, exist_ok=True)

runs = []
checkpoint_rows = []

with serial.Serial(
    args.port, 115200, timeout=2.0, write_timeout=1.0
) as uart:
    time.sleep(0.1)

    print("DPDnano-Lite HW024_dpd - Reprodutibilidade")
    print(f"Execuções             : {args.runs}")
    print(f"Amostras por execução : {args.samples}")
    print(f"Amostras totais       : {args.runs * args.samples}")
    print("Clock                 : 100 MHz")
    print()

    if transact(uart, CMD_PING, 0, 0) != (CMD_PING, 0, 0):
        raise RuntimeError("Falha no PING")

    for run_index in range(1, args.runs + 1):
        response = transact(uart, CMD_RUN, 0, args.samples)

        if response != (CMD_RUN, 0, args.samples):
            raise RuntimeError(
                f"Falha ao iniciar execução {run_index}"
            )

        wall_start = time.perf_counter()
        wait_done(uart, args.timeout)
        wall_elapsed = time.perf_counter() - wall_start

        metrics = read_metrics(uart)
        checkpoints = read_checkpoints(uart)
        received = metrics["samples_received"]

        latency_average = (
            metrics["latency_sum"] / received if received else 0.0
        )
        jitter = metrics["latency_max"] - metrics["latency_min"]
        hardware_time = (
            metrics["total_cycles"] / CLOCK_HZ
            if metrics["total_cycles"] else 0.0
        )
        throughput = (
            received / hardware_time if hardware_time else 0.0
        )
        expected_updates = args.samples // 256

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

        row = {
            "run": run_index,
            "target_samples": args.samples,
            **metrics,
            "latency_average": latency_average,
            "jitter": jitter,
            "hardware_time_seconds": hardware_time,
            "throughput_msps": throughput / 1e6,
            "wall_time_seconds": wall_elapsed,
            "passed": int(passed),
        }
        runs.append(row)

        for checkpoint_index, cycle in enumerate(checkpoints, start=1):
            checkpoint_rows.append({
                "run": run_index,
                "checkpoint": checkpoint_index,
                "samples": checkpoint_index * 100_000,
                "cycle": cycle,
                "time_seconds": cycle / CLOCK_HZ,
            })

        print(
            f"RUN {run_index:02d} "
            f"LAT={latency_average:.3f} "
            f"JITTER={jitter} "
            f"THR={throughput / 1e6:.6f} MS/s "
            f"OVF={metrics['overflow_events']} "
            f"RESULT={'PASS' if passed else 'FAIL'}"
        )

runs_csv = output_dir / "hw024_dpd_reproducibility_runs.csv"
with runs_csv.open("w", newline="", encoding="utf-8") as csv_file:
    writer = csv.DictWriter(csv_file, fieldnames=list(runs[0].keys()))
    writer.writeheader()
    writer.writerows(runs)

checkpoints_csv = (
    output_dir / "hw024_dpd_reproducibility_checkpoints.csv"
)
with checkpoints_csv.open("w", newline="", encoding="utf-8") as csv_file:
    writer = csv.DictWriter(
        csv_file,
        fieldnames=list(checkpoint_rows[0].keys()),
    )
    writer.writeheader()
    writer.writerows(checkpoint_rows)

latencies = [float(row["latency_average"]) for row in runs]
throughputs = [float(row["throughput_msps"]) for row in runs]
overflows = [int(row["overflow_events"]) for row in runs]
saturations = [
    int(row["saturation_positive"]) + int(row["saturation_negative"])
    for row in runs
]
input_signatures = [int(row["input_signature"]) for row in runs]
output_signatures = [int(row["output_signature"]) for row in runs]
pass_count = sum(int(row["passed"]) for row in runs)

summary = {
    "runs": args.runs,
    "samples_per_run": args.samples,
    "total_samples": args.runs * args.samples,
    "pass_count": pass_count,
    "fail_count": args.runs - pass_count,
    "success_rate_percent": 100.0 * pass_count / args.runs,
    "latency_mean_cycles": statistics.mean(latencies),
    "latency_stddev_cycles": statistics.pstdev(latencies),
    "throughput_mean_msps": statistics.mean(throughputs),
    "throughput_min_msps": min(throughputs),
    "throughput_max_msps": max(throughputs),
    "throughput_stddev_msps": statistics.pstdev(throughputs),
    "overflow_mean": statistics.mean(overflows),
    "overflow_stddev": statistics.pstdev(overflows),
    "saturation_mean": statistics.mean(saturations),
    "saturation_stddev": statistics.pstdev(saturations),
    "input_signatures_identical": int(
        len(set(input_signatures)) == 1
    ),
    "output_signatures_identical": int(
        len(set(output_signatures)) == 1
    ),
}

summary_csv = output_dir / "hw024_dpd_reproducibility_summary.csv"
with summary_csv.open("w", newline="", encoding="utf-8") as csv_file:
    writer = csv.DictWriter(csv_file, fieldnames=list(summary.keys()))
    writer.writeheader()
    writer.writerow(summary)

all_passed = (
    pass_count == args.runs
    and summary["input_signatures_identical"] == 1
    and summary["output_signatures_identical"] == 1
    and summary["latency_stddev_cycles"] == 0.0
)

print()
print("==============================================")
print("HW024_dpd - RESUMO ESTATÍSTICO")
print("==============================================")
print(f"Execuções                 : {args.runs}")
print(f"PASS                      : {pass_count}")
print(f"FAIL                      : {args.runs - pass_count}")
print(f"Taxa de sucesso           : {summary['success_rate_percent']:.2f}%")
print(f"Latência média            : {summary['latency_mean_cycles']:.6f}")
print(f"Desvio padrão latência    : {summary['latency_stddev_cycles']:.6f}")
print(f"Throughput médio          : {summary['throughput_mean_msps']:.6f} MS/s")
print(f"Throughput mínimo         : {summary['throughput_min_msps']:.6f} MS/s")
print(f"Throughput máximo         : {summary['throughput_max_msps']:.6f} MS/s")
print(f"Desvio padrão throughput  : {summary['throughput_stddev_msps']:.9f}")
print(f"Overflow médio            : {summary['overflow_mean']:.3f}")
print(f"Saturações médias         : {summary['saturation_mean']:.3f}")
print(
    "Assinaturas entrada iguais: "
    + ("SIM" if summary["input_signatures_identical"] else "NÃO")
)
print(
    "Assinaturas saída iguais  : "
    + ("SIM" if summary["output_signatures_identical"] else "NÃO")
)
print(f"Runs CSV                  : {runs_csv.resolve()}")
print(f"Summary CSV               : {summary_csv.resolve()}")
print("==============================================")

if all_passed:
    print(
        "RESULTADO: PASS - reprodutibilidade "
        "e robustez estatística validadas"
    )
else:
    print("RESULTADO: FAIL - divergência entre execuções")
    raise SystemExit(1)
