`timescale 1ns/1ps
module dpdnano_hw001_uart_ping_top(
    input  wire clk_27mhz,
    input  wire rst_n,
    input  wire uart_rx_i,
    output wire uart_tx_o,
    output wire led_busy,
    output wire led_done,
    output wire led_error
);

localparam [7:0] CMD_PING = 8'h50;
localparam [7:0] RSP_PONG = 8'h4B;

wire [7:0] rx_data;
wire rx_valid, rx_busy, rx_frame_error;
reg  [7:0] tx_data;
reg  tx_start;
wire tx_busy;
reg [24:0] done_counter;
reg error_latched;

uart_rx_27m_115200 u_rx(
    .clk(clk_27mhz), .rst_n(rst_n), .rx_i(uart_rx_i),
    .data_o(rx_data), .data_valid_o(rx_valid),
    .busy_o(rx_busy), .frame_error_o(rx_frame_error)
);

uart_tx_27m_115200 u_tx(
    .clk(clk_27mhz), .rst_n(rst_n), .start_i(tx_start),
    .data_i(tx_data), .tx_o(uart_tx_o), .busy_o(tx_busy)
);

always @(posedge clk_27mhz or negedge rst_n) begin
    if(!rst_n) begin
        tx_data <= 8'h00;
        tx_start <= 1'b0;
    end else begin
        tx_start <= 1'b0;
        if(rx_valid && !tx_busy && rx_data == CMD_PING) begin
            tx_data <= RSP_PONG;
            tx_start <= 1'b1;
        end
    end
end

always @(posedge clk_27mhz or negedge rst_n) begin
    if(!rst_n)
        done_counter <= 25'd0;
    else if(rx_valid && rx_data == CMD_PING)
        done_counter <= 25'd8100000;
    else if(done_counter != 0)
        done_counter <= done_counter - 1'b1;
end

always @(posedge clk_27mhz or negedge rst_n) begin
    if(!rst_n)
        error_latched <= 1'b0;
    else if(rx_frame_error || (rx_valid && rx_data != CMD_PING))
        error_latched <= 1'b1;
end

assign led_busy  = (rx_busy | tx_busy);
assign led_done  = (done_counter != 0);
assign led_error = error_latched;

endmodule
