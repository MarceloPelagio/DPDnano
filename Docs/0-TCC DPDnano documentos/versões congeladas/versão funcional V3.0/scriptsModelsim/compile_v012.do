transcript on
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
vlog ../rtl/mult_generic.v
vlog ../sim/tb_mult_generic.v
