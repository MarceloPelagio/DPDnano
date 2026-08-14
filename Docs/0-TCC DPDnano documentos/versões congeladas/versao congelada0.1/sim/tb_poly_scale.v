
`timescale 1ns/1ps
`default_nettype none
`include "../rtl/config.vh"

module tb_poly_scale;

reg  signed [`DATA_WIDTH-1:0] din;
reg  signed [`ACC_WIDTH-1:0]  scale;

wire signed [`ACC_WIDTH-1:0] dout;
reg  signed [`ACC_WIDTH-1:0] expected;

integer pass=0,fail=0;

poly_scale dut(
    .din(din),
    .scale(scale),
    .dout(dout)
);

task automatic check;
input integer tc;
input [256*8:1] name;
begin
    #1;
    if(dout===expected) begin
        $display("TC%02d - %0s ........ PASS",tc,name);
        pass=pass+1;
    end else begin
        $display("TC%02d - %0s ........ FAIL",tc,name);
        $display("      Expected : %0d",expected);
        $display("      Obtained : %0d",dout);
        fail=fail+1;
    end
end
endtask

initial begin
$display("=========================================================");
$display("DPDnano-Lite Verification Environment");
$display("Module      : poly_scale");
$display("RTL Version : 2.0");
$display("TB Version  : 2.0");
$display("=========================================================");

/* Atualizar expected após validação matemática */
din=0;   scale=0;   expected=0; check(1,"Zero Input");
din=1;   scale=1;   expected=0; check(2,"Unit Scale");
din=100; scale=256; expected=0; check(3,"Positive Scale");
din=-50; scale=256; expected=0; check(4,"Negative Input");
din=50;  scale=-256;expected=0; check(5,"Negative Scale");
din=32767; scale=40'sd32767; expected=0; check(6,"Maximum Input");

$display("---------------------------------------------------------");
$display("Executed : %0d",pass+fail);
$display("Passed   : %0d",pass);
$display("Failed   : %0d",fail);
if(fail==0) $display("STATUS : PASS");
else        $display("STATUS : FAIL");
$finish;
end

endmodule

`default_nettype wire
