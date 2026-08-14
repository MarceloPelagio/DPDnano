`timescale 1ns/1ps
`default_nettype none
`include "../rtl/config.vh"

module tb_acc_mult;

reg signed [`ACC_WIDTH-1:0] a;
reg signed [`DATA_WIDTH-1:0] b;
wire signed [(`ACC_WIDTH+`DATA_WIDTH)-1:0] p;
reg signed [(`ACC_WIDTH+`DATA_WIDTH)-1:0] expected;
integer pass=0,fail=0;

acc_mult dut(.a(a),.b(b),.p(p));

task automatic check;
input integer tc;
input [256*8:1] desc;
begin
 #1;
 if(p===expected) begin
   $display("TC%02d - %0s ........ PASS",tc,desc);
   pass=pass+1;
 end else begin
   $display("TC%02d - %0s ........ FAIL",tc,desc);
   $display("      Expected : %0d",expected);
   $display("      Obtained : %0d",p);
   fail=fail+1;
 end
end
endtask

initial begin
$display("=========================================================");
$display("DPDnano-Lite Verification Environment");
$display("Module      : acc_mult");
$display("RTL Version : 1.0");
$display("TB Version  : 1.0");
$display("=========================================================");

a=0;b=0;expected=0;check(1,"Zero Input");
a=100;b=20;expected=2000;check(2,"Positive Multiply");
a=-50;b=10;expected=-500;check(3,"Negative A");
a=-40;b=-5;expected=200;check(4,"Double Negative");

$display("---------------------------------------------------------");
$display("Executed : %0d",pass+fail);
$display("Passed   : %0d",pass);
$display("Failed   : %0d",fail);
if(fail==0)$display("STATUS : PASS");
else $display("STATUS : FAIL");
$finish;
end

endmodule

`default_nettype wire
