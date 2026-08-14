transcript on

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

echo ""
echo "========================================"
echo " DPDnano-Lite Compile"
echo "========================================"

#------------------------------------------------------------
# RTL
#------------------------------------------------------------

vlog +incdir+../rtl_v3_1 +incdir+../tb_v3_1 -work work ../rtl_v3_1/fixed_mult.v
vlog +incdir+../rtl_v3_1 +incdir+../tb_v3_1 -work work ../rtl_v3_1/complex_mult.v
vlog +incdir+../rtl_v3_1 +incdir+../tb_v3_1 -work work ../rtl_v3_1/complex_add.v
vlog +incdir+../rtl_v3_1 +incdir+../tb_v3_1 -work work ../rtl_v3_1/iq_delay.v
vlog +incdir+../rtl_v3_1 +incdir+../tb_v3_1 -work work ../rtl_v3_1/poly_kernel.v
vlog +incdir+../rtl_v3_1 +incdir+../tb_v3_1 -work work ../rtl_v3_1/poly_branch.v
vlog +incdir+../rtl_v3_1 +incdir+../tb_v3_1 -work work ../rtl_v3_1/rounding.v
vlog +incdir+../rtl_v3_1 +incdir+../tb_v3_1 -work work ../rtl_v3_1/saturator.v
vlog +incdir+../rtl_v3_1 +incdir+../tb_v3_1 -work work ../rtl_v3_1/dpd_core.v

#------------------------------------------------------------
# Functional Validation
#------------------------------------------------------------

vlog +incdir+../rtl_v3_1 +incdir+../tb_v3_1 -work work ../tb_v3_1/tb_dpdnano_lite_TC001.v
vlog +incdir+../rtl_v3_1 +incdir+../tb_v3_1 -work work ../tb_v3_1/tb_dpdnano_lite_TC002.v
vlog +incdir+../rtl_v3_1 +incdir+../tb_v3_1 -work work ../tb_v3_1/tb_dpdnano_lite_TC003.v
vlog +incdir+../rtl_v3_1 +incdir+../tb_v3_1 -work work ../tb_v3_1/tb_dpdnano_lite_TC004.v
vlog +incdir+../rtl_v3_1 +incdir+../tb_v3_1 -work work ../tb_v3_1/tb_dpdnano_lite_TC005.v
vlog +incdir+../rtl_v3_1 +incdir+../tb_v3_1 -work work ../tb_v3_1/tb_dpdnano_lite_TC006.v
vlog +incdir+../rtl_v3_1 +incdir+../tb_v3_1 -work work ../tb_v3_1/tb_dpdnano_lite_TC007.v
vlog +incdir+../rtl_v3_1 +incdir+../tb_v3_1 -work work ../tb_v3_1/tb_dpdnano_lite_TC008.v

#------------------------------------------------------------
# Progressive Stress Validation
#------------------------------------------------------------

vlog +incdir+../rtl_v3_1 +incdir+../tb_v3_1 -work work ../tb_v3_1/tb_dpdnano_lite_TC009.v
vlog +incdir+../rtl_v3_1 +incdir+../tb_v3_1 -work work ../tb_v3_1/tb_dpdnano_lite_TC009_Torture.v
vlog +incdir+../rtl_v3_1 +incdir+../tb_v3_1 -work work ../tb_v3_1/tb_dpdnano_lite_TC009_Nightmare.v

#------------------------------------------------------------
# Legacy / Experimental
#------------------------------------------------------------

vlog +incdir+../rtl_v3_1 +incdir+../tb_v3_1 -work work ../tb_v3_1/tb_dpdnano_lite_TC001-testeA.v

echo ""
echo "========================================"
echo " Compile Finished"
echo "========================================"
