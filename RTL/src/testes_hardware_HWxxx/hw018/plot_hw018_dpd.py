#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from pathlib import Path

import matplotlib.pyplot as plt

parser = argparse.ArgumentParser()
parser.add_argument("--csv", default="hw018_dpd_compression_p1db.csv")
parser.add_argument("--output", default="hw018_dpd_compression_p1db.png")
args = parser.parse_args()

input_values = []
output_values = []

with Path(args.csv).open("r", encoding="utf-8") as csv_file:
    for row in csv.DictReader(csv_file):
        input_values.append(float(row["input_i"]))
        output_values.append(float(row["output_i"]))

plt.figure(figsize=(9, 6))
plt.plot(input_values, output_values, linewidth=2.6, label="Saida medida na FPGA")
plt.plot(
    input_values,
    [0.9 * value for value in input_values],
    color="red",
    linestyle="--",
    linewidth=1.8,
    label="Referencia de pequeno sinal (ganho 0,90)",
)

plt.xlabel("Componente I de entrada (Q1.15)")
plt.ylabel("Componente I de saida (Q1.15)")
plt.title("DPDnano-Lite HW018_dpd - Compressao e P1dB\ncoef1 = +0,90 | coef3 = -0,70")
plt.grid(True, linestyle="--", alpha=0.35)
plt.legend(loc="best")
plt.tight_layout()

output_path = Path(args.output)
output_path.parent.mkdir(parents=True, exist_ok=True)
plt.savefig(output_path, dpi=300)
plt.show()

print(f"Grafico salvo em: {output_path.resolve()}")
