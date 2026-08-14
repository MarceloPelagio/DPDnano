transcript on

vsim -voptargs=+acc work.tb_dpdnano_lite_TMC016

add wave -r sim:/tb_dpdnano_lite_TMC016/*

run -all

wave zoom full
