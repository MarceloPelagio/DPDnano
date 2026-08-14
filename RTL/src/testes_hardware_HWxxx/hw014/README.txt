DPDnano-Lite HW014 - Resposta Complexa e AM/PM

Objetivo

Exercitar o DPDnano-Lite com uma configuracao complexa de coeficientes para
observar a resposta vetorial do sistema e caracterizar o comportamento AM/PM
em hardware.

Este teste complementa os ensaios de AM/AM do HW012 e os ensaios de saturacao
do HW013, introduzindo rotacao de fase controlada na saida.

Coeficientes usados no controlador deste teste

- `coef1 = 0x3333 + j0x199A` -> aproximadamente `0,40 + j0,20`
- `coef3 = 0x0000 + j0x0000`

Arquivos do teste

- Script principal:
  `dpdnano_hw014_dpd.py`
- Scripts de plot:
  `plot_hw014_dpd_ampm.py`
  `plot_hw014_dpd_iq.py`
- Arquivos gerados e de referencia:
  `hw014_dpd_am_pm_complex.csv`
  `hw014_dpd_am_pm.png`
- RTL especifico do teste:
  `rtl/dpdnano_hw014_dpd_top.v`
  `rtl/dpd_controller_hw014_dpd.v`
- Restricoes:
  `rtl/dpdnano_hw014_dpd.cst`
  `rtl/dpdnano_hw014_dpd.sdc`

Dependencias globais do projeto

- Nucleo DPD congelado:
  `src/rtl_v3_1/*.v`
  `src/rtl_v3_1/config.vh`
- Modulos comuns reutilizados:
  `src/common/protocol_controller_hw009_dpd.v`
  `src/common/input_memory_dualread_256x32.v`
  `src/common/output_memory_dualport_256x32.v`
  `src/common/uart_rx_27m_115200.v`
  `src/common/uart_tx_27m_115200.v`

Observacao de organizacao

Este pacote nao deve duplicar localmente os arquivos do nucleo `rtl_v3_1` nem
os modulos globais da pasta `src/common`. A pasta `rtl` deve conter apenas os
arquivos particulares do HW014. A pasta `src/common` deve ser tratada como
infraestrutura global congelada e compartilhada pelos testes que reutilizam
UART, controlador de protocolo e memorias auxiliares.

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
2. Mantenha tambem adicionados os arquivos globais do nucleo em `src/rtl_v3_1`
   e os modulos comuns em `src/common`.
3. Defina o top module como:

   `dpdnano_hw014_dpd_top`

4. Garanta que top-levels e restricoes de outros testes estejam desabilitados.
5. Nao duplique, dentro da pasta do teste, arquivos que ja pertencem ao nucleo
   global ou aos modulos comuns, para evitar erro de modulo duplicado no Gowin.
6. Execute Synthesize, Place & Route e gere o bitstream.
7. Grave o arquivo `.fs` na FPGA.

Como rodar no PC

1. Instale o pyserial:

   `python -m pip install pyserial`

2. Execute o teste:

   `python dpdnano_hw014_dpd.py --port COM15`

3. Para gerar os graficos:

   `python plot_hw014_dpd_ampm.py`
   `python plot_hw014_dpd_iq.py`

Resultado esperado

O teste deve mostrar resposta complexa coerente com a configuracao dos
coeficientes, com desvio de fase controlado entre os vetores de entrada e saida.
