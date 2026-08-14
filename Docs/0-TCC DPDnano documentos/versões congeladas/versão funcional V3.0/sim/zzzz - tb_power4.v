`timescale 1ns/1ps
`default_nettype none
`include "../rtl/config.vh"

module tb_power4;

reg signed [`ACC_WIDTH-1:0] mag2;
wire signed [`ACC_WIDTH-1:0] mag4;
integer pass=0,fail=0;

power4 dut(.mag2(mag2),.mag4(mag4));

task check;
input integer tc;
input signed [`ACC_WIDTH-1:0] vin,vexp;
begin
    mag2=vin; #1;
    if(mag4===vexp) begin
        $display("TC%02d - Power4 ................ PASS",tc);
        pass=pass+1;
    end else begin
        $display("TC%02d - Power4 ................ FAIL",tc);
        $display("Expected=%0d Got=%0d",vexp,mag4);
        fail=fail+1;
    end
end
endtask

initial begin
    $display("DPDnano-Lite Verification Environment");
    check(1,0,0);
    check(2,1,1);
    check(3,2,4);
    check(4,3,9);
    $display("Executed : %0d",pass+fail);
    $display("Passed   : %0d",pass);
    $display("Failed   : %0d",fail);
    if(fail==0)$display("STATUS : PASS"); else $display("STATUS : FAIL");
    $finish;
end
endmodule
