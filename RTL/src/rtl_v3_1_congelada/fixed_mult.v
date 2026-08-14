`timescale 1ns/1ps
`default_nettype none
`include "config.vh"

module fixed_mult
#(
    parameter A_WIDTH = `DATA_WIDTH,
    parameter B_WIDTH = `DATA_WIDTH,
    parameter FRAC_BITS = `DATA_FRAC_BITS
)
(
    input  wire signed [A_WIDTH-1:0] a,
    input  wire signed [B_WIDTH-1:0] b,
    output wire signed [A_WIDTH+B_WIDTH-FRAC_BITS-1:0] p
);

wire signed [A_WIDTH+B_WIDTH-1:0] mult_full;
assign mult_full = a * b;
assign p = mult_full >>> FRAC_BITS;

endmodule

`default_nettype wire
