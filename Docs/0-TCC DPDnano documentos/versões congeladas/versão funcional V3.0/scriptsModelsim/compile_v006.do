transcript on
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work
vlog ../rtl/fixed_mult.v
vlog ../rtl/power4.v
vlog ../sim/tb_power4.v
