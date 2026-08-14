`timescale 1ns/1ps

module dpdnano_hw_top #(
    parameter UART_CLK_FREQ_HZ = 27000000,
    parameter UART_BAUD_RATE   = 921600,
    parameter ADDR_WIDTH       = 10,
    parameter UART_FIFO_ADDR_WIDTH = 4
)(
    input  wire clk_27mhz,
    input  wire rst_n,
    input  wire uart_rx_i,
    output wire uart_tx_o,
    output wire led_busy,
    output wire led_done,
    output wire led_error,
    output wire led_pll_lock
);

wire clk_dpd;
wire pll_lock;
wire rst_uart;
wire rst_dpd;

wire [7:0] uart_rx_data;
wire       uart_rx_valid;
wire       uart_rx_framing_error;

wire [7:0] uart_tx_data;
wire       uart_tx_start;
wire       uart_tx_busy;

wire [7:0] rx_fifo_rd_data;
wire       rx_fifo_rd_en;
wire       rx_fifo_empty;
wire       rx_fifo_full;
wire [UART_FIFO_ADDR_WIDTH:0] rx_fifo_level;

wire [7:0] tx_fifo_wr_data;
wire       tx_fifo_wr_en;
wire       tx_fifo_empty;
wire       tx_fifo_full;
wire [UART_FIFO_ADDR_WIDTH:0] tx_fifo_level;
reg        tx_fifo_rd_en;

wire                  input_wr_en_uart;
wire [ADDR_WIDTH-1:0] input_wr_addr_uart;
wire [31:0]           input_wr_data_uart;
wire [ADDR_WIDTH-1:0] input_rd_addr_dpd;
wire [31:0]           input_rd_data_dpd;

wire                  output_wr_en_dpd;
wire [ADDR_WIDTH-1:0] output_wr_addr_dpd;
wire [39:0]           output_wr_data_dpd;
wire [ADDR_WIDTH-1:0] output_rd_addr_uart;
wire [39:0]           output_rd_data_uart;

wire                  start_uart;
wire [ADDR_WIDTH:0]   sample_count_uart;
wire                  start_dpd;
wire [ADDR_WIDTH:0]   sample_count_dpd;

wire                  busy_dpd;
wire                  done_dpd;
wire [31:0]           cycle_count_dpd;
wire [31:0]           samples_processed_dpd;
wire [31:0]           overflow_count_dpd;

wire                  busy_uart;
wire                  done_uart;
wire [31:0]           cycle_count_uart;
wire [31:0]           samples_processed_uart;
wire [31:0]           overflow_count_uart;
wire                  protocol_error;

wire                  dpd_in_valid;
wire signed [15:0]    dpd_din_re;
wire signed [15:0]    dpd_din_im;
wire                  dpd_out_valid;
wire signed [15:0]    dpd_dout_re;
wire signed [15:0]    dpd_dout_im;
wire                  dpd_overflow;
wire                  dpd_overflow_re;
wire                  dpd_overflow_im;

/* Static coefficients from the frozen RTL coefficient bank. */
wire signed [15:0] coeff_c0_re;
wire signed [15:0] coeff_c0_im;
wire signed [15:0] coeff_c1_re;
wire signed [15:0] coeff_c1_im;
wire signed [15:0] coeff_c2_re;
wire signed [15:0] coeff_c2_im;

assign led_busy     = busy_uart;
assign led_done     = done_uart;
assign led_error    = protocol_error | uart_rx_framing_error | rx_fifo_full;
assign led_pll_lock = pll_lock;

/* Real generated Gowin module name. */
Gowin_PLLVR u_gowin_pllvr (
    .clkout(clk_dpd),
    .lock(pll_lock),
    .clkin(clk_27mhz)
);

reset_sync u_reset_uart (
    .clk(clk_27mhz),
    .arst(~rst_n),
    .srst(rst_uart)
);

reset_sync u_reset_dpd (
    .clk(clk_dpd),
    .arst((~rst_n) | (~pll_lock)),
    .srst(rst_dpd)
);

uart_rx #(
    .CLK_FREQ_HZ(UART_CLK_FREQ_HZ),
    .BAUD_RATE(UART_BAUD_RATE)
) u_uart_rx (
    .clk(clk_27mhz),
    .rst(rst_uart),
    .rx(uart_rx_i),
    .data_out(uart_rx_data),
    .data_valid(uart_rx_valid),
    .framing_error(uart_rx_framing_error)
);

uart_fifo #(
    .DATA_WIDTH(8),
    .ADDR_WIDTH(UART_FIFO_ADDR_WIDTH)
) u_rx_fifo (
    .clk(clk_27mhz),
    .rst(rst_uart),
    .wr_en(uart_rx_valid),
    .wr_data(uart_rx_data),
    .rd_en(rx_fifo_rd_en),
    .rd_data(rx_fifo_rd_data),
    .empty(rx_fifo_empty),
    .full(rx_fifo_full),
    .level(rx_fifo_level)
);

uart_fifo #(
    .DATA_WIDTH(8),
    .ADDR_WIDTH(UART_FIFO_ADDR_WIDTH)
) u_tx_fifo (
    .clk(clk_27mhz),
    .rst(rst_uart),
    .wr_en(tx_fifo_wr_en),
    .wr_data(tx_fifo_wr_data),
    .rd_en(tx_fifo_rd_en),
    .rd_data(uart_tx_data),
    .empty(tx_fifo_empty),
    .full(tx_fifo_full),
    .level(tx_fifo_level)
);

always @(posedge clk_27mhz or posedge rst_uart) begin
    if (rst_uart)
        tx_fifo_rd_en <= 1'b0;
    else begin
        tx_fifo_rd_en <= 1'b0;
        if (!uart_tx_busy && !tx_fifo_empty)
            tx_fifo_rd_en <= 1'b1;
    end
end

assign uart_tx_start = tx_fifo_rd_en;

uart_tx #(
    .CLK_FREQ_HZ(UART_CLK_FREQ_HZ),
    .BAUD_RATE(UART_BAUD_RATE)
) u_uart_tx (
    .clk(clk_27mhz),
    .rst(rst_uart),
    .data_in(uart_tx_data),
    .data_valid(uart_tx_start),
    .tx(uart_tx_o),
    .busy(uart_tx_busy)
);

protocol_controller #(
    .ADDR_WIDTH(ADDR_WIDTH)
) u_protocol_controller (
    .clk(clk_27mhz),
    .rst(rst_uart),
    .rx_fifo_data(rx_fifo_rd_data),
    .rx_fifo_empty(rx_fifo_empty),
    .rx_fifo_rd_en(rx_fifo_rd_en),
    .tx_fifo_data(tx_fifo_wr_data),
    .tx_fifo_full(tx_fifo_full),
    .tx_fifo_wr_en(tx_fifo_wr_en),
    .input_wr_en(input_wr_en_uart),
    .input_wr_addr(input_wr_addr_uart),
    .input_wr_data(input_wr_data_uart),
    .dpd_start(start_uart),
    .sample_count(sample_count_uart),
    .dpd_busy(busy_uart),
    .dpd_done(done_uart),
    .cycle_count(cycle_count_uart),
    .samples_processed(samples_processed_uart),
    .overflow_count(overflow_count_uart),
    .output_rd_addr(output_rd_addr_uart),
    .output_rd_data(output_rd_data_uart),
    .protocol_error(protocol_error)
);

command_cdc #(
    .COUNT_WIDTH(ADDR_WIDTH+1)
) u_command_cdc (
    .src_clk(clk_27mhz),
    .src_rst(rst_uart),
    .src_start(start_uart),
    .src_sample_count(sample_count_uart),
    .dst_clk(clk_dpd),
    .dst_rst(rst_dpd),
    .dst_start(start_dpd),
    .dst_sample_count(sample_count_dpd)
);

status_cdc u_status_cdc (
    .src_clk(clk_dpd),
    .src_rst(rst_dpd),
    .src_busy(busy_dpd),
    .src_done(done_dpd),
    .src_cycle_count(cycle_count_dpd),
    .src_samples_processed(samples_processed_dpd),
    .src_overflow_count(overflow_count_dpd),
    .dst_clk(clk_27mhz),
    .dst_rst(rst_uart),
    .dst_busy(busy_uart),
    .dst_done(done_uart),
    .dst_cycle_count(cycle_count_uart),
    .dst_samples_processed(samples_processed_uart),
    .dst_overflow_count(overflow_count_uart)
);

input_dual_clock_bsram #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(32)
) u_input_bsram (
    .wr_clk(clk_27mhz),
    .wr_en(input_wr_en_uart),
    .wr_addr(input_wr_addr_uart),
    .wr_data(input_wr_data_uart),
    .rd_clk(clk_dpd),
    .rd_addr(input_rd_addr_dpd),
    .rd_data(input_rd_data_dpd)
);

dpd_controller #(
    .ADDR_WIDTH(ADDR_WIDTH)
) u_dpd_controller (
    .clk(clk_dpd),
    .rst(rst_dpd),
    .start(start_dpd),
    .sample_count(sample_count_dpd),
    .input_rd_addr(input_rd_addr_dpd),
    .input_rd_data(input_rd_data_dpd),
    .dpd_in_valid(dpd_in_valid),
    .dpd_din_re(dpd_din_re),
    .dpd_din_im(dpd_din_im),
    .dpd_out_valid(dpd_out_valid),
    .dpd_dout_re(dpd_dout_re),
    .dpd_dout_im(dpd_dout_im),
    .dpd_overflow(dpd_overflow),
    .output_wr_en(output_wr_en_dpd),
    .output_wr_addr(output_wr_addr_dpd),
    .output_wr_data(output_wr_data_dpd),
    .busy(busy_dpd),
    .done(done_dpd),
    .cycle_count(cycle_count_dpd),
    .samples_processed(samples_processed_dpd),
    .overflow_count(overflow_count_dpd)
);

/*
 * Frozen coefficient mapping:
 *   C0 -> first-order (linear) coefficient
 *   C1 -> third-order (cubic) coefficient
 *   C2 -> reserved for future extension
 */
coeff_bank u_coeff_bank (
    .c0_r(coeff_c0_re),
    .c0_i(coeff_c0_im),
    .c1_r(coeff_c1_re),
    .c1_i(coeff_c1_im),
    .c2_r(coeff_c2_re),
    .c2_i(coeff_c2_im)
);

dpd_core u_dpd_core (
    .clk(clk_dpd),
    .rst(rst_dpd),
    .in_valid(dpd_in_valid),
    .din_re(dpd_din_re),
    .din_im(dpd_din_im),

    .coef1_re(coeff_c0_re),
    .coef1_im(coeff_c0_im),
    .coef3_re(coeff_c1_re),
    .coef3_im(coeff_c1_im),

/*`ifdef DPD_ENABLE_OVERFLOW_FLAGS*/
    .overflow(dpd_overflow),
    .overflow_re(dpd_overflow_re),
    .overflow_im(dpd_overflow_im),
/*`endif*/

    .out_valid(dpd_out_valid),
    .dout_re(dpd_dout_re),
    .dout_im(dpd_dout_im)
);

/*
`ifndef DPD_ENABLE_OVERFLOW_FLAGS
assign dpd_overflow    = 1'b0;
assign dpd_overflow_re = 1'b0;
assign dpd_overflow_im = 1'b0;
`endif
*/

output_dual_clock_bsram #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(40)
) u_output_bsram (
    .wr_clk(clk_dpd),
    .wr_en(output_wr_en_dpd),
    .wr_addr(output_wr_addr_dpd),
    .wr_data(output_wr_data_dpd),
    .rd_clk(clk_27mhz),
    .rd_addr(output_rd_addr_uart),
    .rd_data(output_rd_data_uart)
);

endmodule
