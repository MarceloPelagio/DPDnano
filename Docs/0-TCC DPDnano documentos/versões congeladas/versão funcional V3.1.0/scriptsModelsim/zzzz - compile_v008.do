transcript on
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work
vlog ../rtl/fixed_mult.v
vlog ../rtl/complex_mult.v
vlog ../rtl/poly_scale.v
vlog ../rtl/poly_term.v
vlog ../sim/tb_poly_term.v
