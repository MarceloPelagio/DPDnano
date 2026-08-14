`timescale 1ns/1ps
`include "config.vh"

//------------------------------------------------------------------------------
// Module : saturator
// Function : Fixed-point conversion (Q3.30 -> Q1.15) with output saturation
// DPDnano-Lite RTL v3.1
//------------------------------------------------------------------------------
//
// Architecture A:
//   1) Arithmetic shift (Q3.30 -> Q1.15)
//   2) Saturation to signed 16-bit range
//   3) Registered output
//------------------------------------------------------------------------------

module saturator
(
    input clk,
    input rst,
    input in_valid,

    input  signed [`ROUND_WIDTH-1:0] din_re,
    input  signed [`ROUND_WIDTH-1:0] din_im,

    output reg out_valid,

    output reg signed [`DATA_WIDTH-1:0] dout_re,
    output reg signed [`DATA_WIDTH-1:0] dout_im
);

localparam signed [`DATA_WIDTH-1:0] MAX_VAL = 16'sh7FFF;
localparam signed [`DATA_WIDTH-1:0] MIN_VAL = -16'sh8000;

// Arithmetic conversion Q3.30 -> Q1.15
wire signed [17:0] re_shift = din_re >>> 15;
wire signed [17:0] im_shift = din_im >>> 15;

// Saturation
wire signed [`DATA_WIDTH-1:0] re_sat =
    (re_shift > MAX_VAL) ? MAX_VAL :
    (re_shift < MIN_VAL) ? MIN_VAL :
    re_shift[`DATA_WIDTH-1:0];

wire signed [`DATA_WIDTH-1:0] im_sat =
    (im_shift > MAX_VAL) ? MAX_VAL :
    (im_shift < MIN_VAL) ? MIN_VAL :
    im_shift[`DATA_WIDTH-1:0];

always @(posedge clk or posedge rst) begin
    if (rst) begin
        out_valid <= 1'b0;
        dout_re   <= 0;
        dout_im   <= 0;
    end
    else begin
        out_valid <= in_valid;
        if (in_valid) begin
            dout_re <= re_sat;
            dout_im <= im_sat;
        end
    end
end

endmodule
