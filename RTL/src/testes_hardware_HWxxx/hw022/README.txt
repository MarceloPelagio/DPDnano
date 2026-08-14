DPDnano-Lite HW022 - Caracterizacao Temporal do Pipeline

Objetivo

Caracterizar o comportamento temporal do DPDnano-Lite em FPGA real, medindo
latencia, jitter, perdas, duplicacoes, reordenacao e throughput sob diferentes
padroes de trafego.

Cenarios avaliados
------------------

- `continuous`
- `gap2`
- `gap4`
- `gap8`
- `random`
- `burst`

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
  `dpdnano_hw022_dpd.py`
- Script unico de plot:
  `plot_hw022_dpd.py`
- Arquivos gerados:
  `hw022_dpd_temporal_summary.csv`
  `hw022_dpd_timeline.csv`
  `hw022_dpd_latency_by_scenario.png`
  `hw022_dpd_timeline_burst.png`
- RTL especifico do teste:
  `rtl/dpdnano_hw022_dpd_top.v`
  `rtl/dpd_temporal_engine_hw022.v`
  `rtl/protocol_controller_hw022_dpd.v`
  `rtl/command_cdc_hw022_dpd.v`
  `rtl/status_cdc_hw022_dpd.v`
- Restricoes:
  `rtl/dpdnano_hw022_dpd.cst`
  `rtl/dpdnano_hw022_dpd.sdc`

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
conter apenas os arquivos particulares do HW022.

Top module
----------

`dpdnano_hw022_dpd_top`

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
3. Defina o top module como `dpdnano_hw022_dpd_top`.
4. Garanta que top-levels e restricoes de outros testes estejam desabilitados.
5. Execute Synthesize, Place & Route e gere o bitstream.
6. Grave o arquivo `.fs` na FPGA.

Como rodar no PC
----------------

1. Instale o pyserial:

   `python -m pip install pyserial`

2. Execute o teste:

   `python dpdnano_hw022_dpd.py --port COM15`

3. Gere as figuras em sequencia no mesmo script:

   `python plot_hw022_dpd.py`

Criterio esperado
-----------------

PASS quando:

- nao houver overflow
- a latencia permanecer deterministica em cada cenario
- nao houver perdas, duplicacoes ou reordenacao
- o jitter medido for nulo
