#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from pathlib import Path

import matplotlib.pyplot as plt

parser = argparse.ArgumentParser()
parser.add_argument("--summary-csv", default="hw022_dpd_temporal_summary.csv")
parser.add_argument("--timeline-csv", default="hw022_dpd_timeline.csv")
parser.add_argument("--timeline-scenario", default="burst")
args = parser.parse_args()

summary_csv = Path(args.summary_csv)
timeline_csv = Path(args.timeline_csv)

scenarios = []
latencies = []
jitter = []

with summary_csv.open("r", encoding="utf-8") as csv_file:
    for row in csv.DictReader(csv_file):
        scenarios.append(row["scenario"])
        latencies.append(float(row["latency_average"]))
        jitter.append(float(row["jitter"]))

plt.figure(figsize=(10, 7))
bars = plt.bar(scenarios, latencies, color="#4C78A8")

for bar, lat, jit in zip(bars, latencies, jitter):
    plt.text(
        bar.get_x() + bar.get_width() / 2,
        lat + 0.05,
        f"J={jit:.0f}",
        ha="center",
        va="bottom",
        fontsize=9,
    )

plt.xlabel("Cenario de trafego")
plt.ylabel("Latencia media (ciclos)")
plt.title(
    "DPDnano-Lite HW022_dpd - Latencia por cenario\n"
    "Nucleo rtl_v3_1 | PLL 60 MHz | coef1 = +0,75 | coef3 = +0,125"
)
plt.grid(axis="y", linestyle="--", alpha=0.35)
plt.tight_layout()
latency_output = Path("hw022_dpd_latency_by_scenario.png")
latency_output.parent.mkdir(parents=True, exist_ok=True)
plt.savefig(latency_output, dpi=300)
plt.show(block=True)
print(f"Grafico salvo em: {latency_output.resolve()}")

sample = []
input_cycle = []
output_cycle = []

with timeline_csv.open("r", encoding="utf-8") as csv_file:
    for row in csv.DictReader(csv_file):
        if row["scenario"] != args.timeline_scenario:
            continue
        sample.append(int(row["sample_index"]))
        input_cycle.append(int(row["input_cycle"]))
        output_cycle.append(int(row["output_cycle"]))

plt.figure(figsize=(11, 6))
plt.scatter(input_cycle, sample, marker="o", label="Entrada", color="#1F77B4")
plt.scatter(output_cycle, sample, marker="x", label="Saida", color="#D62728")

for index, (x_in, x_out, y) in enumerate(zip(input_cycle, output_cycle, sample)):
    if index < 16:
        plt.plot(
            [x_in, x_out],
            [y, y],
            linestyle=":",
            linewidth=1,
            color="#7F7F7F",
        )

plt.xlabel("Ciclo de clock")
plt.ylabel("Indice da amostra")
plt.title(
    f"DPDnano-Lite HW022_dpd - Timeline do cenario {args.timeline_scenario}\n"
    "Nucleo rtl_v3_1 | PLL 60 MHz | coef1 = +0,75 | coef3 = +0,125"
)
plt.grid(True, linestyle="--", alpha=0.35)
plt.legend(loc="best")
plt.tight_layout()
timeline_output = Path(f"hw022_dpd_timeline_{args.timeline_scenario}.png")
timeline_output.parent.mkdir(parents=True, exist_ok=True)
plt.savefig(timeline_output, dpi=300)
plt.show(block=True)
print(f"Grafico salvo em: {timeline_output.resolve()}")
