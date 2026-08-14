`timescale 1ns/1ps
module output_dual_clock_bsram #(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 40
)(
    input  wire                  wr_clk,
    input  wire                  wr_en,
    input  wire [ADDR_WIDTH-1:0] wr_addr,
    input  wire [DATA_WIDTH-1:0] wr_data,
    input  wire                  rd_clk,
    input  wire [ADDR_WIDTH-1:0] rd_addr,
    output reg  [DATA_WIDTH-1:0] rd_data
);
localparam DEPTH = (1 << ADDR_WIDTH);
(* syn_ramstyle = "block_ram" *) reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

always @(posedge wr_clk)
    if (wr_en)
        mem[wr_addr] <= wr_data;

always @(posedge rd_clk)
    rd_data <= mem[rd_addr];

endmodule
