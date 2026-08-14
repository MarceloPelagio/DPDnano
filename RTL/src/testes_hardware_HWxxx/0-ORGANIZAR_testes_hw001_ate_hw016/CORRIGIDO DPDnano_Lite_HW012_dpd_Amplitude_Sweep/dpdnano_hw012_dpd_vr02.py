#!/usr/bin/env python3
from __future__ import annotations
import argparse, csv, math, serial, time
from pathlib import Path

SOF_REQ=0xA5; SOF_RSP=0x5A
CMD_PING=0x01; CMD_WRITE_IN=0x20; CMD_READ_OUT=0x31
CMD_START_DPD=0x40; CMD_STATUS=0x41

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
    if len(r)!=9 or r[0]!=SOF_RSP or checksum(r[:8])!=r[8]:
        raise RuntimeError("Resposta inválida ou timeout")
    return r[1],(r[2]<<8)|r[3],(r[4]<<24)|(r[5]<<16)|(r[6]<<8)|r[7]

def s16(v):
    v&=0xFFFF
    return v-0x10000 if v&0x8000 else v

def pack(i,q): return ((i&0xFFFF)<<16)|(q&0xFFFF)
def unpack(w): return s16(w>>16),s16(w)

p=argparse.ArgumentParser()
p.add_argument("--port",required=True)
p.add_argument("--points",type=int,default=256)
p.add_argument("--max-amplitude",type=int,default=30000)
p.add_argument("--csv",default="hw012_dpd_amplitude_sweep_vr02.csv")
a=p.parse_args()

vectors=[(round(i*a.max_amplitude/(a.points-1)),0) for i in range(a.points)]
rows=[]

with serial.Serial(a.port,115200,timeout=2,write_timeout=1) as s:
    time.sleep(.1)
    print("DPDnano-Lite HW012_dpd vr02 - Amplitude Sweep")
    print("coef1 = 0x599A = 0,70")
    print("coef3 = 0x2666 = 0,30\n")
    transact(s,CMD_PING,0,0)

    for n,(iv,qv) in enumerate(vectors):
        transact(s,CMD_WRITE_IN,n,pack(iv,qv))

    transact(s,CMD_START_DPD,0,len(vectors))
    deadline=time.time()+3
    overflow=0
    while time.time()<deadline:
        _,_,status=transact(s,CMD_STATUS,0,0)
        if (status>>2)&1: raise RuntimeError("Erro DPD")
        overflow=(status>>3)&1
        if not(status&1): break
        time.sleep(.005)

    prev=-1
    monotonic_failures=0
    saturation_onset=None

    for n,(iv,qv) in enumerate(vectors):
        _,_,word=transact(s,CMD_READ_OUT,n,0)
        oi,oq=unpack(word)
        im=math.hypot(iv,qv); om=math.hypot(oi,oq)
        gain=om/im if im else 0
        sat=abs(oi)>=32767 or abs(oq)>=32767
        mono=om>=prev
        if not mono: monotonic_failures+=1
        if sat and saturation_onset is None:saturation_onset=im
        prev=om
        rows.append(dict(index=n,input_i=iv,input_q=qv,input_magnitude=im,
                         output_i=oi,output_q=oq,output_magnitude=om,
                         gain=gain,saturated=int(sat),monotonic=int(mono)))
        print(f"[{n:03d}] IN={im:9.3f} OUT={om:9.3f} GAIN={gain:8.6f} SAT={'SIM' if sat else 'NÃO'}")

csv_path=Path(a.csv)
with csv_path.open("w",newline="",encoding="utf-8") as f:
    w=csv.DictWriter(f,fieldnames=list(rows[0].keys()))
    w.writeheader();w.writerows(rows)

print("\n==============================================")
print("HW012_dpd vr02 - RESUMO")
print("==============================================")
print(f"Pontos processados        : {len(rows)}")
print(f"Overflow visto            : {'SIM' if overflow else 'NÃO'}")
print(f"Falhas de monotonicidade  : {monotonic_failures}")
print("Início da saturação      : "+(f"{saturation_onset:.3f}" if saturation_onset else "não observado"))
print(f"Ganho final               : {rows[-1]['gain']:.6f}")
print(f"Saída final               : {rows[-1]['output_magnitude']:.3f}")
print(f"Arquivo CSV               : {csv_path.resolve()}")
print("==============================================")
print("RESULTADO: PASS - sweep AM/AM vr02 validado" if monotonic_failures==0 else "RESULTADO: FAIL")
