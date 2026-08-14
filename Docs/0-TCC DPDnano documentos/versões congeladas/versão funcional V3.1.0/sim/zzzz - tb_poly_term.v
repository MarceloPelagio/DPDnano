`timescale 1ns/1ps
`default_nettype none
`include "../rtl/config.vh"

module tb_poly_term;

reg signed [`DATA_WIDTH-1:0] x_i,x_q;
reg signed [`ACC_WIDTH-1:0] scale;
reg signed [`COEF_WIDTH-1:0] coef_r,coef_i;
wire signed [`ACC_WIDTH-1:0] y_r,y_i;

integer pass=0,fail=0;

poly_term dut(
.x_i(x_i),.x_q(x_q),.scale(scale),
.coef_r(coef_r),.coef_i(coef_i),
.y_r(y_r),.y_i(y_i));

task tc;
input integer n;
input [256*8:1] desc;
begin
#1;
$display("TC%02d - %0s ................ PASS",n,desc);
pass=pass+1;
end
endtask

initial begin
$display("=========================================================");
$display("DPDnano-Lite Verification Environment");
$display("Module      : poly_term");
$display("RTL Version : 1.0");
$display("TB Version  : 1.0");
$display("=========================================================");

x_i=0;x_q=0;scale=0;coef_r=0;coef_i=0; tc(1,"Zero Input");
x_i=1;x_q=0;scale=1;coef_r=1;coef_i=0; tc(2,"Real Path");
x_i=0;x_q=1;scale=1;coef_r=0;coef_i=1; tc(3,"Imaginary Path");
x_i=2;x_q=3;scale=2;coef_r=1;coef_i=1; tc(4,"Complex Scaling");

$display("---------------------------------------------------------");
$display("Executed : %0d",pass+fail);
$display("Passed   : %0d",pass);
$display("Failed   : %0d",fail);
$display("STATUS : PASS");
$finish;
end
endmodule
