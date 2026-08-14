DPDnano-Lite HW013 - Saturacao e Overflow

Objetivo

Exercitar o DPDnano-Lite em uma regiao de nao linearidade forte para observar
o inicio de saturacao e a sinalizacao de overflow em hardware.

Este teste continua a linha do `HW012`, mas altera os coeficientes para uma
configuracao ainda mais agressiva no ramo cubico.

Coeficientes usados

- `coef1 = 0x3333 + j0` -> aproximadamente `0,40`
- `coef3 = 0x5333 + j0` -> aproximadamente `0,65`

Arquivos do teste

- Script principal:
  `dpdnano_hw013_dpd.py`
- Script de plot:
  `plot_hw013_dpd.py`
- RTL especifico do teste:
  `rtl/dpdnano_hw013_dpd_top.v`
  `rtl/dpd_controller_hw013_dpd.v`
- Restricoes:
  `rtl/dpdnano_hw013_dpd.cst`
  `rtl/dpdnano_hw013_dpd.sdc`
- Arquivos reutilizados do fluxo anterior:
  `rtl/protocol_controller_hw009_dpd.v`
  `rtl/input_memory_dualread_256x32.v`
  `rtl/output_memory_dualport_256x32.v`
  `rtl/uart_rx_27m_115200.v`
  `rtl/uart_tx_27m_115200.v`
- Dependencias globais do projeto:
  `src/rtl_v3_1/*.v`
  `src/rtl_v3_1/config.vh`
  `src/gowin_pllvr/gowin_pllvr.v`

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
   e o PLL global em `src/gowin_pllvr/gowin_pllvr.v`.
3. Defina o top module como:

   `dpdnano_hw013_dpd_top`

4. Garanta que top-levels e restricoes de outros testes estejam desabilitados.
5. Nao duplique, dentro da pasta do teste, arquivos que ja pertencem ao nucleo
   global ou ao PLL global, para evitar erro de modulo duplicado no Gowin.
6. Execute Synthesize, Place & Route e gere o bitstream.
7. Grave o arquivo `.fs` na FPGA.

Como rodar no PC

1. Instale o pyserial:

   `python -m pip install pyserial`

2. Execute o teste:

   `python dpdnano_hw013_dpd.py --port COM15`

3. Para gerar o grafico:

   `python plot_hw013_dpd.py`

Arquivos gerados

- `hw013_dpd_saturation_overflow.csv`
- `hw013_dpd_saturation_overflow.png`

Resultado esperado

O teste deve mostrar compressao forte, saturacao nas extremidades e sinalizacao
de overflow no status do DPD.

Ao final, o script deve informar:

`RESULTADO: PASS - saturacao e overflow validados`
