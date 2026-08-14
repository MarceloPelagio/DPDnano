transcript on

do ./compile_tmq007_stability_gui.do

view transcript
view wave

quietly WaveActivateNextPane {} 0
delete wave *

add wave -divider {TMQ007 Control}
add wave sim:/tb_dpdnano_lite_TMQ007_StabilityTest/clk
add wave sim:/tb_dpdnano_lite_TMQ007_StabilityTest/rst
add wave sim:/tb_dpdnano_lite_TMQ007_StabilityTest/in_valid
add wave sim:/tb_dpdnano_lite_TMQ007_StabilityTest/out_valid
add wave sim:/tb_dpdnano_lite_TMQ007_StabilityTest/cycle_cnt
add wave sim:/tb_dpdnano_lite_TMQ007_StabilityTest/tx
add wave sim:/tb_dpdnano_lite_TMQ007_StabilityTest/rx

add wave -divider {Stimulus and Coefficients}
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ007_StabilityTest/din_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ007_StabilityTest/din_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ007_StabilityTest/coef1_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ007_StabilityTest/coef1_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ007_StabilityTest/coef3_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ007_StabilityTest/coef3_im

add wave -divider {Robustness Flags}
add wave sim:/tb_dpdnano_lite_TMQ007_StabilityTest/overflow
add wave sim:/tb_dpdnano_lite_TMQ007_StabilityTest/overflow_re
add wave sim:/tb_dpdnano_lite_TMQ007_StabilityTest/overflow_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ007_StabilityTest/xz_errors
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ007_StabilityTest/logical_nan_errors
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ007_StabilityTest/glitch_errors
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ007_StabilityTest/stall_errors
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ007_StabilityTest/oscillation_flags

add wave -divider {Output Activity}
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ007_StabilityTest/dout_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ007_StabilityTest/dout_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ007_StabilityTest/same_output_run
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ007_StabilityTest/max_same_output_run

run -all

wave zoom full

puts ""
puts "======================================================================"
puts "TMQ007 GUI run finished"
puts "Artifacts expected in ../tb_v3_2/results/TMQ007"
puts "Stability SVG : ../tb_v3_2/results/TMQ007/tmq007_stability_dashboard.svg"
puts "======================================================================"
