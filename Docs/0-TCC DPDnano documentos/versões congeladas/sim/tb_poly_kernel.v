`timescale 1ns/1ps
`include "config.vh"

//------------------------------------------------------------------------------
// Testbench : tb_poly_kernel
// Verilog-2001
//------------------------------------------------------------------------------

module tb_poly_kernel;

localparam CLK_PERIOD = 10;
localparam TIMEOUT_CYCLES = 20;

reg clk;
reg rst;
reg in_valid;

reg signed [15:0] x_re;
reg signed [15:0] x_im;

wire out_valid;
wire signed [32:0] mag2;
wire signed [48:0] term_re;
wire signed [48:0] term_im;

integer pass, fail, timeout;

poly_kernel dut(
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid),
    .x_re(x_re),
    .x_im(x_im),
    .out_valid(out_valid),
    .mag2(mag2),
    .term_re(term_re),
    .term_im(term_im)
);

initial clk = 0;
always #(CLK_PERIOD/2) clk = ~clk;

task reset_dut;
begin
    rst = 1;
    in_valid = 0;
    x_re = 0;
    x_im = 0;
    repeat(3) @(posedge clk);
    rst = 0;
    repeat(2) @(posedge clk);
end
endtask

task send_sample;
input signed [15:0] re, im;
begin
    @(posedge clk);
    in_valid <= 1'b1;
    x_re <= re;
    x_im <= im;
    @(posedge clk);
    in_valid <= 1'b0;
end
endtask

task wait_output;
begin
    timeout = TIMEOUT_CYCLES;
    while ((out_valid!==1'b1) && (timeout>0)) begin
        @(posedge clk);
        timeout = timeout - 1;
    end
end
endtask

task check;
input integer tc;
input signed [32:0] exp_mag2;
input signed [48:0] exp_re;
input signed [48:0] exp_im;
begin
    if(timeout==0) begin
        fail=fail+1;
        $display("[FAIL] TC%0d TIMEOUT",tc);
    end else if(mag2!==exp_mag2 || term_re!==exp_re || term_im!==exp_im) begin
        fail=fail+1;
        $display("[FAIL] TC%0d",tc);
    end else begin
        pass=pass+1;
        $display("[PASS] TC%0d",tc);
    end
end
endtask

initial begin
    pass=0; fail=0;
    reset_dut();

    // TC01
    send_sample(16'sd1,16'sd0);
    wait_output();
    check(1,33'sd1,49'sd1,49'sd0);

    // TC02
    send_sample(16'sd2,16'sd3);
    wait_output();
    check(2,33'sd13,49'sd26,49'sd39);

    // TC03
    send_sample(16'sd0,16'sd0);
    wait_output();
    check(3,33'sd0,49'sd0,49'sd0);

    $display("----------------------------------------");
    $display("PASS = %0d",pass);
    $display("FAIL = %0d",fail);

    $stop;
end

endmodule
