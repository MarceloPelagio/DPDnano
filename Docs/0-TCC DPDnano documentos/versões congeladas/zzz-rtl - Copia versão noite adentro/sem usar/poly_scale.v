`timescale 1ns/1ps
`default_nettype none
`include "config.vh"

/******************************************************************************
* Project : DPDnano-Lite
* File    : poly_scale.v
* Version : 2.1
******************************************************************************/

module poly_scale
(
    input  wire signed [`DATA_WIDTH-1:0] din,
    input  wire signed [`ACC_WIDTH-1:0]  scale,
    output wire signed [`ACC_WIDTH-1:0]  dout
);

wire signed [(`ACC_WIDTH+`DATA_WIDTH)-1:0] mult_full;

/* Q10.30 x Q1.15 -> Q11.45 */
mult_generic #(
    .A_WIDTH(`ACC_WIDTH),
    .B_WIDTH(`DATA_WIDTH)
) u_mult (
    .a(scale),
    .b(din),
    .p(mult_full)
);

/* Return to Q11.30.
 * Saturation will be added in a later revision.
 */
assign dout = $signed(mult_full >>> `DATA_FRAC_BITS);

endmodule

`default_nettype wire
