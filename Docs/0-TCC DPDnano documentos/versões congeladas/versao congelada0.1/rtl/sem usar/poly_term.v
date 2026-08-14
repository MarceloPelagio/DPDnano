`timescale 1ns/1ps
`default_nettype none
`include "config.vh"

module poly_term
(
    input  wire signed [`DATA_WIDTH-1:0] vin_i,
    input  wire signed [`DATA_WIDTH-1:0] vin_q,

    input  wire signed [`COEF_WIDTH-1:0] coef_r,
    input  wire signed [`COEF_WIDTH-1:0] coef_i,

    output wire signed [`ACC_WIDTH-1:0] vout_r,
    output wire signed [`ACC_WIDTH-1:0] vout_i
);

wire signed [`MULT_WIDTH-1:0] pr;
wire signed [`MULT_WIDTH-1:0] pi;

complex_mult U_CM(
    .ar(vin_i),
    .ai(vin_q),
    .br(coef_r),
    .bi(coef_i),
    .pr(pr),
    .pi(pi)
);

assign vout_r={{(`ACC_WIDTH-`MULT_WIDTH){pr[`MULT_WIDTH-1]}},pr};
assign vout_i={{(`ACC_WIDTH-`MULT_WIDTH){pi[`MULT_WIDTH-1]}},pi};

endmodule

`default_nettype wire
