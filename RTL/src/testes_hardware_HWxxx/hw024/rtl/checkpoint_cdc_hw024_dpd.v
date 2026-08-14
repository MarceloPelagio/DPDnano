`timescale 1ns/1ps

module checkpoint_cdc_hw024_dpd (
    input  wire        src_clk,
    input  wire [31:0] src_cycle,
    input  wire        dst_clk,
    output reg  [31:0] dst_cycle
);

reg [31:0] sync1;

always @(posedge dst_clk) begin
    sync1 <= src_cycle;
    dst_cycle <= sync1;
end

endmodule
