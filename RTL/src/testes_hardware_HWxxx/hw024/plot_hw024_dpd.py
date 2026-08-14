#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.ticker import ScalarFormatter


def read_rows(path: Path):
    with path.open("r", encoding="utf-8") as csv_file:
        return list(csv.DictReader(csv_file))


parser = argparse.ArgumentParser()
parser.add_argument("--runs-csv", default="hw024_dpd_reproducibility_runs.csv")
args = parser.parse_args()

rows = read_rows(Path(args.runs_csv))
if not rows:
    raise RuntimeError("CSV de execucoes vazio")

runs = [int(row["run"]) for row in rows]
latencies = [float(row["latency_average"]) for row in rows]
throughputs = [float(row["throughput_msps"]) for row in rows]
overflows = [int(row["overflow_events"]) for row in rows]
results = [int(row["passed"]) for row in rows]

plt.figure(figsize=(10, 6))
plt.plot(runs, latencies, marker="o", linewidth=2.4)
plt.xlabel("Execucao")
plt.ylabel("Latencia media (ciclos)")
plt.title(
    "DPDnano-Lite HW024_dpd - Latencia por Execucao\n"
    "coef1 = +0,68..+0,72 | coef3 = +0,38..+0,42 | bitstream dinamico"
)
plt.xticks(runs)
plt.ylim(min(latencies) - 0.5, max(latencies) + 0.5)
plt.grid(True, linestyle="--", alpha=0.35)
plt.tight_layout()
lat_output = Path("hw024_dpd_latency_by_run.png")
plt.savefig(lat_output, dpi=300)
plt.show(block=True)
print(f"Grafico salvo em: {lat_output.resolve()}")

plt.figure(figsize=(10, 6))
plt.plot(runs, throughputs, marker="o", linewidth=2.4)
plt.axhline(60.0, linestyle="--", linewidth=1.4, label="Referencia ideal = 60 MS/s")
plt.xlabel("Execucao")
plt.ylabel("Throughput (MS/s)")
plt.title(
    "DPDnano-Lite HW024_dpd - Throughput por Execucao\n"
    "coef1 = +0,68..+0,72 | coef3 = +0,38..+0,42 | bitstream dinamico"
)
plt.xticks(runs)
margin = max(0.0005, (max(throughputs) - min(throughputs)) * 0.5)
plt.ylim(min(throughputs) - margin, max(throughputs) + margin)
plt.gca().yaxis.set_major_formatter(ScalarFormatter(useOffset=False))
plt.grid(True, linestyle="--", alpha=0.35)
plt.legend(loc="best")
plt.tight_layout()
thr_output = Path("hw024_dpd_throughput_by_run.png")
plt.savefig(thr_output, dpi=300)
plt.show(block=True)
print(f"Grafico salvo em: {thr_output.resolve()}")

plt.figure(figsize=(10, 6))
plt.bar(runs, overflows)
plt.xlabel("Execucao")
plt.ylabel("Eventos de overflow")
plt.title(
    "DPDnano-Lite HW024_dpd - Overflow por Execucao\n"
    "coef1 = +0,68..+0,72 | coef3 = +0,38..+0,42 | bitstream dinamico"
)
plt.xticks(runs)
plt.grid(axis="y", linestyle="--", alpha=0.35)
plt.tight_layout()
ovf_output = Path("hw024_dpd_overflow_by_run.png")
plt.savefig(ovf_output, dpi=300)
plt.show(block=True)
print(f"Grafico salvo em: {ovf_output.resolve()}")

plt.figure(figsize=(10, 5.5))
plt.scatter(runs, results, s=110, marker="o")
plt.plot(runs, results, linestyle="--", linewidth=1.2)
for run, result in zip(runs, results):
    plt.text(run, result + 0.06, "PASS" if result else "FAIL", ha="center", va="bottom", fontsize=9)
plt.xlabel("Execucao")
plt.ylabel("Resultado")
plt.title(
    "DPDnano-Lite HW024_dpd - Resultado das Execucoes\n"
    "coef1 = +0,68..+0,72 | coef3 = +0,38..+0,42 | bitstream dinamico"
)
plt.xticks(runs)
plt.yticks([0, 1], ["FAIL", "PASS"])
plt.ylim(-0.2, 1.25)
plt.grid(True, linestyle="--", alpha=0.35)
plt.tight_layout()
res_output = Path("hw024_dpd_results_by_run.png")
plt.savefig(res_output, dpi=300)
plt.show(block=True)
print(f"Grafico salvo em: {res_output.resolve()}")

print()
print("==============================================")
print("HW024_dpd - GRAFICOS GERADOS")
print("==============================================")
print("1. Latencia por execucao")
print("2. Throughput por execucao")
print("3. Overflow por execucao")
print("4. Resultado PASS/FAIL")
print("==============================================")
