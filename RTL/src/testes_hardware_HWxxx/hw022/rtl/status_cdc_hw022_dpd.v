`timescale 1ns/1ps

module status_cdc_hw022_dpd (
    input  wire        src_clk,
    input  wire        src_rst,
    input  wire        src_busy,
    input  wire        src_done,
    input  wire        src_error,
    input  wire        src_overflow,
    input  wire [15:0] src_latency_min,
    input  wire [15:0] src_latency_max,
    input  wire [31:0] src_latency_sum,
    input  wire [15:0] src_samples_sent,
    input  wire [15:0] src_samples_received,
    input  wire [15:0] src_losses,
    input  wire [15:0] src_duplicates,
    input  wire [15:0] src_reorder,
    input  wire [31:0] src_total_cycles,
    input  wire        dst_clk,
    input  wire        dst_rst,
    output wire        dst_busy,
    output reg         dst_done,
    output wire        dst_error,
    output wire        dst_overflow,
    output wire [15:0] dst_latency_min,
    output wire [15:0] dst_latency_max,
    output wire [31:0] dst_latency_sum,
    output wire [15:0] dst_samples_sent,
    output wire [15:0] dst_samples_received,
    output wire [15:0] dst_losses,
    output wire [15:0] dst_duplicates,
    output wire [15:0] dst_reorder,
    output wire [31:0] dst_total_cycles
);

reg busy_sync1, busy_sync2;
reg error_sync1, error_sync2;
reg overflow_sync1, overflow_sync2;
reg done_toggle_src;
reg done_sync1, done_sync2, done_sync2_d;

reg [15:0] latency_min_sync1, latency_min_sync2;
reg [15:0] latency_max_sync1, latency_max_sync2;
reg [31:0] latency_sum_sync1, latency_sum_sync2;
reg [15:0] samples_sent_sync1, samples_sent_sync2;
reg [15:0] samples_received_sync1, samples_received_sync2;
reg [15:0] losses_sync1, losses_sync2;
reg [15:0] duplicates_sync1, duplicates_sync2;
reg [15:0] reorder_sync1, reorder_sync2;
reg [31:0] total_cycles_sync1, total_cycles_sync2;

always @(posedge src_clk or posedge src_rst) begin
    if (src_rst)
        done_toggle_src <= 1'b0;
    else if (src_done)
        done_toggle_src <= ~done_toggle_src;
end

always @(posedge dst_clk or posedge dst_rst) begin
    if (dst_rst) begin
        busy_sync1 <= 1'b0;
        busy_sync2 <= 1'b0;
        error_sync1 <= 1'b0;
        error_sync2 <= 1'b0;
        overflow_sync1 <= 1'b0;
        overflow_sync2 <= 1'b0;
        done_sync1 <= 1'b0;
        done_sync2 <= 1'b0;
        done_sync2_d <= 1'b0;
        dst_done <= 1'b0;

        latency_min_sync1 <= 16'd0;
        latency_min_sync2 <= 16'd0;
        latency_max_sync1 <= 16'd0;
        latency_max_sync2 <= 16'd0;
        latency_sum_sync1 <= 32'd0;
        latency_sum_sync2 <= 32'd0;
        samples_sent_sync1 <= 16'd0;
        samples_sent_sync2 <= 16'd0;
        samples_received_sync1 <= 16'd0;
        samples_received_sync2 <= 16'd0;
        losses_sync1 <= 16'd0;
        losses_sync2 <= 16'd0;
        duplicates_sync1 <= 16'd0;
        duplicates_sync2 <= 16'd0;
        reorder_sync1 <= 16'd0;
        reorder_sync2 <= 16'd0;
        total_cycles_sync1 <= 32'd0;
        total_cycles_sync2 <= 32'd0;
    end else begin
        busy_sync1 <= src_busy;
        busy_sync2 <= busy_sync1;
        error_sync1 <= src_error;
        error_sync2 <= error_sync1;
        overflow_sync1 <= src_overflow;
        overflow_sync2 <= overflow_sync1;
        done_sync1 <= done_toggle_src;
        done_sync2 <= done_sync1;
        done_sync2_d <= done_sync2;
        dst_done <= (done_sync2 != done_sync2_d);

        latency_min_sync1 <= src_latency_min;
        latency_min_sync2 <= latency_min_sync1;
        latency_max_sync1 <= src_latency_max;
        latency_max_sync2 <= latency_max_sync1;
        latency_sum_sync1 <= src_latency_sum;
        latency_sum_sync2 <= latency_sum_sync1;
        samples_sent_sync1 <= src_samples_sent;
        samples_sent_sync2 <= samples_sent_sync1;
        samples_received_sync1 <= src_samples_received;
        samples_received_sync2 <= samples_received_sync1;
        losses_sync1 <= src_losses;
        losses_sync2 <= losses_sync1;
        duplicates_sync1 <= src_duplicates;
        duplicates_sync2 <= duplicates_sync1;
        reorder_sync1 <= src_reorder;
        reorder_sync2 <= reorder_sync1;
        total_cycles_sync1 <= src_total_cycles;
        total_cycles_sync2 <= total_cycles_sync1;
    end
end

assign dst_busy = busy_sync2;
assign dst_error = error_sync2;
assign dst_overflow = overflow_sync2;
assign dst_latency_min = latency_min_sync2;
assign dst_latency_max = latency_max_sync2;
assign dst_latency_sum = latency_sum_sync2;
assign dst_samples_sent = samples_sent_sync2;
assign dst_samples_received = samples_received_sync2;
assign dst_losses = losses_sync2;
assign dst_duplicates = duplicates_sync2;
assign dst_reorder = reorder_sync2;
assign dst_total_cycles = total_cycles_sync2;

endmodule
