# ============================================================
# DPDnano-Lite
# run_poly_kernel_r01.do
# Current directory:
#   .../TCC_FINAL/scriptsModelsim
# ============================================================

vsim work.tb_poly_kernel

quietly WaveActivateNextPane {} 0

add wave sim:/tb_poly_kernel/clk
add wave sim:/tb_poly_kernel/rst
add wave sim:/tb_poly_kernel/in_valid

add wave sim:/tb_poly_kernel/x_re
add wave sim:/tb_poly_kernel/x_im

add wave sim:/tb_poly_kernel/out_valid
add wave sim:/tb_poly_kernel/mag2
add wave sim:/tb_poly_kernel/term_re
add wave sim:/tb_poly_kernel/term_im

add wave -divider DUT
add wave sim:/tb_poly_kernel/dut/*

configure wave -namecolwidth 220
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1

run -all
