DPDnano_Lite_v3_2
HW019_dpd - Ganho Incremental
=============================

OBJETIVO
--------
Calcular experimentalmente:

dOUT / dIN

a partir do CSV obtido no HW018_dpd.

Este teste não exige:

- nova síntese;
- novo Place & Route;
- regravação da FPGA;
- comunicação UART.

ORGANIZAÇÃO
-----------
Descompacte dentro de /src e execute:

python organize_hw019.py

O script organizará:

src/python/hw019
src/results/hw019
src/tools

A pasta rtl_v3_2 não será alterada.
A pasta common não será alterada.

ENTRADA
-------
O teste utiliza:

src/results/hw018/hw018_dpd_compression_p1db.csv

EXECUÇÃO
--------
A partir de src/python/hw019:

python dpdnano_hw019_dpd.py

GRÁFICO
-------
python plot_hw019_dpd.py

RESULTADOS
----------
src/results/hw019/hw019_dpd_incremental_gain.csv
src/results/hw019/hw019_dpd_incremental_gain.png

INTERPRETAÇÃO
-------------
O ganho incremental positivo indica que a saída ainda cresce.

Quando dOUT/dIN = 0, a saída atinge seu valor máximo.

Quando dOUT/dIN < 0, o modelo está na região de compressão forte,
na qual a saída diminui mesmo com o aumento da entrada.

RESULTADO ESPERADO
------------------
O cruzamento por zero deve ocorrer próximo da entrada correspondente
ao pico de saída medido no HW018.
