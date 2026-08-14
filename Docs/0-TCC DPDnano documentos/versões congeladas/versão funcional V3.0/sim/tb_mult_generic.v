`timescale 1ns/1ps
`include "../rtl/config.vh"

module tb_mult_generic;

reg  signed [15:0] a,b;
wire signed [31:0] p;
integer err;

mult_generic dut(
    .a(a),
    .b(b),
    .p(p)
);

task check;
input signed [15:0] aa,bb;
input signed [31:0] exp;
begin
    a=aa;
    b=bb;
    #1;
    if (p !== exp) begin
        err = err + 1;
        $display("[FAIL] a=%0d b=%0d p=%0d exp=%0d",aa,bb,p,exp);
    end
end
endtask

initial begin
    err = 0;

    check(16'sd0,16'sd0,32'sd0);
    check(16'sd1,16'sd1,32'sd1);
    check(-16'sd2,16'sd3,-32'sd6);
    check(16'sd32767,16'sd2,32'sd65534);
    check(-16'sd32768,16'sd1,-32'sd32768);

    if(err==0)
        $display("======== PASS ========");
    else
        $display("======== FAIL (%0d errors) ========",err);

    // Keep ModelSim open for waveform inspection.
    $stop;
end

endmodule
