#!/usr/bin/env python3
import argparse
import serial
import time

SOF_REQ=0xA5
SOF_RSP=0x5A

CMD_PING=0x01
CMD_VERSION=0x02
CMD_WRITE=0x10
CMD_READ=0x11

ERR_UNKNOWN=0xE1
ERR_CSUM=0xE2
ERR_ADDR=0xE3

def make_frame(cmd, addr=0, data=0):
    checksum = SOF_REQ ^ cmd ^ addr ^ data
    return bytes([SOF_REQ,cmd,addr,data,checksum])

def read_frame(ser):
    return ser.read(5)

def validate_response(frame, cmd, addr, value):
    return (
        len(frame)==5 and
        frame[0]==SOF_RSP and
        frame[1]==cmd and
        frame[2]==addr and
        frame[3]==value and
        frame[4]==(frame[0]^frame[1]^frame[2]^frame[3])
    )

def transact(ser,name,request,cmd,addr,value):
    ser.reset_input_buffer()
    ser.write(request)
    ser.flush()
    response=read_frame(ser)

    ok=validate_response(response,cmd,addr,value)

    print(("PASS" if ok else "FAIL"),name)
    print("  TX:"," ".join(f"{x:02X}" for x in request))
    print("  RX:"," ".join(f"{x:02X}" for x in response) if response else "TIMEOUT")
    return ok

parser=argparse.ArgumentParser()
parser.add_argument("--port",required=True)
args=parser.parse_args()

tests=[]

with serial.Serial(args.port,115200,timeout=1,write_timeout=1) as ser:
    time.sleep(0.1)

    print("DPDnano-Lite HW005 - Register Bank")
    print(f"Porta: {args.port}")
    print("Baud : 115200\n")

    tests.append(transact(
        ser,"PING",
        make_frame(CMD_PING),
        CMD_PING,0x00,0x00
    ))

    tests.append(transact(
        ser,"VERSION",
        make_frame(CMD_VERSION),
        CMD_VERSION,0x00,0x32
    ))

    patterns=[
        (0x00,0x00),
        (0x01,0x55),
        (0x02,0xAA),
        (0x03,0xFF),
        (0x04,0x12),
        (0x05,0x34),
        (0x06,0x56),
        (0x07,0x78),
    ]

    for addr,value in patterns:
        tests.append(transact(
            ser,f"WRITE R{addr}",
            make_frame(CMD_WRITE,addr,value),
            CMD_WRITE,addr,0x00
        ))

        tests.append(transact(
            ser,f"READ R{addr}",
            make_frame(CMD_READ,addr,0x00),
            CMD_READ,addr,value
        ))

    tests.append(transact(
        ser,"INVALID ADDRESS",
        make_frame(CMD_READ,0x08,0x00),
        CMD_READ,0x08,ERR_ADDR
    ))

print()
if all(tests):
    print("RESULTADO: PASS - banco de registradores validado")
else:
    print("RESULTADO: FAIL")
    raise SystemExit(1)
