DPDnano-Lite HW007 - Output Memory

Objetivo

Validar escrita e leitura da memória de saída acessível por protocolo
estruturado via UART, usando palavras de 32 bits compatíveis com amostras I/Q
de saída.

Configuração UART validada

- Baud rate: `115200`
- Formato: `8N1`

Arquivos do teste

- Script de execução no PC:
  `dpdnano_output_memory_hw007.py`
- RTL específico do teste:
  `rtl/dpdnano_hw007_output_memory_top.v`
  `rtl/protocol_hw007.v`
  `rtl/output_memory_256x32.v`
- Restrições:
  `rtl/dpdnano_hw007_output_memory.cst`
  `rtl/dpdnano_hw007_output_memory.sdc`
- Dependências UART:
  `rtl/uart_rx_27m_115200.v`
  `rtl/uart_tx_27m_115200.v`

Organização dos dados na memória

- 256 palavras
- 32 bits por palavra
- `bits [31:16]` = componente I
- `bits [15:0]` = componente Q

Formato dos quadros

- Requisição: `A5 CMD AH AL D3 D2 D1 D0 CHECKSUM`
- Resposta: `5A CMD AH AL D3 D2 D1 D0 CHECKSUM`

Comandos validados

- `01` PING
- `02` VERSION
- `30` WRITE OUTPUT MEMORY
- `31` READ OUTPUT MEMORY

Endereços válidos

- `0000` a `00FF`

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

   `dpdnano_hw007_output_memory_top`

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

   `python dpdnano_output_memory_hw007.py --port COM15`

3. Para um teste maior:

   `python dpdnano_output_memory_hw007.py --port COM15 --random 128`

Resultado esperado

O script deve validar:

- `PING`
- `VERSION`
- escrita dos endereços testados
- leitura dos mesmos endereços
- tentativa de acesso inválido ao endereço `0100`

Ao final, deve informar:

`RESULTADO: PASS - memória de saída validada`
