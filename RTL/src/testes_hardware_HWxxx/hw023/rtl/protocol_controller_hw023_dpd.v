`timescale 1ns/1ps

module protocol_controller_hw023_dpd (
    input wire clk,
    input wire rst_n,
    input wire [7:0] rx_data_i,
    input wire rx_valid_i,
    input wire rx_frame_error_i,
    input wire tx_busy_i,
    output reg [7:0] tx_data_o,
    output reg tx_start_o,
    output reg run_start_o,
    output reg [31:0] target_samples_o,
    input wire engine_busy_i,
    input wire engine_done_i,
    input wire engine_error_i,
    input wire [31:0] samples_sent_i,
    input wire [31:0] samples_received_i,
    input wire [15:0] latency_min_i,
    input wire [15:0] latency_max_i,
    input wire [31:0] latency_sum_i,
    input wire [31:0] total_cycles_i,
    input wire [31:0] overflow_events_i,
    input wire [31:0] saturation_positive_i,
    input wire [31:0] saturation_negative_i,
    input wire [31:0] coefficient_updates_i,
    input wire [31:0] high_amplitude_samples_i,
    input wire [31:0] fifo_errors_i,
    input wire [31:0] losses_i,
    input wire [31:0] duplicates_i,
    input wire [31:0] reorder_i,
    input wire [31:0] input_signature_i,
    input wire [31:0] output_signature_i,
    output wire [3:0] checkpoint_addr_o,
    input wire [31:0] checkpoint_cycle_i,
    output reg busy_o,
    output wire done_o,
    output wire error_o
);

localparam [7:0] SOF_REQ = 8'hA5;
localparam [7:0] SOF_RSP = 8'h5A;
localparam [7:0] CMD_PING = 8'h01, CMD_RUN = 8'h60, CMD_STATUS = 8'h61, CMD_METRIC = 8'h62, CMD_CHECKPOINT = 8'h63;
localparam [31:0] ERR_UNKNOWN = 32'h000000E1, ERR_CSUM = 32'h000000E2, ERR_BUSY = 32'h000000E5, ERR_ARG = 32'h000000E6;
localparam [3:0] ST_SOF = 4'd0, ST_CMD = 4'd1, ST_AH = 4'd2, ST_AL = 4'd3, ST_D3 = 4'd4, ST_D2 = 4'd5, ST_D1 = 4'd6, ST_D0 = 4'd7, ST_CS = 4'd8, ST_SEND = 4'd9;

reg [3:0] state;
reg [7:0] cmd_reg, ah_reg, al_reg;
reg [31:0] data_reg;
reg [7:0] response [0:8];
reg [3:0] tx_index;
reg [24:0] done_count;
reg error_latched;
reg [31:0] selected_metric;

wire [15:0] address = {ah_reg, al_reg};
wire [7:0] request_checksum = SOF_REQ ^ cmd_reg ^ ah_reg ^ al_reg ^ data_reg[31:24] ^ data_reg[23:16] ^ data_reg[15:8] ^ data_reg[7:0];

assign done_o = (done_count != 0);
assign error_o = error_latched;
assign checkpoint_addr_o = address[3:0];

always @(*) begin
    case (address[4:0])
        5'd0: selected_metric = samples_sent_i;
        5'd1: selected_metric = samples_received_i;
        5'd2: selected_metric = {16'd0, latency_min_i};
        5'd3: selected_metric = {16'd0, latency_max_i};
        5'd4: selected_metric = latency_sum_i;
        5'd5: selected_metric = total_cycles_i;
        5'd6: selected_metric = overflow_events_i;
        5'd7: selected_metric = saturation_positive_i;
        5'd8: selected_metric = saturation_negative_i;
        5'd9: selected_metric = coefficient_updates_i;
        5'd10: selected_metric = high_amplitude_samples_i;
        5'd11: selected_metric = fifo_errors_i;
        5'd12: selected_metric = losses_i;
        5'd13: selected_metric = duplicates_i;
        5'd14: selected_metric = reorder_i;
        5'd15: selected_metric = input_signature_i;
        5'd16: selected_metric = output_signature_i;
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
        response[8] <= SOF_RSP ^ command ^ response_address[15:8] ^ response_address[7:0] ^ response_data[31:24] ^ response_data[23:16] ^ response_data[15:8] ^ response_data[7:0];
    end
endtask

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= ST_SOF;
        cmd_reg <= 8'd0; ah_reg <= 8'd0; al_reg <= 8'd0; data_reg <= 32'd0;
        tx_data_o <= 8'd0; tx_start_o <= 1'b0; tx_index <= 4'd0;
        run_start_o <= 1'b0; target_samples_o <= 32'd0;
        busy_o <= 1'b0; done_count <= 25'd0; error_latched <= 1'b0;
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
                if (rx_valid_i && rx_data_i == SOF_REQ) begin busy_o <= 1'b1; state <= ST_CMD; end
            end
            ST_CMD: if (rx_valid_i) begin cmd_reg <= rx_data_i; state <= ST_AH; end
            ST_AH: if (rx_valid_i) begin ah_reg <= rx_data_i; state <= ST_AL; end
            ST_AL: if (rx_valid_i) begin al_reg <= rx_data_i; state <= ST_D3; end
            ST_D3: if (rx_valid_i) begin data_reg[31:24] <= rx_data_i; state <= ST_D2; end
            ST_D2: if (rx_valid_i) begin data_reg[23:16] <= rx_data_i; state <= ST_D1; end
            ST_D1: if (rx_valid_i) begin data_reg[15:8] <= rx_data_i; state <= ST_D0; end
            ST_D0: if (rx_valid_i) begin data_reg[7:0] <= rx_data_i; state <= ST_CS; end
            ST_CS: if (rx_valid_i) begin
                if (rx_data_i != request_checksum) begin
                    build_response(cmd_reg, address, ERR_CSUM);
                    error_latched <= 1'b1;
                end else begin
                    case (cmd_reg)
                        CMD_PING: build_response(CMD_PING, address, 32'd0);
                        CMD_RUN: begin
                            if (engine_busy_i)
                                build_response(CMD_RUN, address, ERR_BUSY);
                            else if (data_reg == 0 || data_reg > 32'd1000000)
                                build_response(CMD_RUN, address, ERR_ARG);
                            else begin
                                target_samples_o <= data_reg;
                                run_start_o <= 1'b1;
                                build_response(CMD_RUN, address, data_reg);
                            end
                        end
                        CMD_STATUS: build_response(CMD_STATUS, address, {28'd0, engine_error_i, engine_done_i, engine_busy_i, 1'b0});
                        CMD_METRIC: build_response(CMD_METRIC, address, selected_metric);
                        CMD_CHECKPOINT: build_response(CMD_CHECKPOINT, address, checkpoint_cycle_i);
                        default: begin build_response(cmd_reg, address, ERR_UNKNOWN); error_latched <= 1'b1; end
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
                    end else
                        tx_index <= tx_index + 1'b1;
                end
            end
            default: state <= ST_SOF;
        endcase
    end
end

endmodule
