transcript on
vsim -voptargs="+acc" work.tb_mult_generic
add wave -radix decimal sim:/tb_mult_generic/a
add wave -radix decimal sim:/tb_mult_generic/b
add wave -radix decimal sim:/tb_mult_generic/p
run -all
