transcript on
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
vlog ../rtl/fixed_mult.v
vlog ../rtl/complex_mult.v
vlog ../rtl/complex_add.v
vlog ../rtl/poly_term.v
vlog ../rtl/poly_branch.v
vlog ../sim/tb_poly_branch.v
