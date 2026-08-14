quietly WaveActivateNextPane {} 0

add wave -radix decimal sim:/tb_complex_mult/ar
add wave -radix decimal sim:/tb_complex_mult/ai

add wave -radix decimal sim:/tb_complex_mult/br
add wave -radix decimal sim:/tb_complex_mult/bi

add wave -radix decimal sim:/tb_complex_mult/pr
add wave -radix decimal sim:/tb_complex_mult/pi

configure wave -namecolwidth 220
configure wave -valuecolwidth 120
configure wave -timelineunits ns
update
