DPDnano-Lite HW023 - Stress Dinamico de Longa Duracao

Objetivo

Submeter o DPDnano-Lite a um ensaio de longa duracao em FPGA real, com fluxo
continuo, entradas I/Q pseudoaleatorias, alta amplitude ocasional e troca
periodica de perfis de coeficientes, para avaliar robustez temporal e
integridade do processamento.

Perfis dinamicos
----------------

- Perfil 0: `coef1 = 0,68`, `coef3 = 0,38`
- Perfil 1: `coef1 = 0,69`, `coef3 = 0,39`
- Perfil 2: `coef1 = 0,70`, `coef3 = 0,40`
- Perfil 3: `coef1 = 0,71`, `coef3 = 0,41`
- Perfil 4: `coef1 = 0,72`, `coef3 = 0,42`

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
  `dpdnano_hw023_dpd.py`
- Script unico de plot:
  `plot_hw023_dpd.py`
- Arquivos gerados:
  `hw023_dpd_stress_summary.csv`
  `hw023_dpd_checkpoints.csv`
  `hw023_dpd_latency_stability.png`
  `hw023_dpd_instantaneous_throughput.png`
  `hw023_dpd_integrity_checkpoints.png`
- RTL especifico do teste:
  `rtl/dpdnano_hw023_dpd_top.v`
  `rtl/dpd_stress_engine_hw023.v`
  `rtl/protocol_controller_hw023_dpd.v`
  `rtl/command_cdc_hw023_dpd.v`
  `rtl/status_cdc_hw023_dpd.v`
  `rtl/checkpoint_cdc_hw023_dpd.v`
- Restricoes:
  `rtl/dpdnano_hw023_dpd.cst`
  `rtl/dpdnano_hw023_dpd.sdc`

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

Observacao de organizacao
-------------------------

Este pacote nao deve duplicar localmente os arquivos do nucleo `rtl_v3_1`, do
PLL global nem os modulos compartilhados de `src/common`. A pasta `rtl` deve
conter apenas os arquivos particulares do HW023.

Top module
----------

`dpdnano_hw023_dpd_top`

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
3. Defina o top module como `dpdnano_hw023_dpd_top`.
4. Garanta que top-levels e restricoes de outros testes estejam desabilitados.
5. Execute Synthesize, Place & Route e gere o bitstream.
6. Grave o arquivo `.fs` na FPGA.

Como rodar no PC
----------------

1. Instale o pyserial:

   `python -m pip install pyserial`

2. Execute o teste:

   `python dpdnano_hw023_dpd.py --port COM15`

3. Para um ensaio menor:

   `python dpdnano_hw023_dpd.py --port COM15 --samples 100000`

4. Gere as figuras em sequencia no mesmo script:

   `python plot_hw023_dpd.py`

Criterio esperado
-----------------

PASS quando:

- todas as amostras forem enviadas e recebidas
- houver zero perdas, zero duplicacoes e zero reordenacao
- houver zero erros da fila
- o jitter permanecer nulo
- o numero de atualizacoes de coeficientes estiver correto
- houver amostras de alta amplitude
- houver eventos de saturacao

Overflow e saturacao sao esperados neste ensaio e nao representam falha por si sós.
