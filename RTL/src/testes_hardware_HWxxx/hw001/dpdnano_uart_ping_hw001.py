#!/usr/bin/env python3
"""
DPDnano-Lite HW001 - UART PING test

Sends 0x50 ('P') and expects 0x4B ('K').
"""

from __future__ import annotations

import argparse
import sys
import time

try:
    import serial
    from serial.tools import list_ports
except ImportError:
    print("ERROR: pyserial is not installed.")
    print("Install it with: python -m pip install pyserial")
    sys.exit(2)


DEFAULT_BAUD = 115200
PING = bytes([0x50])
EXPECTED = bytes([0x4B])


def show_ports() -> None:
    ports = list(list_ports.comports())
    if not ports:
        print("No serial ports found.")
        return

    print("Available serial ports:")
    for port in ports:
        description = port.description or "Unknown device"
        print(f"  {port.device}: {description}")


def choose_port(requested: str | None) -> str:
    if requested:
        return requested

    ports = list(list_ports.comports())
    if len(ports) == 1:
        print(f"Using the only detected port: {ports[0].device}")
        return ports[0].device

    show_ports()
    print()
    return input("Enter the COM port (example COM5): ").strip()


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Test the DPDnano-Lite UART PING command."
    )
    parser.add_argument(
        "--port",
        help="Serial port, for example COM5. If omitted, ports are listed.",
    )
    parser.add_argument(
        "--baud",
        type=int,
        default=DEFAULT_BAUD,
        help=f"UART baud rate (default: {DEFAULT_BAUD}).",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=1.0,
        help="Read timeout in seconds (default: 1.0).",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="List serial ports and exit.",
    )
    args = parser.parse_args()

    if args.list:
        show_ports()
        return 0

    port = choose_port(args.port)
    if not port:
        print("ERROR: no serial port selected.")
        return 2

    print()
    print("DPDnano-Lite HW001 - UART PING")
    print(f"Port : {port}")
    print(f"Baud : {args.baud}")

    try:
        with serial.Serial(
            port=port,
            baudrate=args.baud,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=args.timeout,
            write_timeout=args.timeout,
        ) as uart:
            uart.reset_input_buffer()
            uart.reset_output_buffer()
            time.sleep(0.10)

            print("TX   : 0x50 ('P')")
            uart.write(PING)
            uart.flush()

            response = uart.read(1)

    except serial.SerialException as exc:
        print(f"ERROR: serial communication failed: {exc}")
        return 2

    if not response:
        print("RX   : timeout; no byte received")
        print("RESULT: FAIL")
        return 1

    print(f"RX   : 0x{response[0]:02X}")

    if response == EXPECTED:
        print("RESULT: PASS - FPGA returned 0x4B ('K')")
        return 0

    print(f"RESULT: FAIL - expected 0x{EXPECTED[0]:02X}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
