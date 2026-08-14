DPDnano-Lite HW008 - Memory Transfer

Objetivo

Validar a transferencia controlada da memoria de entrada para a memoria de
saida, usando o protocolo UART estruturado e um processamento deterministico
do tipo:

`OUT[n] = IN[n]`

Esse teste confirma o funcionamento conjunto de:

- escrita na input memory
- leitura sincronizada da input memory
- copia controlada por contador de palavras
- escrita automatica na output memory
- leitura final para comparacao dos dados transferidos

Configuracao UART validada

- Baud rate: `115200`
- Formato: `8N1`

Arquivos do teste

- Script de execucao no PC:
  `dpdnano_memory_transfer_hw008.py`
- RTL especifico do teste:
  `rtl/dpdnano_hw008_memory_transfer_top.v`
  `rtl/protocol_hw008.v`
  `rtl/memory_256x32.v`
- Restricoes:
  `rtl/dpdnano_hw008_memory_transfer.cst`
  `rtl/dpdnano_hw008_memory_transfer.sdc`
- Dependencias UART:
  `rtl/uart_rx_27m_115200.v`
  `rtl/uart_tx_27m_115200.v`

Formato dos quadros

- Requisicao: `A5 CMD AH AL D3 D2 D1 D0 CHECKSUM`
- Resposta: `5A CMD AH AL D3 D2 D1 D0 CHECKSUM`

Comandos validados

- `01` PING
- `02` VERSION
- `20` WRITE INPUT MEMORY
- `21` READ INPUT MEMORY
- `31` READ OUTPUT MEMORY
- `40` PROCESS/COPY

Semantica do comando PROCESS/COPY

- `address` define o endereco inicial da copia
- `data[15:0]` define a quantidade de palavras
- valor `0` em `count` representa `256` palavras

Mapa de memoria

- 256 palavras por memoria
- 32 bits por palavra
- enderecos validos: `0000` a `00FF`

Conexoes

- FPGA pino 39 (`uart_tx_o`) -> RXD do adaptador USB/TTL
- FPGA pino 40 (`uart_rx_i`) <- TXD do adaptador USB/TTL
- GND da FPGA -> GND do adaptador
- Nao ligar VCC entre as placas

LEDs de diagnostico

- Pino 41: `led_busy`
- Pino 42: `led_done`
- Pino 43: `led_error`

Como sintetizar no Gowin

1. Adicione ao projeto os arquivos `.v`, `.cst` e `.sdc` da subpasta `rtl`.
2. Defina o top module como:

   `dpdnano_hw008_memory_transfer_top`

3. Garanta que top-levels e restricoes de outros testes estejam desabilitados.
4. Execute Synthesize, Place & Route e gere o bitstream.
5. Grave o arquivo `.fs` na FPGA.

Observacao sobre LEDs

As saidas `led_busy`, `led_done` e `led_error` ja estao ajustadas para a
polaridade atualmente adotada na sua montagem.

Como rodar no PC

1. Instale o pyserial:

   `python -m pip install pyserial`

2. Execute o teste padrao:

   `python dpdnano_memory_transfer_hw008.py --port COM15`

3. Para transferir as 256 palavras:

   `python dpdnano_memory_transfer_hw008.py --port COM15 --count 256`

4. Para um intervalo parcial:

   `python dpdnano_memory_transfer_hw008.py --port COM15 --start 32 --count 100`

Resultado esperado

O script deve validar:

- `PING`
- `VERSION`
- escrita dos vetores na input memory
- comando `PROCESS/COPY`
- leitura dos mesmos vetores na output memory

Ao final, deve informar:

`RESULTADO: PASS - transferencia Input -> Output validada`
