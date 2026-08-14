`timescale 1ns/1ps
`default_nettype none
`include "config.vh"

module poly_term
(
    input  wire signed [`DATA_WIDTH-1:0] x_i,
    input  wire signed [`DATA_WIDTH-1:0] x_q,
    input  wire signed [`ACC_WIDTH-1:0]  scale,
    input  wire signed [`COEF_WIDTH-1:0] coef_r,
    input  wire signed [`COEF_WIDTH-1:0] coef_i,

    output wire signed [`ACC_WIDTH-1:0] y_r,
    output wire signed [`ACC_WIDTH-1:0] y_i
);

wire signed [`ACC_WIDTH-1:0] sx_i;
wire signed [`ACC_WIDTH-1:0] sx_q;

wire signed [`MULT_WIDTH-1:0] cm_r;
wire signed [`MULT_WIDTH-1:0] cm_i;

poly_scale u_scale_i(.din(x_i),.scale(scale),.dout(sx_i));
poly_scale u_scale_q(.din(x_q),.scale(scale),.dout(sx_q));

complex_mult u_cmult(
    .ar(sx_i[`DATA_WIDTH-1:0]),
    .ai(sx_q[`DATA_WIDTH-1:0]),
    .br(coef_r),
    .bi(coef_i),
    .pr(cm_r),
    .pi(cm_i)
);

assign y_r={{(`ACC_WIDTH-`MULT_WIDTH){cm_r[`MULT_WIDTH-1]}},cm_r};
assign y_i={{(`ACC_WIDTH-`MULT_WIDTH){cm_i[`MULT_WIDTH-1]}},cm_i};

endmodule
`default_nettype wire
