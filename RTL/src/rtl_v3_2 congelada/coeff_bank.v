`timescale 1ns/1ps
`default_nettype none

`include "config.vh"
`include "coeff_pkg.vh"

/******************************************************************************
* Project : DPDnano-Lite
* File    : coeff_bank.v
* Version : 2.0
******************************************************************************/

module coeff_bank
(
    output wire signed [`COEF_WIDTH-1:0] c0_r,
    output wire signed [`COEF_WIDTH-1:0] c0_i,

    output wire signed [`COEF_WIDTH-1:0] c1_r,
    output wire signed [`COEF_WIDTH-1:0] c1_i,

    output wire signed [`COEF_WIDTH-1:0] c2_r,
    output wire signed [`COEF_WIDTH-1:0] c2_i
);

assign c0_r = `C0_REAL;
assign c0_i = `C0_IMAG;

assign c1_r = `C1_REAL;
assign c1_i = `C1_IMAG;

assign c2_r = `C2_REAL;
assign c2_i = `C2_IMAG;

endmodule

`default_nettype wire
