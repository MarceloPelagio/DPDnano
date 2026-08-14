DPDnano_Lite_v3_2 - HW002 UART Echo

Ligações:
FPGA pino 39 (TX) -> RXD do CH340
FPGA pino 40 (RX) <- TXD do CH340
GND -> GND
Não ligar VCC entre as placas. CH340 em 3,3 V.

LEDs:
41 BUSY
42 DONE
43 ERROR

No Gowin:
1. Adicione os três .v, o .cst e o .sdc.
2. Top Module: dpdnano_hw002_uart_echo_top
3. Desabilite os .cst/.sdc normais e do HW001.
4. Synthesize, Place & Route e SRAM Program.

No PC:
python -m pip install pyserial
python dpdnano_uart_echo_hw002.py --list
python dpdnano_uart_echo_hw002.py --port COMxx
