transcript on

vsim -voptargs="+acc" work.tb_power4

quietly WaveActivateNextPane {} 0

add wave -divider {INPUTS}
add wave -radix decimal sim:/tb_power4/mag2

add wave -divider {OUTPUTS}
add wave -radix decimal sim:/tb_power4/mag4

add wave -divider {INTERNALS}
add wave -radix hex sim:/tb_power4/dut/mult_full
add wave -radix hex sim:/tb_power4/dut/mult_round

run -all
wave zoom full
