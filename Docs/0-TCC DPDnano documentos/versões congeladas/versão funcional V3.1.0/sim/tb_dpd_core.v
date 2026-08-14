`timescale 1ns/1ps
`include "config.vh"
module tb_dpd_core;
reg clk=0; always #5 clk=~clk;
reg rst,in_valid;
reg signed [`DATA_WIDTH-1:0] din_re,din_im;
reg signed [`COEF_WIDTH-1:0] c1r,c1i,c3r,c3i;
wire out_valid;
wire signed [`DATA_WIDTH-1:0] dout_re,dout_im;

dpd_core dut(
 .clk(clk),.rst(rst),.in_valid(in_valid),
 .din_re(din_re),.din_im(din_im),
 .coef1_re(c1r),.coef1_im(c1i),
 .coef3_re(c3r),.coef3_im(c3i),
 .out_valid(out_valid),
 .dout_re(dout_re),.dout_im(dout_im));

initial begin
 rst=1; in_valid=0;
 din_re=0; din_im=0;
 c1r=16'sd32767; c1i=0;
 c3r=0; c3i=0;
 repeat(3) @(posedge clk);
 rst=0;
 @(posedge clk);
 in_valid<=1;
 din_re<=16'sd8192;
 din_im<=16'sd4096;
 @(posedge clk);
 in_valid<=0;
 wait(out_valid);
 $display("[PASS] TC1");
 $stop;
end
endmodule
