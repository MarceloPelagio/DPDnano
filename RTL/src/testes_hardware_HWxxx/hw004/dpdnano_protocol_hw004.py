#!/usr/bin/env python3
import argparse, serial, time

SOF_REQ=0xA5
SOF_RSP=0x5A

def req(cmd, data=0):
    return bytes([SOF_REQ, cmd, data, SOF_REQ ^ cmd ^ data])

def valid(r, cmd, data):
    return len(r)==4 and r[0]==SOF_RSP and r[1]==cmd and r[2]==data and r[3]==(r[0]^r[1]^r[2])

def run(s, name, frame, cmd, data):
    s.reset_input_buffer()
    s.write(frame)
    s.flush()
    r=s.read(4)
    ok=valid(r,cmd,data)
    print(("PASS" if ok else "FAIL"), name)
    print("  TX:", " ".join(f"{x:02X}" for x in frame))
    print("  RX:", " ".join(f"{x:02X}" for x in r) if r else "TIMEOUT")
    return ok

p=argparse.ArgumentParser()
p.add_argument("--port",required=True)
a=p.parse_args()

with serial.Serial(a.port,115200,timeout=1,write_timeout=1) as s:
    time.sleep(0.1)
    print("DPDnano-Lite HW004 - Structured Protocol\n")
    ok=[]
    ok.append(run(s,"PING",req(0x01),0x01,0x00))
    ok.append(run(s,"VERSION",req(0x02),0x02,0x32))
    ok.append(run(s,"UNKNOWN",req(0x7F),0x7F,0xE1))
    bad=bytearray(req(0x01)); bad[3]^=0xFF
    ok.append(run(s,"BAD CHECKSUM",bytes(bad),0x01,0xE2))

print()
if all(ok):
    print("RESULTADO: PASS - protocolo estruturado validado")
else:
    print("RESULTADO: FAIL")
    raise SystemExit(1)
