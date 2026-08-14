`timescale 1ns/1ps
`include "config.vh"

module tb_poly_branch;

reg clk=0;
always #5 clk=~clk;

reg rst;
reg in_valid;

reg signed [`TERM_WIDTH-1:0] term_re, term_im;
reg signed [`COEF_WIDTH-1:0] coef_re, coef_im;

wire out_valid;
wire signed [`BRANCH_WIDTH-1:0] branch_re, branch_im;

poly_branch dut(
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid),
    .term_re(term_re),
    .term_im(term_im),
    .coef_re(coef_re),
    .coef_im(coef_im),
    .out_valid(out_valid),
    .branch_re(branch_re),
    .branch_im(branch_im)
);

integer pass=0, fail=0;

initial begin
    rst=1;
    in_valid=0;
    term_re=0; term_im=0;
    coef_re=0; coef_im=0;

    repeat(3) @(posedge clk);
    rst=0;

    // TC1
    @(posedge clk);
    in_valid<=1;
    term_re<=49'sd1073741824;   // 2^30
    term_im<=0;
    coef_re<=16'sd16384;        // 0.5 (Q1.15)
    coef_im<=0;

    @(posedge clk);
    in_valid<=0;

    wait(out_valid);

    if (^branch_re !== 1'bx && ^branch_im !== 1'bx) begin
        pass=pass+1;
        $display("[PASS] TC1");
    end else begin
        fail=fail+1;
        $display("[FAIL] TC1");
    end

    $display("----------------------------------------");
    $display("PASS = %0d", pass);
    $display("FAIL = %0d", fail);
    $stop;
end

endmodule
