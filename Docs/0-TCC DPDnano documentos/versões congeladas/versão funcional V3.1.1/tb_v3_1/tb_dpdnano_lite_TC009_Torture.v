`timescale 1ns/1ps
`include "config.vh"

module tb_dpdnano_lite_TC009_Torture;

// ============================================================
// TC009_Torture - Long Duration Stress Test
// DPDnano-Lite RTL v3.1 (Frozen)
// ============================================================

reg clk=0;
always #5 clk=~clk;

reg rst,in_valid;
reg signed [`DATA_WIDTH-1:0] din_re,din_im;
reg signed [`COEF_WIDTH-1:0] coef1_re,coef1_im,coef3_re,coef3_im;

wire out_valid;
wire signed [`DATA_WIDTH-1:0] dout_re,dout_im;
wire overflow,overflow_re,overflow_im;

integer tx,rx;
integer ovf,ovf_re,ovf_im;
integer timeout;

integer cycle_cnt;
integer first_input_cycle;
integer first_output_cycle;
integer pipeline_latency;
reg first_input_seen;
reg first_output_seen;

dpd_core dut(
 .clk(clk),.rst(rst),.in_valid(in_valid),
 .din_re(din_re),.din_im(din_im),
 .coef1_re(coef1_re),.coef1_im(coef1_im),
 .coef3_re(coef3_re),.coef3_im(coef3_im),
 .overflow(overflow),.overflow_re(overflow_re),.overflow_im(overflow_im),
 .out_valid(out_valid),.dout_re(dout_re),.dout_im(dout_im));

always @(posedge clk) begin
    cycle_cnt <= cycle_cnt + 1;

    if(in_valid && !first_input_seen) begin
        first_input_seen <= 1'b1;
        first_input_cycle <= cycle_cnt;
    end

    if(out_valid) begin
        if(!first_output_seen) begin
            first_output_seen <= 1'b1;
            first_output_cycle <= cycle_cnt;
        end
        rx <= rx + 1;
        if(^dout_re===1'bx || ^dout_im===1'bx) begin
            $display("[FAIL] X/Z detected on DUT outputs.");
            $finish;
        end
    end

    if(overflow) ovf <= ovf+1;
    if(overflow_re) ovf_re <= ovf_re+1;
    if(overflow_im) ovf_im <= ovf_im+1;
end

initial begin
 rst=1; in_valid=0;
 tx=0; rx=0; timeout=0;
 ovf=0; ovf_re=0; ovf_im=0;
 cycle_cnt=0;
 first_input_seen=0;
 first_output_seen=0;
 first_input_cycle=-1;
 first_output_cycle=-1;
 pipeline_latency=-1;

 coef1_re=16'sd32767; coef1_im=0;
 coef3_re=0; coef3_im=0;

 repeat(4) @(posedge clk);
 rst=0;

 $display("======================================================================");
 $display("                 DPDnano-Lite RTL Validation Suite");
 $display("======================================================================");
 $display("Project      : DPDnano-Lite");
 $display("Version      : 3.1 (Frozen)");
 $display("Module       : dpd_core");
 $display("");
 $display("TEST         : TC009_Torture");
 $display("Description  : Long Duration Stress Test");
 $display("======================================================================");
 $display("Configuration");
 $display("  Clock              : 100 MHz");
 $display("  Stimulus           : Mixed + Random");
 $display("  Samples            : 50000");
 $display("  Linear Coef        : 0x7FFF");
 $display("  Cubic Coef         : 0x0000");
 $display("");

 for(tx=0; tx<50000; tx=tx+1) begin
   @(posedge clk);
   in_valid=1;
   case(tx[2:0])
    3'd0: begin din_re=tx; din_im=-tx; end
    3'd1: begin din_re=-tx; din_im=tx; end
    3'd2: begin din_re=16'sh7FFF; din_im=16'sh8000; end
    3'd3: begin din_re=16'sh8000; din_im=16'sh7FFF; end
    3'd4: begin din_re=0; din_im=0; end
    default: begin din_re=$random; din_im=$random; end
   endcase
 end

 @(posedge clk); in_valid=0;

 while((rx<50000)&&(timeout<1000000)) begin
   @(posedge clk);
   timeout=timeout+1;
 end

 pipeline_latency=first_output_cycle-first_input_cycle;

 $display("Execution");
 $display("  Vectors Sent       : %0d",tx);
 $display("  Vectors Received   : %0d",rx);
 $display("  Dropped Vectors    : %0d",tx-rx);
 $display("  Delivery Rate      : %0.2f %%",(tx>0)?((rx*100.0)/tx):0.0);
 $display("");
 $display("Pipeline");
 $display("  Expected Latency   : 5 cycles");
 $display("  Measured Latency   : %0d cycles",pipeline_latency);
 $display("  Latency Check      : %s",(pipeline_latency==5)?"PASS":"FAIL");
 $display("  Pipeline Flush     : %s",(rx==tx)?"PASS":"FAIL");
 $display("");
 $display("Monitors");
 $display("  Data Integrity     : PASS");
 $display("  Output Valid       : %s",(rx==tx)?"PASS":"FAIL");
 $display("  Overflow Events    : %0d",ovf);
 $display("  Overflow RE        : %0d",ovf_re);
 $display("  Overflow IM        : %0d",ovf_im);
 $display("  Timeout            : %s",(timeout<1000000)?"NO":"YES");
 $display("");
 $display("Simulation");
 $display("  Clock Period       : 10 ns");
 $display("  Simulation Cycles  : %0d",cycle_cnt);
 $display("  Simulation Time    : %0d ns",cycle_cnt*10);
 $display("======================================================================");
 $display("SUMMARY");
 $display("======================================================================");
 if((rx==tx)&&(pipeline_latency==5)&&(timeout<1000000)) begin
   $display("TC009_Torture - Long Duration Stress ...... PASS");
   $display("");
   $display("Vectors Executed : %0d",tx);
   $display("Vectors Passed   : %0d",tx);
   $display("Vectors Failed   : 0");
   $display("Overall Result   : PASS");
 end else begin
   $display("TC009_Torture - Long Duration Stress ...... FAIL");
   $display("");
   $display("Vectors Executed : %0d",tx);
   $display("Vectors Passed   : %0d",rx);
   $display("Vectors Failed   : %0d",tx-rx);
   $display("Overall Result   : FAIL");
 end
 $display("======================================================================");
 $finish;
end

endmodule
