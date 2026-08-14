`timescale 1ns/1ps
module uart_rx #(
    parameter CLK_FREQ_HZ = 27000000,
    parameter BAUD_RATE   = 921600
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] data_out,
    output reg        data_valid,
    output reg        framing_error
);
localparam integer CLKS_PER_BIT = CLK_FREQ_HZ / BAUD_RATE;
localparam [2:0] ST_IDLE=0, ST_START=1, ST_DATA=2, ST_STOP=3, ST_DONE=4;

reg [2:0]  state;
reg [31:0] clk_count;
reg [2:0]  bit_index;
reg [7:0]  shift;
reg        rx_meta;
reg        rx_sync;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        rx_meta <= 1'b1;
        rx_sync <= 1'b1;
    end else begin
        rx_meta <= rx;
        rx_sync <= rx_meta;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state         <= ST_IDLE;
        clk_count     <= 0;
        bit_index     <= 0;
        shift         <= 0;
        data_out      <= 0;
        data_valid    <= 1'b0;
        framing_error <= 1'b0;
    end else begin
        data_valid    <= 1'b0;
        framing_error <= 1'b0;

        case (state)
            ST_IDLE: begin
                clk_count <= 0;
                bit_index <= 0;
                if (!rx_sync)
                    state <= ST_START;
            end

            ST_START: begin
                if (clk_count == (CLKS_PER_BIT/2)-1) begin
                    clk_count <= 0;
                    state <= (!rx_sync) ? ST_DATA : ST_IDLE;
                end else begin
                    clk_count <= clk_count + 1'b1;
                end
            end

            ST_DATA: begin
                if (clk_count == CLKS_PER_BIT-1) begin
                    clk_count <= 0;
                    shift[bit_index] <= rx_sync;
                    if (bit_index == 3'd7) begin
                        bit_index <= 0;
                        state <= ST_STOP;
                    end else begin
                        bit_index <= bit_index + 1'b1;
                    end
                end else begin
                    clk_count <= clk_count + 1'b1;
                end
            end

            ST_STOP: begin
                if (clk_count == CLKS_PER_BIT-1) begin
                    clk_count <= 0;
                    framing_error <= ~rx_sync;
                    state <= ST_DONE;
                end else begin
                    clk_count <= clk_count + 1'b1;
                end
            end

            ST_DONE: begin
                data_out   <= shift;
                data_valid <= 1'b1;
                state      <= ST_IDLE;
            end

            default: state <= ST_IDLE;
        endcase
    end
end
endmodule
