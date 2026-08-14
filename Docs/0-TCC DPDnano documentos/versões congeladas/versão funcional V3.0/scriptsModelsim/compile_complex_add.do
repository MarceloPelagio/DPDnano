transcript on
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
vlog ../rtl/complex_add.v
vlog ../sim/tb_complex_add.v
echo "Compile finished."
