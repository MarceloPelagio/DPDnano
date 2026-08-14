transcript on

do ./compile_tmq005_numerical_precision_gui.do

view transcript
view wave

quietly WaveActivateNextPane {} 0
delete wave *

add wave -divider {TMQ005 Control}
add wave sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/clk
add wave sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/rst
add wave sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/in_valid
add wave sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/out_valid
add wave sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/cycle_cnt
add wave sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/current_amp

add wave -divider {Stimulus and Coefficients}
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/din_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/din_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/coef1_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/coef1_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/coef3_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/coef3_im

add wave -divider {Internal Precision Path}
add wave sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/dut/acc_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/dut/acc_re
add wave sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/dut/round_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/dut/round_re
add wave sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/dut/clip_re
add wave sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/dut/clip_dir_re

add wave -divider {Output and Precision Metrics}
add wave sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/overflow
add wave sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/overflow_re
add wave sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/overflow_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/dout_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/dout_im
add wave sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/ideal_re_q15_real
add wave sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/ideal_im_q15_real
add wave sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/clipped_re_q15_real
add wave sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/clipped_im_q15_real
add wave sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/error_re_real
add wave sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/error_im_real
add wave sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/error_mag_real
add wave sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/max_abs_error_mag_lsb
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ005_NumericalPrecision/saturation_points

run -all

wave zoom full

puts ""
puts "======================================================================"
puts "TMQ005 GUI run finished"
puts "Artifacts expected in ../tb_v3_2/results/TMQ005"
puts "Precision SVG : ../tb_v3_2/results/TMQ005/tmq005_numerical_precision_bars.svg"
puts "======================================================================"
