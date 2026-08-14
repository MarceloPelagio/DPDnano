`timescale 1ns/1ps
module command_cdc_hw_dpd(
    input  wire       src_clk,
    input  wire       src_rst,
    input  wire       src_start,
    input  wire [7:0] src_start_addr,
    input  wire [8:0] src_count,
    input  wire       dst_clk,
    input  wire       dst_rst,
    output reg        dst_start,
    output reg  [7:0] dst_start_addr,
    output reg  [8:0] dst_count
);
reg src_toggle;
reg [7:0] src_addr_hold;
reg [8:0] src_count_hold;
reg toggle_sync1, toggle_sync2, toggle_sync2_d;
reg [7:0] addr_sync1, addr_sync2;
reg [8:0] count_sync1, count_sync2;

always @(posedge src_clk or posedge src_rst) begin
    if (src_rst) begin
        src_toggle <= 1'b0;
        src_addr_hold <= 8'd0;
        src_count_hold <= 9'd0;
    end else if (src_start) begin
        src_addr_hold <= src_start_addr;
        src_count_hold <= src_count;
        src_toggle <= ~src_toggle;
    end
end

always @(posedge dst_clk or posedge dst_rst) begin
    if (dst_rst) begin
        toggle_sync1 <= 1'b0;
        toggle_sync2 <= 1'b0;
        toggle_sync2_d <= 1'b0;
        addr_sync1 <= 8'd0;
        addr_sync2 <= 8'd0;
        count_sync1 <= 9'd0;
        count_sync2 <= 9'd0;
        dst_start <= 1'b0;
        dst_start_addr <= 8'd0;
        dst_count <= 9'd0;
    end else begin
        toggle_sync1 <= src_toggle;
        toggle_sync2 <= toggle_sync1;
        toggle_sync2_d <= toggle_sync2;
        addr_sync1 <= src_addr_hold;
        addr_sync2 <= addr_sync1;
        count_sync1 <= src_count_hold;
        count_sync2 <= count_sync1;
        dst_start <= 1'b0;
        if (toggle_sync2 != toggle_sync2_d) begin
            dst_start_addr <= addr_sync2;
            dst_count <= count_sync2;
            dst_start <= 1'b1;
        end
    end
end
endmodule
