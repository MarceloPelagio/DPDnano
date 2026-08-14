transcript on
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
vlog ../rtl/iq_delay.v
vlog ../sim/tb_iq_delay.v
echo "Compile finished."
