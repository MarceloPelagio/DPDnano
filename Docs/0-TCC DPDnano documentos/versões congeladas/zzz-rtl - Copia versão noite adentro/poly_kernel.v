`timescale 1ns/1ps
`default_nettype none

`include "config.vh"

/******************************************************************************
* Module : poly_kernel
* Version: 3.0
*
* Output format:
*     Q4.45 (CUBIC_WIDTH)
******************************************************************************/

module poly_kernel
(
    input  wire signed [`DATA_WIDTH-1:0] din_i,
    input  wire signed [`DATA_WIDTH-1:0] din_q,

    output wire signed [`CUBIC_WIDTH-1:0] cubic_i,
    output wire signed [`CUBIC_WIDTH-1:0] cubic_q
);

wire signed [`MULT_WIDTH-1:0] ii;
wire signed [`MULT_WIDTH-1:0] qq;

mult_generic u_mul_ii(.a(din_i),.b(din_i),.p(ii));
mult_generic u_mul_qq(.a(din_q),.b(din_q),.p(qq));

wire signed [`MAG2_WIDTH-1:0] mag2 = ii + qq;

mult_generic u_mul_i(.a(din_i),.b(mag2),.p(cubic_i));
mult_generic u_mul_q(.a(din_q),.b(mag2),.p(cubic_q));

endmodule

`default_nettype wire
