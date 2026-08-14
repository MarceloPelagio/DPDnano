vsim work.tb_saturator

add wave sim:/tb_saturator/clk
add wave sim:/tb_saturator/rst
add wave sim:/tb_saturator/in_valid
add wave sim:/tb_saturator/din_re
add wave sim:/tb_saturator/din_im
add wave sim:/tb_saturator/out_valid
add wave sim:/tb_saturator/dout_re
add wave sim:/tb_saturator/dout_im
add wave sim:/tb_saturator/dut/*

run -all
