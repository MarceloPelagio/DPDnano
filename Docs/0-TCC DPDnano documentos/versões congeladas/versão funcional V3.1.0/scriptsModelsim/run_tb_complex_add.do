vsim -voptargs=+acc work.tb_complex_add

quietly WaveActivateNextPane {} 0

add wave -radix decimal sim:/tb_complex_add/ar
add wave -radix decimal sim:/tb_complex_add/ai
add wave -radix decimal sim:/tb_complex_add/br
add wave -radix decimal sim:/tb_complex_add/bi

add wave -radix decimal sim:/tb_complex_add/sr
add wave -radix decimal sim:/tb_complex_add/si

configure wave -namecolwidth 220
configure wave -valuecolwidth 120
configure wave -timelineunits ns

run -all
