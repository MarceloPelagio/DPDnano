`timescale 1ns/1ps
`include "config.vh"

/******************************************************************************
* HW016_dpd vr02
*
* Runtime-selectable AM/PM profiles:
*
* Profile A: coef3_im = 0.00 = 0x0000
* Profile B: coef3_im = 0.10 = 0x0CCD
* Profile C: coef3_im = 0.20 = 0x199A
* Profile D: coef3_im = 0.35 = 0x2CCD
*
* Common coefficients:
*
* coef1 = 0.40 + j0.00
* coef3 = 0.00 + j(profile)
*
* Only the coefficient value changes. The active arithmetic paths remain the
* same, allowing all profiles to be evaluated with one bitstream.
******************************************************************************/

module dpd_controller_hw016_dpd (
    input  wire       clk,
    input  wire       rst,

    input  wire       start_i,
    input  wire [7:0] start_addr_i,
    input  wire [8:0] count_i,
    input  wire [1:0] profile_i,

    output reg        in_mem_rd_en_o,
    output reg  [7:0] in_mem_rd_addr_o,
    input  wire [31:0] in_mem_rd_data_i,
    input  wire       in_mem_rd_valid_i,

    output reg        out_mem_wr_en_o,
    output reg  [7:0] out_mem_wr_addr_o,
    output reg  [31:0] out_mem_wr_data_o,

    output reg        busy_o,
    output reg        done_o,
    output reg        error_o,
    output reg        overflow_seen_o
);

localparam [2:0]
    ST_IDLE     = 3'd0,
    ST_READ     = 3'd1,
    ST_FEED     = 3'd2,
    ST_WAIT_DPD = 3'd3,
    ST_WRITE    = 3'd4,
    ST_FINISH   = 3'd5;

reg [2:0] state;
reg [7:0] current_addr;
reg [8:0] remaining;
reg [1:0] active_profile;

reg dpd_in_valid;
reg signed [`DATA_WIDTH-1:0] dpd_din_re;
reg signed [`DATA_WIDTH-1:0] dpd_din_im;

wire dpd_out_valid;
wire signed [`DATA_WIDTH-1:0] dpd_dout_re;
wire signed [`DATA_WIDTH-1:0] dpd_dout_im;

wire dpd_overflow;
wire dpd_overflow_re;
wire dpd_overflow_im;

localparam signed [`COEF_WIDTH-1:0] COEF1_RE = 16'sh3333;
localparam signed [`COEF_WIDTH-1:0] COEF1_IM = 16'sh0000;
localparam signed [`COEF_WIDTH-1:0] COEF3_RE = 16'sh0000;

reg signed [`COEF_WIDTH-1:0] coef3_im_selected;

always @(*) begin
    case (active_profile)
        2'd0: coef3_im_selected = 16'sh0000;
        2'd1: coef3_im_selected = 16'sh0CCD;
        2'd2: coef3_im_selected = 16'sh199A;
        2'd3: coef3_im_selected = 16'sh2CCD;
        default: coef3_im_selected = 16'sh0000;
    endcase
end

dpd_core u_dpd_core (
    .clk(clk),
    .rst(rst),
    .in_valid(dpd_in_valid),

    .din_re(dpd_din_re),
    .din_im(dpd_din_im),

    .coef1_re(COEF1_RE),
    .coef1_im(COEF1_IM),
    .coef3_re(COEF3_RE),
    .coef3_im(coef3_im_selected),

`ifdef DPD_ENABLE_OVERFLOW_FLAGS
    .overflow(dpd_overflow),
    .overflow_re(dpd_overflow_re),
    .overflow_im(dpd_overflow_im),
`endif

    .out_valid(dpd_out_valid),
    .dout_re(dpd_dout_re),
    .dout_im(dpd_dout_im)
);

`ifndef DPD_ENABLE_OVERFLOW_FLAGS
assign dpd_overflow    = 1'b0;
assign dpd_overflow_re = 1'b0;
assign dpd_overflow_im = 1'b0;
`endif

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state             <= ST_IDLE;
        current_addr      <= 8'd0;
        remaining         <= 9'd0;
        active_profile    <= 2'd0;

        in_mem_rd_en_o    <= 1'b0;
        in_mem_rd_addr_o  <= 8'd0;

        out_mem_wr_en_o   <= 1'b0;
        out_mem_wr_addr_o <= 8'd0;
        out_mem_wr_data_o <= 32'd0;

        dpd_in_valid      <= 1'b0;
        dpd_din_re        <= 0;
        dpd_din_im        <= 0;

        busy_o            <= 1'b0;
        done_o            <= 1'b0;
        error_o           <= 1'b0;
        overflow_seen_o   <= 1'b0;
    end else begin
        in_mem_rd_en_o  <= 1'b0;
        out_mem_wr_en_o <= 1'b0;
        dpd_in_valid    <= 1'b0;
        done_o          <= 1'b0;

        if (dpd_overflow | dpd_overflow_re | dpd_overflow_im)
            overflow_seen_o <= 1'b1;

        case (state)
            ST_IDLE: begin
                busy_o <= 1'b0;

                if (start_i) begin
                    if (count_i == 0) begin
                        error_o <= 1'b1;
                    end else begin
                        error_o         <= 1'b0;
                        overflow_seen_o <= 1'b0;
                        current_addr    <= start_addr_i;
                        remaining       <= count_i;
                        active_profile  <= profile_i;
                        busy_o          <= 1'b1;

                        in_mem_rd_addr_o <= start_addr_i;
                        in_mem_rd_en_o   <= 1'b1;
                        state            <= ST_READ;
                    end
                end
            end

            ST_READ: begin
                if (in_mem_rd_valid_i) begin
                    dpd_din_re <= in_mem_rd_data_i[31:16];
                    dpd_din_im <= in_mem_rd_data_i[15:0];
                    state      <= ST_FEED;
                end
            end

            ST_FEED: begin
                dpd_in_valid <= 1'b1;
                state        <= ST_WAIT_DPD;
            end

            ST_WAIT_DPD: begin
                if (dpd_out_valid) begin
                    out_mem_wr_addr_o <= current_addr;
                    out_mem_wr_data_o <= {dpd_dout_re, dpd_dout_im};
                    state             <= ST_WRITE;
                end
            end

            ST_WRITE: begin
                out_mem_wr_en_o <= 1'b1;

                if (remaining == 9'd1) begin
                    state <= ST_FINISH;
                end else begin
                    current_addr      <= current_addr + 1'b1;
                    remaining         <= remaining - 1'b1;
                    in_mem_rd_addr_o  <= current_addr + 1'b1;
                    in_mem_rd_en_o    <= 1'b1;
                    state             <= ST_READ;
                end
            end

            ST_FINISH: begin
                busy_o <= 1'b0;
                done_o <= 1'b1;
                state  <= ST_IDLE;
            end

            default: state <= ST_IDLE;
        endcase
    end
end

endmodule
