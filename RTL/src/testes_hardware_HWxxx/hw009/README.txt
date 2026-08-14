DPDnano-Lite HW009 - First DPD Core Integration

Objetivo

Validar a primeira integracao funcional completa entre:

- input memory
- controlador de protocolo UART
- `dpd_controller`
- `dpd_core`
- output memory

Neste teste, o nucleo DPD opera com clock unico de `27 MHz` e coeficientes
fixos:

- ramo linear: `0x7FFF + j0`
- ramo cubico: `0`

Com essa configuracao, a saida deve acompanhar a entrada com erro pequeno,
limitado pela quantizacao interna do caminho aritmetico.

Configuracao UART validada

- Baud rate: `115200`
- Formato: `8N1`

Arquivos do teste

- Script de execucao no PC:
  `dpdnano_hw009_dpd.py`
- RTL especifico do teste:
  `rtl/dpdnano_hw009_dpd_top.v`
  `rtl/protocol_controller_hw009_dpd.v`
  `rtl/dpd_controller_hw009_dpd.v`
  `rtl/input_memory_dualread_256x32.v`
  `rtl/output_memory_dualport_256x32.v`
- Restricoes:
  `rtl/dpdnano_hw009_dpd.cst`
  `rtl/dpdnano_hw009_dpd.sdc`
- Dependencias UART:
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

1. Escrita de vetores I/Q na input memory.
2. Disparo do comando `START_DPD`.
3. Leitura das amostras pelo `dpd_controller`.
4. Processamento pelo `dpd_core`.
5. Escrita dos resultados na output memory.
6. Leitura final e comparacao no script Python.

Comandos validados

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

   `dpdnano_hw009_dpd_top`

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

   `python dpdnano_hw009_dpd.py --port COM15`

3. Se quiser apertar a verificacao, ajuste a tolerancia:

   `python dpdnano_hw009_dpd.py --port COM15 --tolerance 2`

Resultado esperado

O script envia um conjunto de vetores I/Q de referencia, dispara o
processamento DPD e compara as amostras lidas da output memory com os valores
esperados.

Ao final, deve informar:

`RESULTADO: PASS - primeiro processamento dpd_core validado`
