`timescale 1ns/1ps
`default_nettype none

`include "../rtl/config.vh"
`include "../rtl/coeff_pkg.vh"

module tb_coeff_bank;

wire signed [`COEF_WIDTH-1:0] c0_r,c0_i;
wire signed [`COEF_WIDTH-1:0] c1_r,c1_i;
wire signed [`COEF_WIDTH-1:0] c2_r,c2_i;

coeff_bank DUT(
    .c0_r(c0_r), .c0_i(c0_i),
    .c1_r(c1_r), .c1_i(c1_i),
    .c2_r(c2_r), .c2_i(c2_i)
);

integer executed=0;
integer passed=0;
integer failed=0;

initial begin
    $display("=========================================================");
    $display("DPDnano-Lite Verification Environment");
    $display("Module      : coeff_bank");
    $display("RTL Version : 2.0");
    $display("TB Version  : 1.0");
    $display("=========================================================");

    #1;
    executed = 1;

    if ((c0_r===`C0_REAL)&&(c0_i===`C0_IMAG)&&
        (c1_r===`C1_REAL)&&(c1_i===`C1_IMAG)&&
        (c2_r===`C2_REAL)&&(c2_i===`C2_IMAG))
        passed = 1;
    else
        failed = 1;

    $display("Executed : %0d",executed);
    $display("Passed   : %0d",passed);
    $display("Failed   : %0d",failed);
    $display("STATUS : %s",(failed==0)?"PASS":"FAIL");

    $finish;
end

endmodule

`default_nettype wire
