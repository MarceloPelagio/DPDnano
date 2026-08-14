#!/usr/bin/env python3
import argparse,csv
from pathlib import Path
import matplotlib.pyplot as plt

p=argparse.ArgumentParser()
p.add_argument("--csv",default="hw015_dpd_ampm.csv")
p.add_argument("--output",default="hw015_dpd_ampm.png")
a=p.parse_args()

x=[];y=[]
with Path(a.csv).open("r",encoding="utf-8") as f:
    for row in csv.DictReader(f):
        x.append(float(row["input_magnitude"]))
        y.append(float(row["phase_shift_deg"]))

plt.figure(figsize=(9,6))
plt.plot(x,y,linewidth=2.5,marker="o",markersize=3,
         label="Desvio de fase medido na FPGA")
plt.axhline(0,color="red",linestyle="--",linewidth=1.8,
            label="Referência sem rotação")
plt.xlabel("Magnitude de entrada (Q1.15)")
plt.ylabel("Desvio de fase AM/PM (graus)")
plt.title(
    "DPDnano-Lite HW015_dpd - AM/PM dependente da amplitude\n"
    "coef1 = +0,40 + j0,00 | coef3 = +0,00 + j0,35"
)
plt.grid(True,linestyle="--",alpha=.35)
plt.legend(loc="best")
plt.tight_layout()
plt.savefig(a.output,dpi=300)
plt.show()
print(f"Gráfico salvo em: {Path(a.output).resolve()}")
