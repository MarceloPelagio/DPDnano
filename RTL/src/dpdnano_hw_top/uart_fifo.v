`timescale 1ns/1ps
module uart_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    input  wire                  rd_en,
    output reg  [DATA_WIDTH-1:0] rd_data,
    output wire                  empty,
    output wire                  full,
    output reg  [ADDR_WIDTH:0]   level
);
localparam DEPTH = (1 << ADDR_WIDTH);

reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
reg [ADDR_WIDTH-1:0] wr_ptr;
reg [ADDR_WIDTH-1:0] rd_ptr;

assign empty = (level == 0);
assign full  = (level == DEPTH);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        wr_ptr  <= 0;
        rd_ptr  <= 0;
        rd_data <= 0;
        level   <= 0;
    end else begin
        case ({wr_en && !full, rd_en && !empty})
            2'b10: begin
                mem[wr_ptr] <= wr_data;
                wr_ptr <= wr_ptr + 1'b1;
                level <= level + 1'b1;
            end
            2'b01: begin
                rd_data <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1'b1;
                level <= level - 1'b1;
            end
            2'b11: begin
                mem[wr_ptr] <= wr_data;
                wr_ptr <= wr_ptr + 1'b1;
                rd_data <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1'b1;
            end
            default: begin end
        endcase
    end
end
endmodule
