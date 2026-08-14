vsim work.tb_rounding

add wave sim:/tb_rounding/clk
add wave sim:/tb_rounding/rst
add wave sim:/tb_rounding/in_valid
add wave sim:/tb_rounding/din_re
add wave sim:/tb_rounding/din_im
add wave sim:/tb_rounding/out_valid
add wave sim:/tb_rounding/dout_re
add wave sim:/tb_rounding/dout_im
add wave sim:/tb_rounding/dut/*

run -all
