#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from collections import defaultdict
from pathlib import Path

import matplotlib.pyplot as plt

parser = argparse.ArgumentParser()
parser.add_argument("--csv", default="hw021_dpd_sensitivity_curves.csv")
parser.add_argument("--output-prefix", default="hw021_dpd")
args = parser.parse_args()

rows = list(csv.DictReader(Path(args.csv).open("r", encoding="utf-8")))
curves = defaultdict(lambda: {"x": [], "y": [], "d": []})

for row in rows:
    key = (row["family"], round(float(row["coef1"]), 2), round(float(row["coef3"]), 2))
    curves[key]["x"].append(float(row["input_i"]))
    curves[key]["y"].append(float(row["output_i"]))
    curves[key]["d"].append(float(row["delta_from_nominal"]))


def save_family_plot(family_name, value_key, fixed_text, amam_suffix, delta_suffix, title_prefix):
    family_keys = sorted([key for key in curves.keys() if key[0] == family_name], key=lambda key: key[value_key])

    plt.figure(figsize=(10, 7))
    for key in family_keys:
        coef1 = key[1]
        coef3 = key[2]
        label = f"coef1={coef1:.2f}, coef3={coef3:+.2f}"
        plt.plot(curves[key]["x"], curves[key]["y"], linewidth=2.2, label=label)
    plt.xlabel("Componente I de entrada (Q1.15)")
    plt.ylabel("Componente I de saida (Q1.15)")
    plt.title(
        f"DPDnano-Lite HW021_dpd - {title_prefix} AM/AM\n"
        f"{fixed_text}"
    )
    plt.grid(True, linestyle="--", alpha=0.35)
    plt.legend(loc="best")
    plt.tight_layout()
    amam_output = Path(f"{args.output_prefix}_{amam_suffix}.png")
    amam_output.parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(amam_output, dpi=300)
    plt.show()
    print(f"Grafico salvo em: {amam_output.resolve()}")

    plt.figure(figsize=(10, 7))
    for key in family_keys:
        coef1 = key[1]
        coef3 = key[2]
        label = f"coef1={coef1:.2f}, coef3={coef3:+.2f}"
        plt.plot(curves[key]["x"], curves[key]["d"], linewidth=2.2, label=label)
    plt.axhline(0.0, linestyle=":", linewidth=1.4, color="black", label="Curva nominal")
    plt.xlabel("Componente I de entrada (Q1.15)")
    plt.ylabel("Delta de saida em relacao ao nominal (LSB)")
    plt.title(
        f"DPDnano-Lite HW021_dpd - {title_prefix} Delta\n"
        f"{fixed_text}"
    )
    plt.grid(True, linestyle="--", alpha=0.35)
    plt.legend(loc="best")
    plt.tight_layout()
    delta_output = Path(f"{args.output_prefix}_{delta_suffix}.png")
    delta_output.parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(delta_output, dpi=300)
    plt.show()
    print(f"Grafico salvo em: {delta_output.resolve()}")


save_family_plot(
    "coef1",
    1,
    "coef3 = +0,20 | coef1 = +0,68..+0,72",
    "coef1_amam",
    "coef1_delta",
    "Sensibilidade de coef1",
)

save_family_plot(
    "coef3",
    2,
    "coef1 = +0,70 | coef3 = +0,18..+0,22",
    "coef3_amam",
    "coef3_delta",
    "Sensibilidade de coef3",
)
