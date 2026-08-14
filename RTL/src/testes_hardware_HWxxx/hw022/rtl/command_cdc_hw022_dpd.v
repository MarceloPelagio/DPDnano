`timescale 1ns/1ps

module command_cdc_hw022_dpd (
    input  wire        src_clk,
    input  wire        src_rst,
    input  wire        src_start,
    input  wire [2:0]  src_scenario,
    input  wire [15:0] src_sample_count,
    input  wire        dst_clk,
    input  wire        dst_rst,
    output reg         dst_start,
    output reg  [2:0]  dst_scenario,
    output reg  [15:0] dst_sample_count
);

reg src_toggle;
reg [2:0] src_scenario_hold;
reg [15:0] src_sample_count_hold;

reg toggle_sync1;
reg toggle_sync2;
reg toggle_sync2_d;
reg [2:0] scenario_sync1;
reg [2:0] scenario_sync2;
reg [15:0] sample_count_sync1;
reg [15:0] sample_count_sync2;

always @(posedge src_clk or posedge src_rst) begin
    if (src_rst) begin
        src_toggle <= 1'b0;
        src_scenario_hold <= 3'd0;
        src_sample_count_hold <= 16'd0;
    end else if (src_start) begin
        src_scenario_hold <= src_scenario;
        src_sample_count_hold <= src_sample_count;
        src_toggle <= ~src_toggle;
    end
end

always @(posedge dst_clk or posedge dst_rst) begin
    if (dst_rst) begin
        toggle_sync1 <= 1'b0;
        toggle_sync2 <= 1'b0;
        toggle_sync2_d <= 1'b0;
        scenario_sync1 <= 3'd0;
        scenario_sync2 <= 3'd0;
        sample_count_sync1 <= 16'd0;
        sample_count_sync2 <= 16'd0;
        dst_start <= 1'b0;
        dst_scenario <= 3'd0;
        dst_sample_count <= 16'd0;
    end else begin
        toggle_sync1 <= src_toggle;
        toggle_sync2 <= toggle_sync1;
        toggle_sync2_d <= toggle_sync2;
        scenario_sync1 <= src_scenario_hold;
        scenario_sync2 <= scenario_sync1;
        sample_count_sync1 <= src_sample_count_hold;
        sample_count_sync2 <= sample_count_sync1;
        dst_start <= 1'b0;

        if (toggle_sync2 != toggle_sync2_d) begin
            dst_scenario <= scenario_sync2;
            dst_sample_count <= sample_count_sync2;
            dst_start <= 1'b1;
        end
    end
end

endmodule
