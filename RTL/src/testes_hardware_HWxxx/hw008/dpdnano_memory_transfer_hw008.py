#!/usr/bin/env python3
import argparse
import random
import serial
import time

SOF_REQ=0xA5
SOF_RSP=0x5A

CMD_PING=0x01
CMD_VERSION=0x02
CMD_WRITE_IN=0x20
CMD_READ_IN=0x21
CMD_READ_OUT=0x31
CMD_PROCESS=0x40

def checksum(values):
    value=0
    for item in values:
        value ^= item
    return value & 0xFF

def make_frame(command,address,data):
    body=[
        SOF_REQ,
        command,
        (address>>8)&0xFF,
        address&0xFF,
        (data>>24)&0xFF,
        (data>>16)&0xFF,
        (data>>8)&0xFF,
        data&0xFF,
    ]
    return bytes(body+[checksum(body)])

def decode_response(frame):
    if len(frame)!=9:
        return None
    if frame[0]!=SOF_RSP:
        return None
    if checksum(frame[:8])!=frame[8]:
        return None

    return (
        frame[1],
        (frame[2]<<8)|frame[3],
        (frame[4]<<24)|(frame[5]<<16)|(frame[6]<<8)|frame[7],
    )

def transact(uart,title,command,address,data,expected):
    request=make_frame(command,address,data)
    uart.reset_input_buffer()
    uart.write(request)
    uart.flush()
    response=uart.read(9)
    decoded=decode_response(response)

    passed=(
        decoded is not None and
        decoded==(command,address,expected)
    )

    print(("PASS" if passed else "FAIL"),title)
    print("  TX:"," ".join(f"{x:02X}" for x in request))
    print(
        "  RX:",
        " ".join(f"{x:02X}" for x in response)
        if response else "TIMEOUT"
    )

    return passed

parser=argparse.ArgumentParser()
parser.add_argument("--port",required=True)
parser.add_argument("--count",type=int,default=64)
parser.add_argument("--start",type=int,default=0)
args=parser.parse_args()

if not 1 <= args.count <= 256:
    raise SystemExit("--count deve estar entre 1 e 256")

if not 0 <= args.start <= 255:
    raise SystemExit("--start deve estar entre 0 e 255")

if args.start + args.count > 256:
    raise SystemExit("start + count não pode ultrapassar 256")

random.seed(808)
vectors={}

for address in range(args.start,args.start+args.count):
    i_sample=random.randrange(-32768,32768)
    q_sample=random.randrange(-32768,32768)
    word=((i_sample & 0xFFFF)<<16)|(q_sample & 0xFFFF)
    vectors[address]=word

tests=[]

with serial.Serial(
    args.port,
    115200,
    timeout=2.0,
    write_timeout=1.0,
) as uart:
    time.sleep(0.1)

    print("DPDnano-Lite HW008 - Memory Transfer")
    print(f"Porta : {args.port}")
    print("Baud  : 115200")
    print(f"Start : {args.start}")
    print(f"Count : {args.count}")
    print()

    tests.append(transact(
        uart,"PING",CMD_PING,0,0,0
    ))

    tests.append(transact(
        uart,"VERSION",CMD_VERSION,0,0,0x00000302
    ))

    for address,value in vectors.items():
        tests.append(transact(
            uart,
            f"WRITE IN[{address:04X}]",
            CMD_WRITE_IN,
            address,
            value,
            0,
        ))

    process_count = 0 if args.count == 256 else args.count

    tests.append(transact(
        uart,
        "PROCESS/COPY",
        CMD_PROCESS,
        args.start,
        process_count,
        process_count,
    ))

    for address,value in vectors.items():
        tests.append(transact(
            uart,
            f"READ OUT[{address:04X}]",
            CMD_READ_OUT,
            address,
            0,
            value,
        ))

print()

if all(tests):
    print("RESULTADO: PASS - transferência Input -> Output validada")
else:
    failures=sum(1 for result in tests if not result)
    print(f"RESULTADO: FAIL - {failures} falha(s)")
    raise SystemExit(1)
