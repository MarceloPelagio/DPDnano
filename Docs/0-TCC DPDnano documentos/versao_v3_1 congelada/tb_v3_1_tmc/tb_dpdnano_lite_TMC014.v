`timescale 1ns/1ps
`include "../rtl_v3_1/config.vh"

// ============================================================================
// DPDnano-Lite RTL v3.1
// TMC014 - Architecture Utilization Benchmark
// Revision : v001
// Based on validated TMC013 v001
// ============================================================================

module tb_dpdnano_lite_TMC014;

localparam integer NUM_SAMPLES=10000;

reg clk=0;
always #5 clk=~clk;

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
 .out_valid(out_valid),.dout_re(dout_re),.dout_im(dout_im));

integer tx,rx,cycles;
integer first_in=-1,first_out=-1,last_out=-1;
integer latency,total_cycles;
integer ovf_count;
integer valid_cycles,idle_cycles;
integer max_abs_out,abs_out;
real samples_per_clock,utilization;

always @(posedge clk) begin
    cycles<=cycles+1;
    if(in_valid) begin
        valid_cycles=valid_cycles+1;
        if(first_in==-1) first_in=cycles;
    end else idle_cycles=idle_cycles+1;

    if(out_valid) begin
        rx<=rx+1;
        if(first_out==-1) first_out=cycles;
        last_out=cycles;
        if(overflow) ovf_count=ovf_count+1;
        abs_out=(dout_re<0)?-dout_re:dout_re;
        if(abs_out>max_abs_out) max_abs_out=abs_out;
    end
end

initial begin
 rst=1;in_valid=0;din_re=0;din_im=0;
 coef1_re=16'sh2000;coef1_im=0;
 coef3_re=16'sh0800;coef3_im=0;
 tx=0;rx=0;cycles=0;ovf_count=0;
 valid_cycles=0;idle_cycles=0;max_abs_out=0;
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

 latency=first_out-first_in;
 total_cycles=last_out-first_in+1;
 samples_per_clock=NUM_SAMPLES;
 samples_per_clock=samples_per_clock/total_cycles;
 utilization=valid_cycles;
 utilization=(utilization/total_cycles)*100.0;

 $display("==================================================");
 $display("DPDnano-Lite TMC014 v001");
 $display("==================================================");
 $display("Pipeline Latency         : %0d cycles",latency);
 $display("Processing Cycles        : %0d",total_cycles);
 $display("Valid Input Cycles       : %0d",valid_cycles);
 $display("Idle Cycles             : %0d",idle_cycles);
 $display("Architecture Utilization : %0.3f %%",utilization);
 $display("Samples/Clock            : %0.6f",samples_per_clock);
 $display("Maximum Output Magnitude : %0d",max_abs_out);
 $display("Overflow Events          : %0d",ovf_count);
 $display("RESULT                   : %s",(rx==NUM_SAMPLES)?"PASS":"FAIL");
 $finish;
end

endmodule
