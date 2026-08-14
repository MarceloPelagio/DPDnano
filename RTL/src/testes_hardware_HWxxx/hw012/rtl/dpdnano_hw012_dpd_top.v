`timescale 1ns/1ps

module dpdnano_hw012_dpd_top (
    input  wire clk_27mhz,
    input  wire rst_n,
    input  wire uart_rx_i,
    output wire uart_tx_o,
    output wire led_busy,
    output wire led_done,
    output wire led_error
);

wire clk_dpd, pll_lock, rst_dpd;
wire [7:0] rx_data, tx_data;
wire rx_valid, rx_busy, rx_frame_error, tx_start, tx_busy;
wire protocol_busy, protocol_done, protocol_error;
wire in_wr_en, in_host_rd_en, in_host_rd_valid;
wire [7:0] in_wr_addr, in_host_rd_addr, in_dpd_rd_addr;
wire [31:0] in_wr_data, in_host_rd_data, in_dpd_rd_data;
wire in_dpd_rd_en, in_dpd_rd_valid;
wire out_dpd_wr_en, out_host_rd_en, out_host_rd_valid;
wire [7:0] out_dpd_wr_addr, out_host_rd_addr;
wire [31:0] out_dpd_wr_data, out_host_rd_data;
wire start_uart, start_dpd;
wire [7:0] start_addr_uart, start_addr_dpd;
wire [8:0] count_uart, count_dpd;
wire dpd_busy_fast, dpd_done_fast, dpd_error_fast, dpd_overflow_fast;
wire dpd_busy_uart, dpd_done_uart, dpd_error_uart, dpd_overflow_uart;
wire host_dpd_rd_en;
wire [7:0] host_dpd_rd_addr;
wire [31:0] host_dpd_rd_data;
wire host_dpd_rd_valid;
wire host_dpd_wr_en;
wire [7:0] host_dpd_wr_addr;
wire [31:0] host_dpd_wr_data;
wire out_mem_wr_ready;

assign rst_dpd = (~rst_n) | (~pll_lock);

Gowin_PLLVR u_gowin_pllvr (.clkout(clk_dpd), .lock(pll_lock), .clkin(clk_27mhz));
uart_rx_27m_115200 u_rx (.clk(clk_27mhz), .rst_n(rst_n), .rx_i(uart_rx_i), .data_o(rx_data), .data_valid_o(rx_valid), .busy_o(rx_busy), .frame_error_o(rx_frame_error));
uart_tx_27m_115200 u_tx (.clk(clk_27mhz), .rst_n(rst_n), .start_i(tx_start), .data_i(tx_data), .tx_o(uart_tx_o), .busy_o(tx_busy));

protocol_controller_hw009_dpd u_protocol (
    .clk(clk_27mhz), .rst_n(rst_n),
    .rx_data_i(rx_data), .rx_valid_i(rx_valid), .rx_frame_error_i(rx_frame_error),
    .tx_busy_i(tx_busy), .tx_data_o(tx_data), .tx_start_o(tx_start),
    .in_wr_en_o(in_wr_en), .in_wr_addr_o(in_wr_addr), .in_wr_data_o(in_wr_data),
    .in_rd_en_o(in_host_rd_en), .in_rd_addr_o(in_host_rd_addr), .in_rd_data_i(in_host_rd_data), .in_rd_valid_i(in_host_rd_valid),
    .out_rd_en_o(out_host_rd_en), .out_rd_addr_o(out_host_rd_addr), .out_rd_data_i(out_host_rd_data), .out_rd_valid_i(out_host_rd_valid),
    .dpd_start_o(start_uart), .dpd_start_addr_o(start_addr_uart), .dpd_count_o(count_uart),
    .dpd_busy_i(dpd_busy_uart), .dpd_done_i(dpd_done_uart), .dpd_error_i(dpd_error_uart), .dpd_overflow_i(dpd_overflow_uart),
    .busy_o(protocol_busy), .done_o(protocol_done), .error_o(protocol_error)
);

command_cdc_hw_dpd u_command_cdc (.src_clk(clk_27mhz), .src_rst(~rst_n), .src_start(start_uart), .src_start_addr(start_addr_uart), .src_count(count_uart), .dst_clk(clk_dpd), .dst_rst(rst_dpd), .dst_start(start_dpd), .dst_start_addr(start_addr_dpd), .dst_count(count_dpd));
status_cdc_hw_dpd u_status_cdc (.src_clk(clk_dpd), .src_rst(rst_dpd), .src_busy(dpd_busy_fast), .src_done(dpd_done_fast), .src_error(dpd_error_fast), .src_overflow(dpd_overflow_fast), .dst_clk(clk_27mhz), .dst_rst(~rst_n), .dst_busy(dpd_busy_uart), .dst_done(dpd_done_uart), .dst_error(dpd_error_uart), .dst_overflow(dpd_overflow_uart));

input_memory_dualread_256x32 u_input_memory (
    .clk(clk_27mhz),
    .wr_en_i(in_wr_en), .wr_addr_i(in_wr_addr), .wr_data_i(in_wr_data),
    .host_rd_en_i(in_host_rd_en), .host_rd_addr_i(in_host_rd_addr),
    .host_rd_data_o(in_host_rd_data), .host_rd_valid_o(in_host_rd_valid),
    .dpd_rd_en_i(host_dpd_rd_en), .dpd_rd_addr_i(host_dpd_rd_addr),
    .dpd_rd_data_o(host_dpd_rd_data), .dpd_rd_valid_o(host_dpd_rd_valid)
);

output_memory_dualport_256x32 u_output_memory (
    .clk(clk_27mhz),
    .dpd_wr_en_i(host_dpd_wr_en), .dpd_wr_addr_i(host_dpd_wr_addr), .dpd_wr_data_i(host_dpd_wr_data),
    .host_rd_en_i(out_host_rd_en), .host_rd_addr_i(out_host_rd_addr),
    .host_rd_data_o(out_host_rd_data), .host_rd_valid_o(out_host_rd_valid)
);

input_read_cdc_hw_dpd u_input_read_cdc (
    .fast_clk(clk_dpd), .fast_rst(rst_dpd),
    .fast_rd_en_i(in_dpd_rd_en), .fast_rd_addr_i(in_dpd_rd_addr),
    .fast_rd_data_o(in_dpd_rd_data), .fast_rd_valid_o(in_dpd_rd_valid),
    .host_clk(clk_27mhz), .host_rst(~rst_n),
    .host_rd_en_o(host_dpd_rd_en), .host_rd_addr_o(host_dpd_rd_addr),
    .host_rd_data_i(host_dpd_rd_data), .host_rd_valid_i(host_dpd_rd_valid)
);

output_write_cdc_hw_dpd u_output_write_cdc (
    .fast_clk(clk_dpd), .fast_rst(rst_dpd),
    .fast_wr_en_i(out_dpd_wr_en), .fast_wr_addr_i(out_dpd_wr_addr), .fast_wr_data_i(out_dpd_wr_data),
    .fast_wr_ready_o(out_mem_wr_ready),
    .host_clk(clk_27mhz), .host_rst(~rst_n),
    .host_wr_en_o(host_dpd_wr_en), .host_wr_addr_o(host_dpd_wr_addr), .host_wr_data_o(host_dpd_wr_data)
);

dpd_controller_hw012_dpd u_dpd_controller (
    .clk(clk_dpd), .rst(rst_dpd), .start_i(start_dpd), .start_addr_i(start_addr_dpd), .count_i(count_dpd),
    .in_mem_rd_en_o(in_dpd_rd_en), .in_mem_rd_addr_o(in_dpd_rd_addr), .in_mem_rd_data_i(in_dpd_rd_data), .in_mem_rd_valid_i(in_dpd_rd_valid),
    .out_mem_wr_en_o(out_dpd_wr_en), .out_mem_wr_addr_o(out_dpd_wr_addr), .out_mem_wr_data_o(out_dpd_wr_data), .out_mem_wr_ready_i(out_mem_wr_ready),
    .busy_o(dpd_busy_fast), .done_o(dpd_done_fast), .error_o(dpd_error_fast), .overflow_seen_o(dpd_overflow_fast)
);

assign led_busy = rx_busy | tx_busy | protocol_busy | dpd_busy_uart;
assign led_done = protocol_done | dpd_done_uart;
assign led_error = protocol_error | dpd_error_uart | dpd_overflow_uart | (~pll_lock);

endmodule
