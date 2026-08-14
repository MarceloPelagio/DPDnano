`timescale 1ns/1ps
module command_cdc #(
    parameter COUNT_WIDTH = 11
)(
    input  wire                   src_clk,
    input  wire                   src_rst,
    input  wire                   src_start,
    input  wire [COUNT_WIDTH-1:0] src_sample_count,
    input  wire                   dst_clk,
    input  wire                   dst_rst,
    output reg                    dst_start,
    output reg  [COUNT_WIDTH-1:0] dst_sample_count
);
reg src_toggle;
reg [COUNT_WIDTH-1:0] src_count_hold;
reg toggle_sync1, toggle_sync2, toggle_sync2_d;
reg [COUNT_WIDTH-1:0] count_sync1, count_sync2;

always @(posedge src_clk or posedge src_rst) begin
    if (src_rst) begin
        src_toggle     <= 1'b0;
        src_count_hold <= 0;
    end else if (src_start) begin
        src_count_hold <= src_sample_count;
        src_toggle     <= ~src_toggle;
    end
end

always @(posedge dst_clk or posedge dst_rst) begin
    if (dst_rst) begin
        toggle_sync1    <= 0;
        toggle_sync2    <= 0;
        toggle_sync2_d  <= 0;
        count_sync1     <= 0;
        count_sync2     <= 0;
        dst_start       <= 0;
        dst_sample_count<= 0;
    end else begin
        toggle_sync1   <= src_toggle;
        toggle_sync2   <= toggle_sync1;
        toggle_sync2_d <= toggle_sync2;
        count_sync1    <= src_count_hold;
        count_sync2    <= count_sync1;
        dst_start      <= 1'b0;

        if (toggle_sync2 != toggle_sync2_d) begin
            dst_sample_count <= count_sync2;
            dst_start <= 1'b1;
        end
    end
end
endmodule
