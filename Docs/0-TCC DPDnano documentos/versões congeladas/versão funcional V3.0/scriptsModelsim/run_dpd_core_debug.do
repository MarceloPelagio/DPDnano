transcript on
vsim -voptargs="+acc" work.tb_dpd_core_debug
add wave sim:/tb_dpd_core_debug/*
add wave sim:/tb_dpd_core_debug/DUT/*
run -all
