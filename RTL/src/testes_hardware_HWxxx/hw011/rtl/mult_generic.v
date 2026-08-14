`timescale 1ns/1ps
`default_nettype none

/******************************************************************************
* Project : DPDnano-Lite
* File    : mult_generic.v
* Version : 1.0
* Description:
* Generic signed multiplier.
******************************************************************************/

module mult_generic
#(
    parameter A_WIDTH = 16,
    parameter B_WIDTH = 16
)
(
    input  wire signed [A_WIDTH-1:0] a,
    input  wire signed [B_WIDTH-1:0] b,
    output wire signed [A_WIDTH+B_WIDTH-1:0] p
);

assign p = a * b;

endmodule

`default_nettype wire
