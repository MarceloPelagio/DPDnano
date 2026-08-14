transcript on

do ./compile_tmq013_operational_limit_stress_gui.do

view transcript
view wave

quietly WaveActivateNextPane {} 0
delete wave *

add wave -divider {TMQ013 Control}
add wave sim:/tb_dpdnano_lite_TMQ013_OperationalLimitStressTest/clk
add wave sim:/tb_dpdnano_lite_TMQ013_OperationalLimitStressTest/rst
add wave sim:/tb_dpdnano_lite_TMQ013_OperationalLimitStressTest/in_valid
add wave sim:/tb_dpdnano_lite_TMQ013_OperationalLimitStressTest/out_valid
add wave sim:/tb_dpdnano_lite_TMQ013_OperationalLimitStressTest/cycle_cnt
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ013_OperationalLimitStressTest/tx
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ013_OperationalLimitStressTest/rx
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ013_OperationalLimitStressTest/level_idx
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ013_OperationalLimitStressTest/sample_idx

add wave -divider {Stimulus and Output}
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ013_OperationalLimitStressTest/din_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ013_OperationalLimitStressTest/din_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ013_OperationalLimitStressTest/dout_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ013_OperationalLimitStressTest/dout_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ013_OperationalLimitStressTest/current_amp

add wave -divider {Stress Metrics}
add wave sim:/tb_dpdnano_lite_TMQ013_OperationalLimitStressTest/overflow
add wave sim:/tb_dpdnano_lite_TMQ013_OperationalLimitStressTest/overflow_re
add wave sim:/tb_dpdnano_lite_TMQ013_OperationalLimitStressTest/overflow_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ013_OperationalLimitStressTest/current_level_saturated_count
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ013_OperationalLimitStressTest/max_persistent_run_len
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ013_OperationalLimitStressTest/first_saturation_level
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ013_OperationalLimitStressTest/first_persistent_level
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ013_OperationalLimitStressTest/stress_score

run -all

wave zoom full

puts ""
puts "======================================================================"
puts "TMQ013 GUI run finished"
puts "Artifacts expected in ../tb_v3_2/results/TMQ013"
puts "Stress SVG : ../tb_v3_2/results/TMQ013/tmq013_operational_limit_dashboard.svg"
puts "======================================================================"
