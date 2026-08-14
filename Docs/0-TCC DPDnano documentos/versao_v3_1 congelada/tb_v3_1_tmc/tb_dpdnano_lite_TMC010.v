`timescale 1ns/1ps
`include "../rtl_v3_1/config.vh"

module tb_dpdnano_lite_TMC010;

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

integer tx,rx,cycles,ovf;
integer first_in_cycle=-1;
integer first_out_cycle=-1;
integer last_in_cycle=-1;
integer last_out_cycle=-1;
integer latency,fill_cycles,drain_cycles,total_cycles;
real samples_per_clock;
real cycles_per_sample;

//=========== patch v003 ==========
real clk_freq_mhz = 100.0;
real throughput_msps;
real processing_time_us;
real pipeline_efficiency;
// fim patch v003 ==========




always @(posedge clk) begin
    cycles <= cycles + 1;

    if(in_valid) begin
        if(first_in_cycle==-1) first_in_cycle = cycles;
        last_in_cycle = cycles;
    end

    if(out_valid) begin
        rx <= rx + 1;
        if(first_out_cycle==-1) first_out_cycle = cycles;
        last_out_cycle = cycles;
    end

    if(overflow) ovf <= ovf + 1;
end

initial begin
    rst=1; in_valid=0; din_re=0; din_im=0;
    coef1_re=16'sh2000; coef1_im=0;
    coef3_re=16'sh0800; coef3_im=0;

    tx=0; rx=0; cycles=0; ovf=0;

    repeat(5) @(posedge clk);
    rst=0;

    for(tx=0;tx<NUM_SAMPLES;tx=tx+1) begin
        @(posedge clk);
        in_valid<=1;
        din_re<=tx;
        din_im<=-tx;
    end

    @(posedge clk);
    in_valid<=0;

    wait(rx==NUM_SAMPLES);

    latency = first_out_cycle-first_in_cycle;
    fill_cycles = latency;
    drain_cycles = last_out_cycle-last_in_cycle;
    total_cycles = last_out_cycle-first_in_cycle+1;

    samples_per_clock = NUM_SAMPLES;
    samples_per_clock = samples_per_clock / total_cycles;

    cycles_per_sample = total_cycles;
    cycles_per_sample = cycles_per_sample / NUM_SAMPLES;

    //=========== patch v003 ========== parte 2
    processing_time_us = (total_cycles * 10.0) / 1000.0;
    throughput_msps    = NUM_SAMPLES / processing_time_us;
    pipeline_efficiency = (NUM_SAMPLES * 100.0) / total_cycles;

    // Replace report with:

    $display("==================================================");
    $display("DPDnano-Lite TMC010 v003");
    $display("==================================================");
    $display("TX Samples              : %0d",NUM_SAMPLES);
    $display("RX Samples              : %0d",rx);
    $display("Pipeline Latency        : %0d cycles",latency);
    $display("Pipeline Fill           : %0d cycles",fill_cycles);
    $display("Pipeline Drain          : %0d cycles",drain_cycles);
    $display("Processing Cycles       : %0d",total_cycles);
    $display("Samples/Clock           : %0.6f",samples_per_clock);
    $display("Cycles/Sample           : %0.6f",cycles_per_sample);
    $display("Clock Frequency         : %0.1f MHz",clk_freq_mhz);
    $display("Processing Time         : %0.3f us",processing_time_us);
    $display("Throughput              : %0.3f MSamples/s",throughput_msps);
    $display("Pipeline Efficiency     : %0.3f %%",pipeline_efficiency);
    $display("Overflow Events         : %0d",ovf);
    $display("RESULT                  : %s",(rx==NUM_SAMPLES)?"PASS":"FAIL");
    // fim patch v003 parte 2 ================


    $finish;
end

endmodule
