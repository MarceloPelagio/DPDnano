transcript on
vsim -voptargs=+acc work.tb_poly_term
quietly WaveActivateNextPane {} 0
add wave -divider {INPUTS}
add wave -radix decimal sim:/tb_poly_term/x_i
add wave -radix decimal sim:/tb_poly_term/x_q
add wave -radix decimal sim:/tb_poly_term/scale
add wave -divider {OUTPUTS}
add wave -radix decimal sim:/tb_poly_term/y_r
add wave -radix decimal sim:/tb_poly_term/y_i
run -all
