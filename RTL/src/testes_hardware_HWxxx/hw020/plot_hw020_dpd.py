#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from collections import defaultdict
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

parser = argparse.ArgumentParser()
parser.add_argument("--summary-csv", default="hw020_dpd_operational_window_summary.csv")
parser.add_argument("--curves-csv", default="hw020_dpd_all_curves.csv")
parser.add_argument("--output-prefix", default="hw020_dpd")
args = parser.parse_args()

summary_rows = []
with Path(args.summary_csv).open("r", encoding="utf-8") as csv_file:
    summary_rows = list(csv.DictReader(csv_file))

coef1_values = sorted({float(row["coef1"]) for row in summary_rows})
coef3_values = sorted({float(row["coef3"]) for row in summary_rows})

status_code = {
    "SEGURO": 0,
    "COMPRESSIVO": 1,
    "EXPANSIVO": 2,
    "SATURADO": 3,
    "OVERFLOW": 4,
    "NAO MONOTONICO": 5,
}

status_map = np.zeros((len(coef3_values), len(coef1_values)))
saturation_map = np.full_like(status_map, np.nan, dtype=float)
peak_map = np.zeros_like(status_map, dtype=float)

for row in summary_rows:
    i = coef3_values.index(float(row["coef3"]))
    j = coef1_values.index(float(row["coef1"]))
    status_map[i, j] = status_code[row["status"]]
    peak_map[i, j] = float(row["peak_output"])
    if row["saturation_input"] not in ("", "None"):
        saturation_map[i, j] = float(row["saturation_input"])


def save_map(data, title, colorbar_label, suffix):
    plt.figure(figsize=(8, 6))
    image = plt.imshow(
        data,
        origin="lower",
        aspect="auto",
        extent=[min(coef1_values), max(coef1_values), min(coef3_values), max(coef3_values)],
    )
    plt.xlabel("Coeficiente linear coef1")
    plt.ylabel("Coeficiente cubico coef3")
    plt.title(title)
    plt.colorbar(image, label=colorbar_label)
    plt.tight_layout()
    output = Path(f"{args.output_prefix}_{suffix}.png")
    output.parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(output, dpi=300)
    plt.show()
    print(f"Grafico salvo em: {output.resolve()}")


save_map(
    status_map,
    "DPDnano-Lite HW020_dpd - Classificacao da Janela Operacional\n"
    "coef1 = +0,40..+1,00 | coef3 = -0,70..+0,70",
    "0 Seguro | 1 Compressivo | 2 Expansivo | 3 Saturado | 4 Overflow | 5 Nao monot.",
    "status_map",
)

save_map(
    peak_map,
    "DPDnano-Lite HW020_dpd - Valor Maximo da Saida\n"
    "coef1 = +0,40..+1,00 | coef3 = -0,70..+0,70",
    "Saida maxima (LSB)",
    "peak_output_map",
)

save_map(
    saturation_map,
    "DPDnano-Lite HW020_dpd - Entrada no Inicio da Saturacao\n"
    "coef1 = +0,40..+1,00 | coef3 = -0,70..+0,70",
    "Entrada de saturacao (LSB)",
    "saturation_map",
)

selected = {
    (0.40, -0.70): ("Compressao forte", "red"),
    (0.70, 0.00): ("Referencia", "green"),
    (0.85, 0.35): ("Expansao", "blue"),
    (1.00, 0.70): ("Limite superior", "black"),
}

curves = defaultdict(lambda: {"x": [], "y": []})
with Path(args.curves_csv).open("r", encoding="utf-8") as csv_file:
    for row in csv.DictReader(csv_file):
        key = (round(float(row["coef1"]), 2), round(float(row["coef3"]), 2))
        if key in selected:
            curves[key]["x"].append(float(row["input_i"]))
            curves[key]["y"].append(float(row["output_i"]))

plt.figure(figsize=(10, 7))
for key, (label, color) in selected.items():
    plt.plot(
        curves[key]["x"],
        curves[key]["y"],
        linewidth=2.4,
        color=color,
        label=f"{label}: coef1={key[0]:.2f}, coef3={key[1]:+.2f}",
    )

plt.axhline(32767, linestyle=":", linewidth=1.5, label="Limite de saturacao")
plt.xlabel("Componente I de entrada (Q1.15)")
plt.ylabel("Componente I de saida (Q1.15)")
plt.title(
    "DPDnano-Lite HW020_dpd - Curvas Representativas\n"
    "coef1 = +0,40..+1,00 | coef3 = -0,70..+0,70"
)
plt.grid(True, linestyle="--", alpha=0.35)
plt.legend(loc="best")
plt.tight_layout()

curves_output = Path(f"{args.output_prefix}_representative_curves.png")
curves_output.parent.mkdir(parents=True, exist_ok=True)
plt.savefig(curves_output, dpi=300)
plt.show()
print(f"Grafico salvo em: {curves_output.resolve()}")
