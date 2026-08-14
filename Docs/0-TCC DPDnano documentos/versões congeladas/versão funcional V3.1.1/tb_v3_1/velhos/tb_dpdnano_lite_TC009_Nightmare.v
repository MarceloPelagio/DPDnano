`timescale 1ns/1ps
`include "config.vh"

module tb_dpdnano_lite_TC009_Nightmare;

reg clk=0; always #5 clk=~clk;
reg rst,in_valid;
reg signed [`DATA_WIDTH-1:0] din_re,din_im;
reg signed [`COEF_WIDTH-1:0] coef1_re,coef1_im,coef3_re,coef3_im;
wire out_valid;
wire signed [`DATA_WIDTH-1:0] dout_re,dout_im;
wire overflow,overflow_re,overflow_im;

integer tx,rx,ovf,ovfr,ovfi;
reg [31:0] lfsr;

dpd_core dut(
 .clk(clk),.rst(rst),.in_valid(in_valid),
 .din_re(din_re),.din_im(din_im),
 .coef1_re(coef1_re),.coef1_im(coef1_im),
 .coef3_re(coef3_re),.coef3_im(coef3_im),
 .overflow(overflow),.overflow_re(overflow_re),.overflow_im(overflow_im),
 .out_valid(out_valid),.dout_re(dout_re),.dout_im(dout_im));

always @(posedge clk) begin
  if(out_valid) begin
    rx=rx+1;
    if(^dout_re===1'bx || ^dout_im===1'bx) begin
      $display("[FAIL] X/Z detected"); $finish;
    end
  end
  if(overflow) ovf=ovf+1;
  if(overflow_re) ovfr=ovfr+1;
  if(overflow_im) ovfi=ovfi+1;
end

initial begin
  rst=1; in_valid=0;
  tx=0; rx=0; ovf=0; ovfr=0; ovfi=0;
  lfsr=32'h1ACE_B00C;

  // Ganhos agressivos para provocar saturação (ajuste conforme implementação)
  coef1_re=16'sh7FFF;
  coef1_im=16'sh4000;
  coef3_re=16'sh7FFF;
  coef3_im=16'sh4000;

  repeat(4) @(posedge clk);
  rst=0;

  $display("==========================================================");
  $display("             DPDnano-Lite TC009-Nightmare");
  $display("==========================================================");
  $display("Samples : 100000");
  $display("Target  : Saturation / Overflow / Pipeline");

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

  @(posedge clk); in_valid=0;
  wait(rx==100000);

  $display("==========================================================");
  $display("TC009-Nightmare Report");
  $display("==========================================================");
  $display("Samples TX        : %0d",tx);
  $display("Samples RX        : %0d",rx);
  $display("Dropped           : %0d",tx-rx);
  $display("Overflow          : %0d",ovf);
  $display("Overflow RE       : %0d",ovfr);
  $display("Overflow IM       : %0d",ovfi);
  if(tx!=rx) begin
    $display("************* FAIL *************");
  end else if(ovf==0) begin
    $display("WARNING: no overflow observed");
    $display("************* PASS *************");
  end else begin
    $display("************* PASS *************");
  end
  $finish;
end
endmodule
