#!/usr/bin/env python3

import argparse
import csv
from pathlib import Path

import matplotlib.pyplot as plt

parser = argparse.ArgumentParser()
parser.add_argument("--csv", default="hw017_dpd_saturation_compression.csv")
parser.add_argument("--output", default="hw017_dpd_saturation_compression.png")
args = parser.parse_args()

input_values = []
output_values = []
saturation_flags = []
delta_linear_values = []

with Path(args.csv).open("r", encoding="utf-8") as csv_file:
    for row in csv.DictReader(csv_file):
        input_values.append(float(row["input_i"]))
        output_values.append(float(row["output_i"]))
        saturation_flags.append(int(row["saturated"]))
        delta_linear_values.append(float(row.get("delta_linear", row["output_i"]) ) - float(row["input_i"]) if "delta_linear" not in row else float(row["delta_linear"]))

plt.figure(figsize=(9, 6))
plt.plot(input_values, output_values, linewidth=2.6, label="Saida medida na FPGA")
plt.plot([0, 32767], [0, 32767], color="red", linestyle="--", linewidth=1.8, label="Referencia linear y = x")
plt.axhline(32767, color="black", linestyle=":", linewidth=1.6, label="Limite +32767")

saturation_x = [x for x, flag in zip(input_values, saturation_flags) if flag]
saturation_y = [y for y, flag in zip(output_values, saturation_flags) if flag]
if saturation_x:
    plt.scatter(saturation_x, saturation_y, marker="x", s=30, label="Amostras saturadas")

crossing_x = None
crossing_y = None
previous_delta = None
for x_value, y_value, delta_value in zip(input_values, output_values, delta_linear_values):
    if previous_delta is not None and previous_delta < 0 <= delta_value:
        crossing_x = x_value
        crossing_y = y_value
        break
    previous_delta = delta_value

if crossing_x is not None:
    plt.scatter([crossing_x], [crossing_y], color="darkgreen", s=55, zorder=5, label="Cruzamento com y = x")

plt.xlabel("Componente I de entrada (Q1.15)")
plt.ylabel("Componente I de saida (Q1.15)")
plt.title("DPDnano-Lite HW017_dpd - Saturacao e Compressao\ncoef1 = +0,80 | coef3 = +0,80")
plt.grid(True, linestyle="--", alpha=0.35)
plt.legend(loc="upper left")
plt.tight_layout()

output_path = Path(args.output)
output_path.parent.mkdir(parents=True, exist_ok=True)
plt.savefig(output_path, dpi=300)
plt.show()

print(f"Grafico salvo em: {output_path.resolve()}")
