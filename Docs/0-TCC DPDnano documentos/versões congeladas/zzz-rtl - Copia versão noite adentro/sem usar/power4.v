`timescale 1ns/1ps
`default_nettype none
`include "config.vh"

/******************************************************************************
* Project : DPDnano-Lite
* File    : power4.v
* Version : 2.2
******************************************************************************/

module power4
(
    input  wire signed [`ACC_WIDTH-1:0] mag2,
    output wire signed [`ACC_WIDTH-1:0] mag4
);

wire signed [(2*`ACC_WIDTH)-1:0] mult_full;

/* Q10.30 x Q10.30 -> Q20.60 */
mult_generic #(
    .A_WIDTH(`ACC_WIDTH),
    .B_WIDTH(`ACC_WIDTH)
) u_mult (
    .a(mag2),
    .b(mag2),
    .p(mult_full)
);

/* Return to Q20.30.
 * Saturation will be added in a later revision.
 */
assign mag4 = $signed(mult_full >>> `ACC_FRAC_BITS);

endmodule

`default_nettype wire
