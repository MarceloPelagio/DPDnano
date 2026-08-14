transcript on

vsim -voptargs=+acc work.tb_dpdnano_lite_TMC010

add wave -r sim:/tb_dpdnano_lite_TMC010/*

run -all

wave zoom full
