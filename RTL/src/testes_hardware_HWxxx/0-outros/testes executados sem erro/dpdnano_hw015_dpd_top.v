`timescale 1ns/1ps
module dpdnano_hw015_dpd_top (
    input wire clk_27mhz,
    input wire rst_n,
    input wire uart_rx_i,
    output wire uart_tx_o,
    output wire led_busy,
    output wire led_done,
    output wire led_error
);

wire [7:0] rx_data, tx_data;
wire rx_valid, rx_busy, rx_frame_error;
wire tx_start, tx_busy;
wire protocol_busy, protocol_done, protocol_error;

wire in_wr_en, in_host_rd_en, in_host_rd_valid;
wire [7:0] in_wr_addr, in_host_rd_addr;
wire [31:0] in_wr_data, in_host_rd_data;

wire in_dpd_rd_en, in_dpd_rd_valid;
wire [7:0] in_dpd_rd_addr;
wire [31:0] in_dpd_rd_data;

wire out_dpd_wr_en, out_host_rd_en, out_host_rd_valid;
wire [7:0] out_dpd_wr_addr, out_host_rd_addr;
wire [31:0] out_dpd_wr_data, out_host_rd_data;

wire dpd_start;
wire [7:0] dpd_start_addr;
wire [8:0] dpd_count;
wire dpd_busy, dpd_done, dpd_error, dpd_overflow_seen;

uart_rx_27m_115200 u_rx(
    .clk(clk_27mhz), .rst_n(rst_n), .rx_i(uart_rx_i),
    .data_o(rx_data), .data_valid_o(rx_valid),
    .busy_o(rx_busy), .frame_error_o(rx_frame_error)
);

uart_tx_27m_115200 u_tx(
    .clk(clk_27mhz), .rst_n(rst_n), .start_i(tx_start),
    .data_i(tx_data), .tx_o(uart_tx_o), .busy_o(tx_busy)
);

protocol_controller_hw009_dpd u_protocol(
    .clk(clk_27mhz), .rst_n(rst_n),
    .rx_data_i(rx_data), .rx_valid_i(rx_valid),
    .rx_frame_error_i(rx_frame_error),
    .tx_busy_i(tx_busy), .tx_data_o(tx_data), .tx_start_o(tx_start),
    .in_wr_en_o(in_wr_en), .in_wr_addr_o(in_wr_addr), .in_wr_data_o(in_wr_data),
    .in_rd_en_o(in_host_rd_en), .in_rd_addr_o(in_host_rd_addr),
    .in_rd_data_i(in_host_rd_data), .in_rd_valid_i(in_host_rd_valid),
    .out_rd_en_o(out_host_rd_en), .out_rd_addr_o(out_host_rd_addr),
    .out_rd_data_i(out_host_rd_data), .out_rd_valid_i(out_host_rd_valid),
    .dpd_start_o(dpd_start), .dpd_start_addr_o(dpd_start_addr),
    .dpd_count_o(dpd_count), .dpd_busy_i(dpd_busy),
    .dpd_done_i(dpd_done), .dpd_error_i(dpd_error),
    .dpd_overflow_i(dpd_overflow_seen),
    .busy_o(protocol_busy), .done_o(protocol_done),
    .error_o(protocol_error)
);

input_memory_dualread_256x32 u_input_memory(
    .clk(clk_27mhz),
    .wr_en_i(in_wr_en), .wr_addr_i(in_wr_addr), .wr_data_i(in_wr_data),
    .host_rd_en_i(in_host_rd_en), .host_rd_addr_i(in_host_rd_addr),
    .host_rd_data_o(in_host_rd_data), .host_rd_valid_o(in_host_rd_valid),
    .dpd_rd_en_i(in_dpd_rd_en), .dpd_rd_addr_i(in_dpd_rd_addr),
    .dpd_rd_data_o(in_dpd_rd_data), .dpd_rd_valid_o(in_dpd_rd_valid)
);

output_memory_dualport_256x32 u_output_memory(
    .clk(clk_27mhz),
    .dpd_wr_en_i(out_dpd_wr_en), .dpd_wr_addr_i(out_dpd_wr_addr),
    .dpd_wr_data_i(out_dpd_wr_data),
    .host_rd_en_i(out_host_rd_en), .host_rd_addr_i(out_host_rd_addr),
    .host_rd_data_o(out_host_rd_data), .host_rd_valid_o(out_host_rd_valid)
);

dpd_controller_hw015_dpd u_dpd_controller(
    .clk(clk_27mhz), .rst(~rst_n),
    .start_i(dpd_start), .start_addr_i(dpd_start_addr), .count_i(dpd_count),
    .in_mem_rd_en_o(in_dpd_rd_en), .in_mem_rd_addr_o(in_dpd_rd_addr),
    .in_mem_rd_data_i(in_dpd_rd_data), .in_mem_rd_valid_i(in_dpd_rd_valid),
    .out_mem_wr_en_o(out_dpd_wr_en), .out_mem_wr_addr_o(out_dpd_wr_addr),
    .out_mem_wr_data_o(out_dpd_wr_data),
    .busy_o(dpd_busy), .done_o(dpd_done),
    .error_o(dpd_error), .overflow_seen_o(dpd_overflow_seen)
);

assign led_busy  = ~(rx_busy | tx_busy | protocol_busy | dpd_busy);
assign led_done  = ~(protocol_done | dpd_done);
assign led_error = ~(protocol_error | dpd_error | dpd_overflow_seen);
endmodule
