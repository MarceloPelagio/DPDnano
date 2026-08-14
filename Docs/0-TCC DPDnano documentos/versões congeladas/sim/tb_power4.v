`timescale 1ns/1ps
`default_nettype none
`include "../rtl/config.vh"

module tb_power4;

reg signed [`ACC_WIDTH-1:0] mag2;
wire signed [`ACC_WIDTH-1:0] mag4;
reg signed [`ACC_WIDTH-1:0] expected;

integer pass=0,fail=0;

power4 dut(.mag2(mag2),.mag4(mag4));

task automatic check;
input integer tc;
input [256*8:1] name;
begin
 #1;
 if(mag4===expected) begin
   $display("TC%02d - %0s ........ PASS",tc,name);
   pass=pass+1;
 end else begin
   $display("TC%02d - %0s ........ FAIL",tc,name);
   $display("      Expected : %0d",expected);
   $display("      Obtained : %0d",mag4);
   fail=fail+1;
 end
end
endtask

initial begin
$display("=========================================================");
$display("DPDnano-Lite Verification Environment");
$display("Module      : power4");
$display("RTL Version : 2.0");
$display("TB Version  : 2.0");
$display("=========================================================");

// Update expected values after fixed-point model is finalized.
mag2=0; expected=0; check(1,"Zero Input");
mag2=1; expected=0; check(2,"Unit Input");
mag2=16; expected=0; check(3,"Small Value");
mag2=-16; expected=0; check(4,"Negative Input");

$display("---------------------------------------------------------");
$display("Executed : %0d",pass+fail);
$display("Passed   : %0d",pass);
$display("Failed   : %0d",fail);
if(fail==0) $display("STATUS : PASS");
else $display("STATUS : FAIL");
$finish;
end

endmodule

`default_nettype wire
