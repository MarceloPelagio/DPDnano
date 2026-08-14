`timescale 1ns/1ps

/******************************************************************************
* HW005 - Banco de registradores
*
* Requisição (5 bytes):
*   [0] 0xA5
*   [1] comando
*   [2] endereço
*   [3] dado
*   [4] checksum = XOR dos bytes 0..3
*
* Resposta (5 bytes):
*   [0] 0x5A
*   [1] comando
*   [2] endereço
*   [3] status/dado
*   [4] checksum = XOR dos bytes 0..3
*
* Comandos:
*   0x01 PING
*   0x02 VERSION
*   0x10 WRITE_REGISTER
*   0x11 READ_REGISTER
*
* Registradores:
*   0x00..0x07: leitura/escrita, 8 bits
*
* Erros:
*   0xE1 comando desconhecido
*   0xE2 checksum inválido
*   0xE3 endereço inválido
******************************************************************************/

module protocol_hw005(
    input  wire       clk,
    input  wire       rst_n,

    input  wire [7:0] rx_data_i,
    input  wire       rx_valid_i,
    input  wire       rx_frame_error_i,

    input  wire       tx_busy_i,
    output reg  [7:0] tx_data_o,
    output reg        tx_start_o,

    output reg        busy_o,
    output wire       done_o,
    output wire       error_o
);

localparam [7:0] SOF_REQ = 8'hA5;
localparam [7:0] SOF_RSP = 8'h5A;

localparam [7:0] CMD_PING    = 8'h01;
localparam [7:0] CMD_VERSION = 8'h02;
localparam [7:0] CMD_WRITE   = 8'h10;
localparam [7:0] CMD_READ    = 8'h11;

localparam [7:0] ERR_UNKNOWN = 8'hE1;
localparam [7:0] ERR_CSUM    = 8'hE2;
localparam [7:0] ERR_ADDR    = 8'hE3;

localparam [2:0]
    ST_WAIT_SOF = 3'd0,
    ST_GET_CMD  = 3'd1,
    ST_GET_ADDR = 3'd2,
    ST_GET_DATA = 3'd3,
    ST_GET_CSUM = 3'd4,
    ST_SEND     = 3'd5;

reg [2:0] state;

reg [7:0] cmd_reg;
reg [7:0] addr_reg;
reg [7:0] data_reg;

reg [7:0] reg_bank [0:7];

reg [7:0] response [0:4];
reg [2:0] tx_index;

reg [24:0] done_count;
reg error_latched;

integer i;

wire [7:0] request_checksum =
    SOF_REQ ^ cmd_reg ^ addr_reg ^ data_reg;

assign done_o  = (done_count != 0);
assign error_o = error_latched;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state         <= ST_WAIT_SOF;
        cmd_reg       <= 8'h00;
        addr_reg      <= 8'h00;
        data_reg      <= 8'h00;
        tx_data_o     <= 8'h00;
        tx_start_o    <= 1'b0;
        tx_index      <= 3'd0;
        busy_o        <= 1'b0;
        done_count    <= 25'd0;
        error_latched <= 1'b0;

        for (i = 0; i < 8; i = i + 1)
            reg_bank[i] <= 8'h00;
    end else begin
        tx_start_o <= 1'b0;

        if (done_count != 0)
            done_count <= done_count - 1'b1;

        if (rx_frame_error_i)
            error_latched <= 1'b1;

        case (state)
            ST_WAIT_SOF: begin
                busy_o <= 1'b0;

                if (rx_valid_i && rx_data_i == SOF_REQ) begin
                    busy_o <= 1'b1;
                    state  <= ST_GET_CMD;
                end
            end

            ST_GET_CMD: begin
                if (rx_valid_i) begin
                    cmd_reg <= rx_data_i;
                    state   <= ST_GET_ADDR;
                end
            end

            ST_GET_ADDR: begin
                if (rx_valid_i) begin
                    addr_reg <= rx_data_i;
                    state    <= ST_GET_DATA;
                end
            end

            ST_GET_DATA: begin
                if (rx_valid_i) begin
                    data_reg <= rx_data_i;
                    state    <= ST_GET_CSUM;
                end
            end

            ST_GET_CSUM: begin
                if (rx_valid_i) begin
                    response[0] <= SOF_RSP;
                    response[1] <= cmd_reg;
                    response[2] <= addr_reg;

                    if (rx_data_i != request_checksum) begin
                        response[3] <= ERR_CSUM;
                        response[4] <= SOF_RSP ^ cmd_reg ^ addr_reg ^ ERR_CSUM;
                        error_latched <= 1'b1;
                    end
                    else begin
                        case (cmd_reg)
                            CMD_PING: begin
                                response[3] <= 8'h00;
                                response[4] <= SOF_RSP ^ CMD_PING ^ addr_reg ^ 8'h00;
                            end

                            CMD_VERSION: begin
                                response[3] <= 8'h32;
                                response[4] <= SOF_RSP ^ CMD_VERSION ^ addr_reg ^ 8'h32;
                            end

                            CMD_WRITE: begin
                                if (addr_reg < 8) begin
                                    reg_bank[addr_reg[2:0]] <= data_reg;
                                    response[3] <= 8'h00;
                                    response[4] <= SOF_RSP ^ CMD_WRITE ^ addr_reg ^ 8'h00;
                                end
                                else begin
                                    response[3] <= ERR_ADDR;
                                    response[4] <= SOF_RSP ^ CMD_WRITE ^ addr_reg ^ ERR_ADDR;
                                    error_latched <= 1'b1;
                                end
                            end

                            CMD_READ: begin
                                if (addr_reg < 8) begin
                                    response[3] <= reg_bank[addr_reg[2:0]];
                                    response[4] <= SOF_RSP ^ CMD_READ ^ addr_reg ^
                                                   reg_bank[addr_reg[2:0]];
                                end
                                else begin
                                    response[3] <= ERR_ADDR;
                                    response[4] <= SOF_RSP ^ CMD_READ ^ addr_reg ^ ERR_ADDR;
                                    error_latched <= 1'b1;
                                end
                            end

                            default: begin
                                response[3] <= ERR_UNKNOWN;
                                response[4] <= SOF_RSP ^ cmd_reg ^ addr_reg ^ ERR_UNKNOWN;
                                error_latched <= 1'b1;
                            end
                        endcase
                    end

                    tx_index <= 3'd0;
                    state    <= ST_SEND;
                end
            end

            ST_SEND: begin
                if (!tx_busy_i && !tx_start_o) begin
                    tx_data_o  <= response[tx_index];
                    tx_start_o <= 1'b1;

                    if (tx_index == 3'd4) begin
                        tx_index   <= 3'd0;
                        busy_o     <= 1'b0;
                        done_count <= 25'd8100000;
                        state      <= ST_WAIT_SOF;
                    end
                    else begin
                        tx_index <= tx_index + 1'b1;
                    end
                end
            end

            default: state <= ST_WAIT_SOF;
        endcase
    end
end

endmodule
