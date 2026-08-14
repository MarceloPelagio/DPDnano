`timescale 1ns/1ps
`default_nettype none
`include "config.vh"

module rounding
(
    input  wire signed [`ACC_WIDTH-1:0] din,
    output wire signed [`DATA_WIDTH-1:0] dout
);

localparam integer SHIFT = (`ACC_FRAC_BITS-`DATA_FRAC_BITS);

wire signed [`ACC_WIDTH-1:0] bias =
    ({{(`ACC_WIDTH-1){1'b0}},1'b1} <<< (SHIFT-1));

wire signed [`ACC_WIDTH-1:0] rounded = din + bias;

assign dout = rounded >>> SHIFT;

endmodule

`default_nettype wire
