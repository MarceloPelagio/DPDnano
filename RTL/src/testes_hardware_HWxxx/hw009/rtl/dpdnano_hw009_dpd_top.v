`timescale 1ns/1ps

module dpdnano_hw009_dpd_top(
    input  wire clk_27mhz,
    input  wire rst_n,
    input  wire uart_rx_i,
    output wire uart_tx_o,
    output wire led_busy,
    output wire led_done,
    output wire led_error
);

wire clk_dpd;
wire pll_lock;
wire rst_dpd;

wire [7:0] rx_data, tx_data;
wire rx_valid, rx_busy, rx_frame_error;
wire tx_start, tx_busy;
wire protocol_busy, protocol_done, protocol_error;

wire in_wr_en, in_host_rd_en;
wire [7:0] in_wr_addr, in_host_rd_addr;
wire [31:0] in_wr_data, in_host_rd_data;
wire in_host_rd_valid;

wire in_dpd_rd_en;
wire [7:0] in_dpd_rd_addr;
wire [31:0] in_dpd_rd_data;
wire in_dpd_rd_valid;

wire out_dpd_wr_en;
wire [7:0] out_dpd_wr_addr;
wire [31:0] out_dpd_wr_data;
wire out_host_rd_en;
wire [7:0] out_host_rd_addr;
wire [31:0] out_host_rd_data;
wire out_host_rd_valid;

wire start_uart;
wire [7:0] start_addr_uart;
wire [8:0] count_uart;
wire start_dpd;
wire [7:0] start_addr_dpd;
wire [8:0] count_dpd;

wire dpd_busy_fast, dpd_done_fast, dpd_error_fast, dpd_overflow_fast;
wire dpd_busy_uart, dpd_done_uart, dpd_error_uart, dpd_overflow_uart;

reg in_host_rd_valid_r, out_host_rd_valid_r, in_dpd_rd_valid_r;
reg out_host_rd_en_dly1, out_host_rd_en_dly2;
reg in_dpd_rd_en_dly1, in_dpd_rd_en_dly2;

assign rst_dpd = (~rst_n) | (~pll_lock);
assign in_host_rd_data = 32'd0;
assign in_host_rd_valid = in_host_rd_valid_r;
assign out_host_rd_valid = out_host_rd_valid_r;
assign in_dpd_rd_valid = in_dpd_rd_valid_r;

Gowin_PLLVR u_gowin_pllvr (
    .clkout(clk_dpd),
    .lock(pll_lock),
    .clkin(clk_27mhz)
);

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
    .dpd_start_o(start_uart), .dpd_start_addr_o(start_addr_uart),
    .dpd_count_o(count_uart), .dpd_busy_i(dpd_busy_uart), .dpd_done_i(dpd_done_uart),
    .dpd_error_i(dpd_error_uart), .dpd_overflow_i(dpd_overflow_uart),
    .busy_o(protocol_busy), .done_o(protocol_done), .error_o(protocol_error)
);

command_cdc_hw_dpd u_command_cdc (
    .src_clk(clk_27mhz),
    .src_rst(~rst_n),
    .src_start(start_uart),
    .src_start_addr(start_addr_uart),
    .src_count(count_uart),
    .dst_clk(clk_dpd),
    .dst_rst(rst_dpd),
    .dst_start(start_dpd),
    .dst_start_addr(start_addr_dpd),
    .dst_count(count_dpd)
);

status_cdc_hw_dpd u_status_cdc (
    .src_clk(clk_dpd),
    .src_rst(rst_dpd),
    .src_busy(dpd_busy_fast),
    .src_done(dpd_done_fast),
    .src_error(dpd_error_fast),
    .src_overflow(dpd_overflow_fast),
    .dst_clk(clk_27mhz),
    .dst_rst(~rst_n),
    .dst_busy(dpd_busy_uart),
    .dst_done(dpd_done_uart),
    .dst_error(dpd_error_uart),
    .dst_overflow(dpd_overflow_uart)
);

input_dual_clock_bsram #(
    .ADDR_WIDTH(8),
    .DATA_WIDTH(32)
) u_inmem (
    .wr_clk(clk_27mhz),
    .wr_en(in_wr_en),
    .wr_addr(in_wr_addr),
    .wr_data(in_wr_data),
    .rd_clk(clk_dpd),
    .rd_addr(in_dpd_rd_addr),
    .rd_data(in_dpd_rd_data)
);

output_dual_clock_bsram #(
    .ADDR_WIDTH(8),
    .DATA_WIDTH(32)
) u_outmem (
    .wr_clk(clk_dpd),
    .wr_en(out_dpd_wr_en),
    .wr_addr(out_dpd_wr_addr),
    .wr_data(out_dpd_wr_data),
    .rd_clk(clk_27mhz),
    .rd_addr(out_host_rd_addr),
    .rd_data(out_host_rd_data)
);

always @(posedge clk_27mhz or negedge rst_n) begin
    if (!rst_n) begin
        in_host_rd_valid_r <= 1'b0;
        out_host_rd_valid_r <= 1'b0;
        out_host_rd_en_dly1 <= 1'b0;
        out_host_rd_en_dly2 <= 1'b0;
    end else begin
        in_host_rd_valid_r <= 1'b0;
        out_host_rd_en_dly1 <= out_host_rd_en;
        out_host_rd_en_dly2 <= out_host_rd_en_dly1;
        out_host_rd_valid_r <= out_host_rd_en_dly2;
    end
end

always @(posedge clk_dpd or posedge rst_dpd) begin
    if (rst_dpd) begin
        in_dpd_rd_valid_r <= 1'b0;
        in_dpd_rd_en_dly1 <= 1'b0;
        in_dpd_rd_en_dly2 <= 1'b0;
    end else begin
        in_dpd_rd_en_dly1 <= in_dpd_rd_en;
        in_dpd_rd_en_dly2 <= in_dpd_rd_en_dly1;
        in_dpd_rd_valid_r <= in_dpd_rd_en_dly2;
    end
end

dpd_controller_hw009_dpd u_dpd(
    .clk(clk_dpd), .rst(rst_dpd), .start_i(start_dpd),
    .start_addr_i(start_addr_dpd), .count_i(count_dpd),
    .in_mem_rd_en_o(in_dpd_rd_en), .in_mem_rd_addr_o(in_dpd_rd_addr),
    .in_mem_rd_data_i(in_dpd_rd_data), .in_mem_rd_valid_i(in_dpd_rd_valid),
    .out_mem_wr_en_o(out_dpd_wr_en), .out_mem_wr_addr_o(out_dpd_wr_addr),
    .out_mem_wr_data_o(out_dpd_wr_data), .busy_o(dpd_busy_fast),
    .done_o(dpd_done_fast), .error_o(dpd_error_fast),
    .overflow_seen_o(dpd_overflow_fast)
);

assign led_busy  = rx_busy | tx_busy | protocol_busy | dpd_busy_uart;
assign led_done  = protocol_done | dpd_done_uart;
assign led_error = protocol_error | dpd_error_uart | dpd_overflow_uart | (~pll_lock);

endmodule
