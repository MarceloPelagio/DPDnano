#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import time
from pathlib import Path

import serial

SOF_REQ = 0xA5
SOF_RSP = 0x5A

CMD_PING = 0x01
CMD_RUN = 0x50
CMD_STATUS = 0x51
CMD_METRIC = 0x52

SCENARIOS = [
    ("continuous", 0, 256),
    ("gap2", 1, 128),
    ("gap4", 2, 128),
    ("gap8", 3, 128),
    ("random", 4, 128),
    ("burst", 5, 128),
]

METRICS = {
    0: "latency_min",
    1: "latency_max",
    2: "latency_sum",
    3: "samples_sent",
    4: "samples_received",
    5: "losses",
    6: "duplicates",
    7: "reorder",
    8: "total_cycles",
}


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


def wait_done(uart, timeout_s=5.0):
    deadline = time.time() + timeout_s

    while time.time() < deadline:
        _, _, status = transact(uart, CMD_STATUS, 0, 0)
        busy = (status >> 2) & 0x01
        error = (status >> 4) & 0x01
        overflow = (status >> 5) & 0x01

        if error:
            raise RuntimeError("Engine temporal sinalizou erro")
        if not busy:
            return overflow

        time.sleep(0.005)

    raise RuntimeError("Timeout esperando termino do cenario")


def read_metrics(uart):
    result = {}
    for address, name in METRICS.items():
        command, response_address, value = transact(uart, CMD_METRIC, address, 0)
        if command != CMD_METRIC or response_address != address:
            raise RuntimeError(f"Resposta invalida da metrica {name}")
        result[name] = value
    return result


def reconstruct_input_cycles(scenario_name, sample_count):
    cycles = []
    current_cycle = 0

    if scenario_name == "continuous":
        return list(range(sample_count))
    if scenario_name == "gap2":
        return [2 * index for index in range(sample_count)]
    if scenario_name == "gap4":
        return [4 * index for index in range(sample_count)]
    if scenario_name == "gap8":
        return [8 * index for index in range(sample_count)]
    if scenario_name == "burst":
        while len(cycles) < sample_count:
            for _ in range(16):
                if len(cycles) >= sample_count:
                    break
                cycles.append(current_cycle)
                current_cycle += 1
            current_cycle += 50
        return cycles

    lfsr = 0xACE1
    while len(cycles) < sample_count:
        cycles.append(current_cycle)
        raw = lfsr & 0xF
        if raw >= 10:
            gap = raw - 9
        elif raw == 0:
            gap = 1
        else:
            gap = raw
        current_cycle += gap
        feedback = ((lfsr >> 15) & 1) ^ ((lfsr >> 13) & 1) ^ ((lfsr >> 12) & 1) ^ ((lfsr >> 10) & 1)
        lfsr = ((lfsr << 1) & 0xFFFF) | feedback
    return cycles


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", required=True)
    parser.add_argument("--output-dir", default=".")
    args = parser.parse_args()

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    summary = []
    timeline_rows = []

    with serial.Serial(args.port, 115200, timeout=2.0, write_timeout=1.0) as uart:
        time.sleep(0.1)

        print("DPDnano-Lite HW022_dpd - Caracterizacao Temporal do Pipeline")
        print("Porta                 :", args.port)
        print("Clock interno DPD     : 60 MHz via PLL")
        print()

        if transact(uart, CMD_PING, 0, 0) != (CMD_PING, 0, 0):
            raise RuntimeError("Falha no PING")

        for scenario_name, scenario_id, sample_count in SCENARIOS:
            run_data = (scenario_id << 16) | sample_count
            command, address, response = transact(uart, CMD_RUN, 0, run_data)
            if command != CMD_RUN or address != 0 or response != run_data:
                raise RuntimeError(f"Falha ao iniciar cenario {scenario_name}")

            overflow = wait_done(uart)
            metrics = read_metrics(uart)
            received = metrics["samples_received"]
            latency_average = (metrics["latency_sum"] / received) if received else 0.0
            jitter = metrics["latency_max"] - metrics["latency_min"]
            throughput = (received / metrics["total_cycles"]) if metrics["total_cycles"] else 0.0

            passed = (
                not overflow
                and metrics["samples_sent"] == sample_count
                and metrics["samples_received"] == sample_count
                and metrics["losses"] == 0
                and metrics["duplicates"] == 0
                and metrics["reorder"] == 0
                and jitter == 0
            )

            summary.append(
                {
                    "scenario": scenario_name,
                    "scenario_id": scenario_id,
                    "sample_count": sample_count,
                    "latency_min": metrics["latency_min"],
                    "latency_max": metrics["latency_max"],
                    "latency_average": latency_average,
                    "jitter": jitter,
                    "samples_sent": metrics["samples_sent"],
                    "samples_received": metrics["samples_received"],
                    "losses": metrics["losses"],
                    "duplicates": metrics["duplicates"],
                    "reorder": metrics["reorder"],
                    "total_cycles": metrics["total_cycles"],
                    "throughput_samples_per_cycle": throughput,
                    "overflow": int(overflow),
                    "passed": int(passed),
                }
            )

            input_cycles = reconstruct_input_cycles(scenario_name, min(sample_count, 32))
            latency = int(round(latency_average))
            for index, input_cycle in enumerate(input_cycles):
                timeline_rows.append(
                    {
                        "scenario": scenario_name,
                        "sample_index": index,
                        "input_cycle": input_cycle,
                        "output_cycle": input_cycle + latency,
                        "latency": latency,
                    }
                )

            print("----------------------------------------------")
            print(f"Cenario                  : {scenario_name}")
            print(f"Latencia minima          : {metrics['latency_min']}")
            print(f"Latencia maxima          : {metrics['latency_max']}")
            print(f"Latencia media           : {latency_average:.6f}")
            print(f"Jitter                   : {jitter}")
            print(f"Amostras enviadas        : {metrics['samples_sent']}")
            print(f"Amostras recebidas       : {metrics['samples_received']}")
            print(f"Perdas                   : {metrics['losses']}")
            print(f"Duplicacoes              : {metrics['duplicates']}")
            print(f"Reordenacao              : {metrics['reorder']}")
            print(f"Throughput efetivo       : {throughput:.6f} amostra/ciclo")
            print(f"Overflow                 : {'SIM' if overflow else 'NAO'}")
            print(f"RESULTADO                : {'PASS' if passed else 'FAIL'}")

    summary_csv = output_dir / "hw022_dpd_temporal_summary.csv"
    with summary_csv.open("w", newline="", encoding="utf-8") as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=list(summary[0].keys()))
        writer.writeheader()
        writer.writerows(summary)

    timeline_csv = output_dir / "hw022_dpd_timeline.csv"
    with timeline_csv.open("w", newline="", encoding="utf-8") as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=list(timeline_rows[0].keys()))
        writer.writeheader()
        writer.writerows(timeline_rows)

    all_passed = all(bool(row["passed"]) for row in summary)

    print()
    print("==============================================")
    print("HW022_dpd - RESUMO FINAL")
    print("==============================================")
    for row in summary:
        print(
            f"{row['scenario']:10s} "
            f"LAT={row['latency_average']:.3f} "
            f"JITTER={row['jitter']} "
            f"LOSS={row['losses']} "
            f"RESULT={'PASS' if row['passed'] else 'FAIL'}"
        )
    print(f"Resumo CSV   : {summary_csv.resolve()}")
    print(f"Timeline CSV : {timeline_csv.resolve()}")
    print("==============================================")

    if all_passed:
        print("RESULTADO: PASS - pipeline temporal deterministico validado")
    else:
        print("RESULTADO: FAIL")
        raise SystemExit(1)


if __name__ == "__main__":
    main()
