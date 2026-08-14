transcript on

vsim -voptargs=+acc work.tb_dpdnano_lite_TMC010

quietly WaveActivateNextPane {} 0

add wave -r sim:/tb_dpdnano_lite_TMC010/*

configure wave -namecolwidth 220
configure wave -valuecolwidth 120
configure wave -timelineunits ns

run -all

wave zoom full

echo "========================================"
echo " TMC010 Simulation Finished"
echo "========================================"
