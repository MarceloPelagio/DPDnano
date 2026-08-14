`timescale 1ns/1ps
`include "../rtl_v3_1/config.vh"

// ============================================================================
// DPDnano-Lite RTL v3.1
// TMC015 - Saturation and Overflow Statistics
// Revision : v001
// Based on validated TMC014 v001
// ============================================================================

module tb_dpdnano_lite_TMC015;

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
integer sat_pos_re,sat_neg_re,sat_pos_im,sat_neg_im;
real sat_percent;

always @(posedge clk) begin
    cycles <= cycles + 1;

    if(in_valid && first_in==-1)
        first_in = cycles;

    if(out_valid) begin
        rx <= rx + 1;

        if(first_out==-1)
            first_out = cycles;

        last_out = cycles;

        if(overflow)
            ovf_count = ovf_count + 1;

        if(dout_re==16'sh7FFF) sat_pos_re = sat_pos_re + 1;
        if(dout_re==-16'sh8000) sat_neg_re = sat_neg_re + 1;
        if(dout_im==16'sh7FFF) sat_pos_im = sat_pos_im + 1;
        if(dout_im==-16'sh8000) sat_neg_im = sat_neg_im + 1;
    end
end

initial begin
 rst=1; in_valid=0; din_re=0; din_im=0;
 coef1_re=16'sh2000; coef1_im=0;
 coef3_re=16'sh0800; coef3_im=0;

 tx=0; rx=0; cycles=0;
 ovf_count=0;
 sat_pos_re=0; sat_neg_re=0;
 sat_pos_im=0; sat_neg_im=0;

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

 sat_percent=(100.0*(sat_pos_re+sat_neg_re+sat_pos_im+sat_neg_im))/NUM_SAMPLES;

 $display("==================================================");
 $display("DPDnano-Lite TMC015 v001");
 $display("==================================================");
 $display("Pipeline Latency          : %0d cycles",latency);
 $display("Processing Cycles         : %0d",total_cycles);
 $display("Overflow Events           : %0d",ovf_count);
 $display("Positive Saturation (Re)  : %0d",sat_pos_re);
 $display("Negative Saturation (Re)  : %0d",sat_neg_re);
 $display("Positive Saturation (Im)  : %0d",sat_pos_im);
 $display("Negative Saturation (Im)  : %0d",sat_neg_im);
 $display("Saturation Percentage     : %0.3f %%",sat_percent);
 $display("RESULT                    : %s",(rx==NUM_SAMPLES)?"PASS":"FAIL");
 $finish;
end

endmodule
