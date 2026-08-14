`timescale 1ns/1ps
`include "config.vh"
module complex_mult(
input clk,input rst,input in_valid,
input signed [`DATA_WIDTH-1:0] a_re,a_im,b_re,b_im,
output reg out_valid,
output reg signed [`BRANCH_WIDTH-1:0] y_re,
output reg signed [`BRANCH_WIDTH-1:0] y_im);

reg                 mult_valid;
reg signed [31:0]   p0_r, p1_r, p2_r, p3_r;
wire signed [`BRANCH_WIDTH-1:0] sum_re;
wire signed [`BRANCH_WIDTH-1:0] sum_im;

assign sum_re = $signed({p0_r[31],p0_r}) - $signed({p1_r[31],p1_r});
assign sum_im = $signed({p2_r[31],p2_r}) + $signed({p3_r[31],p3_r});

always @(posedge clk or posedge rst) begin
 if(rst) begin
  mult_valid<=0;
  out_valid<=0;
  p0_r<=0; p1_r<=0; p2_r<=0; p3_r<=0;
  y_re<=0; y_im<=0;
 end
 else begin
  mult_valid<=in_valid;
  if(in_valid) begin
   p0_r<=a_re*b_re;
   p1_r<=a_im*b_im;
   p2_r<=a_re*b_im;
   p3_r<=a_im*b_re;
  end

  out_valid<=mult_valid;
  if(mult_valid) begin
   y_re<=sum_re;
   y_im<=sum_im;
  end
 end
end
endmodule
