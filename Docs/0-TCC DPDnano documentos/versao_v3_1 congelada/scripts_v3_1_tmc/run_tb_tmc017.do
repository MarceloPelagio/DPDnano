transcript on

vsim -voptargs=+acc work.tb_dpdnano_lite_TMC017

add wave -r sim:/tb_dpdnano_lite_TMC017/*

run -all

wave zoom full
