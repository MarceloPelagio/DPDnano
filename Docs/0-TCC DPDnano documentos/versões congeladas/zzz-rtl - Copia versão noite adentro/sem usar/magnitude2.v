`timescale 1ns/1ps
`default_nettype none

`include "config.vh"

/******************************************************************************
* Project : DPDnano-Lite
* File    : magnitude2.v
* Version : 1.0
*
* Description:
* Computes |x|² = I² + Q².
******************************************************************************/

module magnitude2
(
    input  wire signed [`DATA_WIDTH-1:0] i_in,
    input  wire signed [`DATA_WIDTH-1:0] q_in,

    output wire signed [`ACC_WIDTH-1:0] mag2
);

wire signed [`MULT_WIDTH-1:0] ii;
wire signed [`MULT_WIDTH-1:0] qq;

fixed_mult u_mult_i(
    .a(i_in),
    .b(i_in),
    .p(ii)
);

fixed_mult u_mult_q(
    .a(q_in),
    .b(q_in),
    .p(qq)
);

assign mag2 =
    {{(`ACC_WIDTH-`MULT_WIDTH){ii[`MULT_WIDTH-1]}},ii} +
    {{(`ACC_WIDTH-`MULT_WIDTH){qq[`MULT_WIDTH-1]}},qq};

endmodule

`default_nettype wire
