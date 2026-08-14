DPDnano_Lite_v3_2
HW016_dpd vr02 - Multi-Profile One Run
======================================

OBJETIVO
--------
Executar quatro perfis AM/PM em uma única gravação da FPGA e em uma
única execução do script Python.

PERFIS
-------
Todos utilizam:

coef1 = 0x3333 + j0x0000 ≈ 0,40 + j0,00
coef3_re = 0x0000

Perfil A:
coef3_im = 0x0000 ≈ 0,00

Perfil B:
coef3_im = 0x0CCD ≈ 0,10

Perfil C:
coef3_im = 0x199A ≈ 0,20

Perfil D:
coef3_im = 0x2CCD ≈ 0,35

SELEÇÃO EM TEMPO DE EXECUÇÃO
----------------------------
O protocolo adiciona:

CMD_PROFILE = 0x42

O script Python seleciona automaticamente A, B, C e D, processa os
256 pontos de cada perfil, salva os resultados e produz um CSV consolidado.

ARQUIVOS NOVOS
--------------
dpdnano_hw016_dpd_top.v
dpd_controller_hw016_dpd.v
protocol_controller_hw016_dpd.v
dpdnano_hw016_dpd.py
plot_hw016_dpd_compare.py
dpdnano_hw016_dpd.cst
dpdnano_hw016_dpd.sdc

REUTILIZAR
----------
input_memory_dualread_256x32.v
output_memory_dualport_256x32.v
uart_rx_27m_115200.v
uart_tx_27m_115200.v
módulos rtl_v3_1 utilizados pelo dpd_core

Não use protocol_controller_hw009_dpd no top do HW016 vr02.
O top instancia protocol_controller_hw016_dpd.

TOP MODULE
----------
dpdnano_hw016_dpd_top

GOWIN
-----
1. Use otimização Auto/Balanced.
2. Clean impl.
3. Synthesize.
4. Confirme que o uso de DSP é <= 4.
5. Place & Route.
6. SRAM Program.

TESTE ÚNICO
-----------
python dpdnano_hw016_dpd.py --port COM15

ARQUIVOS GERADOS
----------------
hw016_profile_A.csv
hw016_profile_B.csv
hw016_profile_C.csv
hw016_profile_D.csv
hw016_dpd_all_profiles.csv

GRÁFICO COMPARATIVO
-------------------
python plot_hw016_dpd_compare.py

Arquivo:

hw016_dpd_ampm_comparison.png

CORES
-----
Perfil A: azul
Perfil B: verde
Perfil C: vermelho
Perfil D: preto

RESULTADO ESPERADO
------------------
RESULTADO: PASS - quatro perfis AM/PM validados em uma execução

OBSERVAÇÃO IMPORTANTE
---------------------
A seleção dinâmica pode modificar a inferência de DSP em relação ao
HW015, porque coef3_im deixa de ser uma constante única. Antes de gravar,
confirme no relatório que o projeto cabe no dispositivo. Se o uso exceder
4 DSPs, não prossiga para Place & Route e envie o relatório.
