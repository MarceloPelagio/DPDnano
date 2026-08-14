`timescale 1ns/1ps
`include "config.vh"

module dpd_core(
    input clk,
    input rst,
    input in_valid,
    input  signed [`DATA_WIDTH-1:0] din_re,din_im,
    input  signed [`COEF_WIDTH-1:0] coef1_re,coef1_im,
    input  signed [`COEF_WIDTH-1:0] coef3_re,coef3_im,

`ifdef DPD_ENABLE_OVERFLOW_FLAGS
    output overflow,
    output overflow_re,
    output overflow_im,
`endif

    output out_valid,
    output signed [`DATA_WIDTH-1:0] dout_re,dout_im
);

wire lin_valid;
wire signed [`BRANCH_WIDTH-1:0] lin_re,lin_im;

wire round_valid;
wire signed [`ROUND_WIDTH-1:0] round_re, round_im;

wire clip_re;
wire clip_im;
wire clip_dir_re;
wire clip_dir_im;

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

//--------------------------------------------------------------
// Linear branch alignment
//--------------------------------------------------------------
reg signed [`BRANCH_WIDTH-1:0] lin_re_d;
reg signed [`BRANCH_WIDTH-1:0] lin_im_d;
reg                            lin_valid_d;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        lin_re_d    <= 0;
        lin_im_d    <= 0;
        lin_valid_d <= 1'b0;
    end
    else begin
        lin_re_d    <= lin_re;
        lin_im_d    <= lin_im;
        lin_valid_d <= lin_valid;
    end
end

poly_branch u_poly(
 .clk(clk),.rst(rst),.in_valid(kern_valid),
 .term_re(term_re),.term_im(term_im),
 .coef_re(coef3_re),.coef_im(coef3_im),
 .out_valid(poly_valid),
 .branch_re(poly_re),.branch_im(poly_im));

reg acc_valid;
reg signed [`ACC_WIDTH-1:0] acc_re,acc_im;



always @(posedge clk or posedge rst) begin
    if (rst) begin
        acc_valid <= 1'b0;
        acc_re    <= 0;
        acc_im    <= 0;
    end
    else begin

        acc_valid <= poly_valid & lin_valid_d;

        if (poly_valid & lin_valid_d) begin

            acc_re <=
                {lin_re_d[`BRANCH_WIDTH-1], lin_re_d} +
                {poly_re[`BRANCH_WIDTH-1], poly_re};

            acc_im <=
                {lin_im_d[`BRANCH_WIDTH-1], lin_im_d} +
                {poly_im[`BRANCH_WIDTH-1], poly_im};

        end
    end
end

rounding u_round(
    .clk(clk),
    .rst(rst),
    .din_valid(acc_valid),
    .din_re(acc_re),
    .din_im(acc_im),
    .dout_valid(round_valid),
    .dout_re(round_re),
    .dout_im(round_im),
    .clip_re(clip_re),
    .clip_im(clip_im),
    .clip_dir_re(clip_dir_re),
    .clip_dir_im(clip_dir_im)
);

saturator u_sat(
    .clk(clk),
    .rst(rst),
    .din_valid(round_valid),
    .din_re(round_re),
    .din_im(round_im),
    .clip_re(clip_re),
    .clip_im(clip_im),
    .clip_dir_re(clip_dir_re),
    .clip_dir_im(clip_dir_im),

`ifdef DPD_ENABLE_OVERFLOW_FLAGS
    .overflow(overflow),
    .overflow_re(overflow_re),
    .overflow_im(overflow_im),
`endif

    .dout_valid(out_valid),
    .dout_re(dout_re),
    .dout_im(dout_im)
);

endmodule
