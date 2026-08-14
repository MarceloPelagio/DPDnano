#!/usr/bin/env python3
from __future__ import annotations
import argparse,csv
from pathlib import Path
import matplotlib.pyplot as plt
import numpy as np

p=argparse.ArgumentParser()
p.add_argument(
    "--csv",
    default="../../results/hw020/hw020_dpd_operational_window_summary.csv",
)
p.add_argument(
    "--output-prefix",
    default="../../results/hw020/hw020_dpd",
)
a=p.parse_args()

rows=[]
with Path(a.csv).open("r",encoding="utf-8") as f:
    rows=list(csv.DictReader(f))

coef1=sorted({float(r["coef1"]) for r in rows})
coef3=sorted({float(r["coef3"]) for r in rows})

status_code={
    "SEGURO":0,
    "COMPRESSIVO":1,
    "EXPANSIVO":2,
    "SATURADO":3,
    "OVERFLOW":4,
    "NÃO MONOTÔNICO":5,
}

status=np.zeros((len(coef3),len(coef1)))
sat=np.full_like(status,np.nan,dtype=float)
peak=np.zeros_like(status,dtype=float)

for r in rows:
    i=coef3.index(float(r["coef3"]))
    j=coef1.index(float(r["coef1"]))
    status[i,j]=status_code[r["status"]]
    peak[i,j]=float(r["peak_output"])
    if r["saturation_input"] not in ("","None"):
        sat[i,j]=float(r["saturation_input"])

def save_map(data,title,cbar_label,suffix):
    plt.figure(figsize=(8,6))
    image=plt.imshow(
        data,
        origin="lower",
        aspect="auto",
        extent=[min(coef1),max(coef1),min(coef3),max(coef3)],
    )
    plt.xlabel("Coeficiente linear coef1")
    plt.ylabel("Coeficiente cúbico coef3")
    plt.title(title)
    plt.colorbar(image,label=cbar_label)
    plt.tight_layout()
    output=f"{a.output_prefix}_{suffix}.png"
    Path(output).parent.mkdir(parents=True,exist_ok=True)
    plt.savefig(output,dpi=300)
    plt.show()
    print(f"Gráfico salvo em: {Path(output).resolve()}")

save_map(
    status,
    "HW020_dpd — Classificação da Janela Operacional",
    "0 Seguro | 1 Compressivo | 2 Expansivo | 3 Saturado | 4 Overflow",
    "status_map",
)

save_map(
    peak,
    "HW020_dpd — Valor Máximo da Saída",
    "Saída máxima (LSB)",
    "peak_output_map",
)

save_map(
    sat,
    "HW020_dpd — Entrada no Início da Saturação",
    "Entrada de saturação (LSB)",
    "saturation_map",
)
