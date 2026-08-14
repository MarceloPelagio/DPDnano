# ============================================================
# DPDnano-Lite
# run_complex_mult_r06.do
# Current directory:
#   C:/ProjetosGithub/TCC_CHIP_DIGITAL/TCC_FINAL/scriptsModelsim
# ============================================================

vsim work.tb_complex_mult

quietly WaveActivateNextPane {} 0

add wave sim:/tb_complex_mult/clk
add wave sim:/tb_complex_mult/rst
add wave sim:/tb_complex_mult/in_valid

add wave sim:/tb_complex_mult/a_re
add wave sim:/tb_complex_mult/a_im
add wave sim:/tb_complex_mult/b_re
add wave sim:/tb_complex_mult/b_im

add wave sim:/tb_complex_mult/out_valid
add wave sim:/tb_complex_mult/y_re
add wave sim:/tb_complex_mult/y_im

add wave -divider DUT
add wave sim:/tb_complex_mult/dut/*

configure wave -namecolwidth 220
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1

run -all
