transcript on

do ./compile_tmq006_pipeline_timing_gui.do

view transcript
view wave

quietly WaveActivateNextPane {} 0
delete wave *

add wave -divider {TMQ006 Control}
add wave sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/clk
add wave sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/rst
add wave sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/in_valid
add wave sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/out_valid
add wave sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/cycle_cnt
add wave sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/tx
add wave sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/rx

add wave -divider {Stimulus and Coefficients}
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/din_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/din_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/coef1_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/coef1_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/coef3_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/coef3_im

add wave -divider {Pipeline Timing}
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/latency_cycles
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/input_gap
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/output_gap
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/latency_min
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/latency_max
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/input_gap_min
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/output_gap_min

add wave -divider {DUT Path}
add wave sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/dut/lin_valid
add wave sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/dut/kern_valid
add wave sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/dut/poly_valid
add wave sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/dut/acc_valid
add wave sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/dut/round_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/dout_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization/dout_im

run -all

wave zoom full

puts ""
puts "======================================================================"
puts "TMQ006 GUI run finished"
puts "Artifacts expected in ../tb_v3_2/results/TMQ006"
puts "Timing SVG : ../tb_v3_2/results/TMQ006/tmq006_pipeline_timing_table.svg"
puts "======================================================================"
