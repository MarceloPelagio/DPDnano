`timescale 1ns / 1ps
`default_nettype none

`include "config.vh"

module complex_mult
(
    input  wire signed [`DATA_WIDTH-1:0] ar,
    input  wire signed [`DATA_WIDTH-1:0] ai,
    input  wire signed [`COEF_WIDTH-1:0] br,
    input  wire signed [`COEF_WIDTH-1:0] bi,
    output wire signed [`MULT_WIDTH-1:0] pr,
    output wire signed [`MULT_WIDTH-1:0] pi
);

wire signed [`COEF_WIDTH:0] br_plus_bi = br + bi;
wire signed [`DATA_WIDTH:0] ar_plus_ai = ar + ai;
wire signed [`DATA_WIDTH:0] ai_minus_ar = ai - ar;

wire signed [`MULT_WIDTH-1:0] k1 = ar * br_plus_bi;
wire signed [`MULT_WIDTH-1:0] k2 = bi * ar_plus_ai;
wire signed [`MULT_WIDTH-1:0] k3 = br * ai_minus_ar;

assign pr = k1 - k2;
assign pi = k1 + k3;

endmodule

`default_nettype wire
