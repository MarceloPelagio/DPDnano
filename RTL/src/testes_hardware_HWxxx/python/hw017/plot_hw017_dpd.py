#!/usr/bin/env python3
import argparse,csv
from pathlib import Path
import matplotlib.pyplot as plt

p=argparse.ArgumentParser()
p.add_argument("--csv",default="../../results/hw017/hw017_dpd_saturation_compression.csv")
p.add_argument("--output",default="../../results/hw017/hw017_dpd_saturation_compression.png")
a=p.parse_args()

x=[];y=[];sat=[]
with Path(a.csv).open("r",encoding="utf-8") as f:
    for r in csv.DictReader(f):
        x.append(float(r["input_i"]));y.append(float(r["output_i"]));sat.append(int(r["saturated"]))

plt.figure(figsize=(9,6))
plt.plot(x,y,linewidth=2.6,label="Saída medida na FPGA")
plt.plot([0,32767],[0,32767],color="red",linestyle="--",linewidth=1.8,label="Referência linear y=x")
plt.axhline(32767,color="black",linestyle=":",linewidth=1.6,label="Limite +32767")
sx=[a for a,b in zip(x,sat) if b];sy=[a for a,b in zip(y,sat) if b]
if sx:plt.scatter(sx,sy,marker="x",s=30,label="Amostras saturadas")
plt.xlabel("Componente I de entrada (Q1.15)")
plt.ylabel("Componente I de saída (Q1.15)")
plt.title("DPDnano-Lite HW017_dpd — Saturação e Compressão\ncoef1=0x6666 (0,80) | coef3=0x6666 (0,80)")
plt.grid(True,linestyle="--",alpha=.35);plt.legend(loc="upper left");plt.tight_layout()
Path(a.output).parent.mkdir(parents=True,exist_ok=True)
plt.savefig(a.output,dpi=300);plt.show()
print(f"Gráfico salvo em: {Path(a.output).resolve()}")
