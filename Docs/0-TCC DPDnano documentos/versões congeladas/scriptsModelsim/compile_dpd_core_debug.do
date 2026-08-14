transcript on
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work

vlog ../rtl/mult_generic.v
vlog ../rtl/fixed_mult.v
vlog ../rtl/complex_mult.v
vlog ../rtl/complex_add.v
vlog ../rtl/rounding.v
vlog ../rtl/saturator.v
vlog ../rtl/iq_delay.v
vlog ../rtl/coeff_bank.v
vlog ../rtl/poly_kernel.v
vlog ../rtl/poly_branch.v
vlog ../rtl/dpd_core.v
vlog ../sim/tb_dpd_core_debug.v
