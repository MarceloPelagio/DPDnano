transcript on

vsim -voptargs=+acc work.tb_dpdnano_lite_TMC019

add wave -r sim:/tb_dpdnano_lite_TMC019/*

run -all

wave zoom full
