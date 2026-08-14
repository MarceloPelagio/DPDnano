`timescale 1ns/1ps
module status_cdc(
    input  wire        src_clk,
    input  wire        src_rst,
    input  wire        src_busy,
    input  wire        src_done,
    input  wire [31:0] src_cycle_count,
    input  wire [31:0] src_samples_processed,
    input  wire [31:0] src_overflow_count,

    input  wire        dst_clk,
    input  wire        dst_rst,
    output wire        dst_busy,
    output reg         dst_done,
    output reg  [31:0] dst_cycle_count,
    output reg  [31:0] dst_samples_processed,
    output reg  [31:0] dst_overflow_count
);
reg busy_sync1, busy_sync2;
reg done_toggle_src;
reg done_sync1, done_sync2, done_sync2_d;
reg [31:0] cycle_hold, samples_hold, overflow_hold;
reg [31:0] cycle_sync1, cycle_sync2;
reg [31:0] samples_sync1, samples_sync2;
reg [31:0] overflow_sync1, overflow_sync2;

always @(posedge src_clk or posedge src_rst) begin
    if (src_rst) begin
        done_toggle_src <= 0;
        cycle_hold      <= 0;
        samples_hold    <= 0;
        overflow_hold   <= 0;
    end else if (src_done) begin
        cycle_hold      <= src_cycle_count;
        samples_hold    <= src_samples_processed;
        overflow_hold   <= src_overflow_count;
        done_toggle_src <= ~done_toggle_src;
    end
end

always @(posedge dst_clk or posedge dst_rst) begin
    if (dst_rst) begin
        busy_sync1           <= 0;
        busy_sync2           <= 0;
        done_sync1           <= 0;
        done_sync2           <= 0;
        done_sync2_d         <= 0;
        cycle_sync1          <= 0;
        cycle_sync2          <= 0;
        samples_sync1        <= 0;
        samples_sync2        <= 0;
        overflow_sync1       <= 0;
        overflow_sync2       <= 0;
        dst_done             <= 0;
        dst_cycle_count      <= 0;
        dst_samples_processed<= 0;
        dst_overflow_count   <= 0;
    end else begin
        busy_sync1 <= src_busy;
        busy_sync2 <= busy_sync1;

        done_sync1   <= done_toggle_src;
        done_sync2   <= done_sync1;
        done_sync2_d <= done_sync2;

        cycle_sync1    <= cycle_hold;
        cycle_sync2    <= cycle_sync1;
        samples_sync1  <= samples_hold;
        samples_sync2  <= samples_sync1;
        overflow_sync1 <= overflow_hold;
        overflow_sync2 <= overflow_sync1;

        dst_done <= 1'b0;
        if (done_sync2 != done_sync2_d) begin
            dst_cycle_count       <= cycle_sync2;
            dst_samples_processed <= samples_sync2;
            dst_overflow_count    <= overflow_sync2;
            dst_done              <= 1'b1;
        end
    end
end

assign dst_busy = busy_sync2;
endmodule
