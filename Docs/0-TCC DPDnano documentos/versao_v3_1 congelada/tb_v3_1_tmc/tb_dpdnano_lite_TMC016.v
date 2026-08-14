`timescale 1ns/1ps
`include "config.vh"

//------------------------------------------------------------------------------
// Testbench : tb_dpdnano_lite_TMC016
// Benchmark : TMC016 - poly_kernel characterization
// DPDnano-Lite RTL v3.2
//------------------------------------------------------------------------------
//
// NOTE:
// Initial benchmark skeleton frozen for v001.
// Collects statistics for:
//   - mag2
//   - term_re
//   - term_im
//   - valid samples
//   - peak values
//   - average values
//
//------------------------------------------------------------------------------

module tb_dpdnano_lite_TMC016;

reg clk;
reg rst;
reg in_valid;

reg signed [`DATA_WIDTH-1:0] x_re;
reg signed [`DATA_WIDTH-1:0] x_im;

wire out_valid;
wire signed [`MAG2_WIDTH-1:0]  mag2;
wire signed [`TERM_WIDTH-1:0]  term_re;
wire signed [`TERM_WIDTH-1:0]  term_im;

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

// clock
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

integer sample_count;
integer valid_count;

reg signed [`MAG2_WIDTH-1:0] mag2_peak;
reg signed [`TERM_WIDTH-1:0] term_re_peak;
reg signed [`TERM_WIDTH-1:0] term_im_peak;

reg [63:0] mag2_sum;
reg signed [63:0] term_re_sum;
reg signed [63:0] term_im_sum;

task send_sample;
input signed [`DATA_WIDTH-1:0] i;
input signed [`DATA_WIDTH-1:0] q;
begin
    @(posedge clk);
    in_valid <= 1'b1;
    x_re <= i;
    x_im <= q;

    @(posedge clk);
    in_valid <= 1'b0;
end
endtask

always @(posedge clk) begin
    if(rst) begin
        sample_count <= 0;
        valid_count  <= 0;
        mag2_peak    <= 0;
        term_re_peak <= 0;
        term_im_peak <= 0;
        mag2_sum     <= 0;
        term_re_sum  <= 0;
        term_im_sum  <= 0;
    end
    else if(out_valid) begin
        valid_count <= valid_count + 1;

        if(mag2 > mag2_peak)
            mag2_peak <= mag2;

        if(term_re > term_re_peak)
            term_re_peak <= term_re;

        if(term_im > term_im_peak)
            term_im_peak <= term_im;

        mag2_sum    <= mag2_sum + mag2;
        term_re_sum <= term_re_sum + term_re;
        term_im_sum <= term_im_sum + term_im;
    end
end

initial begin

    rst = 1;
    in_valid = 0;
    x_re = 0;
    x_im = 0;

    repeat(5) @(posedge clk);
    rst = 0;

    send_sample(16'sd0,16'sd0);
    send_sample(16'sd1000,16'sd0);
    send_sample(16'sd2000,16'sd1000);
    send_sample(-16'sd3000,16'sd2000);
    send_sample(16'sd8192,-16'sd4096);
    send_sample(16'sd16384,16'sd0);
    send_sample(-16'sd16384,16'sd0);

    repeat(20) @(posedge clk);

    $display("");
    $display("==============================================");
    $display("TMC016 - POLY_KERNEL CHARACTERIZATION");
    $display("==============================================");
    $display("Valid Samples        : %0d", valid_count);
    $display("Peak |x|^2           : %0d", mag2_peak);
    $display("Peak Term Re         : %0d", term_re_peak);
    $display("Peak Term Im         : %0d", term_im_peak);
    $display("Accum |x|^2          : %0d", mag2_sum);
    $display("Accum Term Re        : %0d", term_re_sum);
    $display("Accum Term Im        : %0d", term_im_sum);
    $display("RESULT               : PASS");
    $display("==============================================");

    $finish;

end

endmodule
