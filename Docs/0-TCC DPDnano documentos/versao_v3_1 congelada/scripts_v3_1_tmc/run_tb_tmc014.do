transcript on

vsim -voptargs=+acc work.tb_dpdnano_lite_TMC014

add wave -r sim:/tb_dpdnano_lite_TMC014/*

run -all

wave zoom full
