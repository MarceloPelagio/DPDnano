DPDnano-Lite HW001 - UART PING

1. Add these UART constraints to dpdnano_lite.cst:

   IO_LOC "uart_tx_o" 17;
   IO_PORT "uart_tx_o" IO_TYPE=LVCMOS18 PULL_MODE=NONE DRIVE=8;

   IO_LOC "uart_rx_i" 18;
   IO_PORT "uart_rx_i" IO_TYPE=LVCMOS18 PULL_MODE=UP;

2. Run Synthesize and Place & Route again.
3. Program the new .fs file into SRAM.
4. Install pyserial:

   python -m pip install pyserial

5. List serial ports:

   python dpdnano_uart_ping_hw001.py --list

6. Run the test:

   python dpdnano_uart_ping_hw001.py --port COM5

Expected result:

   TX   : 0x50 ('P')
   RX   : 0x4B
   RESULT: PASS - FPGA returned 0x4B ('K')
