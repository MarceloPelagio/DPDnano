transcript on
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
vlog ../rtl/acc_mult.v
vlog ../sim/tb_acc_mult.v
