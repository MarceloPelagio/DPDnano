`timescale 1ns/1ps
`include "../rtl_v3_1/config.vh"

// ============================================================================
// DPDnano-Lite RTL v3.1
// TMC011 - Pipeline Characterization Benchmark
// Revision : v001
// ============================================================================

module tb_dpdnano_lite_TMC011;

localparam integer NUM_SAMPLES   = 10000;
localparam integer CLK_PERIOD_NS = 10;

reg clk=0;
always #(CLK_PERIOD_NS/2) clk=~clk;

reg rst,in_valid;
reg signed [`DATA_WIDTH-1:0] din_re,din_im;
reg signed [`COEF_WIDTH-1:0] coef1_re,coef1_im,coef3_re,coef3_im;

wire out_valid;
wire signed [`DATA_WIDTH-1:0] dout_re,dout_im;
wire overflow,overflow_re,overflow_im;

dpd_core dut(
    .clk(clk),.rst(rst),.in_valid(in_valid),
    .din_re(din_re),.din_im(din_im),
    .coef1_re(coef1_re),.coef1_im(coef1_im),
    .coef3_re(coef3_re),.coef3_im(coef3_im),
    .overflow(overflow),.overflow_re(overflow_re),.overflow_im(overflow_im),
    .out_valid(out_valid),.dout_re(dout_re),.dout_im(dout_im)
);

integer tx,rx,cycles;
integer first_in=-1, first_out=-1;
integer last_in=-1, last_out=-1;
integer latency,fill_cycles,drain_cycles,total_cycles;
integer bubble_cycles;

always @(posedge clk) begin
    cycles <= cycles + 1;

    if(in_valid) begin
        if(first_in==-1) first_in = cycles;
        last_in = cycles;
    end

    if(out_valid) begin
        rx <= rx + 1;
        if(first_out==-1) first_out = cycles;
        last_out = cycles;
    end
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

    repeat(5) @(posedge clk);
    rst=0;

    for(tx=0; tx<NUM_SAMPLES; tx=tx+1) begin
        @(posedge clk);
        in_valid <= 1'b1;
        din_re   <= tx;
        din_im   <= -tx;
    end

    @(posedge clk);
    in_valid <= 0;

    wait(rx==NUM_SAMPLES);

    latency     = first_out-first_in;
    fill_cycles = latency;
    drain_cycles= last_out-last_in;
    total_cycles= last_out-first_in+1;
    bubble_cycles = total_cycles-(NUM_SAMPLES+fill_cycles);

    $display("==================================================");
    $display("DPDnano-Lite TMC011 v001");
    $display("==================================================");
    $display("Pipeline Latency      : %0d cycles",latency);
    $display("Pipeline Fill         : %0d cycles",fill_cycles);
    $display("Pipeline Drain        : %0d cycles",drain_cycles);
    $display("Pipeline Bubbles      : %0d cycles",bubble_cycles);
    $display("First Input Cycle     : %0d",first_in);
    $display("First Output Cycle    : %0d",first_out);
    $display("Last Input Cycle      : %0d",last_in);
    $display("Last Output Cycle     : %0d",last_out);
    $display("Processing Cycles     : %0d",total_cycles);
    $display("RESULT                : %s",(rx==NUM_SAMPLES)?"PASS":"FAIL");
    $finish;
end

endmodule
