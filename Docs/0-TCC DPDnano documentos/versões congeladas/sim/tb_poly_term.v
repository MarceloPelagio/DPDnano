`timescale 1ns/1ps
`default_nettype none
`include "../rtl/config.vh"

module tb_poly_term;

reg signed [`DATA_WIDTH-1:0] vin_i,vin_q;
reg signed [`COEF_WIDTH-1:0] coef_r,coef_i;

wire signed [`ACC_WIDTH-1:0] vout_r,vout_i;

integer pass=0, fail=0;

reg signed [`ACC_WIDTH-1:0] expected_r;
reg signed [`ACC_WIDTH-1:0] expected_i;

poly_term dut(
    .vin_i(vin_i),
    .vin_q(vin_q),
    .coef_r(coef_r),
    .coef_i(coef_i),
    .vout_r(vout_r),
    .vout_i(vout_i)
);

task automatic check_complex;
input integer tc;
input [256*8:1] desc;
begin
    #1;

    if ((vout_r===expected_r) && (vout_i===expected_i)) begin
        $display("TC%02d - %0s ........ PASS",tc,desc);
        pass = pass + 1;
    end
    else begin
        $display("TC%02d - %0s ........ FAIL",tc,desc);
        $display("      Expected : R=%0d I=%0d",expected_r,expected_i);
        $display("      Obtained : R=%0d I=%0d",vout_r,vout_i);
        fail = fail + 1;
    end
end
endtask

initial begin

$display("=========================================================");
$display("DPDnano-Lite Verification Environment");
$display("Module      : poly_term");
$display("RTL Version : 2.0");
$display("TB Version  : 3.0");
$display("=========================================================");

//
// Basic Tests
//

// TC01
vin_i=0; vin_q=0;
coef_r=0; coef_i=0;
expected_r=0;
expected_i=0;
check_complex(1,"Zero Input");

// TC02
vin_i=1; vin_q=0;
coef_r=1; coef_i=0;
// complex_mult: (1+j0)*(1+j0)=1+j0
expected_r=1;
expected_i=0;
check_complex(2,"Pure Real");

// TC03
vin_i=0; vin_q=1;
coef_r=0; coef_i=1;
// (j)*(j)=-1+j0
expected_r=-1;
expected_i=0;
check_complex(3,"Pure Imaginary");

// TC04
vin_i=2; vin_q=3;
coef_r=0; coef_i=0;
expected_r=0;
expected_i=0;
check_complex(4,"Zero Coefficient");

$display("---------------------------------------------------------");
$display("Executed : %0d",pass+fail);
$display("Passed   : %0d",pass);
$display("Failed   : %0d",fail);

if(fail==0)
    $display("STATUS : PASS");
else
    $display("STATUS : FAIL");

$display("=========================================================");

$finish;

end

endmodule

`default_nettype wire
