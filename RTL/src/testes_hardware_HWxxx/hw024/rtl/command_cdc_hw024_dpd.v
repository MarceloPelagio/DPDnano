`timescale 1ns/1ps

module command_cdc_hw024_dpd (
    input  wire        src_clk,
    input  wire        src_rst,
    input  wire        src_start,
    input  wire [31:0] src_target_samples,
    input  wire        dst_clk,
    input  wire        dst_rst,
    output reg         dst_start,
    output reg [31:0]  dst_target_samples
);

reg src_toggle;
reg [31:0] src_target_samples_hold;
reg toggle_sync1;
reg toggle_sync2;
reg toggle_sync2_d;
reg [31:0] target_samples_sync1;
reg [31:0] target_samples_sync2;

always @(posedge src_clk or posedge src_rst) begin
    if (src_rst) begin
        src_toggle <= 1'b0;
        src_target_samples_hold <= 32'd0;
    end else if (src_start) begin
        src_target_samples_hold <= src_target_samples;
        src_toggle <= ~src_toggle;
    end
end

always @(posedge dst_clk or posedge dst_rst) begin
    if (dst_rst) begin
        toggle_sync1 <= 1'b0;
        toggle_sync2 <= 1'b0;
        toggle_sync2_d <= 1'b0;
        target_samples_sync1 <= 32'd0;
        target_samples_sync2 <= 32'd0;
        dst_start <= 1'b0;
        dst_target_samples <= 32'd0;
    end else begin
        toggle_sync1 <= src_toggle;
        toggle_sync2 <= toggle_sync1;
        toggle_sync2_d <= toggle_sync2;
        target_samples_sync1 <= src_target_samples_hold;
        target_samples_sync2 <= target_samples_sync1;
        dst_start <= 1'b0;

        if (toggle_sync2 != toggle_sync2_d) begin
            dst_target_samples <= target_samples_sync2;
            dst_start <= 1'b1;
        end
    end
end

endmodule
