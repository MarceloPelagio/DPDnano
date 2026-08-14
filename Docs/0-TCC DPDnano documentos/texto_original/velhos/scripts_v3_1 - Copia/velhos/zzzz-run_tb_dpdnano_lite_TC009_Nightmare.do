transcript on

vsim -voptargs="+acc" work.tb_dpdnano_lite_TC009_Nightmare

quietly WaveActivateNextPane {} 0

add wave -divider {Clock / Reset}
add wave sim:/tb_dpdnano_lite_TC009_Nightmare/clk
add wave sim:/tb_dpdnano_lite_TC009_Nightmare/rst

add wave -divider {Input}
add wave sim:/tb_dpdnano_lite_TC009_Nightmare/in_valid
add wave sim:/tb_dpdnano_lite_TC009_Nightmare/din_re
add wave sim:/tb_dpdnano_lite_TC009_Nightmare/din_im

add wave -divider {Coefficients}
add wave sim:/tb_dpdnano_lite_TC009_Nightmare/coef1_re
add wave sim:/tb_dpdnano_lite_TC009_Nightmare/coef1_im
add wave sim:/tb_dpdnano_lite_TC009_Nightmare/coef3_re
add wave sim:/tb_dpdnano_lite_TC009_Nightmare/coef3_im

add wave -divider {Output}
add wave sim:/tb_dpdnano_lite_TC009_Nightmare/out_valid
add wave sim:/tb_dpdnano_lite_TC009_Nightmare/dout_re
add wave sim:/tb_dpdnano_lite_TC009_Nightmare/dout_im

add wave -divider {Overflow}
add wave sim:/tb_dpdnano_lite_TC009_Nightmare/overflow
add wave sim:/tb_dpdnano_lite_TC009_Nightmare/overflow_re
add wave sim:/tb_dpdnano_lite_TC009_Nightmare/overflow_im

add wave -divider {Counters}
add wave sim:/tb_dpdnano_lite_TC009_Nightmare/tx
add wave sim:/tb_dpdnano_lite_TC009_Nightmare/rx
add wave sim:/tb_dpdnano_lite_TC009_Nightmare/cycle_cnt
add wave sim:/tb_dpdnano_lite_TC009_Nightmare/pipeline_latency
add wave sim:/tb_dpdnano_lite_TC009_Nightmare/timeout

run -all

wave zoom full
