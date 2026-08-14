transcript on
vsim -voptargs="+acc" work.tb_dpdnano_lite_TC005
view wave

add wave -divider INPUTS
add wave sim:/tb_dpdnano_lite_TC005/clk
add wave sim:/tb_dpdnano_lite_TC005/rst
add wave sim:/tb_dpdnano_lite_TC005/in_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TC005/din_re
add wave -radix decimal sim:/tb_dpdnano_lite_TC005/din_im

add wave -divider KERNEL
add wave sim:/tb_dpdnano_lite_TC005/dut/kern_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TC005/dut/mag2
add wave -radix decimal sim:/tb_dpdnano_lite_TC005/dut/term_re
add wave -radix decimal sim:/tb_dpdnano_lite_TC005/dut/term_im

add wave -divider POLY
add wave sim:/tb_dpdnano_lite_TC005/dut/poly_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TC005/dut/poly_re
add wave -radix decimal sim:/tb_dpdnano_lite_TC005/dut/poly_im

add wave -divider LINEAR
add wave sim:/tb_dpdnano_lite_TC005/dut/lin_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TC005/dut/lin_re
add wave -radix decimal sim:/tb_dpdnano_lite_TC005/dut/lin_im

add wave -divider ACC
add wave sim:/tb_dpdnano_lite_TC005/dut/acc_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TC005/dut/acc_re
add wave -radix decimal sim:/tb_dpdnano_lite_TC005/dut/acc_im

add wave -divider ROUND
add wave sim:/tb_dpdnano_lite_TC005/dut/round_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TC005/dut/round_re
add wave -radix decimal sim:/tb_dpdnano_lite_TC005/dut/round_im

add wave -divider OUTPUT
add wave sim:/tb_dpdnano_lite_TC005/dut/out_valid
add wave -radix decimal sim:/tb_dpdnano_lite_TC005/dut/dout_re
add wave -radix decimal sim:/tb_dpdnano_lite_TC005/dut/dout_im

run -all
wave zoom full
