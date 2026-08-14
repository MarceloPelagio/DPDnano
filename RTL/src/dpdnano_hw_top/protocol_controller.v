`timescale 1ns/1ps
module protocol_controller #(
    parameter ADDR_WIDTH = 10
)(
    input  wire                  clk,
    input  wire                  rst,

    input  wire [7:0]            rx_fifo_data,
    input  wire                  rx_fifo_empty,
    output reg                   rx_fifo_rd_en,

    output reg  [7:0]            tx_fifo_data,
    input  wire                  tx_fifo_full,
    output reg                   tx_fifo_wr_en,

    output reg                   input_wr_en,
    output reg [ADDR_WIDTH-1:0]  input_wr_addr,
    output reg [31:0]            input_wr_data,

    output reg                   dpd_start,
    output reg [ADDR_WIDTH:0]    sample_count,
    input  wire                  dpd_busy,
    input  wire                  dpd_done,

    input  wire [31:0]           cycle_count,
    input  wire [31:0]           samples_processed,
    input  wire [31:0]           overflow_count,

    output reg [ADDR_WIDTH-1:0]  output_rd_addr,
    input  wire [39:0]           output_rd_data,

    output reg                   protocol_error
);
localparam [7:0]
    CMD_PING   = 8'h50,
    CMD_RESET  = 8'h52,
    CMD_LOAD   = 8'h4C,
    CMD_START  = 8'h53,
    CMD_STATUS = 8'h54,
    CMD_READ   = 8'h44;

localparam [4:0]
    ST_IDLE=0,
    ST_LOAD_N0=1,
    ST_LOAD_N1=2,
    ST_LOAD_B0=3,
    ST_LOAD_B1=4,
    ST_LOAD_B2=5,
    ST_LOAD_B3=6,
    ST_READ_WAIT0=7,
    ST_READ_WAIT1=8,
    ST_READ_SEND=9,
    ST_STATUS_SEND=10,
    ST_FETCH=11;

reg [4:0] state;
reg [4:0] return_state;
reg [31:0] sample_shift;
reg [ADDR_WIDTH:0] load_count;
reg [ADDR_WIDTH:0] read_count;
reg [2:0] tx_index;
reg [39:0] output_latch;
reg [7:0] current_byte;
reg [7:0] status_bytes [0:12];

task request_rx_byte;
    input [4:0] next_state;
    begin
        if (!rx_fifo_empty) begin
            rx_fifo_rd_en <= 1'b1;
            return_state <= next_state;
            state <= ST_FETCH;
        end
    end
endtask

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state          <= ST_IDLE;
        return_state   <= ST_IDLE;
        rx_fifo_rd_en  <= 0;
        tx_fifo_data   <= 0;
        tx_fifo_wr_en  <= 0;
        input_wr_en    <= 0;
        input_wr_addr  <= 0;
        input_wr_data  <= 0;
        dpd_start      <= 0;
        sample_count   <= 0;
        output_rd_addr <= 0;
        protocol_error <= 0;
        sample_shift   <= 0;
        load_count     <= 0;
        read_count     <= 0;
        tx_index       <= 0;
        output_latch   <= 0;
        current_byte   <= 0;
    end else begin
        rx_fifo_rd_en <= 1'b0;
        tx_fifo_wr_en <= 1'b0;
        input_wr_en   <= 1'b0;
        dpd_start     <= 1'b0;

        case (state)
            ST_IDLE: begin
                if (!rx_fifo_empty)
                    request_rx_byte(ST_IDLE);
            end

            ST_FETCH: begin
                current_byte <= rx_fifo_data;
                state <= return_state;

                if (return_state == ST_IDLE) begin
                    case (rx_fifo_data)
                        CMD_PING: begin
                            if (!tx_fifo_full) begin
                                tx_fifo_data  <= 8'h4B;
                                tx_fifo_wr_en <= 1'b1;
                            end
                        end

                        CMD_RESET: begin
                            sample_count   <= 0;
                            protocol_error <= 0;
                            if (!tx_fifo_full) begin
                                tx_fifo_data  <= 8'h4B;
                                tx_fifo_wr_en <= 1'b1;
                            end
                        end

                        CMD_LOAD: state <= ST_LOAD_N0;

                        CMD_START: begin
                            if (!dpd_busy && sample_count != 0) begin
                                dpd_start <= 1'b1;
                                if (!tx_fifo_full) begin
                                    tx_fifo_data  <= 8'h4B;
                                    tx_fifo_wr_en <= 1'b1;
                                end
                            end else begin
                                protocol_error <= 1'b1;
                                if (!tx_fifo_full) begin
                                    tx_fifo_data  <= 8'h45;
                                    tx_fifo_wr_en <= 1'b1;
                                end
                            end
                        end

                        CMD_STATUS: begin
                            status_bytes[0]  <= {5'd0,protocol_error,dpd_done,dpd_busy};
                            status_bytes[1]  <= samples_processed[7:0];
                            status_bytes[2]  <= samples_processed[15:8];
                            status_bytes[3]  <= samples_processed[23:16];
                            status_bytes[4]  <= samples_processed[31:24];
                            status_bytes[5]  <= cycle_count[7:0];
                            status_bytes[6]  <= cycle_count[15:8];
                            status_bytes[7]  <= cycle_count[23:16];
                            status_bytes[8]  <= cycle_count[31:24];
                            status_bytes[9]  <= overflow_count[7:0];
                            status_bytes[10] <= overflow_count[15:8];
                            status_bytes[11] <= overflow_count[23:16];
                            status_bytes[12] <= overflow_count[31:24];
                            tx_index <= 0;
                            state <= ST_STATUS_SEND;
                        end

                        CMD_READ: begin
                            read_count <= 0;
                            output_rd_addr <= 0;
                            state <= ST_READ_WAIT0;
                        end

                        default: begin
                            protocol_error <= 1'b1;
                            if (!tx_fifo_full) begin
                                tx_fifo_data  <= 8'h45;
                                tx_fifo_wr_en <= 1'b1;
                            end
                        end
                    endcase
                end
            end

            ST_LOAD_N0: begin
                if (!rx_fifo_empty)
                    request_rx_byte(ST_LOAD_N1);
            end

            ST_LOAD_N1: begin
                sample_count[7:0] <= current_byte;
                if (!rx_fifo_empty)
                    request_rx_byte(ST_LOAD_B0);
            end

            ST_LOAD_B0: begin
                sample_count[ADDR_WIDTH:8] <= current_byte[ADDR_WIDTH-8:0];
                load_count <= 0;
                input_wr_addr <= 0;
                if (!rx_fifo_empty)
                    request_rx_byte(ST_LOAD_B1);
            end

            ST_LOAD_B1: begin
                sample_shift[7:0] <= current_byte;
                if (!rx_fifo_empty)
                    request_rx_byte(ST_LOAD_B2);
            end

            ST_LOAD_B2: begin
                sample_shift[15:8] <= current_byte;
                if (!rx_fifo_empty)
                    request_rx_byte(ST_LOAD_B3);
            end

            ST_LOAD_B3: begin
                sample_shift[23:16] <= current_byte;
                if (!rx_fifo_empty)
                    request_rx_byte(ST_READ_WAIT0);
            end

            ST_READ_WAIT0: begin
                if (return_state == ST_READ_WAIT0) begin
                    input_wr_data <= {current_byte, sample_shift[23:0]};
                    input_wr_addr <= load_count[ADDR_WIDTH-1:0];
                    input_wr_en   <= 1'b1;
                    load_count    <= load_count + 1'b1;

                    if (load_count + 1'b1 >= sample_count) begin
                        if (!tx_fifo_full) begin
                            tx_fifo_data  <= 8'h4B;
                            tx_fifo_wr_en <= 1'b1;
                            state <= ST_IDLE;
                        end
                    end else begin
                        if (!rx_fifo_empty)
                            request_rx_byte(ST_LOAD_B1);
                    end
                end else begin
                    state <= ST_READ_WAIT1;
                end
            end

            ST_READ_WAIT1: begin
                output_latch <= output_rd_data;
                tx_index <= 0;
                state <= ST_READ_SEND;
            end

            ST_READ_SEND: begin
                if (!tx_fifo_full) begin
                    case (tx_index)
                        3'd0: tx_fifo_data <= output_latch[7:0];
                        3'd1: tx_fifo_data <= output_latch[15:8];
                        3'd2: tx_fifo_data <= output_latch[23:16];
                        3'd3: tx_fifo_data <= output_latch[31:24];
                        default: tx_fifo_data <= output_latch[39:32];
                    endcase
                    tx_fifo_wr_en <= 1'b1;

                    if (tx_index == 3'd4) begin
                        if (read_count + 1'b1 >= sample_count) begin
                            state <= ST_IDLE;
                        end else begin
                            read_count <= read_count + 1'b1;
                            output_rd_addr <= output_rd_addr + 1'b1;
                            state <= ST_READ_WAIT0;
                            return_state <= ST_IDLE;
                        end
                    end else begin
                        tx_index <= tx_index + 1'b1;
                    end
                end
            end

            ST_STATUS_SEND: begin
                if (!tx_fifo_full) begin
                    tx_fifo_data  <= status_bytes[tx_index];
                    tx_fifo_wr_en <= 1'b1;
                    if (tx_index == 12)
                        state <= ST_IDLE;
                    else
                        tx_index <= tx_index + 1'b1;
                end
            end

            default: state <= ST_IDLE;
        endcase
    end
end
endmodule
