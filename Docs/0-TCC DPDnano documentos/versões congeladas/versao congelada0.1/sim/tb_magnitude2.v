`timescale 1ns/1ps
`default_nettype none
`include "../rtl/config.vh"

module tb_magnitude2;

reg signed [`DATA_WIDTH-1:0] i_in,q_in;
wire signed [`ACC_WIDTH-1:0] mag2;

integer pass=0,fail=0;

magnitude2 dut(
.i_in(i_in),
.q_in(q_in),
.mag2(mag2)
);

task check;
input integer tc;
input signed [`DATA_WIDTH-1:0] i;
input signed [`DATA_WIDTH-1:0] q;
input signed [`ACC_WIDTH-1:0] expected;
begin
    i_in=i;
    q_in=q;
    #1;
    if(mag2===expected) begin
        $display("TC%02d PASS",tc);
        pass=pass+1;
    end else begin
        $display("TC%02d FAIL",tc);
        $display("Expected=%0d Got=%0d",expected,mag2);
        fail=fail+1;
    end
end
endtask

initial begin
    $display("==========================================");
    $display("DPDnano-Lite Verification Environment");
    $display("Module : magnitude2");
    $display("RTL Version : 1.0");
    $display("TB Version  : 1.0");
    $display("==========================================");

    check(1,16'sd0,16'sd0,40'sd0);
    check(2,16'sd1,16'sd0,40'sd1);
    check(3,16'sd2,16'sd3,40'sd13);
    check(4,-16'sd2,16'sd3,40'sd13);

    $display("------------------------------------------");
    $display("Executed : %0d",pass+fail);
    $display("Passed   : %0d",pass);
    $display("Failed   : %0d",fail);
    if(fail==0) $display("STATUS : PASS");
    else $display("STATUS : FAIL");
    $display("==========================================");
    $finish;
end

endmodule

`default_nettype wire
