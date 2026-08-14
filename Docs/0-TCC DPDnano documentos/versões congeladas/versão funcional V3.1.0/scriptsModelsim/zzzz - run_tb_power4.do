transcript on

vsim -voptargs="+acc" work.tb_power4

quietly WaveActivateNextPane {} 0

add wave -divider {INPUTS}
add wave -radix decimal sim:/tb_power4/mag2

add wave -divider {INTERNAL}
add wave -radix decimal sim:/tb_power4/dut/p

add wave -divider {OUTPUTS}
add wave -radix decimal sim:/tb_power4/mag4

configure wave -namecolwidth 220
configure wave -valuecolwidth 120
configure wave -justifyvalue left

run -all