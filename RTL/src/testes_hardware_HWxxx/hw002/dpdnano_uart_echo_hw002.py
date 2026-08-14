#!/usr/bin/env python3
import argparse, sys, time
try:
    import serial
    from serial.tools import list_ports
except ImportError:
    print("Instale: python -m pip install pyserial")
    sys.exit(2)

TEST = bytes([0x00,0x55,0xAA,0xFF,0x31,0x32,0x33,0x41,0x42,0x43,0x0D,0x0A])

p=argparse.ArgumentParser()
p.add_argument("--port")
p.add_argument("--list",action="store_true")
p.add_argument("--repeat",type=int,default=1)
a=p.parse_args()

if a.list:
    for x in list_ports.comports():
        print(f"{x.device}: {x.description}")
    sys.exit(0)

port=a.port or input("Porta COM: ").strip()
errors=0

with serial.Serial(port,115200,timeout=1,write_timeout=1) as s:
    s.reset_input_buffer(); s.reset_output_buffer(); time.sleep(0.1)
    print("DPDnano-Lite HW002 - UART Echo")
    print(f"Porta: {port}\nBaud : 115200\n")
    for _ in range(a.repeat):
        for v in TEST:
            s.write(bytes([v])); s.flush()
            r=s.read(1)
            if r==bytes([v]):
                print(f"PASS  TX=0x{v:02X}  RX=0x{r[0]:02X}")
            elif not r:
                print(f"FAIL  TX=0x{v:02X}  RX=TIMEOUT"); errors+=1
            else:
                print(f"FAIL  TX=0x{v:02X}  RX=0x{r[0]:02X}"); errors+=1
            time.sleep(0.02)

print()
print("RESULTADO: PASS" if errors==0 else f"RESULTADO: FAIL - {errors} erro(s)")
sys.exit(0 if errors==0 else 1)
