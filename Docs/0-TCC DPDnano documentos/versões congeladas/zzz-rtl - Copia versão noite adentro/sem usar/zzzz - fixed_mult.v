`timescale 1ns / 1ps
`default_nettype none

`include "config.vh"

module fixed_mult
(
    input  wire signed [`DATA_WIDTH-1:0] a,
    input  wire signed [`COEF_WIDTH-1:0] b,
    output wire signed [`MULT_WIDTH-1:0] p
);

assign p = a * b;

endmodule

`default_nettype wire
