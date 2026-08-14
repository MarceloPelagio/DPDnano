DPDnano-Lite HW018 - Compressao e P1dB

Objetivo

Caracterizar, em hardware real, a regiao de compressao AM/AM produzida por um
coeficiente cubico negativo. O teste busca identificar o ponto de compressao
de 1 dB e verificar se a curva apresenta o comportamento esperado de reducao
gradual do ganho com o aumento da amplitude.

Configuracao congelada deste pacote

- Clock interno do DPD: `60 MHz`
- PLL global: `src/gowin_pllvr/gowin_pllvr.v`
- Nucleo DPD congelado: `src/rtl_v3_1/*.v`
- Modulos comuns globais: `src/common/*.v`

Arquivos do teste

- Script principal:
  `dpdnano_hw018_dpd.py`
- Script de plot:
  `plot_hw018_dpd.py`
- Arquivos gerados e de referencia:
  `hw018_dpd_compression_p1db.csv`
  `hw018_dpd_compression_p1db.png`
- RTL especifico do teste:
  `rtl/dpdnano_hw018_dpd_top.v`
  `rtl/dpd_controller_hw018_dpd.v`
- Restricoes:
  `rtl/dpdnano_hw018_dpd.cst`
  `rtl/dpdnano_hw018_dpd.sdc`

Dependencias globais do projeto

- Nucleo DPD congelado:
  `src/rtl_v3_1/*.v`
  `src/rtl_v3_1/config.vh`
- PLL global:
  `src/gowin_pllvr/gowin_pllvr.v`
- Modulos comuns reutilizados:
  `src/common/uart_rx_27m_115200.v`
  `src/common/uart_tx_27m_115200.v`
  `src/common/protocol_controller_hw009_dpd.v`
  `src/common/input_dual_clock_bsram.v`
  `src/common/output_dual_clock_bsram.v`
  `src/common/command_cdc_hw_dpd.v`
  `src/common/status_cdc_hw_dpd.v`

Observacao de organizacao

Este pacote nao deve duplicar localmente os arquivos do nucleo `rtl_v3_1`, do
PLL global nem os modulos compartilhados de `src/common`. A pasta `rtl` deve
conter apenas os arquivos particulares do HW018.

Coeficientes do teste

- `coef1 = 0x7333 + j0x0000` aproximadamente `+0,90 + j0`
- `coef3 = 0xA667 + j0x0000` aproximadamente `-0,70 + j0`

Configuracao UART validada

- Baud rate: `115200`
- Formato: `8N1`

Conexoes

- FPGA pino 39 (`uart_tx_o`) -> RXD do adaptador USB/TTL
- FPGA pino 40 (`uart_rx_i`) <- TXD do adaptador USB/TTL
- GND da FPGA -> GND do adaptador
- Nao ligar VCC entre as placas

Como sintetizar no Gowin

1. Adicione ao projeto os arquivos especificos do teste na subpasta `rtl`.
2. Mantenha tambem adicionados os arquivos globais do nucleo em `src/rtl_v3_1`,
   o PLL global em `src/gowin_pllvr` e os modulos compartilhados em `src/common`.
3. Defina o top module como:

   `dpdnano_hw018_dpd_top`

4. Garanta que top-levels e restricoes de outros testes estejam desabilitados.
5. Nao duplique, dentro da pasta do teste, arquivos que ja pertencem ao nucleo
   global, ao PLL global ou aos modulos comuns, para evitar erro de modulo
   duplicado no Gowin.
6. Execute Synthesize, Place & Route e gere o bitstream.
7. Grave o arquivo `.fs` na FPGA.

Como rodar no PC

1. Instale o pyserial:

   `python -m pip install pyserial`

2. Execute o teste:

   `python dpdnano_hw018_dpd.py --port COM15`

3. Para gerar o grafico:

   `python plot_hw018_dpd.py`

Resultado esperado

O teste deve apontar ganho de pequeno sinal proximo ao valor configurado para
o termo linear, identificar um ponto de compressao de 1 dB antes do pico da
curva e manter o processamento sem overflow no conjunto de amostras utilizado.
