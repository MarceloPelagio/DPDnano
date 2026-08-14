transcript on

if {[file exists work]} { vdel -lib work -all }

vlib work
vmap work work

vlog ../rtl/coeff_bank.v
vlog ../sim/tb_coeff_bank.v

echo "Compile finished."
