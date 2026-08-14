`timescale 1ns/1ps
module output_memory_dualport_256x32(
 input wire clk,input wire dpd_wr_en_i,input wire [7:0] dpd_wr_addr_i,
 input wire [31:0] dpd_wr_data_i,input wire host_rd_en_i,
 input wire [7:0] host_rd_addr_i,output reg [31:0] host_rd_data_o,
 output reg host_rd_valid_o);
reg [31:0] memory[0:255];
always @(posedge clk) begin
 host_rd_valid_o<=0;
 if(dpd_wr_en_i) memory[dpd_wr_addr_i]<=dpd_wr_data_i;
 if(host_rd_en_i) begin host_rd_data_o<=memory[host_rd_addr_i]; host_rd_valid_o<=1; end
end
endmodule
