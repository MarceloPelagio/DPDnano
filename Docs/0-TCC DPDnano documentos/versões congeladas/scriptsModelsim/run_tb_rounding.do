vsim -voptargs=+acc work.tb_rounding
add wave -radix decimal sim:/tb_rounding/*
run -all
