#!/usr/bin/env python3
import argparse,csv
from pathlib import Path
import matplotlib.pyplot as plt

p=argparse.ArgumentParser()
p.add_argument("--csv",default="hw012_dpd_amplitude_sweep_vr02.csv")
p.add_argument("--output",default="hw012_dpd_am_am_vr02.png")
a=p.parse_args()

x=[];y=[]
with Path(a.csv).open("r",encoding="utf-8") as f:
    for r in csv.DictReader(f):
        x.append(float(r["input_magnitude"]))
        y.append(float(r["output_magnitude"]))

plt.figure()
plt.plot(x,y)
plt.xlabel("Magnitude de entrada")
plt.ylabel("Magnitude de saída")
plt.title("HW012_dpd vr02 - Curva AM/AM")
plt.grid(True)
plt.tight_layout()
plt.savefig(a.output,dpi=200)
plt.show()
print(f"Gráfico salvo em: {Path(a.output).resolve()}")
