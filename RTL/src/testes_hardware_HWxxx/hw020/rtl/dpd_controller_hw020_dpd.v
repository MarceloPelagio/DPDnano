`timescale 1ns/1ps
`include "config.vh"

/*
 * HW020_dpd vr02 - Operational coefficient window
 *
 * Runtime matrix:
 * coef1_re index: 0.40, 0.55, 0.70, 0.85, 1.00
 * coef3_re index: -0.70, -0.35, 0.00, +0.35, +0.70
 *
 * Imaginary components remain zero.
 */

module dpd_controller_hw020_dpd (
    input wire clk,
    input wire rst,
    input wire start_i,
    input wire [7:0] start_addr_i,
    input wire [8:0] count_i,
    input wire [2:0] coef1_index_i,
    input wire [2:0] coef3_index_i,

    output reg in_mem_rd_en_o,
    output reg [7:0] in_mem_rd_addr_o,
    input wire [31:0] in_mem_rd_data_i,
    input wire in_mem_rd_valid_i,

    output reg out_mem_wr_en_o,
    output reg [7:0] out_mem_wr_addr_o,
    output reg [31:0] out_mem_wr_data_o,

    output reg busy_o,
    output reg done_o,
    output reg error_o,
    output reg overflow_seen_o
);

localparam [2:0] ST_IDLE=0, ST_READ=1, ST_FEED=2,
                 ST_WAIT=3, ST_WRITE=4, ST_FINISH=5;

reg [2:0] state;
reg [7:0] current_addr;
reg [8:0] remaining;
reg [2:0] active_coef1_index;
reg [2:0] active_coef3_index;

reg dpd_in_valid;
reg signed [`DATA_WIDTH-1:0] dpd_din_re;
reg signed [`DATA_WIDTH-1:0] dpd_din_im;

wire dpd_out_valid;
wire signed [`DATA_WIDTH-1:0] dpd_dout_re;
wire signed [`DATA_WIDTH-1:0] dpd_dout_im;
wire dpd_overflow, dpd_overflow_re, dpd_overflow_im;

reg signed [`COEF_WIDTH-1:0] coef1_re_selected;
reg signed [`COEF_WIDTH-1:0] coef3_re_selected;

always @(*) begin
    case (active_coef1_index)
        3'd0: coef1_re_selected = 16'sh3333; // 0.40
        3'd1: coef1_re_selected = 16'sh4666; // 0.55
        3'd2: coef1_re_selected = 16'sh599A; // 0.70
        3'd3: coef1_re_selected = 16'sh6CCD; // 0.85
        3'd4: coef1_re_selected = 16'sh7FFF; // 1.00 approx
        default: coef1_re_selected = 16'sh3333;
    endcase

    case (active_coef3_index)
        3'd0: coef3_re_selected = 16'shA667; // -0.70
        3'd1: coef3_re_selected = 16'shD333; // -0.35
        3'd2: coef3_re_selected = 16'sh0000; //  0.00
        3'd3: coef3_re_selected = 16'sh2CCD; // +0.35
        3'd4: coef3_re_selected = 16'sh599A; // +0.70
        default: coef3_re_selected = 16'sh0000;
    endcase
end

dpd_core u_dpd_core (
    .clk(clk), .rst(rst), .in_valid(dpd_in_valid),
    .din_re(dpd_din_re), .din_im(dpd_din_im),
    .coef1_re(coef1_re_selected), .coef1_im(16'sh0000),
    .coef3_re(coef3_re_selected), .coef3_im(16'sh0000),
`ifdef DPD_ENABLE_OVERFLOW_FLAGS
    .overflow(dpd_overflow),
    .overflow_re(dpd_overflow_re),
    .overflow_im(dpd_overflow_im),
`endif
    .out_valid(dpd_out_valid),
    .dout_re(dpd_dout_re), .dout_im(dpd_dout_im)
);

`ifndef DPD_ENABLE_OVERFLOW_FLAGS
assign dpd_overflow=1'b0;
assign dpd_overflow_re=1'b0;
assign dpd_overflow_im=1'b0;
`endif

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state<=ST_IDLE;
        current_addr<=0;
        remaining<=0;
        active_coef1_index<=0;
        active_coef3_index<=2;
        in_mem_rd_en_o<=0;
        in_mem_rd_addr_o<=0;
        out_mem_wr_en_o<=0;
        out_mem_wr_addr_o<=0;
        out_mem_wr_data_o<=0;
        dpd_in_valid<=0;
        dpd_din_re<=0;
        dpd_din_im<=0;
        busy_o<=0;
        done_o<=0;
        error_o<=0;
        overflow_seen_o<=0;
    end else begin
        in_mem_rd_en_o<=0;
        out_mem_wr_en_o<=0;
        dpd_in_valid<=0;
        done_o<=0;

        if (dpd_overflow|dpd_overflow_re|dpd_overflow_im)
            overflow_seen_o<=1;

        case(state)
            ST_IDLE: begin
                busy_o<=0;
                if(start_i) begin
                    if(count_i==0) error_o<=1;
                    else begin
                        error_o<=0;
                        overflow_seen_o<=0;
                        active_coef1_index<=coef1_index_i;
                        active_coef3_index<=coef3_index_i;
                        current_addr<=start_addr_i;
                        remaining<=count_i;
                        busy_o<=1;
                        in_mem_rd_addr_o<=start_addr_i;
                        in_mem_rd_en_o<=1;
                        state<=ST_READ;
                    end
                end
            end

            ST_READ: if(in_mem_rd_valid_i) begin
                dpd_din_re<=in_mem_rd_data_i[31:16];
                dpd_din_im<=in_mem_rd_data_i[15:0];
                state<=ST_FEED;
            end

            ST_FEED: begin
                dpd_in_valid<=1;
                state<=ST_WAIT;
            end

            ST_WAIT: if(dpd_out_valid) begin
                out_mem_wr_addr_o<=current_addr;
                out_mem_wr_data_o<={dpd_dout_re,dpd_dout_im};
                state<=ST_WRITE;
            end

            ST_WRITE: begin
                out_mem_wr_en_o<=1;
                if(remaining==1) state<=ST_FINISH;
                else begin
                    current_addr<=current_addr+1'b1;
                    remaining<=remaining-1'b1;
                    in_mem_rd_addr_o<=current_addr+1'b1;
                    in_mem_rd_en_o<=1;
                    state<=ST_READ;
                end
            end

            ST_FINISH: begin
                busy_o<=0;
                done_o<=1;
                state<=ST_IDLE;
            end

            default: state<=ST_IDLE;
        endcase
    end
end
endmodule
