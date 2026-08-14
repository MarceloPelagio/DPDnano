#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from pathlib import Path
import matplotlib.pyplot as plt

parser=argparse.ArgumentParser()

parser.add_argument(
    "--csv",
    default="../../results/hw022/hw022_dpd_timeline.csv",
)

parser.add_argument(
    "--scenario",
    default="burst",
)

parser.add_argument(
    "--output",
    default="../../results/hw022/hw022_dpd_timeline_burst.png",
)

args=parser.parse_args()

sample=[]
input_cycle=[]
output_cycle=[]

with Path(args.csv).open(
    "r",
    encoding="utf-8",
) as csv_file:
    for row in csv.DictReader(csv_file):
        if row["scenario"]!=args.scenario:
            continue

        sample.append(int(row["sample_index"]))
        input_cycle.append(int(row["input_cycle"]))
        output_cycle.append(int(row["output_cycle"]))

plt.figure(figsize=(11,6))

plt.scatter(
    input_cycle,
    sample,
    marker="o",
    label="Entrada",
)

plt.scatter(
    output_cycle,
    sample,
    marker="x",
    label="Saída",
)

for index,(x_in,x_out,y) in enumerate(
    zip(input_cycle,output_cycle,sample)
):
    if index<16:
        plt.plot(
            [x_in,x_out],
            [y,y],
            linestyle=":",
            linewidth=1,
        )

plt.xlabel("Ciclo de clock")
plt.ylabel("Índice da amostra")
plt.title(
    f"DPDnano-Lite HW022_dpd — Timeline ({args.scenario})"
)
plt.grid(True,linestyle="--",alpha=.35)
plt.legend(loc="best")
plt.tight_layout()

Path(args.output).parent.mkdir(
    parents=True,
    exist_ok=True,
)

plt.savefig(args.output,dpi=300)
plt.show()

print(f"Gráfico salvo em: {Path(args.output).resolve()}")
