#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from pathlib import Path
import matplotlib.pyplot as plt

p=argparse.ArgumentParser()
p.add_argument(
    "--csv",
    default="../../results/hw018/hw018_dpd_compression_p1db.csv",
)
p.add_argument(
    "--output",
    default="../../results/hw018/hw018_dpd_compression_p1db.png",
)
a=p.parse_args()

x=[]
y=[]
compression=[]

with Path(a.csv).open("r",encoding="utf-8") as f:
    for row in csv.DictReader(f):
        x.append(float(row["input_i"]))
        y.append(float(row["output_i"]))
        compression.append(float(row["compression_db"]))

plt.figure(figsize=(9,6))

plt.plot(
    x,
    y,
    linewidth=2.6,
    label="Saída medida na FPGA",
)

plt.plot(
    x,
    [0.9*value for value in x],
    color="red",
    linestyle="--",
    linewidth=1.8,
    label="Referência de pequeno sinal (ganho 0,90)",
)

plt.xlabel("Componente I de entrada (Q1.15)")
plt.ylabel("Componente I de saída (Q1.15)")

plt.title(
    "DPDnano-Lite HW018_dpd — Compressão e P1dB\n"
    "coef1 = +0,90 | coef3 = -0,70"
)

plt.grid(True,linestyle="--",alpha=.35)
plt.legend(loc="best")
plt.tight_layout()

Path(a.output).parent.mkdir(parents=True,exist_ok=True)
plt.savefig(a.output,dpi=300)
plt.show()

print(f"Gráfico salvo em: {Path(a.output).resolve()}")
