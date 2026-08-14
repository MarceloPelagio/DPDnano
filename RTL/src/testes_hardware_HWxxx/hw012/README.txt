DPDnano-Lite HW012 - AM/AM Amplitude Sweep

Objetivo

Executar um sweep de amplitude para caracterizar a curva AM/AM do DPDnano-Lite
com uma curvatura mais pronunciada do que no `HW010` e `HW011`.

Nesta revisao `vr02`, os coeficientes do controlador foram alterados para
forcar uma resposta nao linear mais visivel e facilitar a observacao da regiao
de compressao e da saturacao.

Coeficientes usados

- `coef1 = 0x599A + j0` -> aproximadamente `0,70`
- `coef3 = 0x2666 + j0` -> aproximadamente `0,30`

Importante

Este teste exige nova sintese e nova gravacao da FPGA, porque os coeficientes
embutidos no RTL sao diferentes dos usados no `HW010` e no `HW011`.

Arquivos do teste

- Script principal:
  `dpdnano_hw012_dpd.py`
- Script de plot:
  `plot_hw012_dpd.py`
- RTL especifico do teste:
  `rtl/dpdnano_hw012_dpd_top.v`
  `rtl/dpd_controller_hw012_dpd.v`
- Restricoes:
  `rtl/dpdnano_hw012_dpd.cst`
  `rtl/dpdnano_hw012_dpd.sdc`
- Arquivos reutilizados do fluxo anterior:
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

1. Escrita de um conjunto crescente de amplitudes na input memory.
2. Disparo do processamento DPD.
3. Leitura das amostras de saida.
4. Medicao de magnitude de entrada, magnitude de saida e ganho.
5. Gravacao de um arquivo CSV com os resultados.
6. Geracao posterior do grafico AM/AM.

Configuracao UART validada

- Baud rate: `115200`
- Formato: `8N1`

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

   `dpdnano_hw012_dpd_top`

3. Garanta que top-levels e restricoes de outros testes estejam desabilitados.
4. Execute Synthesize, Place & Route e gere o bitstream.
5. Grave o arquivo `.fs` na FPGA.

Observacao sobre LEDs

As saidas `led_busy`, `led_done` e `led_error` ja estao ajustadas para a
polaridade atualmente adotada na sua montagem.

Como rodar no PC

1. Instale o pyserial:

   `python -m pip install pyserial`

2. Execute o sweep padrao:

   `python dpdnano_hw012_dpd.py --port COM15`

3. Para alterar quantidade de pontos:

   `python dpdnano_hw012_dpd.py --port COM15 --points 128`

4. Para alterar amplitude maxima:

   `python dpdnano_hw012_dpd.py --port COM15 --max-amplitude 28000`

5. Para gerar o grafico a partir do CSV:

   `python plot_hw012_dpd.py`

Arquivos gerados

- `hw012_dpd_amplitude_sweep_vr02.csv`
- `hw012_dpd_am_am_vr02.png`

Resultado esperado

O sweep deve produzir uma curva AM/AM monotonicamente crescente, com aumento
de curvatura e eventual aproximacao da saturacao para amplitudes elevadas.

Ao final, o script deve informar:

`RESULTADO: PASS - sweep AM/AM vr02 validado`
