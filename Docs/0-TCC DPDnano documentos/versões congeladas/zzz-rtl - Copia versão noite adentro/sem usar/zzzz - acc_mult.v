`timescale 1ns/1ps
`default_nettype none
`include "config.vh"

module acc_mult
(
    input  wire signed [`ACC_WIDTH-1:0] a,
    input  wire signed [`DATA_WIDTH-1:0] b,
    output wire signed [(`ACC_WIDTH+`DATA_WIDTH)-1:0] p
);

assign p = a * b;

endmodule

`default_nettype wire
