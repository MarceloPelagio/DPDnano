`timescale 1ns/1ps

/******************************************************************************
* Project : DPDnano_Lite_v3_2
* Test    : HW006 - Input Memory
*
* UART:
*   115200 baud, 8N1
*
* Memory:
*   256 words x 32 bits
*   [31:16] = I sample
*   [15:0]  = Q sample
*
* LEDs adjusted for the current bench wiring.
******************************************************************************/

module dpdnano_hw006_input_memory_top (
    input  wire clk_27mhz,
    input  wire rst_n,
    input  wire uart_rx_i,
    output wire uart_tx_o,
    output wire led_busy,
    output wire led_done,
    output wire led_error
);

wire [7:0] rx_data;
wire       rx_valid;
wire       rx_busy;
wire       rx_frame_error;

wire [7:0] tx_data;
wire       tx_start;
wire       tx_busy;

wire protocol_busy;
wire protocol_done;
wire protocol_error;

uart_rx_27m_115200 u_rx (
    .clk          (clk_27mhz),
    .rst_n        (rst_n),
    .rx_i         (uart_rx_i),
    .data_o       (rx_data),
    .data_valid_o (rx_valid),
    .busy_o       (rx_busy),
    .frame_error_o(rx_frame_error)
);

uart_tx_27m_115200 u_tx (
    .clk    (clk_27mhz),
    .rst_n  (rst_n),
    .start_i(tx_start),
    .data_i (tx_data),
    .tx_o   (uart_tx_o),
    .busy_o (tx_busy)
);

protocol_hw006 u_protocol (
    .clk             (clk_27mhz),
    .rst_n           (rst_n),
    .rx_data_i       (rx_data),
    .rx_valid_i      (rx_valid),
    .rx_frame_error_i(rx_frame_error),
    .tx_busy_i       (tx_busy),
    .tx_data_o       (tx_data),
    .tx_start_o      (tx_start),
    .busy_o          (protocol_busy),
    .done_o          (protocol_done),
    .error_o         (protocol_error)
);

assign led_busy  = (rx_busy | tx_busy | protocol_busy);
assign led_done  = protocol_done;
assign led_error = protocol_error;

endmodule
