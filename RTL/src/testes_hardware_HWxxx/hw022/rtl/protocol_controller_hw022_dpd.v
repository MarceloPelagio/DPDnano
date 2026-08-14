`timescale 1ns/1ps

module protocol_controller_hw022_dpd (
    input wire clk,
    input wire rst_n,
    input wire [7:0] rx_data_i,
    input wire rx_valid_i,
    input wire rx_frame_error_i,
    input wire tx_busy_i,
    output reg [7:0] tx_data_o,
    output reg tx_start_o,
    output reg run_start_o,
    output reg [2:0] scenario_o,
    output reg [15:0] sample_count_o,
    input wire engine_busy_i,
    input wire engine_done_i,
    input wire engine_error_i,
    input wire overflow_seen_i,
    input wire [15:0] latency_min_i,
    input wire [15:0] latency_max_i,
    input wire [31:0] latency_sum_i,
    input wire [15:0] samples_sent_i,
    input wire [15:0] samples_received_i,
    input wire [15:0] losses_i,
    input wire [15:0] duplicates_i,
    input wire [15:0] reorder_i,
    input wire [31:0] total_cycles_i,
    output reg busy_o,
    output wire done_o,
    output wire error_o
);

localparam [7:0] SOF_REQ = 8'hA5;
localparam [7:0] SOF_RSP = 8'h5A;

localparam [7:0]
    CMD_PING   = 8'h01,
    CMD_RUN    = 8'h50,
    CMD_STATUS = 8'h51,
    CMD_METRIC = 8'h52;

localparam [31:0]
    ERR_UNKNOWN = 32'h000000E1,
    ERR_CSUM    = 32'h000000E2,
    ERR_BUSY    = 32'h000000E5,
    ERR_ARG     = 32'h000000E6;

localparam [3:0]
    ST_SOF  = 4'd0,
    ST_CMD  = 4'd1,
    ST_AH   = 4'd2,
    ST_AL   = 4'd3,
    ST_D3   = 4'd4,
    ST_D2   = 4'd5,
    ST_D1   = 4'd6,
    ST_D0   = 4'd7,
    ST_CS   = 4'd8,
    ST_SEND = 4'd9;

reg [3:0] state;
reg [7:0] cmd_reg;
reg [7:0] ah_reg;
reg [7:0] al_reg;
reg [31:0] data_reg;
reg [7:0] response [0:8];
reg [3:0] tx_index;
reg [24:0] done_count;
reg error_latched;
reg [31:0] selected_metric;

wire [15:0] address = {ah_reg, al_reg};
wire [7:0] request_checksum =
    SOF_REQ ^ cmd_reg ^ ah_reg ^ al_reg ^
    data_reg[31:24] ^ data_reg[23:16] ^
    data_reg[15:8] ^ data_reg[7:0];

assign done_o = (done_count != 0);
assign error_o = error_latched;

always @(*) begin
    case (address[3:0])
        4'd0: selected_metric = {16'd0, latency_min_i};
        4'd1: selected_metric = {16'd0, latency_max_i};
        4'd2: selected_metric = latency_sum_i;
        4'd3: selected_metric = {16'd0, samples_sent_i};
        4'd4: selected_metric = {16'd0, samples_received_i};
        4'd5: selected_metric = {16'd0, losses_i};
        4'd6: selected_metric = {16'd0, duplicates_i};
        4'd7: selected_metric = {16'd0, reorder_i};
        4'd8: selected_metric = total_cycles_i;
        default: selected_metric = 32'hFFFFFFFF;
    endcase
end

task build_response;
    input [7:0] command;
    input [15:0] response_address;
    input [31:0] response_data;
    begin
        response[0] <= SOF_RSP;
        response[1] <= command;
        response[2] <= response_address[15:8];
        response[3] <= response_address[7:0];
        response[4] <= response_data[31:24];
        response[5] <= response_data[23:16];
        response[6] <= response_data[15:8];
        response[7] <= response_data[7:0];
        response[8] <= SOF_RSP ^ command ^
            response_address[15:8] ^ response_address[7:0] ^
            response_data[31:24] ^ response_data[23:16] ^
            response_data[15:8] ^ response_data[7:0];
    end
endtask

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= ST_SOF;
        cmd_reg <= 8'd0;
        ah_reg <= 8'd0;
        al_reg <= 8'd0;
        data_reg <= 32'd0;
        tx_data_o <= 8'd0;
        tx_start_o <= 1'b0;
        tx_index <= 4'd0;
        run_start_o <= 1'b0;
        scenario_o <= 3'd0;
        sample_count_o <= 16'd0;
        busy_o <= 1'b0;
        done_count <= 25'd0;
        error_latched <= 1'b0;
    end else begin
        tx_start_o <= 1'b0;
        run_start_o <= 1'b0;

        if (done_count != 0)
            done_count <= done_count - 1'b1;

        if (rx_frame_error_i)
            error_latched <= 1'b1;

        case (state)
            ST_SOF: begin
                busy_o <= 1'b0;
                if (rx_valid_i && rx_data_i == SOF_REQ) begin
                    busy_o <= 1'b1;
                    state <= ST_CMD;
                end
            end

            ST_CMD: if (rx_valid_i) begin
                cmd_reg <= rx_data_i;
                state <= ST_AH;
            end

            ST_AH: if (rx_valid_i) begin
                ah_reg <= rx_data_i;
                state <= ST_AL;
            end

            ST_AL: if (rx_valid_i) begin
                al_reg <= rx_data_i;
                state <= ST_D3;
            end

            ST_D3: if (rx_valid_i) begin
                data_reg[31:24] <= rx_data_i;
                state <= ST_D2;
            end

            ST_D2: if (rx_valid_i) begin
                data_reg[23:16] <= rx_data_i;
                state <= ST_D1;
            end

            ST_D1: if (rx_valid_i) begin
                data_reg[15:8] <= rx_data_i;
                state <= ST_D0;
            end

            ST_D0: if (rx_valid_i) begin
                data_reg[7:0] <= rx_data_i;
                state <= ST_CS;
            end

            ST_CS: if (rx_valid_i) begin
                if (rx_data_i != request_checksum) begin
                    build_response(cmd_reg, address, ERR_CSUM);
                    error_latched <= 1'b1;
                end else begin
                    case (cmd_reg)
                        CMD_PING: begin
                            build_response(CMD_PING, address, 32'd0);
                        end

                        CMD_RUN: begin
                            if (engine_busy_i) begin
                                build_response(CMD_RUN, address, ERR_BUSY);
                            end else if (data_reg[18:16] > 5 || data_reg[15:0] == 0 || data_reg[15:0] > 256) begin
                                build_response(CMD_RUN, address, ERR_ARG);
                            end else begin
                                scenario_o <= data_reg[18:16];
                                sample_count_o <= data_reg[15:0];
                                run_start_o <= 1'b1;
                                build_response(CMD_RUN, address, data_reg);
                            end
                        end

                        CMD_STATUS: begin
                            build_response(
                                CMD_STATUS,
                                address,
                                {26'd0, overflow_seen_i, engine_error_i, engine_done_i, engine_busy_i, 2'd0}
                            );
                        end

                        CMD_METRIC: begin
                            build_response(CMD_METRIC, address, selected_metric);
                        end

                        default: begin
                            build_response(cmd_reg, address, ERR_UNKNOWN);
                            error_latched <= 1'b1;
                        end
                    endcase
                end

                tx_index <= 4'd0;
                state <= ST_SEND;
            end

            ST_SEND: begin
                if (!tx_busy_i && !tx_start_o) begin
                    tx_data_o <= response[tx_index];
                    tx_start_o <= 1'b1;

                    if (tx_index == 8) begin
                        tx_index <= 4'd0;
                        busy_o <= 1'b0;
                        done_count <= 25'd8100000;
                        state <= ST_SOF;
                    end else begin
                        tx_index <= tx_index + 1'b1;
                    end
                end
            end

            default: state <= ST_SOF;
        endcase
    end
end

endmodule
