`timescale 1ns/1ps
`default_nettype none
`include "config.vh"

module complex_add
(
    input  wire signed [`TERM_WIDTH-1:0] a_r,
    input  wire signed [`TERM_WIDTH-1:0] a_i,

    input  wire signed [`TERM_WIDTH-1:0] b_r,
    input  wire signed [`TERM_WIDTH-1:0] b_i,

    input  wire signed [`TERM_WIDTH-1:0] c_r,
    input  wire signed [`TERM_WIDTH-1:0] c_i,

    output wire signed [`ACC_WIDTH-1:0] sum_r,
    output wire signed [`ACC_WIDTH-1:0] sum_i
);

assign sum_r = $signed(a_r) + $signed(b_r) + $signed(c_r);
assign sum_i = $signed(a_i) + $signed(b_i) + $signed(c_i);

endmodule

`default_nettype wire
