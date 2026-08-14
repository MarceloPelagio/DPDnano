`timescale 1ns/1ps
`include "../rtl_v3_1/config.vh"

module tb_dpdnano_lite_TC009_Nightmare;

// ============================================================
// TC009_Nightmare - Maximum Saturation Stress Test
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
integer ovf,ovfr,ovfi;
integer timeout;

integer cycle_cnt;
integer first_input_cycle;
integer first_output_cycle;
integer pipeline_latency;
reg first_input_seen;
reg first_output_seen;

reg [31:0] lfsr;

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
        rx <= rx + 1;
        if(!first_output_seen) begin
            first_output_seen <= 1'b1;
            first_output_cycle <= cycle_cnt;
        end
        if(^dout_re===1'bx || ^dout_im===1'bx) begin
            $display("[FAIL] X/Z detected");
            $finish;
        end
    end

    if(overflow)    ovf  <= ovf+1;
    if(overflow_re) ovfr <= ovfr+1;
    if(overflow_im) ovfi <= ovfi+1;
end

initial begin
 rst=1; in_valid=0;
 tx=0; rx=0;
 ovf=0; ovfr=0; ovfi=0;
 timeout=0;
 cycle_cnt=0;
 first_input_seen=0;
 first_output_seen=0;
 first_input_cycle=-1;
 first_output_cycle=-1;
 pipeline_latency=-1;
 lfsr=32'h1ACE_B00C;

 coef1_re=16'sh7FFF;
 coef1_im=16'sh4000;
 coef3_re=16'sh7FFF;
 coef3_im=16'sh4000;

 repeat(4) @(posedge clk);
 rst=0;

 $display("======================================================================");
 $display("                 DPDnano-Lite RTL Validation Suite");
 $display("======================================================================");
 $display("TEST         : TC009_Nightmare");
 $display("Description  : Maximum Saturation Stress Test");
 $display("Samples      : 100000");
 $display("======================================================================");

 for(tx=0;tx<100000;tx=tx+1) begin
   @(posedge clk);
   in_valid=1;
   lfsr={lfsr[30:0],lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};
   case(tx[3:0])
      4'h0: begin din_re=16'sh7FFF; din_im=16'sh7FFF; end
      4'h1: begin din_re=16'sh8000; din_im=16'sh8000; end
      4'h2: begin din_re=16'sh7FFF; din_im=16'sh8000; end
      4'h3: begin din_re=16'sh8000; din_im=16'sh7FFF; end
      default: begin
        din_re=lfsr[15:0];
        din_im=lfsr[31:16];
      end
   endcase
 end

 @(posedge clk);
 in_valid=0;

 while((rx<100000)&&(timeout<2000000)) begin
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
 $display("Overflow Statistics");
 $display("  Expected Overflow  : YES");
 $display("  Observed Overflow  : %s",(ovf>0)?"YES":"NO");
 $display("  Overflow Events    : %0d",ovf);
 $display("  Overflow RE        : %0d",ovfr);
 $display("  Overflow IM        : %0d",ovfi);
 $display("  Overflow Check     : %s",(ovf>0)?"PASS":"FAIL");
 $display("");
 $display("Simulation");
 $display("  Simulation Cycles  : %0d",cycle_cnt);
 $display("  Simulation Time    : %0d ns",cycle_cnt*10);
 $display("======================================================================");
 if((rx==tx)&&(pipeline_latency==5)&&(timeout<2000000)&&(ovf>0))
   $display("Overall Result   : PASS");
 else
   $display("Overall Result   : FAIL");
 $display("======================================================================");
 $finish;
end

endmodule
