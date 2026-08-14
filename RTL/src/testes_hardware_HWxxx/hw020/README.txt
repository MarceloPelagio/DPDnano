DPDnano-Lite HW020 - Janela Operacional de Coeficientes

Objetivo

Avaliar 25 combinacoes de coeficientes do modelo polinomial, varrendo:

- `coef1 = 0,40; 0,55; 0,70; 0,85; 1,00`
- `coef3 = -0,70; -0,35; 0,00; +0,35; +0,70`

Com 128 pontos por curva, o teste caracteriza a janela operacional do
DPDnano-Lite em termos de ganho, compressao, saturacao e overflow.

Configuracao congelada deste pacote

- Clock interno do DPD: `60 MHz`
- PLL global: `src/gowin_pllvr/gowin_pllvr.v`
- Nucleo DPD congelado: `src/rtl_v3_1/*.v`
- Modulos comuns globais: `src/common/*.v`
- LEDs ligados em `GND`, sem inversao por `~`

Arquivos do teste

- Script principal:
  `dpdnano_hw020_dpd.py`
- Script unico de plot:
  `plot_hw020_dpd.py`
- Arquivos gerados e de referencia:
  `hw020_dpd_operational_window_summary.csv`
  `hw020_dpd_all_curves.csv`
  `hw020_dpd_status_map.png`
  `hw020_dpd_peak_output_map.png`
  `hw020_dpd_saturation_map.png`
  `hw020_dpd_representative_curves.png`
- RTL especifico do teste:
  `rtl/dpdnano_hw020_dpd_top.v`
  `rtl/dpd_controller_hw020_dpd.v`
  `rtl/protocol_controller_hw020_dpd.v`
- Restricoes:
  `rtl/dpdnano_hw020_dpd.cst`
  `rtl/dpdnano_hw020_dpd.sdc`

Dependencias globais do projeto

- Nucleo DPD congelado:
  `src/rtl_v3_1/*.v`
  `src/rtl_v3_1/config.vh`
- PLL global:
  `src/gowin_pllvr/gowin_pllvr.v`
- Modulos comuns reutilizados:
  `src/common/uart_rx_27m_115200.v`
  `src/common/uart_tx_27m_115200.v`
  `src/common/input_dual_clock_bsram.v`
  `src/common/output_dual_clock_bsram.v`
  `src/common/command_cdc_hw_dpd.v`
  `src/common/status_cdc_hw_dpd.v`

Observacao de organizacao

Este pacote nao deve duplicar localmente os arquivos do nucleo `rtl_v3_1`, do
PLL global nem os modulos compartilhados de `src/common`. A pasta `rtl` deve
conter apenas os arquivos particulares do HW020.

Observacao sobre protocolo

O HW020 usa um protocolo especifico com comando de selecao dinamica de
coeficientes:

- `protocol_controller_hw020_dpd.v`

Nao substitua esse protocolo pelo `protocol_controller_hw009_dpd.v`.

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

   `dpdnano_hw020_dpd_top`

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

   `python dpdnano_hw020_dpd.py --port COM15`

3. Gere as figuras em sequencia no mesmo script:

   `python plot_hw020_dpd.py`

Saidas esperadas

Para cada combinacao de coeficientes, o teste registra:

- ganho de pequeno sinal
- ponto de compressao de 1 dB
- entrada no pico
- saida maxima
- inicio da saturacao
- overflow
- classificacao operacional
