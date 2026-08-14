transcript on

do ./compile_tmq008_statistical_gui.do

view transcript
view wave

quietly WaveActivateNextPane {} 0
delete wave *

add wave -divider {TMQ008 Control}
add wave sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/clk
add wave sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/rst
add wave sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/in_valid
add wave sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/out_valid
add wave sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/cycle_cnt
add wave sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/tx
add wave sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/rx

add wave -divider {Stimulus and Coefficients}
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/din_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/din_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/coef1_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/coef1_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/coef3_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/coef3_im

add wave -divider {Statistical Accumulators}
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/dout_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/dout_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/min_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/max_re
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/min_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/max_im
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/overflow
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/xz_errors

add wave -divider {Histogram Bins RE}
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/hist_re(0)
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/hist_re(1)
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/hist_re(2)
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/hist_re(3)
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/hist_re(4)
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/hist_re(5)
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/hist_re(6)
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/hist_re(7)

add wave -divider {Histogram Bins IM}
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/hist_im(0)
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/hist_im(1)
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/hist_im(2)
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/hist_im(3)
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/hist_im(4)
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/hist_im(5)
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/hist_im(6)
add wave -radix decimal sim:/tb_dpdnano_lite_TMQ008_StatisticalCharacterization/hist_im(7)

run -all

wave zoom full

puts ""
puts "======================================================================"
puts "TMQ008 GUI run finished"
puts "Artifacts expected in ../tb_v3_2/results/TMQ008"
puts "Statistical SVG : ../tb_v3_2/results/TMQ008/tmq008_statistical_dashboard.svg"
puts "======================================================================"
