DPDnano-Lite HW024 - Reprodutibilidade Estatistica

Objetivo

Repetir automaticamente o ensaio de stress do `HW023` por multiplas execucoes,
mantendo o mesmo bitstream aprovado, para avaliar reprodutibilidade,
estabilidade temporal e consistencia estatistica entre repeticoes.

Natureza do teste
-----------------

O `HW024` e uma campanha de reprodutibilidade baseada no mesmo conceito de
ensaio aprovado no `HW023`, mas empacotada de forma independente. Para manter
o pacote autocontido para quem baixar apenas este teste, os arquivos RTL
correspondentes ao hardware-base foram copiados e renomeados localmente dentro
da pasta `rtl` deste proprio `HW024`. Assim, o usuario nao precisa sair
buscando arquivos espalhados pelo repositorio para sintetizar ou conferir a
base utilizada no ensaio.

O objetivo do `HW024` e executar repetidamente esse mesmo hardware para
comparar:

- latencia;
- throughput;
- overflow;
- dispersao estatistica de overflow e saturacao;
- assinaturas de entrada;
- assinaturas de saida;
- resultado PASS/FAIL por execucao.

Configuracao congelada deste pacote
-----------------------------------

- Bitstream utilizado: `HW023`
- Clock interno do DPD: `60 MHz`
- PLL global: `src/gowin_pllvr/gowin_pllvr.v`
- Nucleo DPD congelado: `src/rtl_v3_1/*.v`
- Fluxo continuo
- Ensaios repetidos em FPGA real via UART

Arquivos do teste
-----------------

- Script principal:
  `dpdnano_hw024_dpd.py`
- Script unico de plot:
  `plot_hw024_dpd.py`
- Base RTL incluida localmente para independencia do pacote:
  `rtl/dpdnano_hw024_dpd_top.v`
  `rtl/dpd_stress_engine_hw024.v`
  `rtl/protocol_controller_hw024_dpd.v`
  `rtl/command_cdc_hw024_dpd.v`
  `rtl/status_cdc_hw024_dpd.v`
  `rtl/checkpoint_cdc_hw024_dpd.v`
  `rtl/dpdnano_hw024_dpd.cst`
  `rtl/dpdnano_hw024_dpd.sdc`
- Arquivos gerados:
  `hw024_dpd_reproducibility_runs.csv`
  `hw024_dpd_reproducibility_summary.csv`
  `hw024_dpd_reproducibility_checkpoints.csv`
  `hw024_dpd_latency_by_run.png`
  `hw024_dpd_throughput_by_run.png`
  `hw024_dpd_overflow_by_run.png`
  `hw024_dpd_results_by_run.png`

Observacao sobre a pasta rtl
----------------------------

Os arquivos presentes em `hw024/rtl` correspondem ao hardware-base utilizado
na campanha estatistica. Em outras palavras, o `HW024` reaproveita a mesma
linha de arquitetura validada anteriormente, mas agora com todos esses arquivos
copiados e renomeados localmente para preservar a independencia do pacote.

Esse arranjo permite dois usos corretos:

- sintetizar diretamente a partir da propria pasta `hw024/rtl`, sem procurar
  arquivos em outros testes;
- ou simplesmente reutilizar um bitstream ja aprovado dessa mesma base local.

Conexoes
--------

- FPGA pino 39 (`uart_tx_o`) -> RXD do adaptador USB/TTL
- FPGA pino 40 (`uart_rx_i`) <- TXD do adaptador USB/TTL
- GND da FPGA -> GND do adaptador
- Nao ligar VCC entre as placas

Como sintetizar no Gowin
------------------------

1. Adicione ao projeto os arquivos da pasta `hw024/rtl`.
2. Mantenha tambem adicionados os arquivos globais do nucleo em `src/rtl_v3_1`,
   o PLL global em `src/gowin_pllvr` e os modulos compartilhados em `src/common`.
3. Defina o top module como:

   `dpdnano_hw024_dpd_top`

4. Garanta que top-levels e restricoes de outros testes estejam desabilitados.
5. Execute Synthesize, Place & Route e gere o bitstream.
6. Grave o arquivo `.fs` na FPGA.

Como rodar no PC
----------------

1. Instale o pyserial:

   `python -m pip install pyserial`

2. Execute a campanha padrao:

   `python dpdnano_hw024_dpd.py --port COM15`

3. Para campanha reduzida:

   `python dpdnano_hw024_dpd.py --port COM15 --runs 3 --samples 100000`

4. Gere as figuras:

   `python plot_hw024_dpd.py`

Parametros padrao
-----------------

- `runs = 10`
- `samples = 1000000`

Ou seja, a campanha completa cobre `10.000.000` de amostras processadas.

Criterio esperado
-----------------

PASS quando:

- todas as execucoes aprovarem individualmente;
- as assinaturas de entrada forem identicas entre runs;
- a latencia nao variar entre execucoes;
- houver zero perdas, zero duplicacoes e zero reordenacao;
- houver zero erros da fila;
- o jitter permanecer nulo.

Observacao importante
---------------------

Na configuracao congelada em `60 MHz`, a aprovacao final do `HW024` e tratada
como um criterio de reprodutibilidade estatistica. Isso significa que o teste
exige estabilidade temporal e funcional completa entre execucoes, enquanto a
assinatura agregada de saida passa a ser reportada como indicador auxiliar do
ensaio, sem bloquear o PASS final quando todas as demais metricas permanecem
estaveis.
