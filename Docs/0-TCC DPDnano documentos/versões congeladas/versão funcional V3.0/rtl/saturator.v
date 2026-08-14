`timescale 1ns/1ps
`include "config.vh"

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

wire signed [`DATA_WIDTH-1:0] re_trunc = din_re[30:15];
wire signed [`DATA_WIDTH-1:0] im_trunc = din_im[30:15];

always @(posedge clk or posedge rst) begin
    if (rst) begin
        out_valid <= 1'b0;
        dout_re <= 0;
        dout_im <= 0;
    end else begin
        out_valid <= in_valid;
        if (in_valid) begin
            dout_re <= re_trunc;
            dout_im <= im_trunc;
        end
    end
end

endmodule
