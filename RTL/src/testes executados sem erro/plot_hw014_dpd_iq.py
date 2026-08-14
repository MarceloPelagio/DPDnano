#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from pathlib import Path

import matplotlib.pyplot as plt

parser = argparse.ArgumentParser()

parser.add_argument(
    "--csv",
    default="hw014_dpd_am_pm_complex.csv",
)

parser.add_argument(
    "--output",
    default="hw014_dpd_iq_plane.png",
)

args = parser.parse_args()

input_i = []
input_q = []
output_i = []
output_q = []

with Path(args.csv).open(
    "r",
    encoding="utf-8",
) as csv_file:
    for row in csv.DictReader(csv_file):
        input_i.append(float(row["input_i"]))
        input_q.append(float(row["input_q"]))
        output_i.append(float(row["output_i"]))
        output_q.append(float(row["output_q"]))

plt.figure(figsize=(8, 8))

plt.scatter(
    input_i,
    input_q,
    marker="o",
    s=18,
    label="Entrada I/Q",
)

plt.scatter(
    output_i,
    output_q,
    marker="x",
    s=22,
    label="Saída I/Q",
)

plt.axhline(
    0.0,
    color="red",
    linestyle="--",
    linewidth=1.0,
)

plt.axvline(
    0.0,
    color="red",
    linestyle="--",
    linewidth=1.0,
)

plt.xlabel("Componente I")
plt.ylabel("Componente Q")

plt.title(
    "DPDnano-Lite HW014_dpd - Plano Complexo I/Q\n"
    "Rotação controlada por coeficientes complexos"
)

plt.grid(
    True,
    linestyle="--",
    alpha=0.35,
)

plt.axis("equal")
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
