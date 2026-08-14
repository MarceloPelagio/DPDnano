`timescale 1ns/1ps
`include "config.vh"

module tb_complex_mult;

reg clk;
reg rst;
reg in_valid;

reg signed [`DATA_WIDTH-1:0] a_re,a_im,b_re,b_im;

wire out_valid;
wire signed [`BRANCH_WIDTH-1:0] y_re,y_im;

complex_mult dut(
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid),
    .a_re(a_re),
    .a_im(a_im),
    .b_re(b_re),
    .b_im(b_im),
    .out_valid(out_valid),
    .y_re(y_re),
    .y_im(y_im)
);

initial clk=0;
always #5 clk=~clk;

integer pass=0, fail=0;

initial begin
    rst=1;
    in_valid=0;
    a_re=0; a_im=0; b_re=0; b_im=0;

    repeat(3) @(posedge clk);
    rst=0;

    // TC1
    @(posedge clk);
    in_valid<=1;
    a_re<=16'sd16384; a_im<=0;
    b_re<=16'sd16384; b_im<=0;

    @(posedge clk);
    in_valid<=0;

    wait(out_valid);

    if (^y_re!==1'bx && ^y_im!==1'bx) begin
        pass=pass+1;
        $display("[PASS] TC1");
    end else begin
        fail=fail+1;
        $display("[FAIL] TC1");
    end

    $display("----------------------------------------");
    $display("PASS = %0d",pass);
    $display("FAIL = %0d",fail);
    $stop;
end

endmodule
