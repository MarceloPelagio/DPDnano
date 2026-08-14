`timescale 1ns/1ps
`include "config.vh"
module complex_mult(
input clk,input rst,input in_valid,
input signed [`DATA_WIDTH-1:0] a_re,a_im,b_re,b_im,
output reg out_valid,
output reg signed [`BRANCH_WIDTH-1:0] y_re,
output reg signed [`BRANCH_WIDTH-1:0] y_im);
wire signed [31:0] p0,p1,p2,p3;
wire signed [`BRANCH_WIDTH-1:0] sum_re,sum_im;
assign p0=a_re*b_re;
assign p1=a_im*b_im;
assign p2=a_re*b_im;
assign p3=a_im*b_re;
assign sum_re=$signed({p0[31],p0})-$signed({p1[31],p1});
assign sum_im=$signed({p2[31],p2})+$signed({p3[31],p3});
always @(posedge clk or posedge rst) begin
 if(rst) begin out_valid<=0; y_re<=0; y_im<=0; end
 else begin out_valid<=in_valid; if(in_valid) begin y_re<=sum_re; y_im<=sum_im; end end
end
endmodule
