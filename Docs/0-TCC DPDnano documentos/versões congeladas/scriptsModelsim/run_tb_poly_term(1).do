transcript on
vsim -voptargs="+acc" work.tb_poly_term

quietly WaveActivateNextPane {} 0
add wave -divider {INPUTS}
add wave -radix decimal sim:/tb_poly_term/vin_i
add wave -radix decimal sim:/tb_poly_term/vin_q
add wave -radix decimal sim:/tb_poly_term/coef_r
add wave -radix decimal sim:/tb_poly_term/coef_i

add wave -divider {INTERNAL}
add wave -radix decimal sim:/tb_poly_term/dut/pr
add wave -radix decimal sim:/tb_poly_term/dut/pi

add wave -divider {OUTPUTS}
add wave -radix decimal sim:/tb_poly_term/vout_r
add wave -radix decimal sim:/tb_poly_term/vout_i

run -all
