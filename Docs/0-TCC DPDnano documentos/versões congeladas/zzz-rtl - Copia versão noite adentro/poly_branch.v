`timescale 1ns/1ps
`default_nettype none

`include "config.vh"

/******************************************************************************
* Module : poly_branch
* Version: 3.0
*
* Input : cubic term (Q4.45)
* Coef  : Q1.15
* Output: Q5.30 (TERM_WIDTH)
******************************************************************************/

module poly_branch
(
    input  wire signed [`CUBIC_WIDTH-1:0] cubic_i,
    input  wire signed [`CUBIC_WIDTH-1:0] cubic_q,

    input  wire signed [`COEF_WIDTH-1:0] coef_r,
    input  wire signed [`COEF_WIDTH-1:0] coef_i,

    output wire signed [`TERM_WIDTH-1:0] term_r,
    output wire signed [`TERM_WIDTH-1:0] term_i
);

// Complex multiplication (Q5.60 internal)
wire signed [65:0] mul_r;
wire signed [65:0] mul_i;

complex_mult u_cmul(
    .a_r(cubic_i),
    .a_i(cubic_q),
    .b_r(coef_r),
    .b_i(coef_i),
    .p_r(mul_r),
    .p_i(mul_i)
);

// Normalize Q5.60 -> Q5.30
localparam integer SHIFT = 30;

assign term_r = (mul_r + (66'sd1 <<< (SHIFT-1))) >>> SHIFT;
assign term_i = (mul_i + (66'sd1 <<< (SHIFT-1))) >>> SHIFT;

endmodule

`default_nettype wire
