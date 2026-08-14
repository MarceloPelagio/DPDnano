#!/usr/bin/env python3
from __future__ import annotations
import argparse,csv,math,serial,time
from pathlib import Path

SOF_REQ=0xA5;SOF_RSP=0x5A
CMD_PING=0x01;CMD_WRITE_IN=0x20;CMD_READ_OUT=0x31
CMD_START_DPD=0x40;CMD_STATUS=0x41

def checksum(values):
    r=0
    for v in values:r^=v
    return r&0xFF

def frame(cmd,addr,data):
    b=[SOF_REQ,cmd,(addr>>8)&255,addr&255,
       (data>>24)&255,(data>>16)&255,(data>>8)&255,data&255]
    return bytes(b+[checksum(b)])

def transact(s,cmd,addr,data):
    s.reset_input_buffer();s.write(frame(cmd,addr,data));s.flush()
    r=s.read(9)
    if len(r)!=9 or r[0]!=SOF_RSP or checksum(r[:8])!=r[8]:
        raise RuntimeError("Resposta inválida ou timeout")
    return r[1],(r[2]<<8)|r[3],(r[4]<<24)|(r[5]<<16)|(r[6]<<8)|r[7]

def s16(v):
    v&=0xFFFF
    return v-0x10000 if v&0x8000 else v

def pack(i,q):return ((i&0xFFFF)<<16)|(q&0xFFFF)
def unpack(w):return s16(w>>16),s16(w)

def wait_done(s):
    deadline=time.time()+3
    while time.time()<deadline:
        _,_,status=transact(s,CMD_STATUS,0,0)
        if (status>>2)&1:raise RuntimeError("Erro DPD")
        if not(status&1):return (status>>3)&1
        time.sleep(.005)
    raise RuntimeError("Timeout esperando DPD")

p=argparse.ArgumentParser()
p.add_argument("--port",required=True)
p.add_argument("--points",type=int,default=256)
p.add_argument("--max-amplitude",type=int,default=30000)
p.add_argument("--csv",default="hw015_dpd_ampm.csv")
a=p.parse_args()

if not 8<=a.points<=256:raise SystemExit("--points deve estar entre 8 e 256")

vectors=[(round((n+1)*a.max_amplitude/a.points),0) for n in range(a.points)]
rows=[]

with serial.Serial(a.port,115200,timeout=2,write_timeout=1) as s:
    time.sleep(.1)
    print("DPDnano-Lite HW015_dpd - AM/PM dependente da amplitude")
    print("coef1 = 0x3333 + j0x0000")
    print("coef3 = 0x0000 + j0x2CCD\n")
    transact(s,CMD_PING,0,0)

    for n,(iv,qv) in enumerate(vectors):
        transact(s,CMD_WRITE_IN,n,pack(iv,qv))

    transact(s,CMD_START_DPD,0,len(vectors))
    overflow=wait_done(s)

    for n,(iv,qv) in enumerate(vectors):
        _,_,word=transact(s,CMD_READ_OUT,n,0)
        oi,oq=unpack(word)
        in_mag=math.hypot(iv,qv)
        out_mag=math.hypot(oi,oq)
        delta=math.degrees(math.atan2(oq,oi))
        rows.append({
            "index":n,"input_i":iv,"input_q":qv,
            "input_magnitude":in_mag,
            "output_i":oi,"output_q":oq,
            "output_magnitude":out_mag,
            "phase_shift_deg":delta,
        })
        print(f"[{n:03d}] IN={in_mag:9.3f} OUT={out_mag:9.3f} DELTA={delta:8.4f}°")

csv_path=Path(a.csv)
with csv_path.open("w",newline="",encoding="utf-8") as f:
    w=csv.DictWriter(f,fieldnames=list(rows[0].keys()))
    w.writeheader();w.writerows(rows)

phase = [float(r["phase_shift_deg"]) for r in rows]

# Tolerância para pequenas oscilações devido à quantização
EPS_PHASE = 0.5   # graus

mono = sum(
    1 for current_phase, next_phase in zip(phase, phase[1:])
    if next_phase < current_phase - EPS_PHASE
)


print("\n==============================================")
print("HW015_dpd - RESUMO")
print("==============================================")
print(f"Pontos processados       : {len(rows)}")
print(f"Overflow visto           : {'SIM' if overflow else 'NÃO'}")
print(f"Desvio de fase mínimo    : {min(phase):.6f}°")
print(f"Desvio de fase máximo    : {max(phase):.6f}°")
print(f"Falhas de monotonicidade (> {EPS_PHASE:.1f}°) : {mono}")
print(f"Arquivo CSV              : {csv_path.resolve()}")
print("==============================================")

if not overflow and max(phase)>min(phase)+1.0:
    print("RESULTADO: PASS - AM/PM dependente da amplitude validada")
else:
    print("RESULTADO: FAIL")
    raise SystemExit(1)
