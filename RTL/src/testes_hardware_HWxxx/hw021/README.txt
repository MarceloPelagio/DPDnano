DPDnano-Lite HW021 - Sensibilidade aos Coeficientes

Objetivo

Verificar se pequenas alteracoes de `coef1` e `coef3` produzem mudancas
graduais, continuas e previsiveis na caracteristica AM/AM.

Familia 1 - variacao de coef1
-----------------------------

- `coef3` fixo em `0x199A` aproximadamente `+0,20`
- `coef1 = 0,68; 0,69; 0,70; 0,71; 0,72`

Familia 2 - variacao de coef3
-----------------------------

- `coef1` fixo em `0x599A` aproximadamente `+0,70`
- `coef3 = 0,18; 0,19; 0,20; 0,21; 0,22`

Configuracao congelada deste pacote
-----------------------------------

- Clock interno do DPD: `60 MHz`
- PLL global: `src/gowin_pllvr/gowin_pllvr.v`
- Nucleo DPD congelado: `src/rtl_v3_1/*.v`
- Modulos comuns globais: `src/common/*.v`
- LEDs ligados em `GND`, sem inversao por `~`

Arquivos do teste
-----------------

- Script principal:
  `dpdnano_hw021_dpd.py`
- Script unico de plot:
  `plot_hw021_dpd.py`
- Arquivos gerados e de referencia:
  `hw021_dpd_sensitivity_curves.csv`
  `hw021_dpd_sensitivity_summary.csv`
  `hw021_dpd_coef1_amam.png`
  `hw021_dpd_coef1_delta.png`
  `hw021_dpd_coef3_amam.png`
  `hw021_dpd_coef3_delta.png`
- RTL especifico do teste:
  `rtl/dpdnano_hw021_dpd_top.v`
  `rtl/dpd_controller_hw021_dpd.v`
  `rtl/protocol_controller_hw021_dpd.v`
- Restricoes:
  `rtl/dpdnano_hw021_dpd.cst`
  `rtl/dpdnano_hw021_dpd.sdc`

Dependencias globais do projeto
-------------------------------

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
-------------------------

Este pacote nao deve duplicar localmente os arquivos do nucleo `rtl_v3_1`, do
PLL global nem os modulos compartilhados de `src/common`. A pasta `rtl` deve
conter apenas os arquivos particulares do HW021.

Observacao sobre protocolo
--------------------------

O HW021 usa um protocolo especifico com selecao dinamica de familias de
coeficientes:

- `protocol_controller_hw021_dpd.v`

Nao substitua esse protocolo pelo `protocol_controller_hw009_dpd.v`.

Conexoes
--------

- FPGA pino 39 (`uart_tx_o`) -> RXD do adaptador USB/TTL
- FPGA pino 40 (`uart_rx_i`) <- TXD do adaptador USB/TTL
- GND da FPGA -> GND do adaptador
- Nao ligar VCC entre as placas

Como sintetizar no Gowin
------------------------

1. Adicione ao projeto os arquivos especificos do teste na subpasta `rtl`.
2. Mantenha tambem adicionados os arquivos globais do nucleo em `src/rtl_v3_1`,
   o PLL global em `src/gowin_pllvr` e os modulos compartilhados em `src/common`.
3. Defina o top module como:

   `dpdnano_hw021_dpd_top`

4. Garanta que top-levels e restricoes de outros testes estejam desabilitados.
5. Nao duplique, dentro da pasta do teste, arquivos que ja pertencem ao nucleo
   global, ao PLL global ou aos modulos comuns, para evitar erro de modulo
   duplicado no Gowin.
6. Execute Synthesize, Place & Route e gere o bitstream.
7. Grave o arquivo `.fs` na FPGA.

Como rodar no PC
----------------

1. Instale o pyserial:

   `python -m pip install pyserial`

2. Execute o teste:

   `python dpdnano_hw021_dpd.py --port COM15`

3. Gere as figuras em sequencia no mesmo script:

   `python plot_hw021_dpd.py`

Criterio esperado
-----------------

PASS quando:

- nao houver overflow nas familias avaliadas
- as curvas permanecerem ordenadas
- pequenas variacoes de coeficientes produzirem diferencas mensuraveis
- nao surgirem saltos abruptos nem comportamento inesperado
