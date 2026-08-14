transcript on

vsim -voptargs=+acc work.tb_dpdnano_lite_TMC012

add wave -r sim:/tb_dpdnano_lite_TMC012/*

run -all

wave zoom full
