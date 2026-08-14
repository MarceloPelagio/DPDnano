DPDnano-Lite HW002 - UART Echo

Objetivo

Validar a comunicação bidirecional básica da interface UART da FPGA por meio
de um teste de eco. Cada byte enviado pelo computador deve ser devolvido pela
FPGA sem alteração.

Configuração UART validada

- Baud rate: `115200`
- Formato: `8N1`

Arquivos do teste

- Script de execução no PC:
  `dpdnano_uart_echo_hw002.py`
- RTL específico do teste:
  `rtl/dpdnano_hw002_uart_echo_top.v`
- Restrições:
  `rtl/dpdnano_hw002_uart_echo.cst`
  `rtl/dpdnano_hw002_uart_echo.sdc`
- Dependências UART:
  `rtl/uart_rx_27m_115200.v`
  `rtl/uart_tx_27m_115200.v`

Conexões

- FPGA pino 39 (`uart_tx_o`) -> RXD do adaptador USB/TTL
- FPGA pino 40 (`uart_rx_i`) <- TXD do adaptador USB/TTL
- GND da FPGA -> GND do adaptador
- Não ligar VCC entre as placas

LEDs de diagnóstico

- Pino 41: `led_busy`
- Pino 42: `led_done`
- Pino 43: `led_error`

Como sintetizar no Gowin

1. Adicione ao projeto os arquivos `.v`, `.cst` e `.sdc` da subpasta `rtl`.
2. Defina o top module como:

   `dpdnano_hw002_uart_echo_top`

3. Garanta que top-levels e restrições de outros testes estejam desabilitados.
4. Execute Synthesize, Place & Route e gere o bitstream.
5. Grave o arquivo `.fs` na FPGA.

Observação sobre LEDs

As saídas `led_busy`, `led_done` e `led_error` já estão ajustadas para a
polaridade atualmente adotada na montagem da placa.

Como rodar no PC

1. Instale o pyserial:

   `python -m pip install pyserial`

2. Liste as portas seriais disponíveis:

   `python dpdnano_uart_echo_hw002.py --list`

3. Execute o teste:

   `python dpdnano_uart_echo_hw002.py --port COM15`

4. Se desejar repetir automaticamente a sequência:

   `python dpdnano_uart_echo_hw002.py --port COM15 --repeat 5`

Resultado esperado

Cada byte transmitido deve retornar com o mesmo valor. Ao final, o script deve
informar:

`RESULTADO: PASS`
