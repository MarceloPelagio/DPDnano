#!/usr/bin/env python3
from __future__ import annotations

import argparse,csv,math,serial,time
from pathlib import Path

SOF_REQ=0xA5; SOF_RSP=0x5A
CMD_PING=0x01; CMD_WRITE_IN=0x20; CMD_READ_OUT=0x31
CMD_START_DPD=0x40; CMD_STATUS=0x41; CMD_COEFS=0x43

COEF1_VALUES=[0.40,0.55,0.70,0.85,1.00]
COEF3_VALUES=[-0.70,-0.35,0.00,0.35,0.70]

def checksum(values):
    r=0
    for v in values:r^=v
    return r&0xFF

def frame(cmd,addr,data):
    b=[SOF_REQ,cmd,(addr>>8)&255,addr&255,
       (data>>24)&255,(data>>16)&255,(data>>8)&255,data&255]
    return bytes(b+[checksum(b)])

def transact(s,cmd,addr,data):
    s.reset_input_buffer(); s.write(frame(cmd,addr,data)); s.flush()
    r=s.read(9)
    if len(r)!=9: raise RuntimeError("Resposta incompleta ou timeout")
    if r[0]!=SOF_RSP: raise RuntimeError("SOF inválido")
    if checksum(r[:8])!=r[8]: raise RuntimeError("Checksum inválido")
    return r[1],(r[2]<<8)|r[3],(r[4]<<24)|(r[5]<<16)|(r[6]<<8)|r[7]

def s16(v):
    v&=0xFFFF
    return v-0x10000 if v&0x8000 else v

def pack(i,q=0):
    return ((i&0xFFFF)<<16)|(q&0xFFFF)

def unpack(w):
    return s16(w>>16),s16(w)

def wait_done(s):
    deadline=time.time()+3
    while time.time()<deadline:
        _,_,status=transact(s,CMD_STATUS,0,0)
        busy=status&1
        error=(status>>2)&1
        overflow=(status>>3)&1
        c1=(status>>4)&7
        c3=(status>>7)&7
        if error: raise RuntimeError("Erro DPD")
        if not busy: return overflow,c1,c3
        time.sleep(.005)
    raise RuntimeError("Timeout esperando DPD")

def classify(overflow,saturation_input,p1db_input,peak_input,last_output,first_gain,last_gain):
    if overflow:
        return "OVERFLOW"
    if saturation_input is not None:
        return "SATURADO"
    if p1db_input is not None:
        return "COMPRESSIVO"
    if last_gain>first_gain+0.02:
        return "EXPANSIVO"
    if peak_input is not None and peak_input<29000 and last_output<0:
        return "NÃO MONOTÔNICO"
    return "SEGURO"

p=argparse.ArgumentParser()
p.add_argument("--port",required=True)
p.add_argument("--points",type=int,default=128)
p.add_argument("--max-amplitude",type=int,default=30000)
p.add_argument("--output-dir",default="../../results/hw020")
a=p.parse_args()

if not 32<=a.points<=256:
    raise SystemExit("--points deve estar entre 32 e 256")

out_dir=Path(a.output_dir)
out_dir.mkdir(parents=True,exist_ok=True)
vectors=[round(i*a.max_amplitude/(a.points-1)) for i in range(a.points)]

summary=[]
all_rows=[]

with serial.Serial(a.port,115200,timeout=2,write_timeout=1) as s:
    time.sleep(.1)
    print("DPDnano-Lite HW020_dpd - Janela Operacional de Coeficientes")
    print(f"Combinações        : {len(COEF1_VALUES)*len(COEF3_VALUES)}")
    print(f"Pontos por curva   : {a.points}")
    print(f"Amostras totais    : {a.points*25}")
    print()

    if transact(s,CMD_PING,0,0)!=(CMD_PING,0,0):
        raise RuntimeError("Falha no PING")

    for c1_idx,c1 in enumerate(COEF1_VALUES):
        for c3_idx,c3 in enumerate(COEF3_VALUES):
            data=(c3_idx<<4)|c1_idx
            cmd,addr,rsp=transact(s,CMD_COEFS,0,data)
            if cmd!=CMD_COEFS or addr!=0:
                raise RuntimeError("Falha ao selecionar coeficientes")

            for n,iv in enumerate(vectors):
                if transact(s,CMD_WRITE_IN,n,pack(iv))!=(CMD_WRITE_IN,n,0):
                    raise RuntimeError(f"Falha ao escrever {n}")

            if transact(s,CMD_START_DPD,0,len(vectors))!=(CMD_START_DPD,0,len(vectors)):
                raise RuntimeError("Falha no START_DPD")

            overflow,active_c1,active_c3=wait_done(s)
            if active_c1!=c1_idx or active_c3!=c3_idx:
                raise RuntimeError("Índices ativos divergentes")

            rows=[]
            small_gain=None
            p1db_input=None
            saturation_input=None

            for n,iv in enumerate(vectors):
                cmd,addr,word=transact(s,CMD_READ_OUT,n,0)
                if cmd!=CMD_READ_OUT or addr!=n:
                    raise RuntimeError(f"Leitura inválida {n}")

                oi,oq=unpack(word)
                gain=(oi/iv) if iv else 0.0

                if small_gain is None and iv>=1000 and oi>0:
                    small_gain=gain

                compression_db=0.0
                if small_gain and gain>0:
                    compression_db=20*math.log10(gain/small_gain)
                    if p1db_input is None and compression_db<=-1.0:
                        p1db_input=iv

                if saturation_input is None and oi==32767:
                    saturation_input=iv

                row={
                    "coef1_index":c1_idx,"coef3_index":c3_idx,
                    "coef1":c1,"coef3":c3,
                    "index":n,"input_i":iv,"output_i":oi,"output_q":oq,
                    "gain_linear":gain,"compression_db":compression_db,
                    "saturated":int(oi==32767),
                }
                rows.append(row)
                all_rows.append(row)

            peak=max(rows,key=lambda r:r["output_i"])
            first_gain=next((r["gain_linear"] for r in rows if r["input_i"]>=1000),0.0)
            last_gain=rows[-1]["gain_linear"]

            status=classify(
                overflow,saturation_input,p1db_input,
                peak["input_i"],rows[-1]["output_i"],first_gain,last_gain
            )

            summary.append({
                "coef1_index":c1_idx,"coef3_index":c3_idx,
                "coef1":c1,"coef3":c3,
                "status":status,
                "overflow":int(overflow),
                "p1db_input":p1db_input,
                "saturation_input":saturation_input,
                "peak_input":peak["input_i"],
                "peak_output":peak["output_i"],
                "final_output":rows[-1]["output_i"],
                "small_signal_gain":small_gain,
                "final_gain":last_gain,
            })

            print(
                f"coef1={c1:+.2f} coef3={c3:+.2f} "
                f"STATUS={status:14s} P1dB={str(p1db_input):>6s} "
                f"SAT={str(saturation_input):>6s} OVF={'SIM' if overflow else 'NÃO'}"
            )

summary_csv=out_dir/"hw020_dpd_operational_window_summary.csv"
with summary_csv.open("w",newline="",encoding="utf-8") as f:
    w=csv.DictWriter(f,fieldnames=list(summary[0].keys()))
    w.writeheader(); w.writerows(summary)

curves_csv=out_dir/"hw020_dpd_all_curves.csv"
with curves_csv.open("w",newline="",encoding="utf-8") as f:
    w=csv.DictWriter(f,fieldnames=list(all_rows[0].keys()))
    w.writeheader(); w.writerows(all_rows)

safe=sum(1 for r in summary if r["status"]=="SEGURO")
compressive=sum(1 for r in summary if r["status"]=="COMPRESSIVO")
expansive=sum(1 for r in summary if r["status"]=="EXPANSIVO")
saturated=sum(1 for r in summary if r["status"]=="SATURADO")
overflow_count=sum(1 for r in summary if r["status"]=="OVERFLOW")

print()
print("==============================================")
print("HW020_dpd - RESUMO")
print("==============================================")
print(f"Combinações avaliadas : {len(summary)}")
print(f"Seguras               : {safe}")
print(f"Compressivas          : {compressive}")
print(f"Expansivas            : {expansive}")
print(f"Saturadas             : {saturated}")
print(f"Com overflow          : {overflow_count}")
print(f"Resumo CSV            : {summary_csv.resolve()}")
print(f"Curvas CSV            : {curves_csv.resolve()}")
print("==============================================")
print("RESULTADO: PASS - janela operacional de coeficientes caracterizada")
