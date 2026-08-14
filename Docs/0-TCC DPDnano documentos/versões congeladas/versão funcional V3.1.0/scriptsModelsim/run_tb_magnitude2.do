vsim -voptargs=+acc work.tb_magnitude2
add wave -radix decimal sim:/tb_magnitude2/*
run -all
