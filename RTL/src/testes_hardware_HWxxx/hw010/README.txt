DPDnano-Lite HW010 - Cubic Model

Objetivo

Validar a primeira ativacao do ramo cubico do DPDnano-Lite em hardware,
comparando a saida da FPGA com um modelo Python de referencia em ponto fixo.

Nesta etapa, o teste reaproveita a infraestrutura do `HW009`, mas altera os
coeficientes estaticos do `dpd_core` para exercitar o comportamento nao linear.

Coeficientes usados

- `coef1 = 0x6000 + j0`  -> `0,75`
- `coef3 = 0x1000 + j0`  -> `0,125`

Configuracao UART validada

- Baud rate: `115200`
- Formato: `8N1`

Arquivos do teste

- Script de execucao no PC:
  `dpdnano_hw010_dpd.py`
- RTL especifico do teste:
  `rtl/dpdnano_hw010_dpd_top.v`
  `rtl/dpd_controller_hw010_dpd.v`
- Restricoes:
  `rtl/dpdnano_hw010_dpd.cst`
  `rtl/dpdnano_hw010_dpd.sdc`
- Arquivos reutilizados do fluxo HW009:
  `rtl/protocol_controller_hw009_dpd.v`
  `rtl/input_memory_dualread_256x32.v`
  `rtl/output_memory_dualport_256x32.v`
  `rtl/uart_rx_27m_115200.v`
  `rtl/uart_tx_27m_115200.v`
- Dependencias do nucleo DPD copiadas para este pacote:
  `rtl/config.vh`
  `rtl/dpd_core.v`
  `rtl/complex_mult.v`
  `rtl/poly_kernel.v`
  `rtl/poly_branch.v`
  `rtl/rounding.v`
  `rtl/saturator.v`
  `rtl/fixed_mult.v`
  `rtl/mult_generic.v`

Fluxo validado

1. Escrita das amostras I/Q na input memory.
2. Disparo do comando `START_DPD`.
3. Leitura sequencial pelo `dpd_controller_hw010_dpd`.
4. Processamento com ramo linear e ramo cubico ativos.
5. Escrita dos resultados na output memory.
6. Comparacao entre FPGA e modelo Python.

Comandos exercitados pelo script

- `01` PING
- `20` WRITE INPUT MEMORY
- `31` READ OUTPUT MEMORY
- `40` START_DPD
- `41` STATUS

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

1. Adicione ao projeto todos os arquivos `.v`, `.vh`, `.cst` e `.sdc` da
   subpasta `rtl`.
2. Defina o top module como:

   `dpdnano_hw010_dpd_top`

3. Garanta que top-levels e restricoes de outros testes estejam desabilitados.
4. Execute Synthesize, Place & Route e gere o bitstream.
5. Grave o arquivo `.fs` na FPGA.

Observacao sobre LEDs

As saidas `led_busy`, `led_done` e `led_error` ja estao ajustadas para a
polaridade atualmente adotada na sua montagem.

Como rodar no PC

1. Instale o pyserial:

   `python -m pip install pyserial`

2. Execute o teste:

   `python dpdnano_hw010_dpd.py --port COM15`

3. Para explicitar a tolerancia:

   `python dpdnano_hw010_dpd.py --port COM15 --tolerance 4`

Resultado esperado

O script compara as amostras geradas pela FPGA com o primeiro modelo Python de
referencia para o ramo cubico, aceitando pequena diferenca de arredondamento.

Ao final, deve informar:

`RESULTADO: PASS - ramo cubico e modelo Python validados`
