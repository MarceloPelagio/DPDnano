transcript on
vsim -voptargs="+acc" work.tb_iq_delay
add wave sim:/tb_iq_delay/*
run -all
