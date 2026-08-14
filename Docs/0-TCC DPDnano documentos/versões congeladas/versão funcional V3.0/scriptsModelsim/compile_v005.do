transcript on

if {[file exists work]} { vdel -lib work -all }

vlib work
vmap work work

echo "Compiling RTL..."
vlog ../rtl/fixed_mult.v
vlog ../rtl/magnitude2.v

echo "Compiling Testbenches..."
vlog ../sim/tb_magnitude2.v

echo "Compile finished."
