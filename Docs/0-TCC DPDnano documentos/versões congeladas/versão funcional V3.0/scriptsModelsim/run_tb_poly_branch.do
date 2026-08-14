transcript on
vsim -voptargs=+acc work.tb_poly_branch
quietly WaveActivateNextPane {} 0
add wave -divider {INPUTS}
add wave sim:/tb_poly_branch/x1_i
add wave sim:/tb_poly_branch/x1_q
add wave -divider {OUTPUTS}
add wave sim:/tb_poly_branch/y_r
add wave sim:/tb_poly_branch/y_i
run -all
