#!/usr/bin/env python3
import argparse,csv
from pathlib import Path
import matplotlib.pyplot as plt

COEF1_LINEAR = 0x599A / 32768.0

p=argparse.ArgumentParser()
p.add_argument("--csv",default="hw012_dpd_amplitude_sweep_vr02.csv")
p.add_argument("--output",default="hw012_dpd_am_am_vr02.png")
a=p.parse_args()

x=[];y=[];y_linear=[]
with Path(a.csv).open("r",encoding="utf-8") as f:
    for r in csv.DictReader(f):
        input_mag=float(r["input_magnitude"])
        output_mag=float(r["output_magnitude"])
        x.append(input_mag)
        y.append(output_mag)
        y_linear.append(input_mag * COEF1_LINEAR)

plt.figure()
plt.plot(x,y,label="Saida FPGA",linewidth=2.0)
plt.plot(
    x,
    y_linear,
    "--",
    label=f"Referencia linear (ganho={COEF1_LINEAR:.4f})",
    linewidth=1.6
)
plt.xlabel("Magnitude de entrada")
plt.ylabel("Magnitude de saida")
plt.title("HW012_dpd vr02 - Curva AM/AM")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig(a.output,dpi=200)
plt.show()
print(f"Grafico salvo em: {Path(a.output).resolve()}")
