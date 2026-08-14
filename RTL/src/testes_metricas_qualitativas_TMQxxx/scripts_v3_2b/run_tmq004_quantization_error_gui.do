transcript on

do ./compile_tmq004_quantization_error_gui.do

view transcript
view wave

quietly WaveActivateNextPane {} 0
delete wave *

add wave -divider {TMQ004 Control}
add wave sim:/tb_dpdnano_lite_TMQ004_QuantizationErrorAnalysis/clk
add wave sim:/tb_dpdnano_lite_TMQ004_QuantizationErrorAnalysis/rst
add wave sim:/tb_dpdnano_lite_TMQ004_QuantizationErrorAnalysis/in_valid
add wave sim:/tb_dpdnano_lite_TMQ004_QuantizationErrorAnalysis/out_valid
add wave sim:/tb_dpdnano_lite_TMQ004_QuantizationErrorAnalysis/cycle_cnt
add wave sim:/tb_dpdnano_lite_TMQ004_QuantizationErrorAnalysis/current_amp

add wave -divider {Stimulus and Coefficients}
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ004_QuantizationErrorAnalysis/din_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ004_QuantizationErrorAnalysis/coef1_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ004_QuantizationErrorAnalysis/coef3_re

add wave -divider {Accumulator and Rounding}
add wave sim:/tb_dpdnano_lite_TMQ004_QuantizationErrorAnalysis/dut/acc_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ004_QuantizationErrorAnalysis/dut/acc_re
add wave sim:/tb_dpdnano_lite_TMQ004_QuantizationErrorAnalysis/dut/round_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ004_QuantizationErrorAnalysis/dut/round_re
add wave sim:/tb_dpdnano_lite_TMQ004_QuantizationErrorAnalysis/dut/clip_re
add wave sim:/tb_dpdnano_lite_TMQ004_QuantizationErrorAnalysis/dut/clip_dir_re

add wave -divider {Output and Error Accumulation}
add wave sim:/tb_dpdnano_lite_TMQ004_QuantizationErrorAnalysis/overflow
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ004_QuantizationErrorAnalysis/dout_re
add wave sim:/tb_dpdnano_lite_TMQ004_QuantizationErrorAnalysis/ideal_q15_real
add wave sim:/tb_dpdnano_lite_TMQ004_QuantizationErrorAnalysis/error_real
add wave sim:/tb_dpdnano_lite_TMQ004_QuantizationErrorAnalysis/max_abs_error_lsb_real

run -all

wave zoom full

puts ""
puts "======================================================================"
puts "TMQ004 GUI run finished"
puts "Artifacts expected in ../tb_v3_2/results/TMQ004"
puts "Histogram SVG : ../tb_v3_2/results/TMQ004/tmq004_quantization_histogram.svg"
puts "======================================================================"
