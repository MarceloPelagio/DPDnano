DPDnano-Lite HW016 - Multi-Profile One Run

Objetivo

Executar, com um unico bitstream, quatro perfis distintos de resposta AM/PM
selecionaveis por comando de perfil, permitindo comparar diferentes niveis de
rotacao de fase sem necessidade de recompilar a FPGA a cada variacao.

Este teste amplia a ideia do HW015 ao reunir, em uma unica campanha, perfis
de comportamento linear e de AM/PM leve, medio e forte.

Perfis previstos no script

- Perfil A: comportamento linear
- Perfil B: AM/PM leve
- Perfil C: AM/PM media
- Perfil D: AM/PM forte

Arquivos do teste

- Script principal:
  `dpdnano_hw016_dpd.py`
- Script de plot:
  `plot_hw016_dpd_compare.py`
- Arquivos gerados e de referencia:
  `hw016_dpd_all_profiles.csv`
  `hw016_profile_A.csv`
  `hw016_profile_B.csv`
  `hw016_profile_C.csv`
  `hw016_profile_D.csv`
  `hw016_dpd_ampm_comparison.png`
- RTL especifico do teste:
  `rtl/dpdnano_hw016_dpd_top.v`
  `rtl/dpd_controller_hw016_dpd.v`
  `rtl/protocol_controller_hw016_dpd.v`
- Restricoes:
  `rtl/dpdnano_hw016_dpd.cst`
  `rtl/dpdnano_hw016_dpd.sdc`

Dependencias globais do projeto

- Nucleo DPD congelado:
  `src/rtl_v3_1/*.v`
  `src/rtl_v3_1/config.vh`
- Modulos comuns reutilizados:
  `src/common/input_memory_dualread_256x32.v`
  `src/common/output_memory_dualport_256x32.v`
  `src/common/uart_rx_27m_115200.v`
  `src/common/uart_tx_27m_115200.v`

Observacao de organizacao

Este pacote nao deve duplicar localmente os arquivos do nucleo `rtl_v3_1` nem
os modulos globais da pasta `src/common`. A pasta `rtl` deve conter apenas os
arquivos particulares do HW016.

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

   `dpdnano_hw016_dpd_top`

4. Garanta que top-levels e restricoes de outros testes estejam desabilitados.
5. Nao duplique, dentro da pasta do teste, arquivos que ja pertencem ao nucleo
   global ou aos modulos comuns, para evitar erro de modulo duplicado no Gowin.
6. Execute Synthesize, Place & Route e gere o bitstream.
7. Grave o arquivo `.fs` na FPGA.

Como rodar no PC

1. Instale o pyserial:

   `python -m pip install pyserial`

2. Execute o teste:

   `python dpdnano_hw016_dpd.py --port COM15`

3. Para gerar o grafico comparativo:

   `python plot_hw016_dpd_compare.py`

Resultado esperado

O teste deve validar, em uma unica execucao, os quatro perfis previstos pelo
controlador. O perfil A deve permanecer aproximadamente linear, enquanto os
perfis B, C e D devem apresentar rotacao de fase crescente com o aumento da
amplitude, sem overflow e sem falhas de monotonicidade acima da tolerancia
configurada no script.
