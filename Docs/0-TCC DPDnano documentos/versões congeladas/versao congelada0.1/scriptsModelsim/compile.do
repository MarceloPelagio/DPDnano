transcript on

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

vlog ../rtl/config.vh
vlog ../rtl/fixed_mult.v
vlog ../rtl/complex_mult.v

vlog ../sim/tb_complex_mult.v
