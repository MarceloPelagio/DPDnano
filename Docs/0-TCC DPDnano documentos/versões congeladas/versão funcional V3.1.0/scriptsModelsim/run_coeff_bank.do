transcript on

vsim -voptargs="+acc" work.tb_coeff_bank

add wave sim:/tb_coeff_bank/c0_r
add wave sim:/tb_coeff_bank/c0_i
add wave sim:/tb_coeff_bank/c1_r
add wave sim:/tb_coeff_bank/c1_i
add wave sim:/tb_coeff_bank/c2_r
add wave sim:/tb_coeff_bank/c2_i

run -all
