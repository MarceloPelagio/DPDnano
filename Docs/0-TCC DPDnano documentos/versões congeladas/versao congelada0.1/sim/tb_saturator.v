`timescale 1ns/1ps
`include "config.vh"

module tb_saturator;

localparam CLK_PERIOD=10;
localparam TIMEOUT_CYCLES=20;

reg clk,rst,in_valid;
reg signed [`TERM_WIDTH-1:0] din_re,din_im;

wire out_valid;
wire signed [`DATA_WIDTH-1:0] dout_re,dout_im;

integer pass,fail,timeout;

saturator dut(
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
input signed [`TERM_WIDTH-1:0] re,im;
begin
 @(posedge clk);
 in_valid<=1;
 din_re<=re; din_im<=im;
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
input signed [`DATA_WIDTH-1:0] er,ei;
begin
 if(timeout==0) begin
   fail=fail+1; $display("[FAIL] TC%0d TIMEOUT",tc);
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

 // TC01 - pass-through
 send_sample(36'sd32768,36'sd65536); // 1<<15,2<<15
 wait_output();
 check(1,16'sd1,16'sd2);

 // TC02 - positive saturation
 send_sample(36'sd1073741823,36'sd0);
 wait_output();
 check(2,16'sh7FFF,16'sd0);

 // TC03 - negative saturation
 send_sample(-36'sd1073774592,-36'sd32768);
 wait_output();
 check(3,16'sh8000,-16'sd1);

 $display("----------------------------------------");
 $display("PASS = %0d",pass);
 $display("FAIL = %0d",fail);
 $stop;
end

endmodule
