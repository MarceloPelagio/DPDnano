transcript on

if {[file exists work]} {
    vdel -lib work -all
}

vlib work

vlog +acc +define+DPD_ENABLE_OVERFLOW_FLAGS +incdir+../rtl_v3_1 ../rtl_v3_1/complex_add.v ../rtl_v3_1/complex_mult.v ../rtl_v3_1/fixed_mult.v ../rtl_v3_1/iq_delay.v ../rtl_v3_1/mult_generic.v ../rtl_v3_1/poly_kernel.v ../rtl_v3_1/poly_branch.v ../rtl_v3_1/rounding.v ../rtl_v3_1/saturator.v ../rtl_v3_1/dpd_core.v ../tb_v3_2/tb_dpdnano_lite_TMQ002_GainLinearity.v

vsim -voptargs=+acc work.tb_dpdnano_lite_TMQ002_GainLinearity
