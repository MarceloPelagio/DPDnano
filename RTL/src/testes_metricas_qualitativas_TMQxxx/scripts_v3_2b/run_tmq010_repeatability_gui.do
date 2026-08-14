transcript on

do ./compile_tmq010_repeatability_gui.do

view transcript
view wave

quietly WaveActivateNextPane {} 0
delete wave *

add wave -divider {TMQ010 Control}
add wave sim:/tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization/clk
add wave sim:/tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization/rst
add wave sim:/tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization/in_valid
add wave sim:/tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization/out_valid
add wave sim:/tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization/cycle_cnt
add wave sim:/tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization/tx
add wave sim:/tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization/rx

add wave -divider {Stimulus and Output}
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization/din_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization/din_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization/dout_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization/dout_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization/run_idx
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization/sample_idx

add wave -divider {Repeatability Check}
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization/mismatch_count
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization/mismatch_re_count
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization/mismatch_im_count
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization/first_mismatch_run
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization/first_mismatch_sample

add wave -divider {Robustness}
add wave sim:/tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization/overflow
add wave sim:/tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization/overflow_re
add wave sim:/tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization/overflow_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization/xz_errors

run -all

wave zoom full

puts ""
puts "======================================================================"
puts "TMQ010 GUI run finished"
puts "Artifacts expected in ../tb_v3_2/results/TMQ010"
puts "Repeatability SVG : ../tb_v3_2/results/TMQ010/tmq010_repeatability_dashboard.svg"
puts "======================================================================"
