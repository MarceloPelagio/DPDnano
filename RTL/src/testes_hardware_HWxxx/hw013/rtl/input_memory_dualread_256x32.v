`timescale 1ns/1ps
module input_memory_dualread_256x32(
 input wire clk,input wire wr_en_i,input wire [7:0] wr_addr_i,
 input wire [31:0] wr_data_i,input wire host_rd_en_i,
 input wire [7:0] host_rd_addr_i,output reg [31:0] host_rd_data_o,
 output reg host_rd_valid_o,input wire dpd_rd_en_i,
 input wire [7:0] dpd_rd_addr_i,output reg [31:0] dpd_rd_data_o,
 output reg dpd_rd_valid_o);
reg [31:0] memory[0:255];
always @(posedge clk) begin
 host_rd_valid_o<=0; dpd_rd_valid_o<=0;
 if(wr_en_i) memory[wr_addr_i]<=wr_data_i;
 if(host_rd_en_i) begin host_rd_data_o<=memory[host_rd_addr_i]; host_rd_valid_o<=1; end
 if(dpd_rd_en_i) begin dpd_rd_data_o<=memory[dpd_rd_addr_i]; dpd_rd_valid_o<=1; end
end
endmodule
