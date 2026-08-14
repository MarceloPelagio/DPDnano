transcript on

if {[file exists work]} { vdel -lib work -all }

vlib work
vmap work work

echo "Compiling RTL..."
vlog ../rtl/fixed_mult.v
vlog ../rtl/complex_mult.v
vlog ../rtl/complex_add.v
vlog ../rtl/iq_delay.v
vlog ../rtl/rounding.v
vlog ../rtl/saturator.v

echo "Compiling Testbenches..."
vlog ../sim/tb_complex_mult.v
vlog ../sim/tb_complex_add.v
vlog ../sim/tb_iq_delay.v
vlog ../sim/tb_rounding.v
vlog ../sim/tb_saturator.v

echo "Compile finished."
