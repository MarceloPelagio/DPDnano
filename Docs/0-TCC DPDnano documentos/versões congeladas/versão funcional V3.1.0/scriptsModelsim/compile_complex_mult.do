# ============================================================
# DPDnano-Lite
# compile_complex_mult_r06.do
# Current directory:
#   C:/ProjetosGithub/TCC_CHIP_DIGITAL/TCC_FINAL/scriptsModelsim
# ============================================================

# Compile RTL
vlog +incdir+../rtl ../rtl/complex_mult.v

# Compile Testbench
vlog +incdir+../rtl ../sim/tb_complex_mult.v
