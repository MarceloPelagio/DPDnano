#!/usr/bin/env python3
from __future__ import annotations
import argparse, csv, math, serial, time
from pathlib import Path

SOF_REQ=0xA5; SOF_RSP=0x5A
CMD_PING=0x01; CMD_WRITE_IN=0x20; CMD_READ_IN=0x21; CMD_READ_OUT=0x31
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
        raise RuntimeError("Resposta invalida ou timeout")
    return r[1],(r[2]<<8)|r[3],(r[4]<<24)|(r[5]<<16)|(r[6]<<8)|r[7]

def s16(v):
    v&=0xFFFF
    return v-0x10000 if v&0x8000 else v

def pack(i,q): return ((i&0xFFFF)<<16)|(q&0xFFFF)
def unpack(w): return s16(w>>16),s16(w)

def read_output_stable(uart, address):
    # Prime the readback path, then require the read value to settle.
    samples=[]
    transact(uart, CMD_READ_OUT, address, 0)
    for _ in range(5):
        _,_,word=transact(uart, CMD_READ_OUT, address, 0)
        samples.append(word)

    last_three=samples[-3:]
    if last_three[0]==last_three[1] or last_three[0]==last_three[2]:
        return last_three[0], True, samples
    if last_three[1]==last_three[2]:
        return last_three[1], True, samples
    return last_three[-1], False, samples

def read_input_word(uart, address):
    _,_,word=transact(uart, CMD_READ_IN, address, 0)
    return word

p=argparse.ArgumentParser()
p.add_argument("--port",required=True)
p.add_argument("--points",type=int,default=256)
p.add_argument("--max-amplitude",type=int,default=30000)
p.add_argument("--csv",default="hw012_dpd_amplitude_sweep_vr02.csv")
a=p.parse_args()

vectors=[(round(i*a.max_amplitude/(a.points-1)),0) for i in range(a.points)]
rows=[]
unstable_readbacks=0
input_mismatches=0

with serial.Serial(a.port,115200,timeout=2,write_timeout=1) as s:
    time.sleep(.1)
    print("DPDnano-Lite HW012_dpd vr02 - Amplitude Sweep")
    print("coef1 = 0x2666 = 0,30")
    print("coef3 = 0x599A = 0,70\n")
    transact(s,CMD_PING,0,0)

    for n,(iv,qv) in enumerate(vectors):
        transact(s,CMD_WRITE_IN,n,pack(iv,qv))

    print("\nVerificando memoria de entrada...")
    for n,(iv,qv) in enumerate(vectors):
        expected=pack(iv,qv)
        got=read_input_word(s,n)
        if got!=expected:
            input_mismatches+=1
            ex_i,ex_q=unpack(expected)
            got_i,got_q=unpack(got)
            print(f"READ_IN_MISMATCH[{n:03d}] EXP=({ex_i},{ex_q}) GOT=({got_i},{got_q}) WORD_EXP={expected:08X} WORD_GOT={got:08X}")

    transact(s,CMD_START_DPD,0,len(vectors))
    deadline=time.time()+3
    overflow=0
    while time.time()<deadline:
        _,_,status=transact(s,CMD_STATUS,0,0)
        if (status>>2)&1:
            raise RuntimeError("Erro DPD")
        overflow=(status>>3)&1
        if not(status&1):
            break
        time.sleep(.005)

    prev=-1
    monotonic_failures=0
    saturation_count=0
    saturation_onset=None

    for n,(iv,qv) in enumerate(vectors):
        word,stable,raw_reads=read_output_stable(s,n)
        oi,oq=unpack(word)
        im=math.hypot(iv,qv)
        om=math.hypot(oi,oq)
        gain=om/im if im else 0
        sat=abs(oi)>=32767 or abs(oq)>=32767
        mono=om>=prev
        if not stable:
            unstable_readbacks+=1
        if not mono:
            monotonic_failures+=1
        if sat and saturation_onset is None:
            saturation_onset=im
        if sat:
            saturation_count+=1
        prev=om
        rows.append(dict(index=n,input_i=iv,input_q=qv,input_magnitude=im,
                         output_i=oi,output_q=oq,output_magnitude=om,
                         gain=gain,saturated=int(sat),monotonic=int(mono),
                         readback_stable=int(stable)))
        line=f"[{n:03d}] IN={im:9.3f} OUT={om:9.3f} GAIN={gain:8.6f} SAT={'SIM' if sat else 'NAO'}"
        if not stable:
            words=" ".join(f"{value:08X}" for value in raw_reads)
            line += f" READBACK_INSTAVEL={words}"
        print(line)

csv_path=Path(a.csv)
with csv_path.open("w",newline="",encoding="utf-8") as f:
    w=csv.DictWriter(f,fieldnames=list(rows[0].keys()))
    w.writeheader();w.writerows(rows)

print("\n==============================================")
print("HW012_dpd vr02 - RESUMO")
print("==============================================")
print(f"Pontos processados        : {len(rows)}")
print(f"Falhas em READ_IN         : {input_mismatches}")
print(f"Overflow visto            : {'SIM' if overflow else 'NAO'}")
print(f"Falhas de monotonicidade  : {monotonic_failures}")
print(f"Saturacoes observadas     : {saturation_count}")
print(f"Leituras instaveis        : {unstable_readbacks}")
print("Inicio da saturacao       : "+(f"{saturation_onset:.3f}" if saturation_onset else "nao observado"))
print(f"Ganho final               : {rows[-1]['gain']:.6f}")
print(f"Saida final               : {rows[-1]['output_magnitude']:.3f}")
print(f"Arquivo CSV               : {csv_path.resolve()}")
print("==============================================")
passed = (
    input_mismatches == 0 and
    not overflow and
    saturation_count == 0 and
    monotonic_failures == 0 and
    unstable_readbacks == 0
)
print("RESULTADO: PASS - sweep AM/AM vr02 validado" if passed else "RESULTADO: FAIL")
