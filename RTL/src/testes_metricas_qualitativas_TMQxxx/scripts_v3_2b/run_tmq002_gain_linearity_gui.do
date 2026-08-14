transcript on

do ./compile_tmq002_gain_linearity_gui.do

view transcript
view wave

quietly WaveActivateNextPane {} 0
delete wave *

add wave -divider {TMQ002 Control}
add wave sim:/tb_dpdnano_lite_TMQ002_GainLinearity/clk
add wave sim:/tb_dpdnano_lite_TMQ002_GainLinearity/rst
add wave sim:/tb_dpdnano_lite_TMQ002_GainLinearity/in_valid
add wave sim:/tb_dpdnano_lite_TMQ002_GainLinearity/out_valid
add wave sim:/tb_dpdnano_lite_TMQ002_GainLinearity/cycle_cnt
add wave sim:/tb_dpdnano_lite_TMQ002_GainLinearity/level_idx
add wave sim:/tb_dpdnano_lite_TMQ002_GainLinearity/repeat_idx

add wave -divider {Stimulus and Gain Target}
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ002_GainLinearity/current_amp
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ002_GainLinearity/din_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ002_GainLinearity/din_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ002_GainLinearity/coef1_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ002_GainLinearity/coef3_re

add wave -divider {Linear Path}
add wave sim:/tb_dpdnano_lite_TMQ002_GainLinearity/dut/lin_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ002_GainLinearity/dut/lin_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ002_GainLinearity/dut/lin_im
add wave sim:/tb_dpdnano_lite_TMQ002_GainLinearity/dut/lin_valid_d
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ002_GainLinearity/dut/lin_re_d

add wave -divider {Polynomial Path Disabled Check}
add wave sim:/tb_dpdnano_lite_TMQ002_GainLinearity/dut/kern_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ002_GainLinearity/dut/term_re
add wave sim:/tb_dpdnano_lite_TMQ002_GainLinearity/dut/poly_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ002_GainLinearity/dut/poly_re

add wave -divider {Accumulator and Output}
add wave sim:/tb_dpdnano_lite_TMQ002_GainLinearity/dut/acc_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ002_GainLinearity/dut/acc_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ002_GainLinearity/dut/round_re
add wave sim:/tb_dpdnano_lite_TMQ002_GainLinearity/overflow
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ002_GainLinearity/dout_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ002_GainLinearity/dout_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ002_GainLinearity/max_abs_error_re

run -all

wave zoom full

puts ""
puts "======================================================================"
puts "TMQ002 GUI run finished"
puts "Artifacts expected in ../tb_v3_2/results/TMQ002"
puts "Gain SVG : ../tb_v3_2/results/TMQ002/tmq002_gain_vs_input.svg"
puts "Gain CSV : ../tb_v3_2/results/TMQ002/tmq002_gain_vs_input.csv"
puts "======================================================================"
