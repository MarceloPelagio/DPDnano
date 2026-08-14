transcript on

vsim -voptargs=+acc work.tb_dpdnano_lite_TMC013

add wave -r sim:/tb_dpdnano_lite_TMC013/*

run -all

wave zoom full
