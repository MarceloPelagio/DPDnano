transcript on

if {[file exists work]} { vdel -lib work -all }

vlib work
vmap work work

echo "Compiling RTL..."

vlog ../rtl/mult_generic.v
vlog ../rtl/poly_scale.v

echo "Compiling Testbench..."

vlog ../sim/tb_poly_scale.v

echo "Compile finished."