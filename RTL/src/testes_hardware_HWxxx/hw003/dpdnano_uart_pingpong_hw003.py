#!/usr/bin/env python3
import argparse, sys, time
try:
    import serial
except ImportError:
    print("Instale: python -m pip install pyserial")
    sys.exit(2)

p = argparse.ArgumentParser()
p.add_argument("--port", required=True)
p.add_argument("--repeat", type=int, default=10)
a = p.parse_args()

errors = 0
with serial.Serial(a.port,115200,timeout=1,write_timeout=1) as s:
    s.reset_input_buffer()
    s.reset_output_buffer()
    time.sleep(0.1)
    print("DPDnano-Lite HW003 - UART PING/PONG")
    print(f"Porta: {a.port}")
    print("Baud : 115200\n")
    for i in range(1,a.repeat+1):
        s.write(b'P')
        s.flush()
        r = s.read(1)
        if r == b'K':
            print(f"PASS {i:03d}  TX=0x50 ('P')  RX=0x4B ('K')")
        elif not r:
            print(f"FAIL {i:03d}  TX=0x50  RX=TIMEOUT")
            errors += 1
        else:
            print(f"FAIL {i:03d}  TX=0x50  RX=0x{r[0]:02X}")
            errors += 1
        time.sleep(0.1)

print()
print("RESULTADO: PASS - protocolo PING/PONG validado" if errors==0 else f"RESULTADO: FAIL - {errors} erro(s)")
sys.exit(0 if errors==0 else 1)
