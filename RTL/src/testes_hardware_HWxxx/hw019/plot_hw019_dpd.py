#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from pathlib import Path

import matplotlib.pyplot as plt


def load_base_rows(path: Path):
    input_i = []
    output_i = []
    with path.open("r", encoding="utf-8") as csv_file:
        for row in csv.DictReader(csv_file):
            input_i.append(float(row["input_i"]))
            output_i.append(float(row["output_i"]))
    return input_i, output_i


def load_incremental_rows(path: Path):
    input_i = []
    incremental_gain = []
    static_gain = []
    with path.open("r", encoding="utf-8") as csv_file:
        for row in csv.DictReader(csv_file):
            input_i.append(float(row["input_i"]))
            incremental_gain.append(float(row["incremental_gain"]))
            static_gain.append(float(row["static_gain"]))
    return input_i, incremental_gain, static_gain


parser = argparse.ArgumentParser()
parser.add_argument("--base-csv", default="hw019_dpd_compression_base.csv")
parser.add_argument("--incremental-csv", default="hw019_dpd_incremental_gain.csv")
parser.add_argument("--base-output", default="hw019_dpd_compression_base.png")
parser.add_argument("--incremental-output", default="hw019_dpd_incremental_gain.png")
args = parser.parse_args()

base_csv_path = Path(args.base_csv)
incremental_csv_path = Path(args.incremental_csv)

base_input_i, base_output_i = load_base_rows(base_csv_path)
inc_input_i, incremental_gain, static_gain = load_incremental_rows(incremental_csv_path)

zero_crossing_input = None
for previous_index in range(len(incremental_gain) - 1):
    current_index = previous_index + 1
    if incremental_gain[previous_index] > 0 and incremental_gain[current_index] <= 0:
        zero_crossing_input = inc_input_i[current_index]
        break

# Figura 1: curva base AM/AM
plt.figure(figsize=(9, 6))
plt.plot(base_input_i, base_output_i, linewidth=2.6, label="Saida medida na FPGA")
plt.plot(
    base_input_i,
    [0.9 * value for value in base_input_i],
    color="red",
    linestyle="--",
    linewidth=1.8,
    label="Referencia de pequeno sinal (ganho 0,90)",
)
plt.xlabel("Componente I de entrada (Q1.15)")
plt.ylabel("Componente I de saida (Q1.15)")
plt.title(
    "DPDnano-Lite HW019_dpd - Curva Base AM/AM\n"
    "coef1 = +0,90 | coef3 = -0,70"
)
plt.grid(True, linestyle="--", alpha=0.35)
plt.legend(loc="best")
plt.tight_layout()

base_output_path = Path(args.base_output)
base_output_path.parent.mkdir(parents=True, exist_ok=True)
plt.savefig(base_output_path, dpi=300)
plt.show()
print(f"Grafico salvo em: {base_output_path.resolve()}")

# Figura 2: ganho incremental
plt.figure(figsize=(9, 6))
plt.plot(inc_input_i, incremental_gain, linewidth=2.6, label="Ganho incremental dOUT/dIN")
plt.plot(
    inc_input_i,
    static_gain,
    color="red",
    linestyle="--",
    linewidth=1.8,
    label="Ganho estatico OUT/IN",
)
plt.axhline(0.0, color="black", linestyle=":", linewidth=1.5, label="Ganho incremental nulo")

if zero_crossing_input is not None:
    plt.axvline(
        zero_crossing_input,
        linestyle="--",
        linewidth=1.4,
        label=f"Cruzamento por zero ~ {zero_crossing_input:.0f}",
    )

plt.xlabel("Componente I de entrada (Q1.15)")
plt.ylabel("Ganho")
plt.title(
    "DPDnano-Lite HW019_dpd - Ganho Incremental\n"
    "coef1 = +0,90 | coef3 = -0,70"
)
plt.grid(True, linestyle="--", alpha=0.35)
plt.legend(loc="best")
plt.tight_layout()

incremental_output_path = Path(args.incremental_output)
incremental_output_path.parent.mkdir(parents=True, exist_ok=True)
plt.savefig(incremental_output_path, dpi=300)
plt.show()
print(f"Grafico salvo em: {incremental_output_path.resolve()}")
