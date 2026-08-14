transcript on

do ./compile_tmq011_coefficient_sensitivity_gui.do

view transcript
view wave

quietly WaveActivateNextPane {} 0
delete wave *

add wave -divider {TMQ011 Control}
add wave sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/clk
add wave sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/rst
add wave sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/in_valid
add wave sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/out_valid
add wave sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/cycle_cnt
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/total_tx
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/total_rx
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/combo_idx

add wave -divider {Stimulus and Coefficients}
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/din_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/dout_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/coef1_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/coef3_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/current_coef1_q15
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/current_coef3_q15
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/input_idx

add wave -divider {Safety Evaluation}
add wave sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/overflow
add wave sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/overflow_re
add wave sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/overflow_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/current_combo_overflow
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/current_combo_xz
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/current_combo_max_abs_out
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/margin_lsb
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/current_safe_flag

add wave -divider {Global Summary}
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/safe_count
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/unsafe_count
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/max_safe_abs_c1_q15
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/max_safe_abs_c3_q15
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/best_safe_c1_q15
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/best_safe_c3_q15
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/best_safe_margin_lsb
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/first_unsafe_c1_q15
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ011_CoefficientSensitivity/first_unsafe_c3_q15

run -all

wave zoom full

puts ""
puts "======================================================================"
puts "TMQ011 GUI run finished"
puts "Artifacts expected in ../tb_v3_2/results/TMQ011"
puts "Safe Region SVG : ../tb_v3_2/results/TMQ011/tmq011_safe_region.svg"
puts "CSV Map         : ../tb_v3_2/tmq011_coefficient_sensitivity_map.csv"
puts "======================================================================"
