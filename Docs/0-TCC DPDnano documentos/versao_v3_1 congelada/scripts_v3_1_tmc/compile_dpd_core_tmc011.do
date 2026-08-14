transcript on

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

echo "========================================"
echo " Compiling DPDnano-Lite RTL v3.1 TMC011"
echo "========================================"

vlog -work work ../rtl_v3_1/fixed_mult.v
vlog -work work ../rtl_v3_1/complex_mult.v
vlog -work work ../rtl_v3_1/complex_add.v
vlog -work work ../rtl_v3_1/iq_delay.v
vlog -work work ../rtl_v3_1/poly_kernel.v
vlog -work work ../rtl_v3_1/poly_branch.v
vlog -work work ../rtl_v3_1/rounding.v
vlog -work work ../rtl_v3_1/saturator.v
vlog -work work ../rtl_v3_1/dpd_core.v

echo "========================================"
echo " Compiling TMC011"
echo "========================================"

vlog -work work ../tb_v3_1_tmc/tb_dpdnano_lite_TMC011.v

echo "========================================"
echo " Compile Finished"
echo "========================================"
