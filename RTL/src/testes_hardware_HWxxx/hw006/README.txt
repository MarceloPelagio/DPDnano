DPDnano-Lite HW006 - Input Memory

Objetivo

Validar escrita e leitura da memória de entrada acessível por protocolo
estruturado via UART, usando palavras de 32 bits compatíveis com amostras I/Q.

Configuração UART validada

- Baud rate: `115200`
- Formato: `8N1`

Arquivos do teste

- Script de execução no PC:
  `dpdnano_input_memory_hw006.py`
- RTL específico do teste:
  `rtl/dpdnano_hw006_input_memory_top.v`
  `rtl/protocol_hw006.v`
  `rtl/input_memory_256x32.v`
- Restrições:
  `rtl/dpdnano_hw006_input_memory.cst`
  `rtl/dpdnano_hw006_input_memory.sdc`
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
- `20` WRITE MEMORY
- `21` READ MEMORY

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

Correção incorporada nesta versão

Este pacote já incorpora a correção da `vr02`, necessária para permitir
inferência de block RAM na Tang Nano 4K:

- remoção do reset do conteúdo da memória
- separação da RAM em `input_memory_256x32.v`
- leitura síncrona com ciclo de espera

Por esse motivo, use esta versão do teste como referência final e não a
implementação antiga baseada apenas na `vr01`.

Como sintetizar no Gowin

1. Adicione ao projeto os arquivos `.v`, `.cst` e `.sdc` da subpasta `rtl`.
2. Defina o top module como:

   `dpdnano_hw006_input_memory_top`

3. Garanta que top-levels e restrições de outros testes estejam desabilitados.
4. Limpe a pasta `impl`, se necessário.
5. Execute Synthesize e verifique se a memória foi inferida corretamente.
6. Execute Place & Route.
7. Grave o arquivo `.fs` na FPGA.

Observação sobre LEDs

As saídas `led_busy`, `led_done` e `led_error` já estão ajustadas para a
polaridade atualmente adotada na montagem da placa.

Como rodar no PC

1. Instale o pyserial:

   `python -m pip install pyserial`

2. Execute o teste padrão:

   `python dpdnano_input_memory_hw006.py --port COM15`

3. Para um teste maior:

   `python dpdnano_input_memory_hw006.py --port COM15 --random 128`

Resultado esperado

O script deve validar:

- `PING`
- `VERSION`
- escrita dos endereços testados
- leitura dos mesmos endereços
- tentativa de acesso inválido ao endereço `0100`

Ao final, deve informar:

`RESULTADO: PASS - memória de entrada validada`
