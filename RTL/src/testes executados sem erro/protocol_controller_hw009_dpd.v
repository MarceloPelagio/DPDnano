`timescale 1ns/1ps
module protocol_controller_hw009_dpd(
 input wire clk,input wire rst_n,input wire [7:0] rx_data_i,
 input wire rx_valid_i,input wire rx_frame_error_i,input wire tx_busy_i,
 output reg [7:0] tx_data_o,output reg tx_start_o,
 output reg in_wr_en_o,output reg [7:0] in_wr_addr_o,
 output reg [31:0] in_wr_data_o,output reg in_rd_en_o,
 output reg [7:0] in_rd_addr_o,input wire [31:0] in_rd_data_i,
 input wire in_rd_valid_i,output reg out_rd_en_o,
 output reg [7:0] out_rd_addr_o,input wire [31:0] out_rd_data_i,
 input wire out_rd_valid_i,output reg dpd_start_o,
 output reg [7:0] dpd_start_addr_o,output reg [8:0] dpd_count_o,
 input wire dpd_busy_i,input wire dpd_done_i,input wire dpd_error_i,
 input wire dpd_overflow_i,output reg busy_o,output wire done_o,
 output wire error_o);

localparam [7:0] SOF_REQ=8'hA5,SOF_RSP=8'h5A;
localparam [7:0] CMD_PING=8'h01,CMD_VERSION=8'h02,CMD_WRITE_IN=8'h20;
localparam [7:0] CMD_READ_IN=8'h21,CMD_READ_OUT=8'h31;
localparam [7:0] CMD_START_DPD=8'h40,CMD_STATUS=8'h41;
localparam [31:0] ERR_UNKNOWN=32'hE1,ERR_CSUM=32'hE2;
localparam [31:0] ERR_ADDR=32'hE3,ERR_COUNT=32'hE4,ERR_BUSY=32'hE5;
localparam WAIT_SOF=0,GET_CMD=1,GET_AH=2,GET_AL=3,GET_D3=4;
localparam GET_D2=5,GET_D1=6,GET_D0=7,GET_CSUM=8;
localparam READ_IN=9,READ_OUT=10,SEND=11;

reg [3:0] state;
reg [7:0] cmd_reg,ah_reg,al_reg;
reg [31:0] data_reg;
reg [7:0] response[0:8];
reg [3:0] tx_index;
reg [24:0] done_count;
reg error_latched;
wire [15:0] address={ah_reg,al_reg};
wire [7:0] req_csum=SOF_REQ^cmd_reg^ah_reg^al_reg^
 data_reg[31:24]^data_reg[23:16]^data_reg[15:8]^data_reg[7:0];

assign done_o=(done_count!=0);
assign error_o=error_latched;

task build_response;
 input [7:0] cmd; input [15:0] addr; input [31:0] data;
 begin
  response[0]<=SOF_RSP; response[1]<=cmd;
  response[2]<=addr[15:8]; response[3]<=addr[7:0];
  response[4]<=data[31:24]; response[5]<=data[23:16];
  response[6]<=data[15:8]; response[7]<=data[7:0];
  response[8]<=SOF_RSP^cmd^addr[15:8]^addr[7:0]^
   data[31:24]^data[23:16]^data[15:8]^data[7:0];
 end
endtask

always @(posedge clk or negedge rst_n) begin
 if(!rst_n) begin
  state<=WAIT_SOF; cmd_reg<=0; ah_reg<=0; al_reg<=0; data_reg<=0;
  tx_data_o<=0; tx_start_o<=0; tx_index<=0;
  in_wr_en_o<=0; in_wr_addr_o<=0; in_wr_data_o<=0;
  in_rd_en_o<=0; in_rd_addr_o<=0; out_rd_en_o<=0; out_rd_addr_o<=0;
  dpd_start_o<=0; dpd_start_addr_o<=0; dpd_count_o<=0;
  busy_o<=0; done_count<=0; error_latched<=0;
 end else begin
  tx_start_o<=0; in_wr_en_o<=0; in_rd_en_o<=0; out_rd_en_o<=0; dpd_start_o<=0;
  if(done_count!=0) done_count<=done_count-1'b1;
  if(rx_frame_error_i) error_latched<=1;
  case(state)
   WAIT_SOF: begin busy_o<=0; if(rx_valid_i&&rx_data_i==SOF_REQ) begin busy_o<=1; state<=GET_CMD; end end
   GET_CMD: if(rx_valid_i) begin cmd_reg<=rx_data_i; state<=GET_AH; end
   GET_AH: if(rx_valid_i) begin ah_reg<=rx_data_i; state<=GET_AL; end
   GET_AL: if(rx_valid_i) begin al_reg<=rx_data_i; state<=GET_D3; end
   GET_D3: if(rx_valid_i) begin data_reg[31:24]<=rx_data_i; state<=GET_D2; end
   GET_D2: if(rx_valid_i) begin data_reg[23:16]<=rx_data_i; state<=GET_D1; end
   GET_D1: if(rx_valid_i) begin data_reg[15:8]<=rx_data_i; state<=GET_D0; end
   GET_D0: if(rx_valid_i) begin data_reg[7:0]<=rx_data_i; state<=GET_CSUM; end
   GET_CSUM: if(rx_valid_i) begin
    if(rx_data_i!=req_csum) begin build_response(cmd_reg,address,ERR_CSUM); error_latched<=1; tx_index<=0; state<=SEND; end
    else case(cmd_reg)
     CMD_PING: begin build_response(CMD_PING,address,0); tx_index<=0; state<=SEND; end
     CMD_VERSION: begin build_response(CMD_VERSION,address,32'h00000901); tx_index<=0; state<=SEND; end
     CMD_WRITE_IN: begin
      if(dpd_busy_i) begin build_response(CMD_WRITE_IN,address,ERR_BUSY); error_latched<=1; end
      else if(address>=256) begin build_response(CMD_WRITE_IN,address,ERR_ADDR); error_latched<=1; end
      else begin in_wr_en_o<=1; in_wr_addr_o<=address[7:0]; in_wr_data_o<=data_reg; build_response(CMD_WRITE_IN,address,0); end
      tx_index<=0; state<=SEND;
     end
     CMD_READ_IN: begin
      if(dpd_busy_i) begin build_response(CMD_READ_IN,address,ERR_BUSY); error_latched<=1; tx_index<=0; state<=SEND; end
      else if(address>=256) begin build_response(CMD_READ_IN,address,ERR_ADDR); error_latched<=1; tx_index<=0; state<=SEND; end
      else begin in_rd_en_o<=1; in_rd_addr_o<=address[7:0]; state<=READ_IN; end
     end
     CMD_READ_OUT: begin
      if(dpd_busy_i) begin build_response(CMD_READ_OUT,address,ERR_BUSY); error_latched<=1; tx_index<=0; state<=SEND; end
      else if(address>=256) begin build_response(CMD_READ_OUT,address,ERR_ADDR); error_latched<=1; tx_index<=0; state<=SEND; end
      else begin out_rd_en_o<=1; out_rd_addr_o<=address[7:0]; state<=READ_OUT; end
     end
     CMD_START_DPD: begin
      if(dpd_busy_i) begin build_response(CMD_START_DPD,address,ERR_BUSY); error_latched<=1; end
      else if(address>=256) begin build_response(CMD_START_DPD,address,ERR_ADDR); error_latched<=1; end
      else if(data_reg[8:0]==0||data_reg[8:0]>256||address+data_reg[8:0]>256) begin build_response(CMD_START_DPD,address,ERR_COUNT); error_latched<=1; end
      else begin
       dpd_start_addr_o<=address[7:0]; dpd_count_o<=data_reg[8:0]; dpd_start_o<=1;
       build_response(CMD_START_DPD,address,{23'd0,data_reg[8:0]});
      end
      tx_index<=0; state<=SEND;
     end
     CMD_STATUS: begin
      build_response(CMD_STATUS,address,{28'd0,dpd_overflow_i,dpd_error_i,dpd_done_i,dpd_busy_i});
      tx_index<=0; state<=SEND;
     end
     default: begin build_response(cmd_reg,address,ERR_UNKNOWN); error_latched<=1; tx_index<=0; state<=SEND; end
    endcase
   end
   READ_IN: if(in_rd_valid_i) begin build_response(CMD_READ_IN,address,in_rd_data_i); tx_index<=0; state<=SEND; end
   READ_OUT: if(out_rd_valid_i) begin build_response(CMD_READ_OUT,address,out_rd_data_i); tx_index<=0; state<=SEND; end
   SEND: if(!tx_busy_i&&!tx_start_o) begin
    tx_data_o<=response[tx_index]; tx_start_o<=1;
    if(tx_index==8) begin tx_index<=0; busy_o<=0; done_count<=25'd8100000; state<=WAIT_SOF; end
    else tx_index<=tx_index+1'b1;
   end
   default: state<=WAIT_SOF;
  endcase
 end
end
endmodule
