vsim -voptargs=+acc work.tb_iq_delay

add wave -radix decimal sim:/tb_iq_delay/*

run -all
