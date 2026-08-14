transcript on

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

vlog +incdir+../rtl ../rtl/mult_generic.v
vlog +incdir+../rtl ../sim/tb_mult_generic.v
