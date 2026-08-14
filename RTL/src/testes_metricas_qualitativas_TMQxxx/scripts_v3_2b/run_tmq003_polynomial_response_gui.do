transcript on

do ./compile_tmq003_polynomial_response_gui.do

view transcript
view wave

quietly WaveActivateNextPane {} 0
delete wave *

add wave -divider {TMQ003 Control}
add wave sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/clk
add wave sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/rst
add wave sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/in_valid
add wave sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/out_valid
add wave sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/cycle_cnt
add wave sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/level_idx
add wave sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/repeat_idx

add wave -divider {Stimulus}
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/current_amp
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/din_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/coef1_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/coef3_re

add wave -divider {Linear Term}
add wave sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/dut/lin_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/dut/lin_re
add wave sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/dut/lin_valid_d
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/dut/lin_re_d

add wave -divider {Polynomial Term}
add wave sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/dut/kern_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/dut/mag2
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/dut/term_re
add wave sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/dut/poly_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/dut/poly_re

add wave -divider {Accumulator and Output}
add wave sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/dut/acc_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/dut/acc_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/dut/round_re
add wave sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/overflow
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/dout_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization/dout_im

run -all

wave zoom full

puts ""
puts "======================================================================"
puts "TMQ003 GUI run finished"
puts "Artifacts expected in ../tb_v3_2/results/TMQ003"
puts "Plot SVG : ../tb_v3_2/results/TMQ003/tmq003_polynomial_response.svg"
puts "Curve CSV: ../tb_v3_2/results/TMQ003/tmq003_polynomial_curves.csv"
puts "======================================================================"
