`timescale 1ns/1ps
`include "config.vh"

module poly_branch
(
    input clk,
    input rst,
    input in_valid,

    input  signed [`TERM_WIDTH-1:0] term_re,
    input  signed [`TERM_WIDTH-1:0] term_im,

    input  signed [`COEF_WIDTH-1:0] coef_re,
    input  signed [`COEF_WIDTH-1:0] coef_im,

    output reg out_valid,

    output reg signed [`BRANCH_WIDTH-1:0] branch_re,
    output reg signed [`BRANCH_WIDTH-1:0] branch_im
);

wire signed [64:0] m0 = term_re * coef_re;
wire signed [64:0] m1 = term_im * coef_im;
wire signed [64:0] m2 = term_re * coef_im;
wire signed [64:0] m3 = term_im * coef_re;

wire signed [65:0] acc_re = {m0[64],m0} - {m1[64],m1};
wire signed [65:0] acc_im = {m2[64],m2} + {m3[64],m3};

// Q?.60 -> Q3.30
wire signed [65:0] acc_re_r = acc_re + 66'sd536870912; // 1<<29
wire signed [65:0] acc_im_r = acc_im + 66'sd536870912;

wire signed [`BRANCH_WIDTH-1:0] norm_re = acc_re_r >>> 30;
wire signed [`BRANCH_WIDTH-1:0] norm_im = acc_im_r >>> 30;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        out_valid <= 1'b0;
        branch_re <= 0;
        branch_im <= 0;
    end else begin
        out_valid <= in_valid;
        if(in_valid) begin
            branch_re <= norm_re;
            branch_im <= norm_im;
        end
    end
end

endmodule
