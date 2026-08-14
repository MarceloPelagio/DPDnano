`timescale 1ns/1ps
`include "config.vh"

module rounding
(
    input clk,
    input rst,
    input in_valid,

    input  signed [`ACC_WIDTH-1:0] din_re,
    input  signed [`ACC_WIDTH-1:0] din_im,

    output reg out_valid,

    output reg signed [`ROUND_WIDTH-1:0] dout_re,
    output reg signed [`ROUND_WIDTH-1:0] dout_im
);

// Remove one integer growth bit (Q4.30 -> Q3.30)
wire signed [`ROUND_WIDTH-1:0] round_re = din_re[`ROUND_WIDTH-1:0];
wire signed [`ROUND_WIDTH-1:0] round_im = din_im[`ROUND_WIDTH-1:0];

always @(posedge clk or posedge rst) begin
    if (rst) begin
        out_valid <= 1'b0;
        dout_re   <= '0;
        dout_im   <= '0;
    end else begin
        out_valid <= in_valid;
        if (in_valid) begin
            dout_re <= round_re;
            dout_im <= round_im;
        end
    end
end

endmodule
