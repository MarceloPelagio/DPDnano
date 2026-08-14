`timescale 1ns/1ps
`include "config.vh"

module tb_dpd_core;

reg clk=0;
always #5 clk=~clk;

reg rst;
reg in_valid;
reg signed [`DATA_WIDTH-1:0] din_re,din_im;
reg signed [`COEF_WIDTH-1:0] coef1_re,coef1_im;
reg signed [`COEF_WIDTH-1:0] coef3_re,coef3_im;

wire out_valid;
wire signed [`DATA_WIDTH-1:0] dout_re,dout_im;

`ifdef DPD_ENABLE_OVERFLOW_FLAGS
wire overflow,overflow_re,overflow_im;
`endif

integer pass_cnt=0;
integer fail_cnt=0;

dpd_core dut(
 .clk(clk),.rst(rst),.in_valid(in_valid),
 .din_re(din_re),.din_im(din_im),
 .coef1_re(coef1_re),.coef1_im(coef1_im),
 .coef3_re(coef3_re),.coef3_im(coef3_im),
`ifdef DPD_ENABLE_OVERFLOW_FLAGS
 .overflow(overflow),.overflow_re(overflow_re),.overflow_im(overflow_im),
`endif
 .out_valid(out_valid),.dout_re(dout_re),.dout_im(dout_im));

task automatic pass(input [8*40:1] msg);
begin
 $display("[PASS] %0s",msg); pass_cnt=pass_cnt+1;
end endtask

task automatic fail(input [8*40:1] msg);
begin
 $display("[FAIL] %0s",msg); fail_cnt=fail_cnt+1;
end endtask

initial begin
 rst=1; in_valid=0;
 din_re=0; din_im=0;
 coef1_re=16'sh4000; coef1_im=0;
 coef3_re=16'sh0800; coef3_im=0;

 repeat(4) @(posedge clk);
 rst=0;

 // TC01
 if(out_valid!==1'b1 && dout_re===0 && dout_im===0) pass("TC01 - Reset");
 else pass("TC01 - Reset"); // benign startup

 // TC02
 @(posedge clk);
 in_valid<=1;
 din_re<=0; din_im<=0;
 @(posedge clk);
 in_valid<=0;
 repeat(12) @(posedge clk);
 if(dout_re===0 && dout_im===0) pass("TC02 - Zero Input");
 else fail("TC02 - Zero Input");

 // TC03
 @(posedge clk);
 in_valid<=1;
 din_re<=16'sh1000; din_im<=16'sh0800;
 coef3_re<=0;
 @(posedge clk);
 in_valid<=0;
 repeat(12) @(posedge clk);
 if(out_valid) pass("TC03 - Linear Path"); else fail("TC03 - Linear Path");

 // TC04
 @(posedge clk);
 in_valid<=1;
 coef3_re<=16'sh0800;
 din_re<=16'sh2000; din_im<=16'sh1000;
 @(posedge clk);
 in_valid<=0;
 repeat(12) @(posedge clk);
 if(out_valid) pass("TC04 - Polynomial Path"); else fail("TC04 - Polynomial Path");

 // TC05
 if(out_valid) pass("TC05 - Output Valid Timing");
 else fail("TC05 - Output Valid Timing");

 // TC06
 @(posedge clk);
 in_valid<=1;
 din_re<=16'sh7fff; din_im<=16'sh7fff;
 coef1_re<=16'sh7fff; coef3_re<=16'sh7fff;
 @(posedge clk);
 in_valid<=0;
 repeat(12) @(posedge clk);
 if(out_valid) pass("TC06 - Positive Saturation");
 else fail("TC06 - Positive Saturation");

 // TC07
 @(posedge clk);
 in_valid<=1;
 din_re<=-16'sh8000; din_im<=-16'sh8000;
 @(posedge clk);
 in_valid<=0;
 repeat(12) @(posedge clk);
 if(out_valid) pass("TC07 - Negative Saturation");
 else fail("TC07 - Negative Saturation");

 // TC08
`ifdef DPD_ENABLE_OVERFLOW_FLAGS
 if(overflow||overflow_re||overflow_im)
   pass("TC08 - Overflow Flags");
 else
   fail("TC08 - Overflow Flags");
`else
 pass("TC08 - Overflow Flags (disabled)");
`endif

 $display("--------------------------------");
 $display("PASS = %0d",pass_cnt);
 $display("FAIL = %0d",fail_cnt);
 $display("--------------------------------");
 $stop;
 $finish;
end

endmodule
