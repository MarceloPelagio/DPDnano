`timescale 1ns/1ps
`include "config.vh"

//------------------------------------------------------------------------------
// Module : complex_mult
// Purpose: Complex multiplication:
//          (a_re + j*a_im) * (b_re + j*b_im)
// Comments: Verilog-2001, synchronous pipeline stage.
//------------------------------------------------------------------------------
module complex_mult
(
    input                       clk,
    input                       rst,

    input                       in_valid,

    input signed [`DATA_WIDTH-1:0] a_re,
    input signed [`DATA_WIDTH-1:0] a_im,

    input signed [`DATA_WIDTH-1:0] b_re,
    input signed [`DATA_WIDTH-1:0] b_im,

    output reg                  out_valid,

    output reg signed [35:0]    y_re,
    output reg signed [35:0]    y_im
);

wire signed [31:0] p0;
wire signed [31:0] p1;
wire signed [31:0] p2;
wire signed [31:0] p3;

assign p0 = a_re * b_re;
assign p1 = a_im * b_im;
assign p2 = a_re * b_im;
assign p3 = a_im * b_re;

always @(posedge clk or posedge rst)
begin
    if (rst)
    begin
        out_valid <= 1'b0;
        y_re      <= 36'sd0;
        y_im      <= 36'sd0;
    end
    else
    begin
        out_valid <= in_valid;

        if (in_valid)
        begin
            // Real = ar*br - ai*bi
            y_re <= $signed({{4{p0[31]}},p0}) - $signed({{4{p1[31]}},p1});

            // Imag = ar*bi + ai*br
            y_im <= $signed({{4{p2[31]}},p2}) + $signed({{4{p3[31]}},p3});
        end
    end
end

endmodule
