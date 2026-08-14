DPDnano-Lite HW019 - Ganho Incremental

Objetivo

Caracterizar experimentalmente o ganho incremental:

`dOUT / dIN`

a partir de uma nova curva AM/AM medida na propria FPGA durante a execucao do
teste. O HW019 identifica a regiao na qual a saida ainda cresce com a entrada,
o ponto em que a derivada cruza zero e a regiao posterior ao pico, na qual a
saida passa a diminuir.

Natureza do teste

Este teste executa duas etapas dentro da propria pasta:

- aquisicao serial de uma nova curva base AM/AM na FPGA
- calculo numerico do ganho incremental a partir dessa aquisicao

O pacote foi tornado independente dos demais. Para isso, ele incorpora:

- uma pasta `rtl/` propria, renomeada para `HW019`
- scripts e resultados locais

Arquivos do teste

- Script principal:
  `dpdnano_hw019_dpd.py`
- Script de plot:
  `plot_hw019_dpd.py`
- Arquivos gerados e de referencia:
  `hw019_dpd_compression_base.csv`
  `hw019_dpd_incremental_gain.csv`
  `hw019_dpd_compression_base.png`
  `hw019_dpd_incremental_gain.png`
- RTL especifico do teste:
  `rtl/dpdnano_hw019_dpd_top.v`
  `rtl/dpd_controller_hw019_dpd.v`
- Restricoes:
  `rtl/dpdnano_hw019_dpd.cst`
  `rtl/dpdnano_hw019_dpd.sdc`

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

O HW019 possui uma subpasta `rtl/` propria para manter a independencia
estrutural em relacao aos demais testes. A aquisicao serial e a analise
numerica sao realizadas pelos scripts Python da raiz da pasta.

Como sintetizar no Gowin

1. Adicione ao projeto os arquivos especificos do teste na subpasta `rtl`.
2. Mantenha tambem adicionados os arquivos globais do nucleo em `src/rtl_v3_1`,
   o PLL global em `src/gowin_pllvr` e os modulos compartilhados em `src/common`.
3. Defina o top module como:

   `dpdnano_hw019_dpd_top`

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

   `python dpdnano_hw019_dpd.py --port COM15`

3. Para gerar as figuras em sequencia no mesmo script:

   `python plot_hw019_dpd.py`

Interpretacao

- `ganho incremental > 0`: a saida ainda cresce com a entrada
- `ganho incremental = 0`: local aproximado do pico de saida
- `ganho incremental < 0`: a curva entrou na regiao descendente apos o pico

Resultado esperado

O cruzamento por zero deve ocorrer proximo da entrada correspondente ao pico de
saida da curva base medida no proprio `HW019`.
