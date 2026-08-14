transcript on

do ./compile_tmq009_symmetry_gui.do

view transcript
view wave

quietly WaveActivateNextPane {} 0
delete wave *

add wave -divider {TMQ009 Control}
add wave sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/clk
add wave sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/rst
add wave sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/in_valid
add wave sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/out_valid
add wave sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/cycle_cnt
add wave sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/tx
add wave sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/rx

add wave -divider {Paired Stimulus}
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/din_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/din_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/coef1_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/coef1_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/coef3_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/coef3_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/sample_sign_hist(0)

add wave -divider {Symmetry Output Check}
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/dout_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/dout_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/pos_out_re_q15
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/pos_out_im_q15
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/max_abs_symmetry_error_re_lsb
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/max_abs_symmetry_error_im_lsb
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/max_abs_symmetry_error_mag_lsb

add wave -divider {Robustness}
add wave sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/overflow
add wave sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/overflow_re
add wave sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/overflow_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/xz_errors
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ009_SymmetryCharacterization/pair_count

run -all

wave zoom full

puts ""
puts "======================================================================"
puts "TMQ009 GUI run finished"
puts "Artifacts expected in ../tb_v3_2/results/TMQ009"
puts "Symmetry SVG : ../tb_v3_2/results/TMQ009/tmq009_symmetry_dashboard.svg"
puts "======================================================================"
