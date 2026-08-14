#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from collections import defaultdict
from pathlib import Path

import matplotlib.pyplot as plt

parser=argparse.ArgumentParser()

parser.add_argument(
    "--csv",
    default="../../results/hw021/hw021_dpd_sensitivity_curves.csv",
)

parser.add_argument(
    "--output-amam",
    default="../../results/hw021/hw021_dpd_coef1_amam.png",
)

parser.add_argument(
    "--output-delta",
    default="../../results/hw021/hw021_dpd_coef1_delta.png",
)

args=parser.parse_args()

curves=defaultdict(
    lambda:{
        "input":[],
        "output":[],
        "delta":[],
        "coef1":0.0,
        "coef3":0.0,
    }
)

with Path(args.csv).open(
    "r",
    encoding="utf-8",
) as csv_file:
    for row in csv.DictReader(csv_file):
        if row["family"]!="coef1":
            continue

        index=int(row["curve_index"])

        curves[index]["input"].append(
            float(row["input_i"])
        )

        curves[index]["output"].append(
            float(row["output_i"])
        )

        curves[index]["delta"].append(
            float(row["delta_output_lsb"])
        )

        curves[index]["coef1"]=float(
            row["coef1"]
        )

        curves[index]["coef3"]=float(
            row["coef3"]
        )

colors={
    0:"red",
    1:"green",
    2:"black",
    3:"blue",
    4:"magenta",
}

plt.figure(figsize=(10,7))

for index in range(5):
    data=curves[index]

    plt.plot(
        data["input"],
        data["output"],
        color=colors[index],
        linewidth=3.0 if index==2 else 1.8,
        label=(
            f"coef1={data['coef1']:.2f}, "
            f"coef3={data['coef3']:.2f}"
        ),
    )

plt.xlabel("Componente I de entrada (Q1.15)")
plt.ylabel("Componente I de saída (Q1.15)")

plt.title(
    "DPDnano-Lite HW021_dpd — Sensibilidade de coef1\n"
    "Curva nominal destacada em preto"
)

plt.grid(
    True,
    linestyle="--",
    alpha=0.35,
)

plt.legend(loc="best")
plt.tight_layout()

Path(args.output_amam).parent.mkdir(
    parents=True,
    exist_ok=True,
)

plt.savefig(
    args.output_amam,
    dpi=300,
)

plt.show()

plt.figure(figsize=(10,7))

for index in range(5):
    data=curves[index]

    plt.plot(
        data["input"],
        data["delta"],
        color=colors[index],
        linewidth=3.0 if index==2 else 1.8,
        label=(
            f"coef1={data['coef1']:.2f}"
        ),
    )

plt.axhline(
    0.0,
    color="black",
    linestyle="--",
    linewidth=1.2,
)

plt.xlabel("Componente I de entrada (Q1.15)")
plt.ylabel("ΔSaída em relação à curva nominal (LSB)")

plt.title(
    "DPDnano-Lite HW021_dpd — Diferença causada por coef1"
)

plt.grid(
    True,
    linestyle="--",
    alpha=0.35,
)

plt.legend(loc="best")
plt.tight_layout()

Path(args.output_delta).parent.mkdir(
    parents=True,
    exist_ok=True,
)

plt.savefig(
    args.output_delta,
    dpi=300,
)

plt.show()

print(
    f"Gráficos salvos em:\n"
    f"{Path(args.output_amam).resolve()}\n"
    f"{Path(args.output_delta).resolve()}"
)
