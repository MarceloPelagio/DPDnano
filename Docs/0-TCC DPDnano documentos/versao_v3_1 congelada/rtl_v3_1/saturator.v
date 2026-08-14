`timescale 1ns/1ps
`include "config.vh"

module saturator
(
    input clk,
    input rst,
    input din_valid,

    input signed [`ROUND_WIDTH-1:0] din_re,
    input signed [`ROUND_WIDTH-1:0] din_im,

    input clip_re,
    input clip_im,
    input clip_dir_re,
    input clip_dir_im,

`ifdef DPD_ENABLE_OVERFLOW_FLAGS
    output reg overflow,
    output reg overflow_re,
    output reg overflow_im,
`endif

    output reg dout_valid,
    output reg signed [`DATA_WIDTH-1:0] dout_re,
    output reg signed [`DATA_WIDTH-1:0] dout_im
);

wire signed [`DATA_WIDTH-1:0] re_sat =
    clip_re ?
        (clip_dir_re ? `SAT_MIN : `SAT_MAX)
        :
        din_re[`DATA_WIDTH-1:0];

wire signed [`DATA_WIDTH-1:0] im_sat =
    clip_im ?
        (clip_dir_im ? `SAT_MIN : `SAT_MAX)
        :
        din_im[`DATA_WIDTH-1:0];

always @(posedge clk)
begin
    if (rst)
    begin
        dout_valid <= 1'b0;
        dout_re <= '0;
        dout_im <= '0;
`ifdef DPD_ENABLE_OVERFLOW_FLAGS
        overflow <= 1'b0;
        overflow_re <= 1'b0;
        overflow_im <= 1'b0;
`endif
    end
    else
    begin
        dout_valid <= din_valid;

        if (din_valid)
        begin
            dout_re <= re_sat;
            dout_im <= im_sat;

`ifdef DPD_ENABLE_OVERFLOW_FLAGS
            overflow_re <= clip_re;
            overflow_im <= clip_im;
            overflow <= clip_re | clip_im;
`endif
        end
    end
end

endmodule
