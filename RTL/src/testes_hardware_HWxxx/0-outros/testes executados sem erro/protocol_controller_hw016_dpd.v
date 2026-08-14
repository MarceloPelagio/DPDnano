`timescale 1ns/1ps

/******************************************************************************
* HW016_dpd vr02 protocol
*
* Frame:
*   A5 CMD AH AL D3 D2 D1 D0 CS
*
* Commands:
*   0x01 PING
*   0x20 WRITE INPUT
*   0x31 READ OUTPUT
*   0x40 START DPD
*   0x41 STATUS
*   0x42 SELECT PROFILE
*
* SELECT PROFILE:
*   data[1:0]:
*     0 = A
*     1 = B
*     2 = C
*     3 = D
******************************************************************************/

module protocol_controller_hw016_dpd (
    input wire clk,
    input wire rst_n,

    input wire [7:0] rx_data_i,
    input wire rx_valid_i,
    input wire rx_frame_error_i,

    input wire tx_busy_i,
    output reg [7:0] tx_data_o,
    output reg tx_start_o,

    output reg in_wr_en_o,
    output reg [7:0] in_wr_addr_o,
    output reg [31:0] in_wr_data_o,

    output reg out_rd_en_o,
    output reg [7:0] out_rd_addr_o,
    input wire [31:0] out_rd_data_i,
    input wire out_rd_valid_i,

    output reg dpd_start_o,
    output reg [7:0] dpd_start_addr_o,
    output reg [8:0] dpd_count_o,

    input wire dpd_busy_i,
    input wire dpd_done_i,
    input wire dpd_error_i,
    input wire dpd_overflow_i,

    output reg [1:0] profile_o,

    output reg busy_o,
    output wire done_o,
    output wire error_o
);

localparam [7:0] SOF_REQ=8'hA5, SOF_RSP=8'h5A;

localparam [7:0]
    CMD_PING       = 8'h01,
    CMD_WRITE_IN   = 8'h20,
    CMD_READ_OUT   = 8'h31,
    CMD_START_DPD  = 8'h40,
    CMD_STATUS     = 8'h41,
    CMD_PROFILE    = 8'h42;

localparam [31:0]
    ERR_UNKNOWN = 32'h000000E1,
    ERR_CSUM    = 32'h000000E2,
    ERR_ADDR    = 32'h000000E3,
    ERR_COUNT   = 32'h000000E4,
    ERR_BUSY    = 32'h000000E5,
    ERR_PROFILE = 32'h000000E6;

localparam [3:0]
    ST_WAIT_SOF = 4'd0,
    ST_GET_CMD  = 4'd1,
    ST_GET_AH   = 4'd2,
    ST_GET_AL   = 4'd3,
    ST_GET_D3   = 4'd4,
    ST_GET_D2   = 4'd5,
    ST_GET_D1   = 4'd6,
    ST_GET_D0   = 4'd7,
    ST_GET_CSUM = 4'd8,
    ST_READ_OUT = 4'd9,
    ST_SEND     = 4'd10;

reg [3:0] state;
reg [7:0] cmd_reg, ah_reg, al_reg;
reg [31:0] data_reg;

reg [7:0] response [0:8];
reg [3:0] tx_index;

reg [24:0] done_count;
reg error_latched;

wire [15:0] address = {ah_reg, al_reg};

wire [7:0] request_checksum =
    SOF_REQ ^ cmd_reg ^ ah_reg ^ al_reg ^
    data_reg[31:24] ^ data_reg[23:16] ^
    data_reg[15:8] ^ data_reg[7:0];

assign done_o  = (done_count != 0);
assign error_o = error_latched;

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
                       response_address[15:8] ^
                       response_address[7:0] ^
                       response_data[31:24] ^
                       response_data[23:16] ^
                       response_data[15:8] ^
                       response_data[7:0];
    end
endtask

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= ST_WAIT_SOF;
        cmd_reg <= 0;
        ah_reg <= 0;
        al_reg <= 0;
        data_reg <= 0;

        tx_data_o <= 0;
        tx_start_o <= 0;
        tx_index <= 0;

        in_wr_en_o <= 0;
        in_wr_addr_o <= 0;
        in_wr_data_o <= 0;

        out_rd_en_o <= 0;
        out_rd_addr_o <= 0;

        dpd_start_o <= 0;
        dpd_start_addr_o <= 0;
        dpd_count_o <= 0;

        profile_o <= 2'd0;

        busy_o <= 0;
        done_count <= 0;
        error_latched <= 0;
    end else begin
        tx_start_o <= 0;
        in_wr_en_o <= 0;
        out_rd_en_o <= 0;
        dpd_start_o <= 0;

        if (done_count != 0)
            done_count <= done_count - 1'b1;

        if (rx_frame_error_i)
            error_latched <= 1'b1;

        case (state)
            ST_WAIT_SOF: begin
                busy_o <= 0;

                if (rx_valid_i && rx_data_i == SOF_REQ) begin
                    busy_o <= 1;
                    state <= ST_GET_CMD;
                end
            end

            ST_GET_CMD: if (rx_valid_i) begin
                cmd_reg <= rx_data_i;
                state <= ST_GET_AH;
            end

            ST_GET_AH: if (rx_valid_i) begin
                ah_reg <= rx_data_i;
                state <= ST_GET_AL;
            end

            ST_GET_AL: if (rx_valid_i) begin
                al_reg <= rx_data_i;
                state <= ST_GET_D3;
            end

            ST_GET_D3: if (rx_valid_i) begin
                data_reg[31:24] <= rx_data_i;
                state <= ST_GET_D2;
            end

            ST_GET_D2: if (rx_valid_i) begin
                data_reg[23:16] <= rx_data_i;
                state <= ST_GET_D1;
            end

            ST_GET_D1: if (rx_valid_i) begin
                data_reg[15:8] <= rx_data_i;
                state <= ST_GET_D0;
            end

            ST_GET_D0: if (rx_valid_i) begin
                data_reg[7:0] <= rx_data_i;
                state <= ST_GET_CSUM;
            end

            ST_GET_CSUM: if (rx_valid_i) begin
                if (rx_data_i != request_checksum) begin
                    build_response(cmd_reg, address, ERR_CSUM);
                    error_latched <= 1;
                    tx_index <= 0;
                    state <= ST_SEND;
                end else begin
                    case (cmd_reg)
                        CMD_PING: begin
                            build_response(CMD_PING, address, 32'd0);
                            tx_index <= 0;
                            state <= ST_SEND;
                        end

                        CMD_WRITE_IN: begin
                            if (dpd_busy_i) begin
                                build_response(CMD_WRITE_IN, address, ERR_BUSY);
                                error_latched <= 1;
                            end else if (address >= 256) begin
                                build_response(CMD_WRITE_IN, address, ERR_ADDR);
                                error_latched <= 1;
                            end else begin
                                in_wr_en_o <= 1;
                                in_wr_addr_o <= address[7:0];
                                in_wr_data_o <= data_reg;
                                build_response(CMD_WRITE_IN, address, 32'd0);
                            end
                            tx_index <= 0;
                            state <= ST_SEND;
                        end

                        CMD_READ_OUT: begin
                            if (dpd_busy_i) begin
                                build_response(CMD_READ_OUT, address, ERR_BUSY);
                                error_latched <= 1;
                                tx_index <= 0;
                                state <= ST_SEND;
                            end else if (address >= 256) begin
                                build_response(CMD_READ_OUT, address, ERR_ADDR);
                                error_latched <= 1;
                                tx_index <= 0;
                                state <= ST_SEND;
                            end else begin
                                out_rd_en_o <= 1;
                                out_rd_addr_o <= address[7:0];
                                state <= ST_READ_OUT;
                            end
                        end

                        CMD_START_DPD: begin
                            if (dpd_busy_i) begin
                                build_response(CMD_START_DPD, address, ERR_BUSY);
                                error_latched <= 1;
                            end else if (
                                data_reg[8:0] == 0 ||
                                data_reg[8:0] > 256 ||
                                address + data_reg[8:0] > 256
                            ) begin
                                build_response(CMD_START_DPD, address, ERR_COUNT);
                                error_latched <= 1;
                            end else begin
                                dpd_start_addr_o <= address[7:0];
                                dpd_count_o <= data_reg[8:0];
                                dpd_start_o <= 1;
                                build_response(
                                    CMD_START_DPD,
                                    address,
                                    {23'd0, data_reg[8:0]}
                                );
                            end
                            tx_index <= 0;
                            state <= ST_SEND;
                        end

                        CMD_STATUS: begin
                            build_response(
                                CMD_STATUS,
                                address,
                                {
                                    26'd0,
                                    profile_o,
                                    dpd_overflow_i,
                                    dpd_error_i,
                                    dpd_done_i,
                                    dpd_busy_i
                                }
                            );
                            tx_index <= 0;
                            state <= ST_SEND;
                        end

                        CMD_PROFILE: begin
                            if (dpd_busy_i) begin
                                build_response(CMD_PROFILE, address, ERR_BUSY);
                                error_latched <= 1;
                            end else if (data_reg > 3) begin
                                build_response(CMD_PROFILE, address, ERR_PROFILE);
                                error_latched <= 1;
                            end else begin
                                profile_o <= data_reg[1:0];
                                build_response(
                                    CMD_PROFILE,
                                    address,
                                    {30'd0, data_reg[1:0]}
                                );
                            end
                            tx_index <= 0;
                            state <= ST_SEND;
                        end

                        default: begin
                            build_response(cmd_reg, address, ERR_UNKNOWN);
                            error_latched <= 1;
                            tx_index <= 0;
                            state <= ST_SEND;
                        end
                    endcase
                end
            end

            ST_READ_OUT: begin
                if (out_rd_valid_i) begin
                    build_response(
                        CMD_READ_OUT,
                        address,
                        out_rd_data_i
                    );
                    tx_index <= 0;
                    state <= ST_SEND;
                end
            end

            ST_SEND: begin
                if (!tx_busy_i && !tx_start_o) begin
                    tx_data_o <= response[tx_index];
                    tx_start_o <= 1;

                    if (tx_index == 8) begin
                        tx_index <= 0;
                        busy_o <= 0;
                        done_count <= 25'd8100000;
                        state <= ST_WAIT_SOF;
                    end else begin
                        tx_index <= tx_index + 1'b1;
                    end
                end
            end

            default: state <= ST_WAIT_SOF;
        endcase
    end
end

endmodule
