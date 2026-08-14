DPDnano_Lite_v3_2 - HW010_dpd Cubic Model
================================================

OBJETIVO
--------
Ativar o ramo cúbico do DPDnano-Lite e comparar a saída da FPGA com
um primeiro modelo Python de referência em ponto fixo.

COEFICIENTES
------------
coef1 = 0x6000 + j0 = 0,75
coef3 = 0x1000 + j0 = 0,125

ARQUIVOS NOVOS
--------------
dpdnano_hw010_dpd_top.v
dpd_controller_hw010_dpd.v
dpdnano_hw010_dpd.py
dpdnano_hw010_dpd.cst
dpdnano_hw010_dpd.sdc

REUTILIZAR DO HW009_dpd
-----------------------
protocol_controller_hw009_dpd.v
input_memory_dualread_256x32.v
output_memory_dualport_256x32.v
uart_rx_27m_115200.v
uart_tx_27m_115200.v

Também manter todos os módulos congelados de rtl_v3_1 usados pelo dpd_core.

TOP MODULE
----------
dpdnano_hw010_dpd_top

PROCEDIMENTO
------------
1. Adicione os arquivos novos.
2. Mantenha apenas uma cópia dos arquivos reutilizados.
3. Ative somente o CST e SDC do HW010_dpd.
4. Limpe impl.
5. Execute Synthesize.
6. Execute Place & Route.
7. Grave o novo .fs.
8. Execute:

python dpdnano_hw010_dpd.py --port COM15

A tolerância padrão é 4 LSB:

python dpdnano_hw010_dpd.py --port COM15 --tolerance 4

OBSERVAÇÃO
----------
Este é o primeiro modelo Python do ramo cúbico. Caso apareça uma diferença
sistemática pequena, ela será usada para ajustar o tratamento bit-accurate
do estágio de arredondamento no próximo refinamento, sem alterar o RTL.
