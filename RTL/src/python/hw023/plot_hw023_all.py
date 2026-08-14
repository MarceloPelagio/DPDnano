#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.ticker import ScalarFormatter


CLOCK_HZ = 100_000_000


def read_single_row_csv(path: Path) -> dict[str, str]:
    with path.open("r", encoding="utf-8") as csv_file:
        rows = list(csv.DictReader(csv_file))

    if len(rows) != 1:
        raise RuntimeError(
            f"O arquivo {path} deve conter exatamente uma linha de dados."
        )

    return rows[0]


def read_checkpoint_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8") as csv_file:
        rows = list(csv.DictReader(csv_file))

    if not rows:
        raise RuntimeError(
            f"O arquivo {path} não contém checkpoints."
        )

    return rows


def save_latency_graph(
    summary: dict[str, str],
    checkpoints: list[dict[str, str]],
    output_path: Path,
) -> None:
    samples = [
        int(row["samples"])
        for row in checkpoints
    ]

    latency_average = float(
        summary["latency_average"]
    )

    latency_values = [
        latency_average
        for _ in samples
    ]

    latency_min = float(
        summary["latency_min"]
    )

    latency_max = float(
        summary["latency_max"]
    )

    figure, axis = plt.subplots(
        figsize=(10, 6)
    )

    axis.plot(
        samples,
        latency_values,
        marker="o",
        linewidth=2.4,
        label="Latência média medida",
    )

    axis.axhline(
        latency_min,
        linestyle="--",
        linewidth=1.4,
        label=f"Latência mínima = {latency_min:.0f} ciclos",
    )

    axis.axhline(
        latency_max,
        linestyle=":",
        linewidth=1.4,
        label=f"Latência máxima = {latency_max:.0f} ciclos",
    )

    axis.set_xlabel(
        "Amostras processadas"
    )

    axis.set_ylabel(
        "Latência (ciclos)"
    )

    axis.set_title(
        "DPDnano-Lite HW023_dpd — "
        "Estabilidade da Latência"
    )

    axis.set_ylim(
        latency_average - 0.5,
        latency_average + 0.5,
    )

    axis.grid(
        True,
        linestyle="--",
        alpha=0.35,
    )

    axis.legend(
        loc="best"
    )

    axis.ticklabel_format(
        axis="x",
        style="plain",
    )

    figure.tight_layout()

    output_path.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    figure.savefig(
        output_path,
        dpi=300,
    )

    plt.show()

    print(
        f"Gráfico salvo em: {output_path.resolve()}"
    )


def save_instantaneous_throughput_graph(
    checkpoints: list[dict[str, str]],
    output_path: Path,
) -> None:
    sample_marks = [
        int(row["samples"])
        for row in checkpoints
    ]

    checkpoint_cycles = [
        int(row["cycle"])
        for row in checkpoints
    ]

    block_samples = []
    block_throughput_msps = []

    previous_samples = 0
    previous_cycles = 0

    for samples, cycles in zip(
        sample_marks,
        checkpoint_cycles,
    ):
        delta_samples = (
            samples - previous_samples
        )

        delta_cycles = (
            cycles - previous_cycles
        )

        if delta_cycles <= 0:
            raise RuntimeError(
                "Os ciclos dos checkpoints não são crescentes."
            )

        throughput = (
            delta_samples
            * CLOCK_HZ
            / delta_cycles
            / 1e6
        )

        block_samples.append(samples)
        block_throughput_msps.append(
            throughput
        )

        previous_samples = samples
        previous_cycles = cycles

    figure, axis = plt.subplots(
        figsize=(10, 6)
    )

    axis.plot(
        block_samples,
        block_throughput_msps,
        marker="o",
        linewidth=2.4,
        label="Throughput por bloco de 100.000 amostras",
    )

    axis.axhline(
        100.0,
        linestyle="--",
        linewidth=1.4,
        label="Referência ideal = 100 MS/s",
    )

    axis.set_xlabel(
        "Amostras processadas"
    )

    axis.set_ylabel(
        "Throughput do bloco (MS/s)"
    )

    axis.set_title(
        "DPDnano-Lite HW023_dpd — "
        "Throughput Instantâneo por Bloco"
    )

    minimum = min(
        block_throughput_msps
    )

    maximum = max(
        block_throughput_msps
    )

    margin = max(
        0.0005,
        (maximum - minimum) * 0.5,
    )

    axis.set_ylim(
        minimum - margin,
        maximum + margin,
    )

    axis.grid(
        True,
        linestyle="--",
        alpha=0.35,
    )

    axis.legend(
        loc="best"
    )

    axis.ticklabel_format(
        axis="x",
        style="plain",
    )

    axis.yaxis.set_major_formatter(
        ScalarFormatter(
            useOffset=False
        )
    )

    figure.tight_layout()

    output_path.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    figure.savefig(
        output_path,
        dpi=300,
    )

    plt.show()

    print(
        f"Gráfico salvo em: {output_path.resolve()}"
    )


def save_checkpoint_integrity_graph(
    summary: dict[str, str],
    checkpoints: list[dict[str, str]],
    output_path: Path,
) -> None:
    samples = [
        int(row["samples"])
        for row in checkpoints
    ]

    integrity_ok = (
        int(summary["fifo_errors"]) == 0
        and int(summary["losses"]) == 0
        and int(summary["duplicates"]) == 0
        and int(summary["reorder"]) == 0
        and int(summary["jitter"]) == 0
    )

    checkpoint_status = [
        1 if integrity_ok else 0
        for _ in samples
    ]

    figure, axis = plt.subplots(
        figsize=(10, 5.5)
    )

    axis.scatter(
        samples,
        checkpoint_status,
        s=95,
        marker="o",
        label="Checkpoint aprovado",
    )

    axis.plot(
        samples,
        checkpoint_status,
        linestyle="--",
        linewidth=1.2,
    )

    for samples_value, status in zip(
        samples,
        checkpoint_status,
    ):
        axis.text(
            samples_value,
            status + 0.06,
            "PASS" if status else "FAIL",
            ha="center",
            va="bottom",
            fontsize=9,
        )

    axis.set_xlabel(
        "Amostras processadas"
    )

    axis.set_ylabel(
        "Integridade do processamento"
    )

    axis.set_title(
        "DPDnano-Lite HW023_dpd — "
        "Checkpoints de Integridade"
    )

    axis.set_yticks(
        [0, 1]
    )

    axis.set_yticklabels(
        ["FAIL", "PASS"]
    )

    axis.set_ylim(
        -0.2,
        1.25,
    )

    axis.grid(
        True,
        linestyle="--",
        alpha=0.35,
    )

    axis.legend(
        loc="lower right"
    )

    axis.ticklabel_format(
        axis="x",
        style="plain",
    )

    figure.tight_layout()

    output_path.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    figure.savefig(
        output_path,
        dpi=300,
    )

    plt.show()

    print(
        f"Gráfico salvo em: {output_path.resolve()}"
    )


parser = argparse.ArgumentParser(
    description=(
        "Gera os três gráficos finais do HW023_dpd."
    )
)

parser.add_argument(
    "--summary",
    default=(
        "../../results/hw023/"
        "hw023_dpd_stress_summary.csv"
    ),
)

parser.add_argument(
    "--checkpoints",
    default=(
        "../../results/hw023/"
        "hw023_dpd_checkpoints.csv"
    ),
)

parser.add_argument(
    "--output-dir",
    default="../../results/hw023",
)

args = parser.parse_args()

summary_path = Path(
    args.summary
)

checkpoint_path = Path(
    args.checkpoints
)

output_dir = Path(
    args.output_dir
)

summary = read_single_row_csv(
    summary_path
)

checkpoints = read_checkpoint_csv(
    checkpoint_path
)

save_latency_graph(
    summary,
    checkpoints,
    output_dir
    / "hw023_dpd_latency_stability.png",
)

save_instantaneous_throughput_graph(
    checkpoints,
    output_dir
    / "hw023_dpd_instantaneous_throughput.png",
)

save_checkpoint_integrity_graph(
    summary,
    checkpoints,
    output_dir
    / "hw023_dpd_integrity_checkpoints.png",
)

print()
print("==============================================")
print("HW023_dpd - GRÁFICOS GERADOS")
print("==============================================")
print("1. Estabilidade da latência")
print("2. Throughput instantâneo por bloco")
print("3. Checkpoints de integridade")
print("==============================================")
