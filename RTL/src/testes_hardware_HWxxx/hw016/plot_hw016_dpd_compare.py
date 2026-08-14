#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from collections import defaultdict
from pathlib import Path

import matplotlib.pyplot as plt

parser = argparse.ArgumentParser()
parser.add_argument("--csv", default="hw016_dpd_all_profiles.csv")
parser.add_argument("--output", default="hw016_dpd_ampm_comparison.png")
args = parser.parse_args()


def parse_q15_text(value: str) -> float:
    text = str(value).strip()
    if text.lower().startswith("0x"):
        raw = int(text, 16)
        if raw >= 0x8000:
            raw -= 0x10000
        return raw / 32768.0
    return float(text)


profiles = defaultdict(
    lambda: {
        "x": [],
        "y": [],
        "label": "",
        "coef3_im": "",
    }
)

with Path(args.csv).open("r", encoding="utf-8") as csv_file:
    for row in csv.DictReader(csv_file):
        profile = row["profile"]
        profiles[profile]["x"].append(float(row["input_magnitude"]))
        profiles[profile]["y"].append(float(row["phase_shift_deg"]))
        profiles[profile]["label"] = row["profile_label"]
        profiles[profile]["coef3_im"] = row["coef3_im"]

colors = {
    "A": "blue",
    "B": "green",
    "C": "red",
    "D": "black",
}

plt.figure(figsize=(10, 7))

for profile in ("A", "B", "C", "D"):
    data = profiles[profile]
    plt.plot(
        data["x"],
        data["y"],
        color=colors[profile],
        linewidth=2.4,
        label=(
            f"Perfil {profile} - {data['label']} "
            f"(coef3_im={parse_q15_text(data['coef3_im']):+.2f})"
        ),
    )

plt.axhline(
    0,
    linestyle="--",
    linewidth=1.2,
    label="Referencia sem rotacao",
)

plt.xlabel("Magnitude de entrada (Q1.15)")
plt.ylabel("Desvio de fase AM/PM (graus)")
plt.title(
    "DPDnano-Lite HW016_dpd - Comparacao AM/PM\n"
    "coef1 = +0,40 + j0,00 | coef3_re = +0,00"
)
plt.grid(True, linestyle="--", alpha=0.35)
plt.legend(loc="upper left")
plt.tight_layout()
plt.savefig(args.output, dpi=300)
plt.show()

print(f"Grafico salvo em: {Path(args.output).resolve()}")
