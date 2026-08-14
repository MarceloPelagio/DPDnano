vsim work.tb_poly_branch

add wave sim:/tb_poly_branch/clk
add wave sim:/tb_poly_branch/rst
add wave sim:/tb_poly_branch/in_valid
add wave sim:/tb_poly_branch/term_re
add wave sim:/tb_poly_branch/term_im
add wave sim:/tb_poly_branch/coef_re
add wave sim:/tb_poly_branch/coef_im
add wave sim:/tb_poly_branch/out_valid
add wave sim:/tb_poly_branch/branch_re
add wave sim:/tb_poly_branch/branch_im
add wave sim:/tb_poly_branch/dut/*

run -all
