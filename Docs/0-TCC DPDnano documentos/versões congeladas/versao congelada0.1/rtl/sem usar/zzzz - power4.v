`timescale 1ns/1ps
`default_nettype none

`include "config.vh"

/******************************************************************************
* Project : DPDnano-Lite
* File    : power4.v
* Version : 1.0
******************************************************************************/

module power4
(
    input  wire signed [`ACC_WIDTH-1:0] mag2,
    output wire signed [`ACC_WIDTH-1:0] mag4
);

wire signed [`MULT_WIDTH-1:0] p;

fixed_mult u_mult(
    .a(mag2[`DATA_WIDTH-1:0]),
    .b(mag2[`COEF_WIDTH-1:0]),
    .p(p)
);

assign mag4={{(`ACC_WIDTH-`MULT_WIDTH){p[`MULT_WIDTH-1]}},p};

endmodule

`default_nettype wire
