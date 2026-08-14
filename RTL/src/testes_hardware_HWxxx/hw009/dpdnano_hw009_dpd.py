#!/usr/bin/env python3
import argparse,serial,time
SOF_REQ=0xA5; SOF_RSP=0x5A
CMD_PING=0x01; CMD_WRITE_IN=0x20; CMD_READ_OUT=0x31
CMD_START_DPD=0x40; CMD_STATUS=0x41

def checksum(values):
    r=0
    for v in values:r^=v
    return r&0xFF

def frame(cmd,addr,data):
    b=[SOF_REQ,cmd,(addr>>8)&255,addr&255,(data>>24)&255,(data>>16)&255,(data>>8)&255,data&255]
    return bytes(b+[checksum(b)])

def transact(s,cmd,addr,data):
    tx=frame(cmd,addr,data); s.reset_input_buffer(); s.write(tx); s.flush(); rx=s.read(9)
    if len(rx)!=9 or rx[0]!=SOF_RSP or checksum(rx[:8])!=rx[8]:
        raise RuntimeError("Resposta inválida: "+(" ".join(f"{x:02X}" for x in rx) if rx else "TIMEOUT"))
    return rx[1],(rx[2]<<8)|rx[3],(rx[4]<<24)|(rx[5]<<16)|(rx[6]<<8)|rx[7]

def s16(v):
    v&=0xFFFF
    return v-0x10000 if v&0x8000 else v

def pack(i,q): return ((i&0xFFFF)<<16)|(q&0xFFFF)
def unpack(w): return s16(w>>16),s16(w)

vectors=[(0,0),(1,0),(-1,0),(1000,0),(-1000,0),(0,1000),(0,-1000),
(500,500),(-500,500),(500,-500),(-500,-500),(10000,-5000),
(-12000,9000),(20000,10000),(-20000,-10000),(30000,-30000)]

p=argparse.ArgumentParser()
p.add_argument("--port",required=True)
p.add_argument("--tolerance",type=int,default=3)
a=p.parse_args()

with serial.Serial(a.port,115200,timeout=2,write_timeout=1) as s:
    time.sleep(.1)
    print("DPDnano-Lite HW009_dpd - First Core Integration\n")
    transact(s,CMD_PING,0,0)
    for n,(i,q) in enumerate(vectors):
        transact(s,CMD_WRITE_IN,n,pack(i,q))
    transact(s,CMD_START_DPD,0,len(vectors))
    deadline=time.time()+2
    overflow=0
    while time.time()<deadline:
        _,_,status=transact(s,CMD_STATUS,0,0)
        busy=status&1; error=(status>>2)&1; overflow=(status>>3)&1
        if error: raise RuntimeError("Controlador DPD sinalizou erro")
        if not busy: break
        time.sleep(.01)
    else: raise RuntimeError("Timeout esperando DPD")

    fails=0
    for n,(ei,eq) in enumerate(vectors):
        _,_,word=transact(s,CMD_READ_OUT,n,0)
        ai,aq=unpack(word); di=ai-ei; dq=aq-eq
        ok=abs(di)<=a.tolerance and abs(dq)<=a.tolerance
        print(f"{'PASS' if ok else 'FAIL'} [{n:02d}] IN=({ei:6d},{eq:6d}) OUT=({ai:6d},{aq:6d}) ERR=({di:+d},{dq:+d})")
        if not ok:fails+=1
    print()
    print("Overflow visto:","SIM" if overflow else "NÃO")
    if fails:
        print(f"RESULTADO: FAIL - {fails} divergência(s)"); raise SystemExit(1)
    print("RESULTADO: PASS - primeiro processamento dpd_core validado")
