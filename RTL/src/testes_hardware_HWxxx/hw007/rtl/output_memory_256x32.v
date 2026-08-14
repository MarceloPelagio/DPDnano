`timescale 1ns/1ps

module output_memory_256x32 (
    input  wire        clk,
    input  wire        wr_en_i,
    input  wire [7:0]  wr_addr_i,
    input  wire [31:0] wr_data_i,
    input  wire        rd_en_i,
    input  wire [7:0]  rd_addr_i,
    output reg  [31:0] rd_data_o,
    output reg         rd_valid_o
);

reg [31:0] memory [0:255];

always @(posedge clk) begin
    rd_valid_o <= 1'b0;

    if (wr_en_i)
        memory[wr_addr_i] <= wr_data_i;

    if (rd_en_i) begin
        rd_data_o  <= memory[rd_addr_i];
        rd_valid_o <= 1'b1;
    end
end

endmodule
