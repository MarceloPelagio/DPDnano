`timescale 1ns/1ps
`include "config.vh"

module dpd_core(
    input clk,
    input rst,
    input in_valid,
    input  signed [`DATA_WIDTH-1:0] din_re,din_im,
    input  signed [`COEF_WIDTH-1:0] coef1_re,coef1_im,
    input  signed [`COEF_WIDTH-1:0] coef3_re,coef3_im,
    output out_valid,
    output signed [`DATA_WIDTH-1:0] dout_re,dout_im
);

wire lin_valid;
wire signed [`BRANCH_WIDTH-1:0] lin_re,lin_im;

complex_mult u_lin(
 .clk(clk),.rst(rst),.in_valid(in_valid),
 .a_re(din_re),.a_im(din_im),
 .b_re(coef1_re),.b_im(coef1_im),
 .out_valid(lin_valid),
 .y_re(lin_re),.y_im(lin_im));

wire kern_valid;
wire signed [`MAG2_WIDTH-1:0] mag2;
wire signed [`TERM_WIDTH-1:0] term_re,term_im;

poly_kernel u_kernel(
 .clk(clk),.rst(rst),.in_valid(in_valid),
 .x_re(din_re),.x_im(din_im),
 .out_valid(kern_valid),
 .mag2(mag2),.term_re(term_re),.term_im(term_im));

wire poly_valid;
wire signed [`BRANCH_WIDTH-1:0] poly_re,poly_im;

poly_branch u_poly(
 .clk(clk),.rst(rst),.in_valid(kern_valid),
 .term_re(term_re),.term_im(term_im),
 .coef_re(coef3_re),.coef_im(coef3_im),
 .out_valid(poly_valid),
 .branch_re(poly_re),.branch_im(poly_im));

reg acc_valid;
reg signed [`ACC_WIDTH-1:0] acc_re,acc_im;

always @(posedge clk or posedge rst) begin
 if(rst) begin acc_valid<=0; acc_re<=0; acc_im<=0; end
 else begin
  acc_valid<=poly_valid;
  if(poly_valid) begin
   acc_re<={lin_re[`BRANCH_WIDTH-1],lin_re}+{poly_re[`BRANCH_WIDTH-1],poly_re};
   acc_im<={lin_im[`BRANCH_WIDTH-1],lin_im}+{poly_im[`BRANCH_WIDTH-1],poly_im};
  end
 end
end

wire round_valid;
wire signed [`ROUND_WIDTH-1:0] round_re,round_im;

rounding u_round(
 .clk(clk),.rst(rst),.in_valid(acc_valid),
 .din_re(acc_re),.din_im(acc_im),
 .out_valid(round_valid),
 .dout_re(round_re),.dout_im(round_im));

saturator u_sat(
 .clk(clk),.rst(rst),.in_valid(round_valid),
 .din_re(round_re),.din_im(round_im),
 .out_valid(out_valid),
 .dout_re(dout_re),.dout_im(dout_im));

endmodule
