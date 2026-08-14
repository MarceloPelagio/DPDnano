transcript on
vsim -voptargs=\"+acc\" work.tb_acc_mult
add wave -radix decimal sim:/tb_acc_mult/a
add wave -radix decimal sim:/tb_acc_mult/b
add wave -radix decimal sim:/tb_acc_mult/p
run -all
