`timescale 1ns/1ps
`include "../rtl_v3_1/config.vh"
// DPDnano-Lite RTL v3.1
// TMC012 - Throughput Characterization Benchmark v001
module tb_dpdnano_lite_TMC012;
localparam integer NUM_SAMPLES=10000;
localparam integer CLK_PERIOD_NS=10;
localparam real CLK_FREQ_MHZ=100.0;
reg clk=0; always #(CLK_PERIOD_NS/2) clk=~clk;
reg rst,in_valid;
reg signed [`DATA_WIDTH-1:0] din_re,din_im;
reg signed [`COEF_WIDTH-1:0] coef1_re,coef1_im,coef3_re,coef3_im;
wire out_valid; wire signed [`DATA_WIDTH-1:0] dout_re,dout_im;
wire overflow,overflow_re,overflow_im;
dpd_core dut(.clk(clk),.rst(rst),.in_valid(in_valid),.din_re(din_re),.din_im(din_im),.coef1_re(coef1_re),.coef1_im(coef1_im),.coef3_re(coef3_re),.coef3_im(coef3_im),.overflow(overflow),.overflow_re(overflow_re),.overflow_im(overflow_im),.out_valid(out_valid),.dout_re(dout_re),.dout_im(dout_im));
integer tx,rx,cycles,first_in=-1,first_out=-1,last_out=-1,latency,total_cycles;
real samples_per_clock,cycles_per_sample,processing_time_us,throughput_msps,efficiency;
always @(posedge clk) begin
 cycles<=cycles+1;
 if(in_valid && first_in==-1) first_in=cycles;
 if(out_valid) begin rx<=rx+1; if(first_out==-1) first_out=cycles; last_out=cycles; end
end
initial begin
 rst=1;in_valid=0;din_re=0;din_im=0;coef1_re=16'sh2000;coef1_im=0;coef3_re=16'sh0800;coef3_im=0;tx=0;rx=0;cycles=0;
 repeat(5) @(posedge clk); rst=0;
 for(tx=0;tx<NUM_SAMPLES;tx=tx+1) begin @(posedge clk); in_valid<=1; din_re<=tx; din_im<=-tx; end
 @(posedge clk); in_valid<=0;
 wait(rx==NUM_SAMPLES);
 latency=first_out-first_in;
 total_cycles=last_out-first_in+1;
 samples_per_clock=NUM_SAMPLES; samples_per_clock=samples_per_clock/total_cycles;
 cycles_per_sample=total_cycles; cycles_per_sample=cycles_per_sample/NUM_SAMPLES;
 processing_time_us=(total_cycles*CLK_PERIOD_NS)/1000.0;
 throughput_msps=NUM_SAMPLES/processing_time_us;
 efficiency=(throughput_msps/CLK_FREQ_MHZ)*100.0;
 $display("==================================================");
 $display("DPDnano-Lite TMC012 v001");
 $display("==================================================");
 $display("Clock Frequency         : %0.1f MHz",CLK_FREQ_MHZ);
 $display("Pipeline Latency        : %0d cycles",latency);
 $display("Processing Cycles       : %0d",total_cycles);
 $display("Samples/Clock           : %0.6f",samples_per_clock);
 $display("Cycles/Sample           : %0.6f",cycles_per_sample);
 $display("Processing Time         : %0.3f us",processing_time_us);
 $display("Theoretical Throughput  : %0.3f MSamples/s",CLK_FREQ_MHZ);
 $display("Measured Throughput     : %0.3f MSamples/s",throughput_msps);
 $display("Throughput Efficiency   : %0.3f %%",efficiency);
 $display("RESULT                  : %s",(rx==NUM_SAMPLES)?"PASS":"FAIL");
 $finish;
end
endmodule
