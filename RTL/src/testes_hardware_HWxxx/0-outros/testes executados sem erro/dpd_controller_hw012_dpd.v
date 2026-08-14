`timescale 1ns/1ps
`include "config.vh"

/******************************************************************************
* DPDnano_Lite_v3_2
* HW012_dpd vr02 - Enhanced AM/AM curvature
*
* Coefficients:
*   coef1 = 0.70 + j0 = 16'sh599A
*   coef3 = 0.30 + j0 = 16'sh2666
******************************************************************************/

module dpd_controller_hw012_dpd (
    input  wire       clk,
    input  wire       rst,
    input  wire       start_i,
    input  wire [7:0] start_addr_i,
    input  wire [8:0] count_i,

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

reg dpd_in_valid;
reg signed [`DATA_WIDTH-1:0] dpd_din_re;
reg signed [`DATA_WIDTH-1:0] dpd_din_im;

wire dpd_out_valid;
wire signed [`DATA_WIDTH-1:0] dpd_dout_re;
wire signed [`DATA_WIDTH-1:0] dpd_dout_im;

wire dpd_overflow;
wire dpd_overflow_re;
wire dpd_overflow_im;

localparam signed [`COEF_WIDTH-1:0] COEF1_RE = 16'sh3333; // ≈ 0,40
/*localparam signed [`COEF_WIDTH-1:0] COEF1_RE = 16'sh599A;*/
localparam signed [`COEF_WIDTH-1:0] COEF1_IM = 16'sh0000;

localparam signed [`COEF_WIDTH-1:0] COEF3_RE = 16'sh5333; // ≈ 0,65
/*localparam signed [`COEF_WIDTH-1:0] COEF3_RE = 16'sh2666;*/
localparam signed [`COEF_WIDTH-1:0] COEF3_IM = 16'sh0000;



dpd_core u_dpd_core (
    .clk(clk),
    .rst(rst),
    .in_valid(dpd_in_valid),
    .din_re(dpd_din_re),
    .din_im(dpd_din_im),
    .coef1_re(COEF1_RE),
    .coef1_im(COEF1_IM),
    .coef3_re(COEF3_RE),
    .coef3_im(COEF3_IM),
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
                    current_addr     <= current_addr + 1'b1;
                    remaining        <= remaining - 1'b1;
                    in_mem_rd_addr_o <= current_addr + 1'b1;
                    in_mem_rd_en_o   <= 1'b1;
                    state            <= ST_READ;
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
