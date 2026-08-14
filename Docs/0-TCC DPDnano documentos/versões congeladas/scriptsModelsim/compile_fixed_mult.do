transcript on

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

vlog +incdir+../rtl ../rtl/fixed_mult.v
vlog +incdir+../rtl ../sim/tb_fixed_mult.v
