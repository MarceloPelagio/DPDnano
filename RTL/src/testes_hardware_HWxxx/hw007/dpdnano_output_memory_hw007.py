#!/usr/bin/env python3
import argparse, random, serial, time

SOF_REQ=0xA5
SOF_RSP=0x5A
CMD_PING=0x01
CMD_VERSION=0x02
CMD_WRITE=0x30
CMD_READ=0x31
ERR_ADDR=0x000000E3

def checksum(values):
    r=0
    for v in values:
        r ^= v
    return r & 0xFF

def frame(cmd,addr,data):
    body=[
        SOF_REQ,cmd,(addr>>8)&0xFF,addr&0xFF,
        (data>>24)&0xFF,(data>>16)&0xFF,
        (data>>8)&0xFF,data&0xFF
    ]
    return bytes(body+[checksum(body)])

def decode(r):
    if len(r)!=9 or r[0]!=SOF_RSP or checksum(r[:8])!=r[8]:
        return None
    return (
        r[1],
        (r[2]<<8)|r[3],
        (r[4]<<24)|(r[5]<<16)|(r[6]<<8)|r[7]
    )

def transact(s,name,cmd,addr,data,expected):
    tx=frame(cmd,addr,data)
    s.reset_input_buffer()
    s.write(tx); s.flush()
    rx=s.read(9)
    d=decode(rx)
    ok=d is not None and d==(cmd,addr,expected)
    print(("PASS" if ok else "FAIL"),name)
    print("  TX:"," ".join(f"{x:02X}" for x in tx))
    print("  RX:"," ".join(f"{x:02X}" for x in rx) if rx else "TIMEOUT")
    return ok

p=argparse.ArgumentParser()
p.add_argument("--port",required=True)
p.add_argument("--random",type=int,default=32)
a=p.parse_args()

patterns={
    0x0000:0x00000000,
    0x0001:0x55555555,
    0x0002:0xAAAAAAAA,
    0x0003:0xFFFFFFFF,
    0x007F:0x12345678,
    0x0080:0x89ABCDEF,
    0x00FE:0x7FFF8000,
    0x00FF:0x80007FFF,
}

random.seed(77)
for _ in range(a.random):
    patterns[random.randrange(256)] = random.randrange(0x100000000)

tests=[]

with serial.Serial(a.port,115200,timeout=1,write_timeout=1) as s:
    time.sleep(0.1)

    print("DPDnano-Lite HW007 - Output Memory")
    print(f"Porta: {a.port}")
    print("Baud : 115200")
    print(f"Palavras testadas: {len(patterns)}\n")

    tests.append(transact(s,"PING",CMD_PING,0,0,0))
    tests.append(transact(s,"VERSION",CMD_VERSION,0,0,0x00000302))

    for addr,val in sorted(patterns.items()):
        tests.append(transact(
            s,f"WRITE OUT[{addr:04X}]",
            CMD_WRITE,addr,val,0
        ))

    for addr,val in sorted(patterns.items()):
        tests.append(transact(
            s,f"READ OUT[{addr:04X}]",
            CMD_READ,addr,0,val
        ))

    tests.append(transact(
        s,"INVALID ADDRESS",
        CMD_READ,0x0100,0,ERR_ADDR
    ))

print()
if all(tests):
    print("RESULTADO: PASS - memória de saída validada")
else:
    failures=sum(1 for x in tests if not x)
    print(f"RESULTADO: FAIL - {failures} falha(s)")
    raise SystemExit(1)
