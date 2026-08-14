transcript on

do ./compile_tmq012_complex_coefficient_sensitivity_gui.do

view transcript
view wave

quietly WaveActivateNextPane {} 0
delete wave *

add wave -divider {TMQ012 Control}
add wave sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/clk
add wave sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/rst
add wave sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/in_valid
add wave sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/out_valid
add wave sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/cycle_cnt
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/total_tx
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/total_rx
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/combo_idx

add wave -divider {Stimulus and Coefficients}
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/din_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/din_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/dout_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/dout_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/coef1_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/coef1_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/coef3_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/coef3_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/current_c1_mag_q15
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/current_c3_mag_q15
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/c1_phase_idx
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/c3_phase_idx
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/in_amp_idx
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/in_phase_idx

add wave -divider {Safety Evaluation}
add wave sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/overflow
add wave sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/overflow_re
add wave sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/overflow_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/current_combo_overflow
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/current_combo_xz
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/current_combo_max_abs_out
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/margin_lsb
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/current_safe_flag

add wave -divider {Global Summary}
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/safe_count
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/unsafe_count
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/max_safe_abs_c1_mag_q15
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/max_safe_abs_c3_mag_q15
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/best_safe_c1_mag_q15
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/best_safe_c3_mag_q15
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity/best_safe_margin_lsb

run -all

wave zoom full

puts ""
puts "======================================================================"
puts "TMQ012 GUI run finished"
puts "Artifacts expected in ../tb_v3_2/results/TMQ012"
puts "Safe Region SVG : ../tb_v3_2/results/TMQ012/tmq012_complex_safe_region.svg"
puts "CSV Map         : ../tb_v3_2/tmq012_complex_coefficient_sensitivity_map.csv"
puts "======================================================================"
