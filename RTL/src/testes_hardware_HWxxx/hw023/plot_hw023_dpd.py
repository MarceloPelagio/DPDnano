#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.ticker import ScalarFormatter

parser = argparse.ArgumentParser(description="Gera os graficos finais do HW023_dpd.")
parser.add_argument("--summary-csv", default="hw023_dpd_stress_summary.csv")
parser.add_argument("--checkpoints-csv", default="hw023_dpd_checkpoints.csv")
args = parser.parse_args()

summary_rows = list(csv.DictReader(Path(args.summary_csv).open("r", encoding="utf-8")))
if len(summary_rows) != 1:
    raise RuntimeError("O resumo do HW023 deve conter exatamente uma linha.")
summary = summary_rows[0]

checkpoints = list(csv.DictReader(Path(args.checkpoints_csv).open("r", encoding="utf-8")))
if not checkpoints:
    raise RuntimeError("O arquivo de checkpoints do HW023 esta vazio.")

samples = [int(row["samples"]) for row in checkpoints]
cycles = [int(row["cycle"]) for row in checkpoints]
latency_average = float(summary["latency_average"])
latency_min = float(summary["latency_min"])
latency_max = float(summary["latency_max"])

plt.figure(figsize=(10, 6))
plt.plot(samples, [latency_average for _ in samples], marker="o", linewidth=2.4, label="Latencia media medida")
plt.axhline(latency_min, linestyle="--", linewidth=1.4, label=f"Latencia minima = {latency_min:.0f} ciclos")
plt.axhline(latency_max, linestyle=":", linewidth=1.4, label=f"Latencia maxima = {latency_max:.0f} ciclos")
plt.xlabel("Amostras processadas")
plt.ylabel("Latencia (ciclos)")
plt.title(
    "DPDnano-Lite HW023_dpd - Estabilidade da Latencia\n"
    "coef1 = +0,68..+0,72 | coef3 = +0,38..+0,42 | 5 perfis dinamicos"
)
plt.ylim(latency_average - 0.5, latency_average + 0.5)
plt.grid(True, linestyle="--", alpha=0.35)
plt.legend(loc="best")
plt.ticklabel_format(axis="x", style="plain")
plt.tight_layout()
latency_output = Path("hw023_dpd_latency_stability.png")
plt.savefig(latency_output, dpi=300)
plt.show(block=True)
print(f"Grafico salvo em: {latency_output.resolve()}")

block_throughput_msps = []
previous_samples = 0
previous_cycles = 0
for sample_mark, cycle_mark in zip(samples, cycles):
    delta_samples = sample_mark - previous_samples
    delta_cycles = cycle_mark - previous_cycles
    throughput = delta_samples * 60_000_000 / delta_cycles / 1e6
    block_throughput_msps.append(throughput)
    previous_samples = sample_mark
    previous_cycles = cycle_mark

plt.figure(figsize=(10, 6))
plt.plot(samples, block_throughput_msps, marker="o", linewidth=2.4, label="Throughput por bloco de 100.000 amostras")
plt.axhline(60.0, linestyle="--", linewidth=1.4, label="Referencia ideal = 60 MS/s")
plt.xlabel("Amostras processadas")
plt.ylabel("Throughput do bloco (MS/s)")
plt.title(
    "DPDnano-Lite HW023_dpd - Throughput Instantaneo por Bloco\n"
    "coef1 = +0,68..+0,72 | coef3 = +0,38..+0,42 | 5 perfis dinamicos"
)
minimum = min(block_throughput_msps)
maximum = max(block_throughput_msps)
margin = max(0.0005, (maximum - minimum) * 0.5)
plt.ylim(minimum - margin, maximum + margin)
plt.grid(True, linestyle="--", alpha=0.35)
plt.legend(loc="best")
plt.ticklabel_format(axis="x", style="plain")
plt.gca().yaxis.set_major_formatter(ScalarFormatter(useOffset=False))
plt.tight_layout()
throughput_output = Path("hw023_dpd_instantaneous_throughput.png")
plt.savefig(throughput_output, dpi=300)
plt.show(block=True)
print(f"Grafico salvo em: {throughput_output.resolve()}")

integrity_ok = (
    int(summary["fifo_errors"]) == 0
    and int(summary["losses"]) == 0
    and int(summary["duplicates"]) == 0
    and int(summary["reorder"]) == 0
    and int(summary["jitter"]) == 0
)
checkpoint_status = [1 if integrity_ok else 0 for _ in samples]

plt.figure(figsize=(10, 5.5))
plt.scatter(samples, checkpoint_status, s=95, marker="o", label="Checkpoint aprovado")
plt.plot(samples, checkpoint_status, linestyle="--", linewidth=1.2)
for sample_mark, status in zip(samples, checkpoint_status):
    plt.text(sample_mark, status + 0.06, "PASS" if status else "FAIL", ha="center", va="bottom", fontsize=9)
plt.xlabel("Amostras processadas")
plt.ylabel("Integridade do processamento")
plt.title(
    "DPDnano-Lite HW023_dpd - Checkpoints de Integridade\n"
    "coef1 = +0,68..+0,72 | coef3 = +0,38..+0,42 | 5 perfis dinamicos"
)
plt.yticks([0, 1], ["FAIL", "PASS"])
plt.ylim(-0.2, 1.25)
plt.grid(True, linestyle="--", alpha=0.35)
plt.legend(loc="lower right")
plt.ticklabel_format(axis="x", style="plain")
plt.tight_layout()
integrity_output = Path("hw023_dpd_integrity_checkpoints.png")
plt.savefig(integrity_output, dpi=300)
plt.show(block=True)
print(f"Grafico salvo em: {integrity_output.resolve()}")
