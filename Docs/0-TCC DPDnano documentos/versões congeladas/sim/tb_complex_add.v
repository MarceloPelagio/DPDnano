`timescale 1ns/1ps
`default_nettype none
`include "../rtl/config.vh"
module tb_complex_add;
reg signed [`TERM_WIDTH-1:0] a_r,a_i,b_r,b_i,c_r,c_i;
wire signed [`ACC_WIDTH-1:0] sum_r,sum_i;
complex_add dut(.*);
initial begin
a_r=10;a_i=20;b_r=30;b_i=40;c_r=50;c_i=60;
#1;
$display("SUM_R=%0d SUM_I=%0d",sum_r,sum_i);
$finish;
end
endmodule
`default_nettype wire
