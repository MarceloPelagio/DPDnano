DPDnano-Lite HW005 - Register Bank

Objetivo

Validar o primeiro banco interno de registradores acessível por protocolo
estruturado via UART. O teste cobre comandos de escrita, leitura, identificação
de versão e tratamento de endereços inválidos.

Configuração UART validada

- Baud rate: `115200`
- Formato: `8N1`

Arquivos do teste

- Script de execução no PC:
  `dpdnano_register_bank_hw005.py`
- RTL específico do teste:
  `rtl/dpdnano_hw005_register_bank_top.v`
  `rtl/protocol_hw005.v`
- Restrições:
  `rtl/dpdnano_hw005_register_bank.cst`
  `rtl/dpdnano_hw005_register_bank.sdc`
- Dependências UART:
  `rtl/uart_rx_27m_115200.v`
  `rtl/uart_tx_27m_115200.v`

Formato dos quadros

- Requisição: `A5 CMD ADDR DATA CHECKSUM`
- Resposta: `5A CMD ADDR STATUS/DATA CHECKSUM`

Comandos validados

- `01` PING
- `02` VERSION
- `10` WRITE REGISTER
- `11` READ REGISTER

Banco de registradores

- 8 registradores de 8 bits
- endereços válidos: `00` a `07`

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

   `dpdnano_hw005_register_bank_top`

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

   `python dpdnano_register_bank_hw005.py --port COM15`

Resultado esperado

O script deve validar:

- `PING`
- `VERSION`
- escrita e leitura dos registradores `00` a `07`
- tentativa de acesso ao endereço inválido `08`

Ao final, deve informar:

`RESULTADO: PASS - banco de registradores validado`
