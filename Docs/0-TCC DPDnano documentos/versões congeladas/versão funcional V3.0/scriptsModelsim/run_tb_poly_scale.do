
transcript on

vsim -voptargs="+acc" work.tb_poly_scale

add wave -divider {INPUTS}
add wave -radix decimal sim:/tb_poly_scale/din
add wave -radix decimal sim:/tb_poly_scale/scale

add wave -divider {OUTPUT}
add wave -radix decimal sim:/tb_poly_scale/dout

add wave -divider {INTERNALS}
add wave -radix hex sim:/tb_poly_scale/dut/mult_full
add wave -radix hex sim:/tb_poly_scale/dut/mult_shift

run -all
wave zoom full
