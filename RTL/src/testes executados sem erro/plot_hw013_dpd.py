#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from pathlib import Path
import matplotlib.pyplot as plt

parser = argparse.ArgumentParser()
parser.add_argument(
    "--csv",
    default="hw013_dpd_saturation_overflow.csv",
)
parser.add_argument(
    "--output",
    default="hw013_dpd_saturation_overflow.png",
)
args = parser.parse_args()

input_i = []
output_i = []

with Path(args.csv).open("r", encoding="utf-8") as csv_file:
    for row in csv.DictReader(csv_file):
        input_i.append(float(row["input_i"]))
        output_i.append(float(row["output_i"]))

plt.figure(figsize=(9, 6))

plt.plot(
    input_i,
    output_i,
    linewidth=2.5,
    marker=".",
    markersize=4,
    label="Saída medida na FPGA",
)

plt.plot(
    [-32768, 32767],
    [-32768, 32767],
    color="red",
    linestyle="--",
    linewidth=1.8,
    label="Referência linear y = x",
)

plt.axhline(
    32767,
    linestyle=":",
    linewidth=1.5,
    label="Limite positivo +32767",
)

plt.axhline(
    -32768,
    linestyle=":",
    linewidth=1.5,
    label="Limite negativo -32768",
)

plt.xlabel("Componente I de entrada (Q1.15)")
plt.ylabel("Componente I de saída (Q1.15)")
plt.title(
    "DPDnano-Lite HW013_dpd - Saturação e Overflow\n"
    "coef1 = 0x3333 (0,40) | coef3 = 0x5333 (0,65)"
)
plt.grid(True, linestyle="--", alpha=0.35)
plt.legend(loc="upper left")
plt.xlim(-34000, 34000)
plt.ylim(-35000, 35000)
plt.tight_layout()
plt.savefig(args.output, dpi=300)
plt.show()

print(f"Gráfico salvo em: {Path(args.output).resolve()}")
