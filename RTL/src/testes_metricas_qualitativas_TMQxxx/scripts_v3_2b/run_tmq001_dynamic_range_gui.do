transcript on

do ./compile_tmq001_dynamic_range_gui.do

view transcript
view wave

quietly WaveActivateNextPane {} 0
delete wave *

add wave -divider {TMQ001 Control}
add wave sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/clk
add wave sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/rst
add wave sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/in_valid
add wave sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/out_valid
add wave sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/cycle_cnt
add wave sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/tx
add wave sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/rx

add wave -divider {Stimulus}
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/din_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/din_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/amp_code
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/pattern_sel
add wave -radix hexadecimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/lfsr

add wave -divider {Coefficients}
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/coef1_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/coef1_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/coef3_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/coef3_im

add wave -divider {Linear Branch}
add wave sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dut/lin_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dut/lin_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dut/lin_im
add wave sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dut/lin_valid_d
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dut/lin_re_d
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dut/lin_im_d

add wave -divider {Polynomial Kernel}
add wave sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dut/kern_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dut/mag2
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dut/term_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dut/term_im

add wave -divider {Polynomial Branch}
add wave sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dut/poly_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dut/poly_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dut/poly_im

add wave -divider {Accumulator}
add wave sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dut/acc_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dut/acc_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dut/acc_im

add wave -divider {Rounding}
add wave sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dut/round_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dut/round_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dut/round_im
add wave sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dut/clip_re
add wave sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dut/clip_im
add wave sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dut/clip_dir_re
add wave sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dut/clip_dir_im

add wave -divider {Output and Overflow}
add wave sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/overflow
add wave sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/overflow_re
add wave sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/overflow_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dout_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization/dout_im

run -all

wave zoom full

puts ""
puts "======================================================================"
puts "TMQ001 GUI run finished"
puts "Artifacts expected in ../tb_v3_2"
puts "CSV     : ../tb_v3_2/tmq001_dynamic_range_samples.csv"
puts "Summary : ../tb_v3_2/tmq001_dynamic_range_summary.txt"
puts "======================================================================"
