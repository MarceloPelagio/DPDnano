`timescale 1ns/1ps
`include "config.vh"
module tb_saturator;
reg clk=0; always #5 clk=~clk;
reg rst,in_valid;
reg signed [`ROUND_WIDTH-1:0] din_re,din_im;
wire out_valid;
wire signed [`DATA_WIDTH-1:0] dout_re,dout_im;
saturator dut(.clk(clk),.rst(rst),.in_valid(in_valid),.din_re(din_re),.din_im(din_im),.out_valid(out_valid),.dout_re(dout_re),.dout_im(dout_im));
integer pass=0,fail=0;
initial begin
 rst=1; in_valid=0; din_re=0; din_im=0;
 repeat(3) @(posedge clk); rst=0;
 @(posedge clk); in_valid<=1; din_re<=33'sd32768<<<15; din_im<=-(33'sd16384<<<15);
 @(posedge clk); in_valid<=0;
 wait(out_valid);
 if(^dout_re!==1'bx && ^dout_im!==1'bx) begin pass=pass+1;$display("[PASS] TC1"); end
 else begin fail=fail+1;$display("[FAIL] TC1"); end
 $display("PASS=%0d FAIL=%0d",pass,fail);
 $stop;
end
endmodule
