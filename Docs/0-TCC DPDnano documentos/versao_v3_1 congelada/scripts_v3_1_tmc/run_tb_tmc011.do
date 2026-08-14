transcript on

vsim -voptargs=+acc work.tb_dpdnano_lite_TMC011

add wave -r sim:/tb_dpdnano_lite_TMC011/*

run -all

wave zoom full
