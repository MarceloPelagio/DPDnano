#!/usr/bin/env python3
from __future__ import annotations
import argparse,csv
from collections import defaultdict
from pathlib import Path
import matplotlib.pyplot as plt

p=argparse.ArgumentParser()
p.add_argument(
    "--csv",
    default="../../results/hw020/hw020_dpd_all_curves.csv",
)
p.add_argument(
    "--output",
    default="../../results/hw020/hw020_dpd_representative_curves.png",
)
a=p.parse_args()

selected={
    (0.40,-0.70):("Compressão forte","red"),
    (0.70,0.00):("Referência","green"),
    (0.85,0.35):("Expansão","blue"),
    (1.00,0.70):("Limite superior","black"),
}

curves=defaultdict(lambda:{"x":[],"y":[]})

with Path(a.csv).open("r",encoding="utf-8") as f:
    for row in csv.DictReader(f):
        key=(round(float(row["coef1"]),2),round(float(row["coef3"]),2))
        if key in selected:
            curves[key]["x"].append(float(row["input_i"]))
            curves[key]["y"].append(float(row["output_i"]))

plt.figure(figsize=(10,7))

for key,(label,color) in selected.items():
    plt.plot(
        curves[key]["x"],
        curves[key]["y"],
        linewidth=2.4,
        color=color,
        label=f"{label}: coef1={key[0]:.2f}, coef3={key[1]:+.2f}",
    )

plt.axhline(
    32767,
    linestyle=":",
    linewidth=1.5,
    label="Limite de saturação",
)

plt.xlabel("Componente I de entrada (Q1.15)")
plt.ylabel("Componente I de saída (Q1.15)")
plt.title("DPDnano-Lite HW020_dpd — Curvas Representativas")
plt.grid(True,linestyle="--",alpha=.35)
plt.legend(loc="best")
plt.tight_layout()

Path(a.output).parent.mkdir(parents=True,exist_ok=True)
plt.savefig(a.output,dpi=300)
plt.show()
print(f"Gráfico salvo em: {Path(a.output).resolve()}")
