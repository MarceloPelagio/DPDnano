`timescale 1ns/1ps
`default_nettype none
`include "config.vh"

module dpd_core(
    input  wire clk,
    input  wire rst,
    input  wire valid_in,
    input  wire signed [`DATA_WIDTH-1:0] vin_i,
    input  wire signed [`DATA_WIDTH-1:0] vin_q,
    output wire valid_out,
    output wire signed [`DATA_WIDTH-1:0] vout_i,
    output wire signed [`DATA_WIDTH-1:0] vout_q
);

wire signed [`DATA_WIDTH-1:0] x0_i,x0_q,x1_i,x1_q,x2_i,x2_q;

iq_delay u_delay(
.clk(clk),.rst(rst),.valid_in(valid_in),
.din_i(vin_i),.din_q(vin_q),
.x0_i(x0_i),.x0_q(x0_q),
.x1_i(x1_i),.x1_q(x1_q),
.x2_i(x2_i),.x2_q(x2_q),
.valid_out(valid_out));

wire signed [`COEF_WIDTH-1:0] c0_r,c0_i,c1_r,c1_i,c2_r,c2_i;
coeff_bank u_coef(.c0_r(c0_r),.c0_i(c0_i),.c1_r(c1_r),.c1_i(c1_i),.c2_r(c2_r),.c2_i(c2_i));

wire signed [`CUBIC_WIDTH-1:0] k0r,k0i,k1r,k1i,k2r,k2i;
poly_kernel p0(.din_i(x0_i),.din_q(x0_q),.cubic_i(k0r),.cubic_q(k0i));
poly_kernel p1(.din_i(x1_i),.din_q(x1_q),.cubic_i(k1r),.cubic_q(k1i));
poly_kernel p2(.din_i(x2_i),.din_q(x2_q),.cubic_i(k2r),.cubic_q(k2i));

wire signed [`TERM_WIDTH-1:0] t0r,t0i,t1r,t1i,t2r,t2i;
poly_branch b0(.cubic_i(k0r),.cubic_q(k0i),.coef_r(c0_r),.coef_i(c0_i),.term_r(t0r),.term_i(t0i));
poly_branch b1(.cubic_i(k1r),.cubic_q(k1i),.coef_r(c1_r),.coef_i(c1_i),.term_r(t1r),.term_i(t1i));
poly_branch b2(.cubic_i(k2r),.cubic_q(k2i),.coef_r(c2_r),.coef_i(c2_i),.term_r(t2r),.term_i(t2i));

wire signed [`ACC_WIDTH-1:0] acc_r,acc_i;
complex_add add(.a_r(t0r),.a_i(t0i),.b_r(t1r),.b_i(t1i),.c_r(t2r),.c_i(t2i),.sum_r(acc_r),.sum_i(acc_i));

wire signed [`DATA_WIDTH-1:0] rnd_r,rnd_i;
rounding rr(.din(acc_r),.dout(rnd_r));
rounding ri(.din(acc_i),.dout(rnd_i));

saturator sr(.din(rnd_r),.dout(vout_i));
saturator si(.din(rnd_i),.dout(vout_q));

endmodule
`default_nettype wire
