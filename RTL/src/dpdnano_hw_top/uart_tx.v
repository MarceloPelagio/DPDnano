`timescale 1ns/1ps
module uart_tx #(
    parameter CLK_FREQ_HZ = 27000000,
    parameter BAUD_RATE   = 921600
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] data_in,
    input  wire       data_valid,
    output reg        tx,
    output reg        busy
);
localparam integer CLKS_PER_BIT = CLK_FREQ_HZ / BAUD_RATE;
localparam [2:0] ST_IDLE=0, ST_START=1, ST_DATA=2, ST_STOP=3;

reg [2:0]  state;
reg [31:0] clk_count;
reg [2:0]  bit_index;
reg [7:0]  shift;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state     <= ST_IDLE;
        clk_count <= 0;
        bit_index <= 0;
        shift     <= 0;
        tx        <= 1'b1;
        busy      <= 1'b0;
    end else begin
        case (state)
            ST_IDLE: begin
                tx        <= 1'b1;
                busy      <= 1'b0;
                clk_count <= 0;
                bit_index <= 0;
                if (data_valid) begin
                    shift <= data_in;
                    busy  <= 1'b1;
                    state <= ST_START;
                end
            end

            ST_START: begin
                tx <= 1'b0;
                if (clk_count == CLKS_PER_BIT-1) begin
                    clk_count <= 0;
                    state <= ST_DATA;
                end else begin
                    clk_count <= clk_count + 1'b1;
                end
            end

            ST_DATA: begin
                tx <= shift[bit_index];
                if (clk_count == CLKS_PER_BIT-1) begin
                    clk_count <= 0;
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
                tx <= 1'b1;
                if (clk_count == CLKS_PER_BIT-1) begin
                    clk_count <= 0;
                    busy <= 1'b0;
                    state <= ST_IDLE;
                end else begin
                    clk_count <= clk_count + 1'b1;
                end
            end

            default: state <= ST_IDLE;
        endcase
    end
end
endmodule
