transcript on

if {[file exists work]} { vdel -lib work -all }

vlib work
vmap work work

echo "Compiling RTL..."

vlog ../rtl/config.vh
vlog ../rtl/mult_generic.v
vlog ../rtl/power4.v

echo "Compiling Testbench..."

vlog ../sim/tb_power4.v

echo "Compile finished."
