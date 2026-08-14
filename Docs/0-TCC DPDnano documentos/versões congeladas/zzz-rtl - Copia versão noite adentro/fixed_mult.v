`timescale 1ns/1ps
`default_nettype none
`include "config.vh"

module fixed_mult
(
    input  wire signed [`DATA_WIDTH-1:0] a,
    input  wire signed [`COEF_WIDTH-1:0] b,
    output wire signed [`MULT_WIDTH-1:0] p
);

mult_generic #(
    .A_WIDTH(`DATA_WIDTH),
    .B_WIDTH(`COEF_WIDTH)
)
u_mult(
    .a(a),
    .b(b),
    .p(p)
);

endmodule

`default_nettype wire
