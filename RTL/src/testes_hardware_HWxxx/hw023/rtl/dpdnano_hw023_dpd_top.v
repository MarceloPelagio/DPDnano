`timescale 1ns/1ps

module dpdnano_hw023_dpd_top (
    input  wire clk_27mhz,
    input  wire rst_n,
    input  wire uart_rx_i,
    output wire uart_tx_o,
    output wire led_busy,
    output wire led_done,
    output wire led_error
);

wire [7:0] rx_data;
wire [7:0] tx_data;
wire rx_valid;
wire rx_busy;
wire rx_frame_error;
wire tx_start;
wire tx_busy;

wire protocol_busy;
wire protocol_done;
wire protocol_error;

wire clk_dpd;
wire pll_lock;
wire rst_dpd;

wire run_start_uart;
wire [31:0] target_samples_uart;
wire run_start_dpd;
wire [31:0] target_samples_dpd;

wire engine_busy_fast;
wire engine_done_fast;
wire engine_error_fast;

wire [31:0] samples_sent_fast;
wire [31:0] samples_received_fast;
wire [15:0] latency_min_fast;
wire [15:0] latency_max_fast;
wire [31:0] latency_sum_fast;
wire [31:0] total_cycles_fast;
wire [31:0] overflow_events_fast;
wire [31:0] saturation_positive_fast;
wire [31:0] saturation_negative_fast;
wire [31:0] coefficient_updates_fast;
wire [31:0] high_amplitude_samples_fast;
wire [31:0] fifo_errors_fast;
wire [31:0] losses_fast;
wire [31:0] duplicates_fast;
wire [31:0] reorder_fast;
wire [31:0] input_signature_fast;
wire [31:0] output_signature_fast;

wire engine_busy_uart;
wire engine_done_uart;
wire engine_error_uart;
wire [3:0] checkpoint_addr;
wire [31:0] checkpoint_cycle_fast;

assign rst_dpd = (~rst_n) | (~pll_lock);

Gowin_PLLVR u_gowin_pllvr (
    .clkout(clk_dpd),
    .lock(pll_lock),
    .clkin(clk_27mhz)
);

uart_rx_27m_115200 u_rx (
    .clk(clk_27mhz),
    .rst_n(rst_n),
    .rx_i(uart_rx_i),
    .data_o(rx_data),
    .data_valid_o(rx_valid),
    .busy_o(rx_busy),
    .frame_error_o(rx_frame_error)
);

uart_tx_27m_115200 u_tx (
    .clk(clk_27mhz),
    .rst_n(rst_n),
    .start_i(tx_start),
    .data_i(tx_data),
    .tx_o(uart_tx_o),
    .busy_o(tx_busy)
);

protocol_controller_hw023_dpd u_protocol (
    .clk(clk_27mhz),
    .rst_n(rst_n),
    .rx_data_i(rx_data),
    .rx_valid_i(rx_valid),
    .rx_frame_error_i(rx_frame_error),
    .tx_busy_i(tx_busy),
    .tx_data_o(tx_data),
    .tx_start_o(tx_start),
    .run_start_o(run_start_uart),
    .target_samples_o(target_samples_uart),
    .engine_busy_i(engine_busy_uart),
    .engine_done_i(engine_done_uart),
    .engine_error_i(engine_error_uart),
    .samples_sent_i(samples_sent_fast),
    .samples_received_i(samples_received_fast),
    .latency_min_i(latency_min_fast),
    .latency_max_i(latency_max_fast),
    .latency_sum_i(latency_sum_fast),
    .total_cycles_i(total_cycles_fast),
    .overflow_events_i(overflow_events_fast),
    .saturation_positive_i(saturation_positive_fast),
    .saturation_negative_i(saturation_negative_fast),
    .coefficient_updates_i(coefficient_updates_fast),
    .high_amplitude_samples_i(high_amplitude_samples_fast),
    .fifo_errors_i(fifo_errors_fast),
    .losses_i(losses_fast),
    .duplicates_i(duplicates_fast),
    .reorder_i(reorder_fast),
    .input_signature_i(input_signature_fast),
    .output_signature_i(output_signature_fast),
    .checkpoint_addr_o(checkpoint_addr),
    .checkpoint_cycle_i(checkpoint_cycle_fast),
    .busy_o(protocol_busy),
    .done_o(protocol_done),
    .error_o(protocol_error)
);

command_cdc_hw023_dpd u_command_cdc (
    .src_clk(clk_27mhz),
    .src_rst(~rst_n),
    .src_start(run_start_uart),
    .src_target_samples(target_samples_uart),
    .dst_clk(clk_dpd),
    .dst_rst(rst_dpd),
    .dst_start(run_start_dpd),
    .dst_target_samples(target_samples_dpd)
);

status_cdc_hw023_dpd u_status_cdc (
    .src_clk(clk_dpd),
    .src_rst(rst_dpd),
    .src_busy(engine_busy_fast),
    .src_done(engine_done_fast),
    .src_error(engine_error_fast),
    .dst_clk(clk_27mhz),
    .dst_rst(~rst_n),
    .dst_busy(engine_busy_uart),
    .dst_done(engine_done_uart),
    .dst_error(engine_error_uart)
);

dpd_stress_engine_hw023 u_engine (
    .clk(clk_dpd),
    .rst(rst_dpd),
    .start_i(run_start_dpd),
    .target_samples_i(target_samples_dpd),
    .busy_o(engine_busy_fast),
    .done_o(engine_done_fast),
    .error_o(engine_error_fast),
    .samples_sent_o(samples_sent_fast),
    .samples_received_o(samples_received_fast),
    .latency_min_o(latency_min_fast),
    .latency_max_o(latency_max_fast),
    .latency_sum_o(latency_sum_fast),
    .total_cycles_o(total_cycles_fast),
    .overflow_events_o(overflow_events_fast),
    .saturation_positive_o(saturation_positive_fast),
    .saturation_negative_o(saturation_negative_fast),
    .coefficient_updates_o(coefficient_updates_fast),
    .high_amplitude_samples_o(high_amplitude_samples_fast),
    .fifo_errors_o(fifo_errors_fast),
    .losses_o(losses_fast),
    .duplicates_o(duplicates_fast),
    .reorder_o(reorder_fast),
    .input_signature_o(input_signature_fast),
    .output_signature_o(output_signature_fast),
    .checkpoint_addr_i(checkpoint_addr),
    .checkpoint_cycle_o(checkpoint_cycle_fast)
);

assign led_busy = (rx_busy | tx_busy | protocol_busy | engine_busy_uart);
assign led_done = (protocol_done | engine_done_uart);
assign led_error = (protocol_error | engine_error_uart | (~pll_lock));

endmodule
