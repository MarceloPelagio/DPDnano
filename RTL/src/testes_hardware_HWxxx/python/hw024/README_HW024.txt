DPDnano_Lite_v3_2
HW024_dpd - Reprodutibilidade em 10 Execuções
==============================================

OBJETIVO
--------
Repetir automaticamente dez vezes o ensaio HW023.

Cada execução utiliza:

- 1.000.000 de amostras;
- clock de 100 MHz;
- fluxo contínuo;
- entradas I/Q pseudoaleatórias;
- cinco perfis dinâmicos;
- atualização dos coeficientes a cada 256 amostras;
- saturação e overflow monitorados.

TOTAL PADRÃO
------------
10 execuções x 1.000.000 = 10.000.000 de amostras.

IMPORTANTE
----------
O HW024 reutiliza o bitstream aprovado do HW023.

Não é necessário:

- alterar RTL;
- ressintetizar;
- executar Place & Route;
- regravar a FPGA.

ORGANIZAÇÃO
-----------
Descompacte dentro de /src e execute:

python organize_hw024.py

EXECUÇÃO
--------
A partir de src/python/hw024:

python dpdnano_hw024_dpd.py --port COM15

Teste reduzido:

python dpdnano_hw024_dpd.py --port COM15 --runs 3 --samples 100000

GRÁFICOS
--------
python plot_hw024_dpd.py

RESULTADOS
----------
src/results/hw024/

Arquivos CSV:

hw024_dpd_reproducibility_runs.csv
hw024_dpd_reproducibility_summary.csv
hw024_dpd_reproducibility_checkpoints.csv

Gráficos:

hw024_dpd_latency_by_run.png
hw024_dpd_throughput_by_run.png
hw024_dpd_overflow_by_run.png
hw024_dpd_results_by_run.png

CRITÉRIO DE PASS
----------------
- todas as execuções aprovadas;
- assinaturas de entrada idênticas;
- assinaturas de saída idênticas;
- latência sem variação;
- zero perdas;
- zero duplicações;
- zero reordenação;
- zero erros da fila;
- jitter zero.
