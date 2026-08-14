DPDnano_Lite_v3_2
HW023_dpd - Três Gráficos Finais
================================

OBJETIVO
--------
Substituir o gráfico de throughput acumulado por três gráficos
mais claros para o TCC e para a apresentação:

1. Latência x amostras processadas
2. Throughput instantâneo por bloco de 100.000 amostras
3. Checkpoints de integridade

NÃO É NECESSÁRIO
----------------
- ressintetizar;
- regravar a FPGA;
- repetir o teste HW023;
- usar a porta UART.

O script utiliza os CSVs já gerados:

../../results/hw023/hw023_dpd_stress_summary.csv
../../results/hw023/hw023_dpd_checkpoints.csv

INSTALAÇÃO
----------
Copie plot_hw023_all.py para:

src/python/hw023/

Substitua também o plot_hw023_throughput.py antigo pelo arquivo
fornecido neste pacote, caso deseje manter o nome antigo.

EXECUÇÃO
--------
A partir de src/python/hw023:

python plot_hw023_all.py

ARQUIVOS GERADOS
----------------
src/results/hw023/hw023_dpd_latency_stability.png

src/results/hw023/hw023_dpd_instantaneous_throughput.png

src/results/hw023/hw023_dpd_integrity_checkpoints.png

INTERPRETAÇÃO
-------------
O gráfico de throughput instantâneo calcula a taxa em cada intervalo
entre dois checkpoints consecutivos. Dessa forma, os seis ciclos
iniciais não são novamente acumulados em todos os pontos.

A latência é apresentada como uma linha constante de seis ciclos,
conforme as métricas mínima, máxima e média medidas pelo HW023.

O gráfico de checkpoints mostra PASS quando permanecem nulos:

- jitter;
- perdas;
- duplicações;
- reordenação;
- erros da fila.
