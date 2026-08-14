#!/usr/bin/env python3
from __future__ import annotations
import argparse,csv,math,serial,time
from pathlib import Path

SOF_REQ=0xA5;SOF_RSP=0x5A
CMD_PING=0x01;CMD_WRITE_IN=0x20;CMD_READ_OUT=0x31
CMD_START_DPD=0x40;CMD_STATUS=0x41
POS_LIMIT=32767

def checksum(v):
    r=0
    for x in v:r^=x
    return r&255

def frame(c,a,d):
    b=[SOF_REQ,c,(a>>8)&255,a&255,(d>>24)&255,(d>>16)&255,(d>>8)&255,d&255]
    return bytes(b+[checksum(b)])

def transact(s,c,a,d):
    s.reset_input_buffer();s.write(frame(c,a,d));s.flush();r=s.read(9)
    if len(r)!=9 or r[0]!=SOF_RSP or checksum(r[:8])!=r[8]:
        raise RuntimeError("Resposta inválida ou timeout")
    return r[1],(r[2]<<8)|r[3],(r[4]<<24)|(r[5]<<16)|(r[6]<<8)|r[7]

def s16(v):
    v&=65535
    return v-65536 if v&32768 else v

def pack(i,q=0):return ((i&65535)<<16)|(q&65535)
def unpack(w):return s16(w>>16),s16(w)

def wait_done(s):
    deadline=time.time()+3
    while time.time()<deadline:
        _,_,st=transact(s,CMD_STATUS,0,0)
        if (st>>2)&1:raise RuntimeError("Erro DPD")
        if not(st&1):return (st>>3)&1
        time.sleep(.005)
    raise RuntimeError("Timeout esperando DPD")

p=argparse.ArgumentParser()
p.add_argument("--port",required=True)
p.add_argument("--points",type=int,default=256)
p.add_argument("--max-amplitude",type=int,default=32767)
p.add_argument("--output-dir",default="../../results/hw017")
a=p.parse_args()

outdir=Path(a.output_dir);outdir.mkdir(parents=True,exist_ok=True)
vectors=[round(i*a.max_amplitude/(a.points-1)) for i in range(a.points)]
rows=[]

with serial.Serial(a.port,115200,timeout=2,write_timeout=1) as s:
    time.sleep(.1)
    print("DPDnano-Lite HW017_dpd - Saturação, Overflow e Compressão")
    print("coef1=0x6666 (0,80) | coef3=0x6666 (0,80)\n")
    transact(s,CMD_PING,0,0)
    for n,x in enumerate(vectors):transact(s,CMD_WRITE_IN,n,pack(x))
    transact(s,CMD_START_DPD,0,len(vectors))
    overflow=wait_done(s)

    sat_onset=None;sat_count=0;prev=-1;mono=0
    small_gain=None;p1db=None

    for n,x in enumerate(vectors):
        _,_,w=transact(s,CMD_READ_OUT,n,0)
        y,q=unpack(w)
        gain=y/x if x else 0.0
        if small_gain is None and x>=1000 and y>0:small_gain=gain
        comp=0.0
        if small_gain and gain>0:
            comp=20*math.log10(gain/small_gain)
            if p1db is None and comp<=-1.0:p1db=x
        sat=(y==POS_LIMIT)
        if sat:
            sat_count+=1
            if sat_onset is None:sat_onset=x
        if y<prev:mono+=1
        prev=y
        rows.append({
            "index":n,"input_i":x,"output_i":y,"output_q":q,
            "gain_linear":gain,"compression_db":comp,"saturated":int(sat)
        })
        print(f"[{n:03d}] IN={x:6d} OUT={y:6d} GAIN={gain:8.5f} COMP={comp:8.4f} dB SAT={'SIM' if sat else 'NÃO'}")

csv_path=outdir/"hw017_dpd_saturation_compression.csv"
with csv_path.open("w",newline="",encoding="utf-8") as f:
    wr=csv.DictWriter(f,fieldnames=list(rows[0].keys()));wr.writeheader();wr.writerows(rows)

print("\n================================================")
print("HW017_dpd - RESUMO")
print("================================================")
print(f"Overflow visto            : {'SIM' if overflow else 'NÃO'}")
print(f"Início da saturação       : {sat_onset}")
print(f"Amostras saturadas        : {sat_count}")
print(f"Ponto de compressão 1 dB  : {p1db}")
print(f"Falhas de monotonicidade  : {mono}")
print(f"Arquivo CSV               : {csv_path.resolve()}")
print("================================================")

if overflow and sat_onset is not None and sat_count>0 and mono==0:
    print("RESULTADO: PASS - saturação, overflow e compressão caracterizados")
else:
    print("RESULTADO: FAIL")
    raise SystemExit(1)
