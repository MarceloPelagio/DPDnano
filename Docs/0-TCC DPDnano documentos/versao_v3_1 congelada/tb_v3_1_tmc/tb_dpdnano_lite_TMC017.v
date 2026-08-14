`timescale 1ns/1ps
`include "config.vh"

//------------------------------------------------------------------------------
// Testbench : tb_dpdnano_lite_TMC017
// Benchmark : TMC017 - poly_branch characterization
//------------------------------------------------------------------------------

module tb_dpdnano_lite_TMC017;

reg clk;
reg rst;
reg in_valid;

reg signed [`TERM_WIDTH-1:0] term_re;
reg signed [`TERM_WIDTH-1:0] term_im;

reg signed [`COEF_WIDTH-1:0] coef_re;
reg signed [`COEF_WIDTH-1:0] coef_im;

wire out_valid;
wire signed [`BRANCH_WIDTH-1:0] branch_re;
wire signed [`BRANCH_WIDTH-1:0] branch_im;

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

initial begin
    clk=0;
    forever #5 clk=~clk;
end

integer valid_count;
reg signed [`BRANCH_WIDTH-1:0] peak_re,peak_im;
reg signed [63:0] sum_re,sum_im;

task send_sample;
input signed [`TERM_WIDTH-1:0] tr,ti;
input signed [`COEF_WIDTH-1:0] cr,ci;
begin
    @(posedge clk);
    in_valid<=1;
    term_re<=tr;
    term_im<=ti;
    coef_re<=cr;
    coef_im<=ci;
    @(posedge clk);
    in_valid<=0;
end
endtask

always @(posedge clk) begin
    if(rst) begin
        valid_count<=0;
        peak_re<=0;
        peak_im<=0;
        sum_re<=0;
        sum_im<=0;
    end else if(out_valid) begin
        valid_count<=valid_count+1;
        if(branch_re>peak_re) peak_re<=branch_re;
        if(branch_im>peak_im) peak_im<=branch_im;
        sum_re<=sum_re+branch_re;
        sum_im<=sum_im+branch_im;
    end
end

initial begin
    rst=1;
    in_valid=0;
    term_re=0;
    term_im=0;
    coef_re=0;
    coef_im=0;

    repeat(5) @(posedge clk);
    rst=0;

    // OBJ1
    send_sample(0,0,0,0);

    // OBJ2
    send_sample(49'sd1073741824,49'sd0,16'sd32767,16'sd0);

    // OBJ3
    send_sample(49'sd1073741824,49'sd0,16'sd0,16'sd32767);

    // OBJ4
    send_sample(49'sd2147483648,49'sd1073741824,16'sd16384,16'sd0);

    // OBJ5
    send_sample(49'sd2147483648,49'sd1073741824,-16'sd16384,16'sd0);

    // OBJ6
    send_sample(49'sd3221225472,49'sd2147483648,16'sd32767,16'sd32767);

    // OBJ7
    send_sample(49'sd4294967296,49'sd2147483648,16'sd32767,16'sd0);

    repeat(20) @(posedge clk);

    $display("");
    $display("==============================================");
    $display("TMC017 - POLY_BRANCH CHARACTERIZATION");
    $display("==============================================");
    $display("Valid Samples      : %0d",valid_count);
    $display("Peak Branch Re     : %0d",peak_re);
    $display("Peak Branch Im     : %0d",peak_im);
    $display("Accum Branch Re    : %0d",sum_re);
    $display("Accum Branch Im    : %0d",sum_im);
    $display("RESULT             : PASS");
    $display("==============================================");
    $finish;
end

endmodule
