DPDnano-Lite HW004 - Structured Protocol

Objetivo

Validar a primeira versão do protocolo estruturado sobre UART. O computador
envia quadros com formato fixo e a FPGA deve responder com quadros consistentes
para os comandos suportados e para as condições de erro previstas.

Configuração UART validada

- Baud rate: `115200`
- Formato: `8N1`

Arquivos do teste

- Script de execução no PC:
  `dpdnano_protocol_hw004.py`
- RTL específico do teste:
  `rtl/dpdnano_hw004_structured_protocol_top.v`
  `rtl/protocol_hw004.v`
- Restrições:
  `rtl/dpdnano_hw004_structured_protocol.cst`
  `rtl/dpdnano_hw004_structured_protocol.sdc`
- Dependências UART:
  `rtl/uart_rx_27m_115200.v`
  `rtl/uart_tx_27m_115200.v`

Formato dos quadros

- Requisição: `A5 CMD DATA CHECKSUM`
- Resposta: `5A CMD STATUS/DATA CHECKSUM`

Comandos validados

- `01` PING -> retorno de status `00`
- `02` VERSION -> retorno de dado `32` hexadecimal, representando `v3.2`

Erros validados

- `E1` comando desconhecido
- `E2` checksum inválido

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

   `dpdnano_hw004_structured_protocol_top`

3. Garanta que top-levels e restrições de outros testes estejam desabilitados.
4. Execute Synthesize, Place & Route e gere o bitstream.
5. Grave o arquivo `.fs` na FPGA.

Observação sobre LEDs

As saídas `led_busy`, `led_done` e `led_error` já estão ajustadas para a
polaridade atualmente adotada na montagem da placa.

Como rodar no PC

1. Instale o pyserial:

   `python -m pip install pyserial`

2. Execute o teste:

   `python dpdnano_protocol_hw004.py --port COM15`

Resultado esperado

O script deve validar os cenários:

- `PING`
- `VERSION`
- `UNKNOWN`
- `BAD CHECKSUM`

Ao final, deve informar:

`RESULTADO: PASS - protocolo estruturado validado`
