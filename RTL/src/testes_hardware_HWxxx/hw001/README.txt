DPDnano-Lite HW001 - UART PING

Objetivo

Validar o bring-up inicial da interface UART da FPGA por meio de um comando
simples de ping. O teste envia 0x50 ('P') e espera receber 0x4B ('K').

Configuração UART validada

- Baud rate: `115200`
- Formato: `8N1`

Arquivos do teste

- Script de execução no PC:
  `dpdnano_uart_ping_hw001.py`
- RTL específico do teste:
  `rtl/dpdnano_hw001_uart_ping_top.v`
- Restrições:
  `rtl/dpdnano_hw001_uart_ping.cst`
  `rtl/dpdnano_hw001_uart_ping.sdc`
- Dependências UART:
  `rtl/uart_rx_27m_115200.v`
  `rtl/uart_tx_27m_115200.v`

Como sintetizar no Gowin

1. Adicione ao projeto os arquivos `.v`, `.cst` e `.sdc` da subpasta `rtl`.
2. Defina o top module como:

   `dpdnano_hw001_uart_ping_top`

3. Garanta que as restrições e o top de outros testes estejam desabilitados.
4. Execute Synthesize, Place & Route e gere o bitstream.
5. Grave o arquivo `.fs` na FPGA.

Observação sobre LEDs

Este teste usa saídas `led_busy`, `led_done` e `led_error` já ajustadas para a
polaridade atualmente adotada na montagem da placa.

Como rodar no PC

1. Instale o pyserial:

   `python -m pip install pyserial`

2. Liste as portas seriais disponíveis:

   `python dpdnano_uart_ping_hw001.py --list`

3. Execute o teste:

   `python dpdnano_uart_ping_hw001.py --port COM5`

   Se necessário, o baud pode ser informado explicitamente:

   `python dpdnano_uart_ping_hw001.py --port COM5 --baud 115200`

Resultado esperado

   TX   : 0x50 ('P')
   RX   : 0x4B
   RESULT: PASS - FPGA returned 0x4B ('K')
