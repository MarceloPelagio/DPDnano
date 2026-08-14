vsim -voptargs=+acc work.tb_saturator
add wave -radix decimal sim:/tb_saturator/*
run -all
