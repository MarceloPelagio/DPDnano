`timescale 1ns/1ps
`include "config.vh"

module tb_rounding;

localparam CLK_PERIOD=10;
localparam TIMEOUT_CYCLES=20;

reg clk,rst,in_valid;
reg signed [`ACC_WIDTH-1:0] din_re,din_im;

wire out_valid;
wire signed [`TERM_WIDTH-1:0] dout_re,dout_im;

integer pass,fail,timeout;

rounding dut(
 .clk(clk),.rst(rst),.in_valid(in_valid),
 .din_re(din_re),.din_im(din_im),
 .out_valid(out_valid),
 .dout_re(dout_re),.dout_im(dout_im));

initial clk=0;
always #(CLK_PERIOD/2) clk=~clk;

task reset_dut;
begin
 rst=1; in_valid=0; din_re=0; din_im=0;
 repeat(3) @(posedge clk);
 rst=0;
 repeat(2) @(posedge clk);
end
endtask

task send_sample;
input signed [`ACC_WIDTH-1:0] re,im;
begin
 @(posedge clk);
 in_valid<=1;
 din_re<=re;
 din_im<=im;
 @(posedge clk);
 in_valid<=0;
end
endtask

task wait_output;
begin
 timeout=TIMEOUT_CYCLES;
 while((out_valid!==1'b1)&&(timeout>0)) begin
   @(posedge clk);
   timeout=timeout-1;
 end
end
endtask

task check;
input integer tc;
input signed [`TERM_WIDTH-1:0] er,ei;
begin
 if(timeout==0) begin
   fail=fail+1;
   $display("[FAIL] TC%0d TIMEOUT",tc);
 end else if(dout_re!==er || dout_im!==ei) begin
   fail=fail+1;
   $display("[FAIL] TC%0d RE=%0d IM=%0d EXP_RE=%0d EXP_IM=%0d",
            tc,dout_re,dout_im,er,ei);
 end else begin
   pass=pass+1;
   $display("[PASS] TC%0d",tc);
 end
end
endtask

initial begin
 pass=0; fail=0;
 reset_dut();

 // TC01
 send_sample(67'sd1073741824,67'sd0);      // 1<<30
 wait_output();
 check(1,36'sd1,36'sd0);

 // TC02
 send_sample(67'sd2147483648,67'sd1073741824); // 2<<30 ,1<<30
 wait_output();
 check(2,36'sd2,36'sd1);

 // TC03
 send_sample(-67'sd1073741824,-67'sd2147483648);
 wait_output();
 check(3,-36'sd1,-36'sd2);

 $display("----------------------------------------");
 $display("PASS = %0d",pass);
 $display("FAIL = %0d",fail);
 $stop;
end

endmodule
