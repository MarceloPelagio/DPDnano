DPDnano-Lite HW011 - Random FPGA x Python Comparison

Objetivo

Ampliar a validacao do `HW010` para uma campanha com ate `256` vetores I/Q,
comparando a saida da FPGA com o modelo Python de referencia em ponto fixo.

Este teste foi criado para aumentar a cobertura estatistica sem alterar a
arquitetura ja congelada do hardware.

Importante: nao ha alteracao no RTL

O `HW011` reutiliza o mesmo comportamento funcional do `HW010`, mas nesta
organizacao do repositorio o pacote foi renomeado para identidade propria.

- Top module: `dpdnano_hw011_dpd_top`
- `coef1 = 0x6000 + j0` -> `0,75`
- `coef3 = 0x1000 + j0` -> `0,125`

Na versao antiga do teste, o bitstream era reaproveitado diretamente do
`HW010`. Na organizacao atual, os arquivos RTL do `HW011` continuam derivados
do `HW010`, mas foram renomeados para manter consistencia de nomenclatura.

Arquivos do teste

- Script de execucao no PC:
  `dpdnano_hw011_dpd.py`
- Copia de referencia do RTL derivado do `HW010`:
  subpasta `rtl`

O conteudo de `rtl` foi mantido funcionalmente equivalente ao hardware do
`HW010`, mas com nomes de arquivos e top module alinhados ao `HW011`.

Configuracao UART validada

- Baud rate: `115200`
- Formato: `8N1`

Conexoes

- FPGA pino 39 (`uart_tx_o`) -> RXD do adaptador USB/TTL
- FPGA pino 40 (`uart_rx_i`) <- TXD do adaptador USB/TTL
- GND da FPGA -> GND do adaptador
- Nao ligar VCC entre as placas

Como rodar no PC

1. Garanta que a FPGA esteja com o bitstream do `HW010`.
2. Instale o pyserial:

   `python -m pip install pyserial`

3. Execute o teste padrao:

   `python dpdnano_hw011_dpd.py --port COM15`

Teste padrao

- `256` vetores
- amplitude maxima `+-12000`
- `seed = 11011`
- tolerancia `1 LSB`

Outros exemplos

- Exibir todas as amostras:
  `python dpdnano_hw011_dpd.py --port COM15 --show-all`
- Rodar `128` vetores:
  `python dpdnano_hw011_dpd.py --port COM15 --count 128`
- Usar outra `seed`:
  `python dpdnano_hw011_dpd.py --port COM15 --seed 12345`
- Alterar amplitude:
  `python dpdnano_hw011_dpd.py --port COM15 --amplitude 10000`
- Medir coincidencia estrita:
  `python dpdnano_hw011_dpd.py --port COM15 --tolerance 0`

Metricas apresentadas

- quantidade de amostras
- componentes I/Q avaliados
- quantidade de pares I/Q com coincidencia exata
- erro absoluto maximo
- erro absoluto medio
- distribuicao dos erros em LSB
- indicacao de overflow
- quantidade de amostras fora da tolerancia

Resultado esperado

Ao final, o script deve informar:

`RESULTADO: PASS - comparacao aleatoria FPGA x Python validada`

Observacao

A tolerancia padrao foi reduzida em relacao ao `HW010`, porque o teste anterior
ja mostrou erro maximo observado de apenas `+-1 LSB`.
