vsim -voptargs=+acc work.tb_coeff_bank
add wave -radix decimal sim:/tb_coeff_bank/*
run -all
