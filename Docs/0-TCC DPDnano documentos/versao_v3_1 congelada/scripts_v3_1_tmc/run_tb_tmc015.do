transcript on

vsim -voptargs=+acc work.tb_dpdnano_lite_TMC015

add wave -r sim:/tb_dpdnano_lite_TMC015/*

run -all

wave zoom full
