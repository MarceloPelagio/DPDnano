`timescale 1ns/1ps
`include "config.vh"
module tb_rounding;
reg clk=0; always #5 clk=~clk;
reg rst,in_valid;
reg signed [`ACC_WIDTH-1:0] din_re,din_im;
wire out_valid;
wire signed [`ROUND_WIDTH-1:0] dout_re,dout_im;
rounding dut(
 .clk(clk),.rst(rst),.in_valid(in_valid),
 .din_re(din_re),.din_im(din_im),
 .out_valid(out_valid),.dout_re(dout_re),.dout_im(dout_im));
integer pass=0,fail=0;
initial begin
 rst=1; in_valid=0; din_re=0; din_im=0;
 repeat(3) @(posedge clk); rst=0;
 @(posedge clk);
 in_valid<=1;
 din_re<=34'sd123456;
 din_im<=-34'sd654321;
 @(posedge clk);
 in_valid<=0;
 wait(out_valid);
 if(^dout_re!==1'bx && ^dout_im!==1'bx) begin
   pass=pass+1; $display("[PASS] TC1");
 end else begin
   fail=fail+1; $display("[FAIL] TC1");
 end
 $display("----------------------------------------");
 $display("PASS = %0d",pass);
 $display("FAIL = %0d",fail);
 $stop;
end
endmodule
