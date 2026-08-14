#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from pathlib import Path

import matplotlib.pyplot as plt

parser = argparse.ArgumentParser()

parser.add_argument(
    "--csv",
    default="../../results/hw019/hw019_dpd_incremental_gain.csv",
)

parser.add_argument(
    "--output",
    default="../../results/hw019/hw019_dpd_incremental_gain.png",
)

args = parser.parse_args()

input_i = []
incremental_gain = []
static_gain = []

with Path(args.csv).open(
    "r",
    encoding="utf-8",
) as csv_file:
    for row in csv.DictReader(csv_file):
        input_i.append(
            float(row["input_i"])
        )

        incremental_gain.append(
            float(row["incremental_gain"])
        )

        static_gain.append(
            float(row["static_gain"])
        )

zero_crossing_input = None

for previous_index in range(
    len(incremental_gain) - 1
):
    current_index = previous_index + 1

    if (
        incremental_gain[previous_index] > 0
        and incremental_gain[current_index] <= 0
    ):
        zero_crossing_input = input_i[current_index]
        break

plt.figure(figsize=(9, 6))

plt.plot(
    input_i,
    incremental_gain,
    linewidth=2.6,
    label="Ganho incremental dOUT/dIN",
)

plt.plot(
    input_i,
    static_gain,
    color="red",
    linestyle="--",
    linewidth=1.8,
    label="Ganho estático OUT/IN",
)

plt.axhline(
    0.0,
    color="black",
    linestyle=":",
    linewidth=1.5,
    label="Ganho incremental nulo",
)

if zero_crossing_input is not None:
    plt.axvline(
        zero_crossing_input,
        linestyle="--",
        linewidth=1.4,
        label=(
            "Pico de saída / cruzamento por zero "
            f"≈ {zero_crossing_input:.0f}"
        ),
    )

plt.xlabel(
    "Componente I de entrada (Q1.15)"
)

plt.ylabel(
    "Ganho"
)

plt.title(
    "DPDnano-Lite HW019_dpd — Ganho Incremental\n"
    "Derivado dos resultados experimentais do HW018"
)

plt.grid(
    True,
    linestyle="--",
    alpha=0.35,
)

plt.legend(
    loc="best",
)

plt.tight_layout()

Path(args.output).parent.mkdir(
    parents=True,
    exist_ok=True,
)

plt.savefig(
    args.output,
    dpi=300,
)

plt.show()

print(
    f"Gráfico salvo em: "
    f"{Path(args.output).resolve()}"
)
