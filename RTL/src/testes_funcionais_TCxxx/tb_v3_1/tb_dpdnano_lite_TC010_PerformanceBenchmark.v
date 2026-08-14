`timescale 1ns/1ps
`include "../rtl_v3_1/config.vh"

module tb_dpdnano_lite_TC010_PerformanceBenchmark;

// ============================================================================
// TC010 - Performance Benchmark
// DPDnano-Lite RTL v3.1 (Frozen)
// Revision : v001
// NOTE: This benchmark is intended to be completed against the frozen RTL.
// ============================================================================

// User requested downloadable artifact with versioned filename.
// Keep module name unchanged for compile/run scripts.

localparam integer NUM_SAMPLES    = 1000000;
localparam integer TIMEOUT_CYCLES = NUM_SAMPLES*20;

// -----------------------------------------------------------------------------
// Clock / Reset
// -----------------------------------------------------------------------------
reg clk=0;
always #5 clk=~clk;

reg rst,in_valid;
reg signed [`DATA_WIDTH-1:0] din_re,din_im;
reg signed [`COEF_WIDTH-1:0] coef1_re,coef1_im,coef3_re,coef3_im;

wire out_valid;
wire signed [`DATA_WIDTH-1:0] dout_re,dout_im;
wire overflow,overflow_re,overflow_im;

// DUT
dpd_core dut(
 .clk(clk),.rst(rst),.in_valid(in_valid),
 .din_re(din_re),.din_im(din_im),
 .coef1_re(coef1_re),.coef1_im(coef1_im),
 .coef3_re(coef3_re),.coef3_im(coef3_im),
 .overflow(overflow),.overflow_re(overflow_re),.overflow_im(overflow_im),
 .out_valid(out_valid),.dout_re(dout_re),.dout_im(dout_im)
);

// -----------------------------------------------------------------------------
// Statistics
// -----------------------------------------------------------------------------
integer tx,rx,cycle_cnt,timeout;
integer first_input_cycle,first_output_cycle;
integer pipeline_latency;
integer bubble_cycles;
integer ovf,ovfr,ovfi;
real delivery_rate;

always @(posedge clk) begin
    cycle_cnt <= cycle_cnt + 1;
    if(out_valid) rx <= rx + 1;
    if(overflow) ovf <= ovf + 1;
    if(overflow_re) ovfr <= ovfr + 1;
    if(overflow_im) ovfi <= ovfi + 1;
end

initial begin
    rst=1;
    in_valid=0;
    tx=0;rx=0;cycle_cnt=0;timeout=0;
    ovf=0;ovfr=0;ovfi=0;
    coef1_re=16'sh2000;
    coef1_im=0;
    coef3_re=16'sh0800;
    coef3_im=0;

    repeat(4) @(posedge clk);
    rst=0;

    $display("");
    $display("======================================================================");
    $display("                 DPDnano-Lite RTL Validation Suite");
    $display("======================================================================");
    $display("TEST         : TC010_PerformanceBenchmark");
    $display("Revision     : v001");
    $display("Samples      : %0d",NUM_SAMPLES);
    $display("======================================================================");

    for(tx=0;tx<NUM_SAMPLES;tx=tx+1) begin
        @(posedge clk);
        in_valid=1;
        din_re=tx;
        din_im=~tx;
    end

    @(posedge clk);
    in_valid=0;

    while((rx<NUM_SAMPLES)&&(timeout<TIMEOUT_CYCLES)) begin
        @(posedge clk);
        timeout=timeout+1;
    end

    delivery_rate=(100.0*rx)/NUM_SAMPLES;

    $display("Delivery Rate : %0.2f %%",delivery_rate);
    $display("RX            : %0d",rx);
    $display("TX            : %0d",tx);

    if(rx==tx)
        $display("PASS");
    else
        $display("FAIL");

    $finish;
end

endmodule
