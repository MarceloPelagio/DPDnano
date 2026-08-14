`timescale 1ns/1ps
`include "../rtl_v3_1/config.vh"

module tb_dpdnano_lite_TC009_Apocalypse;

// ============================================================
// TC009_Apocalypse
// Dynamic Coefficient Stress Test
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
integer cycle_cnt,timeout;
integer first_input_cycle,first_output_cycle,pipeline_latency;
reg first_input_seen,first_output_seen;

reg [31:0] lfsr;

dpd_core dut(
 .clk(clk),.rst(rst),.in_valid(in_valid),
 .din_re(din_re),.din_im(din_im),
 .coef1_re(coef1_re),.coef1_im(coef1_im),
 .coef3_re(coef3_re),.coef3_im(coef3_im),
 .overflow(overflow),.overflow_re(overflow_re),.overflow_im(overflow_im),
 .out_valid(out_valid),.dout_re(dout_re),.dout_im(dout_im));

always @(posedge clk) begin
  cycle_cnt<=cycle_cnt+1;

  if(in_valid && !first_input_seen) begin
    first_input_seen<=1;
    first_input_cycle<=cycle_cnt;
  end

  if(out_valid) begin
    rx<=rx+1;
    if(!first_output_seen) begin
      first_output_seen<=1;
      first_output_cycle<=cycle_cnt;
    end
    if(^dout_re===1'bx || ^dout_im===1'bx) begin
      $display("[FAIL] X/Z detected");
      $finish;
    end
  end

  if(overflow) ovf<=ovf+1;
  if(overflow_re) ovfr<=ovfr+1;
  if(overflow_im) ovfi<=ovfi+1;
end

initial begin
 rst=1; in_valid=0;
 tx=0; rx=0; ovf=0; ovfr=0; ovfi=0;
 timeout=0; cycle_cnt=0;
 first_input_seen=0; first_output_seen=0;
 first_input_cycle=-1; first_output_cycle=-1;
 pipeline_latency=-1;
 lfsr=32'hA5A55A5A;

 coef1_re=0; coef1_im=0;
 coef3_re=0; coef3_im=0;

 repeat(4) @(posedge clk);
 rst=0;

 $display("==========================================================");
 $display("           DPDnano-Lite TC009_Apocalypse");
 $display("==========================================================");
 $display("Samples : 100000");
 $display("Mode    : Dynamic Coefficient Stress");

 for(tx=0; tx<100000; tx=tx+1) begin
   @(posedge clk);
   in_valid=1;

   lfsr={lfsr[30:0],lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};

   // Dynamic coefficients (change every 256 samples)
   if(tx[7:0]==8'h00) begin
      case(tx[15:8])
        8'd0: begin
          coef1_re=16'sh2000; coef1_im=16'sh0000;
          coef3_re=16'sh0800; coef3_im=16'sh0000;
        end
        8'd1: begin
          coef1_re=16'sh4000; coef1_im=16'sh1000;
          coef3_re=16'sh3000; coef3_im=16'sh1000;
        end
        8'd2: begin
          coef1_re=16'sh6000; coef1_im=16'sh2000;
          coef3_re=16'sh5000; coef3_im=16'sh2000;
        end
        default: begin
          coef1_re=lfsr[15:0];
          coef1_im=lfsr[31:16];
          coef3_re={lfsr[7:0],lfsr[15:8]};
          coef3_im={lfsr[23:16],lfsr[31:24]};
        end
      endcase
   end

   case(tx[2:0])
     3'd0: begin din_re=16'sh7FFF; din_im=16'sh7FFF; end
     3'd1: begin din_re=16'sh8000; din_im=16'sh8000; end
     default: begin
       din_re=lfsr[15:0];
       din_im=lfsr[31:16];
     end
   endcase
 end

 @(posedge clk); in_valid=0;

 while((rx<100000)&&(timeout<2000000)) begin
   @(posedge clk);
   timeout=timeout+1;
 end

 pipeline_latency=first_output_cycle-first_input_cycle;

 $display("Vectors TX        : %0d",tx);
 $display("Vectors RX        : %0d",rx);
 $display("Latency           : %0d",pipeline_latency);
 $display("Overflow          : %0d",ovf);
 $display("Overflow RE       : %0d",ovfr);
 $display("Overflow IM       : %0d",ovfi);
 $display("Cycles            : %0d",cycle_cnt);
 $display("Simulation Time   : %0d ns",cycle_cnt*10);

 if((rx==tx)&&(pipeline_latency==5))
   $display("************* PASS *************");
 else
   $display("************* FAIL *************");

 $finish;
end

endmodule
