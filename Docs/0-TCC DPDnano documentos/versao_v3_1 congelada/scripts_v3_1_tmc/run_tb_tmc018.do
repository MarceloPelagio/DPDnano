transcript on

vsim -voptargs=+acc work.tb_dpdnano_lite_TMC018

add wave -r sim:/tb_dpdnano_lite_TMC018/*

run -all

wave zoom full
