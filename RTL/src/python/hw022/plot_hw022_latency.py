#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from pathlib import Path
import matplotlib.pyplot as plt

parser=argparse.ArgumentParser()

parser.add_argument(
    "--csv",
    default="../../results/hw022/hw022_dpd_temporal_summary.csv",
)

parser.add_argument(
    "--output",
    default="../../results/hw022/hw022_dpd_latency_by_scenario.png",
)

args=parser.parse_args()

scenarios=[]
latencies=[]
jitter=[]

with Path(args.csv).open(
    "r",
    encoding="utf-8",
) as csv_file:
    for row in csv.DictReader(csv_file):
        scenarios.append(row["scenario"])
        latencies.append(float(row["latency_average"]))
        jitter.append(float(row["jitter"]))

plt.figure(figsize=(10,6))
bars=plt.bar(scenarios,latencies)

for bar,value in zip(bars,latencies):
    plt.text(
        bar.get_x()+bar.get_width()/2,
        value+0.05,
        f"{value:.2f}",
        ha="center",
        va="bottom",
    )

plt.xlabel("Cenário de tráfego")
plt.ylabel("Latência média (ciclos)")
plt.title(
    "DPDnano-Lite HW022_dpd — "
    "Latência do Pipeline por Cenário"
)
plt.grid(axis="y",linestyle="--",alpha=.35)
plt.tight_layout()

Path(args.output).parent.mkdir(
    parents=True,
    exist_ok=True,
)

plt.savefig(args.output,dpi=300)
plt.show()

print(f"Gráfico salvo em: {Path(args.output).resolve()}")
