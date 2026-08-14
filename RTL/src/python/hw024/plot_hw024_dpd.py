#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.ticker import ScalarFormatter


def read_rows(path: Path):
    with path.open("r", encoding="utf-8") as csv_file:
        return list(csv.DictReader(csv_file))


parser = argparse.ArgumentParser()

parser.add_argument(
    "--runs-csv",
    default=(
        "../../results/hw024/"
        "hw024_dpd_reproducibility_runs.csv"
    ),
)

parser.add_argument(
    "--output-dir",
    default="../../results/hw024",
)

args = parser.parse_args()

rows = read_rows(Path(args.runs_csv))

if not rows:
    raise RuntimeError("CSV de execuções vazio")

output_dir = Path(args.output_dir)
output_dir.mkdir(parents=True, exist_ok=True)

runs = [int(row["run"]) for row in rows]
latencies = [float(row["latency_average"]) for row in rows]
throughputs = [float(row["throughput_msps"]) for row in rows]
overflows = [int(row["overflow_events"]) for row in rows]
results = [int(row["passed"]) for row in rows]


def save_latency():
    figure, axis = plt.subplots(figsize=(10, 6))

    axis.plot(
        runs,
        latencies,
        marker="o",
        linewidth=2.4,
    )

    axis.set_xlabel("Execução")
    axis.set_ylabel("Latência média (ciclos)")

    axis.set_title(
        "DPDnano-Lite HW024_dpd — "
        "Latência por Execução"
    )

    axis.set_xticks(runs)
    axis.set_ylim(
        min(latencies) - 0.5,
        max(latencies) + 0.5,
    )

    axis.grid(
        True,
        linestyle="--",
        alpha=0.35,
    )

    figure.tight_layout()

    output = (
        output_dir
        / "hw024_dpd_latency_by_run.png"
    )

    figure.savefig(
        output,
        dpi=300,
    )

    plt.show()

    print(
        f"Gráfico salvo em: {output.resolve()}"
    )


def save_throughput():
    figure, axis = plt.subplots(figsize=(10, 6))

    axis.plot(
        runs,
        throughputs,
        marker="o",
        linewidth=2.4,
    )

    axis.axhline(
        100.0,
        linestyle="--",
        linewidth=1.4,
        label="Referência ideal = 100 MS/s",
    )

    axis.set_xlabel("Execução")
    axis.set_ylabel("Throughput (MS/s)")

    axis.set_title(
        "DPDnano-Lite HW024_dpd — "
        "Throughput por Execução"
    )

    axis.set_xticks(runs)

    margin = max(
        0.0005,
        (max(throughputs) - min(throughputs)) * 0.5,
    )

    axis.set_ylim(
        min(throughputs) - margin,
        max(throughputs) + margin,
    )

    axis.yaxis.set_major_formatter(
        ScalarFormatter(useOffset=False)
    )

    axis.grid(
        True,
        linestyle="--",
        alpha=0.35,
    )

    axis.legend(loc="best")
    figure.tight_layout()

    output = (
        output_dir
        / "hw024_dpd_throughput_by_run.png"
    )

    figure.savefig(
        output,
        dpi=300,
    )

    plt.show()

    print(
        f"Gráfico salvo em: {output.resolve()}"
    )


def save_overflow():
    figure, axis = plt.subplots(figsize=(10, 6))

    axis.bar(
        runs,
        overflows,
    )

    axis.set_xlabel("Execução")
    axis.set_ylabel("Eventos de overflow")

    axis.set_title(
        "DPDnano-Lite HW024_dpd — "
        "Overflow por Execução"
    )

    axis.set_xticks(runs)

    axis.grid(
        axis="y",
        linestyle="--",
        alpha=0.35,
    )

    figure.tight_layout()

    output = (
        output_dir
        / "hw024_dpd_overflow_by_run.png"
    )

    figure.savefig(
        output,
        dpi=300,
    )

    plt.show()

    print(
        f"Gráfico salvo em: {output.resolve()}"
    )


def save_results():
    figure, axis = plt.subplots(figsize=(10, 5.5))

    axis.scatter(
        runs,
        results,
        s=110,
        marker="o",
    )

    axis.plot(
        runs,
        results,
        linestyle="--",
        linewidth=1.2,
    )

    for run, result in zip(runs, results):
        axis.text(
            run,
            result + 0.06,
            "PASS" if result else "FAIL",
            ha="center",
            va="bottom",
            fontsize=9,
        )

    axis.set_xlabel("Execução")
    axis.set_ylabel("Resultado")

    axis.set_title(
        "DPDnano-Lite HW024_dpd — "
        "Resultado das Execuções"
    )

    axis.set_xticks(runs)
    axis.set_yticks([0, 1])
    axis.set_yticklabels(["FAIL", "PASS"])
    axis.set_ylim(-0.2, 1.25)

    axis.grid(
        True,
        linestyle="--",
        alpha=0.35,
    )

    figure.tight_layout()

    output = (
        output_dir
        / "hw024_dpd_results_by_run.png"
    )

    figure.savefig(
        output,
        dpi=300,
    )

    plt.show()

    print(
        f"Gráfico salvo em: {output.resolve()}"
    )


save_latency()
save_throughput()
save_overflow()
save_results()

print()
print("==============================================")
print("HW024_dpd - GRÁFICOS GERADOS")
print("==============================================")
print("1. Latência por execução")
print("2. Throughput por execução")
print("3. Overflow por execução")
print("4. Resultado PASS/FAIL")
print("==============================================")
