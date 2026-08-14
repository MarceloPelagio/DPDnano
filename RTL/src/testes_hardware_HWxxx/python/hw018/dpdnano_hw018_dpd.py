#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import math
import serial
import time
from pathlib import Path

SOF_REQ=0xA5
SOF_RSP=0x5A
CMD_PING=0x01
CMD_WRITE_IN=0x20
CMD_READ_OUT=0x31
CMD_START_DPD=0x40
CMD_STATUS=0x41

def checksum(values):
    r=0
    for v in values:
        r ^= v
    return r & 0xFF

def frame(cmd, addr, data):
    b=[
        SOF_REQ,cmd,(addr>>8)&255,addr&255,
        (data>>24)&255,(data>>16)&255,(data>>8)&255,data&255
    ]
    return bytes(b+[checksum(b)])

def transact(s,cmd,addr,data):
    s.reset_input_buffer()
    s.write(frame(cmd,addr,data))
    s.flush()
    r=s.read(9)

    if len(r)!=9 or r[0]!=SOF_RSP or checksum(r[:8])!=r[8]:
        raise RuntimeError("Resposta inválida ou timeout")

    return (
        r[1],
        (r[2]<<8)|r[3],
        (r[4]<<24)|(r[5]<<16)|(r[6]<<8)|r[7],
    )

def s16(v):
    v &= 0xFFFF
    return v-0x10000 if v&0x8000 else v

def pack(i,q=0):
    return ((i&0xFFFF)<<16)|(q&0xFFFF)

def unpack(w):
    return s16(w>>16),s16(w)

def wait_done(s):
    deadline=time.time()+3
    while time.time()<deadline:
        _,_,status=transact(s,CMD_STATUS,0,0)
        if (status>>2)&1:
            raise RuntimeError("Erro DPD")
        if not(status&1):
            return (status>>3)&1
        time.sleep(.005)
    raise RuntimeError("Timeout esperando DPD")

p=argparse.ArgumentParser()
p.add_argument("--port",required=True)
p.add_argument("--points",type=int,default=256)
p.add_argument("--max-amplitude",type=int,default=30000)
p.add_argument("--output-dir",default="../../results/hw018")
a=p.parse_args()

out_dir=Path(a.output_dir)
out_dir.mkdir(parents=True,exist_ok=True)

vectors=[
    round(index*a.max_amplitude/(a.points-1))
    for index in range(a.points)
]

rows=[]

with serial.Serial(a.port,115200,timeout=2,write_timeout=1) as s:
    time.sleep(.1)

    print("DPDnano-Lite HW018_dpd - Compressão e P1dB")
    print("coef1 = 0x7333 ≈ +0,90")
    print("coef3 = 0xA667 ≈ -0,70")
    print()

    if transact(s,CMD_PING,0,0)!=(CMD_PING,0,0):
        raise RuntimeError("Falha no PING")

    for n,iv in enumerate(vectors):
        if transact(s,CMD_WRITE_IN,n,pack(iv))!=(CMD_WRITE_IN,n,0):
            raise RuntimeError(f"Falha ao escrever {n}")

    if transact(s,CMD_START_DPD,0,len(vectors))!=(CMD_START_DPD,0,len(vectors)):
        raise RuntimeError("Falha no START_DPD")

    overflow=wait_done(s)

    small_gain=None
    p1db_input=None
    p1db_output=None
    monotonic_failures=0
    previous_output=-1

    for n,iv in enumerate(vectors):
        cmd,addr,word=transact(s,CMD_READ_OUT,n,0)

        if cmd!=CMD_READ_OUT or addr!=n:
            raise RuntimeError(f"Leitura inválida em {n}")

        oi,oq=unpack(word)

        gain=(oi/iv) if iv else 0.0

        if small_gain is None and iv>=1000 and oi>0:
            small_gain=gain

        compression_db=0.0

        if small_gain and gain>0:
            compression_db=20*math.log10(gain/small_gain)

            if p1db_input is None and compression_db<=-1.0:
                p1db_input=iv
                p1db_output=oi

        if oi<previous_output:
            monotonic_failures+=1

        previous_output=oi

        rows.append({
            "index":n,
            "input_i":iv,
            "output_i":oi,
            "output_q":oq,
            "gain_linear":gain,
            "gain_db":20*math.log10(gain) if gain>0 else float("-inf"),
            "compression_db":compression_db,
        })

        print(
            f"[{n:03d}] IN={iv:6d} OUT={oi:6d} "
            f"GAIN={gain:8.5f} COMP={compression_db:8.4f} dB"
        )

csv_path=out_dir/"hw018_dpd_compression_p1db.csv"

with csv_path.open("w",newline="",encoding="utf-8") as f:
    w=csv.DictWriter(f,fieldnames=list(rows[0].keys()))
    w.writeheader()
    w.writerows(rows)

# Em uma curva com coeficiente cúbico negativo, a saída pode atingir
# um máximo e diminuir posteriormente. Isso não é falha de monotonicidade,
# mas consequência da compressão forte do modelo polinomial.

peak_row = max(
    rows,
    key=lambda row: row["output_i"],
)

peak_input = peak_row["input_i"]
peak_output = peak_row["output_i"]

passed = (
    not overflow
    and p1db_input is not None
    and peak_input > p1db_input
    and peak_output > p1db_output
)

print()
print("==============================================")
print("HW018_dpd - RESUMO")
print("==============================================")
print(f"Overflow visto            : {'SIM' if overflow else 'NÃO'}")
print(f"Ganho de pequeno sinal    : {small_gain:.6f}")
print(f"Ponto de compressão 1 dB  : {p1db_input}")
print(f"Saída no ponto de 1 dB    : {p1db_output}")
print(f"Pontos após o pico        : {monotonic_failures}")
print(f"Arquivo CSV               : {csv_path.resolve()}")
print(f"Entrada no pico de saída  : {peak_input}")
print(f"Valor máximo de saída     : {peak_output}")
print("==============================================")

if passed:
    print("RESULTADO: PASS - compressão e ponto de 1 dB caracterizados")
else:
    print("RESULTADO: FAIL")
    raise SystemExit(1)
