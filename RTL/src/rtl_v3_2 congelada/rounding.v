`timescale 1ns/1ps
`include "config.vh"

module rounding
(
    input                           clk,
    input                           rst,
    input                           din_valid,

    input  signed [`ACC_WIDTH-1:0]  din_re,
    input  signed [`ACC_WIDTH-1:0]  din_im,

    output reg                      dout_valid,

    output reg signed [`ROUND_WIDTH-1:0] dout_re,
    output reg signed [`ROUND_WIDTH-1:0] dout_im,

    output reg                      clip_re,
    output reg                      clip_im,
    output reg                      clip_dir_re,
    output reg                      clip_dir_im
);

localparam integer SHIFT = (`ACC_FRAC-`ROUND_FRAC);

localparam signed [`ACC_WIDTH-1:0] ROUND_BIAS = (1 <<< (SHIFT-1));

reg stage1_valid;
reg signed [`ACC_WIDTH-1:0] re_scaled_r;
reg signed [`ACC_WIDTH-1:0] im_scaled_r;
reg                         re_clip_dir_r;
reg                         im_clip_dir_r;

wire signed [`ACC_WIDTH-1:0] re_round =
    din_re + (din_re[`ACC_WIDTH-1] ? -ROUND_BIAS : ROUND_BIAS);

wire signed [`ACC_WIDTH-1:0] im_round =
    din_im + (din_im[`ACC_WIDTH-1] ? -ROUND_BIAS : ROUND_BIAS);

wire signed [`ROUND_WIDTH-1:0] re_conv = re_scaled_r[`ROUND_WIDTH-1:0];
wire signed [`ROUND_WIDTH-1:0] im_conv = im_scaled_r[`ROUND_WIDTH-1:0];

wire re_clip =
(
    re_scaled_r[`ACC_WIDTH-1:`ROUND_WIDTH]
    !=
    {(`ACC_WIDTH-`ROUND_WIDTH){re_scaled_r[`ROUND_WIDTH-1]}}
);

wire im_clip =
(
    im_scaled_r[`ACC_WIDTH-1:`ROUND_WIDTH]
    !=
    {(`ACC_WIDTH-`ROUND_WIDTH){im_scaled_r[`ROUND_WIDTH-1]}}
);

always @(posedge clk)
begin
    if (rst)
    begin
        stage1_valid <= 1'b0;
        re_scaled_r  <= {`ACC_WIDTH{1'b0}};
        im_scaled_r  <= {`ACC_WIDTH{1'b0}};
        re_clip_dir_r <= 1'b0;
        im_clip_dir_r <= 1'b0;
        dout_valid   <= 1'b0;
        dout_re      <= 0;
        dout_im      <= 0;
        clip_re      <= 1'b0;
        clip_im      <= 1'b0;
        clip_dir_re  <= 1'b0;
        clip_dir_im  <= 1'b0;
    end
    else
    begin
        stage1_valid <= din_valid;
        if (din_valid)
        begin
            re_scaled_r <= re_round >>> SHIFT;
            im_scaled_r <= im_round >>> SHIFT;
            re_clip_dir_r <= re_round[`ACC_WIDTH-1];
            im_clip_dir_r <= im_round[`ACC_WIDTH-1];
        end

        dout_valid <= stage1_valid;
        if (stage1_valid)
        begin
            dout_re <= re_conv;
            dout_im <= im_conv;
            clip_re <= re_clip;
            clip_im <= im_clip;
            clip_dir_re <= re_clip_dir_r;
            clip_dir_im <= im_clip_dir_r;
        end
    end
end

endmodule
