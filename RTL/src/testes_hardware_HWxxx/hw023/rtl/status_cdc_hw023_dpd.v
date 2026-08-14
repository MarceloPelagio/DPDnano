`timescale 1ns/1ps

module status_cdc_hw023_dpd (
    input  wire src_clk,
    input  wire src_rst,
    input  wire src_busy,
    input  wire src_done,
    input  wire src_error,
    input  wire dst_clk,
    input  wire dst_rst,
    output wire dst_busy,
    output reg  dst_done,
    output wire dst_error
);

reg busy_sync1, busy_sync2;
reg error_sync1, error_sync2;
reg done_toggle_src;
reg done_sync1, done_sync2, done_sync2_d;

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
        done_sync1 <= 1'b0;
        done_sync2 <= 1'b0;
        done_sync2_d <= 1'b0;
        dst_done <= 1'b0;
    end else begin
        busy_sync1 <= src_busy;
        busy_sync2 <= busy_sync1;
        error_sync1 <= src_error;
        error_sync2 <= error_sync1;
        done_sync1 <= done_toggle_src;
        done_sync2 <= done_sync1;
        done_sync2_d <= done_sync2;
        dst_done <= (done_sync2 != done_sync2_d);
    end
end

assign dst_busy = busy_sync2;
assign dst_error = error_sync2;

endmodule
