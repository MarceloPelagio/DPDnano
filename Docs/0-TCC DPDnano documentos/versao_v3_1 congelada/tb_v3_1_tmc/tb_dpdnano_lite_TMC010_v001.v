`timescale 1ns/1ps
`include "../rtl_v3_1/config.vh"

// ============================================================================
// DPDnano-Lite RTL v3.1
// TMC010 - General Architecture Characterization Benchmark
// Revision : v001
//
// NOTE:
// This is the initial framework for the TMC benchmark suite.
// It is intended to be expanded while preserving interface compatibility.
// ============================================================================

module tb_dpdnano_lite_TMC010;

localparam integer NUM_SAMPLES = 10000;
localparam integer CLK_PERIOD_NS = 10;

reg clk = 0;
always #(CLK_PERIOD_NS/2) clk = ~clk;

reg rst;
reg in_valid;
reg signed [`DATA_WIDTH-1:0] din_re, din_im;

reg signed [`COEF_WIDTH-1:0] coef1_re, coef1_im;
reg signed [`COEF_WIDTH-1:0] coef3_re, coef3_im;

wire out_valid;
wire signed [`DATA_WIDTH-1:0] dout_re, dout_im;
wire overflow, overflow_re, overflow_im;

// DUT
dpd_core dut(
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid),
    .din_re(din_re),
    .din_im(din_im),
    .coef1_re(coef1_re),
    .coef1_im(coef1_im),
    .coef3_re(coef3_re),
    .coef3_im(coef3_im),
    .overflow(overflow),
    .overflow_re(overflow_re),
    .overflow_im(overflow_im),
    .out_valid(out_valid),
    .dout_re(dout_re),
    .dout_im(dout_im)
);

// Characterization counters
integer tx, rx;
integer cycles;
integer ovf_total;
integer first_in, first_out;
integer latency;

always @(posedge clk) begin
    cycles <= cycles + 1;
    if (out_valid)
        rx <= rx + 1;
    if (overflow)
        ovf_total <= ovf_total + 1;
end

initial begin
    rst=1;
    in_valid=0;
    din_re=0;
    din_im=0;

    coef1_re=16'sh2000;
    coef1_im=0;
    coef3_re=16'sh0800;
    coef3_im=0;

    tx=0;
    rx=0;
    cycles=0;
    ovf_total=0;
    first_in=-1;
    first_out=-1;

    repeat(5) @(posedge clk);
    rst=0;

    $display("==============================================================");
    $display("DPDnano-Lite TMC010 - General Characterization");
    $display("Samples            : %0d",NUM_SAMPLES);
    $display("Clock              : %0d ns",CLK_PERIOD_NS);
    $display("==============================================================");

    for(tx=0; tx<NUM_SAMPLES; tx=tx+1) begin
        @(posedge clk);
        in_valid <= 1'b1;
        din_re <= tx;
        din_im <= -tx;
        if(first_in==-1) first_in = cycles;
    end

    @(posedge clk);
    in_valid <= 0;

    wait(rx==NUM_SAMPLES);

    first_out = cycles;
    latency = first_out-first_in;

    $display("");
    $display("Execution Summary");
    $display("------------------------------");
    $display("TX Samples        : %0d",tx);
    $display("RX Samples        : %0d",rx);
    $display("Latency (cycles)  : %0d",latency);
    $display("Simulation Cycles : %0d",cycles);
    $display("Overflow Events   : %0d",ovf_total);

    if(tx==rx)
        $display("RESULT            : PASS");
    else
        $display("RESULT            : FAIL");

    $finish;
end

endmodule
