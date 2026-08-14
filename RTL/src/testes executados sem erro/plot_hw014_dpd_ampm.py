#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from collections import defaultdict
from pathlib import Path

import matplotlib.pyplot as plt

parser = argparse.ArgumentParser()

parser.add_argument(
    "--csv",
    default="hw014_dpd_am_pm_complex.csv",
)

parser.add_argument(
    "--output",
    default="hw014_dpd_am_pm.png",
)

args = parser.parse_args()

phase_values = defaultdict(list)

with Path(args.csv).open(
    "r",
    encoding="utf-8",
) as csv_file:
    for row in csv.DictReader(csv_file):
        phase_values[
            float(row["requested_amplitude"])
        ].append(
            float(row["phase_shift_deg"])
        )

amplitudes = sorted(phase_values)

average_phase_shift = [
    sum(phase_values[amplitude])
    / len(phase_values[amplitude])
    for amplitude in amplitudes
]

plt.figure(figsize=(9, 6))

plt.plot(
    amplitudes,
    average_phase_shift,
    linewidth=2.5,
    marker="o",
    markersize=4,
    label="Desvio de fase medido na FPGA",
)

plt.axhline(
    0.0,
    color="red",
    linestyle="--",
    linewidth=1.8,
    label="Referência sem rotação",
)

plt.xlabel("Magnitude de entrada (Q1.15)")
plt.ylabel("Desvio de fase AM/PM (graus)")

plt.title(
    "DPDnano-Lite HW014_dpd - Validação da Multiplicação Complexa\n"
    "coef1 = 0x3333 + j0x0000 | "
    "coef3 = 0x4666 + j0x199A"
)

plt.grid(
    True,
    linestyle="--",
    alpha=0.35,
)

plt.legend(loc="best")
plt.tight_layout()

plt.savefig(
    args.output,
    dpi=300,
)

plt.show()

print(
    f"Gráfico salvo em: "
    f"{Path(args.output).resolve()}"
)
