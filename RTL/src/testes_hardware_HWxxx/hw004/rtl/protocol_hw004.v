`timescale 1ns/1ps
module protocol_hw004(
    input wire clk,
    input wire rst_n,
    input wire [7:0] rx_data_i,
    input wire rx_valid_i,
    input wire rx_frame_error_i,
    input wire tx_busy_i,
    output reg [7:0] tx_data_o,
    output reg tx_start_o,
    output reg busy_o,
    output wire done_o,
    output wire error_o
);

localparam [7:0] SOF_REQ=8'hA5, SOF_RSP=8'h5A;
localparam [7:0] CMD_PING=8'h01, CMD_VERSION=8'h02;
localparam [7:0] ERR_UNKNOWN=8'hE1, ERR_CSUM=8'hE2;
localparam [2:0] WAIT_SOF=0, GET_CMD=1, GET_DATA=2, GET_CSUM=3, SEND=4;

reg [2:0] state;
reg [7:0] cmd_reg, data_reg;
reg [7:0] rsp0, rsp1, rsp2, rsp3;
reg [1:0] tx_index;
reg [24:0] done_count;
reg error_latched;

wire [7:0] expected_csum = SOF_REQ ^ cmd_reg ^ data_reg;

assign done_o = (done_count != 0);
assign error_o = error_latched;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state<=WAIT_SOF; cmd_reg<=0; data_reg<=0;
        rsp0<=0; rsp1<=0; rsp2<=0; rsp3<=0;
        tx_data_o<=0; tx_start_o<=0; tx_index<=0;
        busy_o<=0; done_count<=0; error_latched<=0;
    end else begin
        tx_start_o <= 1'b0;
        if(done_count != 0) done_count <= done_count - 1'b1;
        if(rx_frame_error_i) error_latched <= 1'b1;

        case(state)
        WAIT_SOF: begin
            busy_o <= 1'b0;
            if(rx_valid_i && rx_data_i==SOF_REQ) begin
                busy_o <= 1'b1;
                state <= GET_CMD;
            end
        end

        GET_CMD: if(rx_valid_i) begin
            cmd_reg <= rx_data_i;
            state <= GET_DATA;
        end

        GET_DATA: if(rx_valid_i) begin
            data_reg <= rx_data_i;
            state <= GET_CSUM;
        end

        GET_CSUM: if(rx_valid_i) begin
            rsp0 <= SOF_RSP;
            rsp1 <= cmd_reg;

            if(rx_data_i != expected_csum) begin
                rsp2 <= ERR_CSUM;
                rsp3 <= SOF_RSP ^ cmd_reg ^ ERR_CSUM;
                error_latched <= 1'b1;
            end else if(cmd_reg == CMD_PING) begin
                rsp2 <= 8'h00;
                rsp3 <= SOF_RSP ^ CMD_PING ^ 8'h00;
            end else if(cmd_reg == CMD_VERSION) begin
                rsp2 <= 8'h32;
                rsp3 <= SOF_RSP ^ CMD_VERSION ^ 8'h32;
            end else begin
                rsp2 <= ERR_UNKNOWN;
                rsp3 <= SOF_RSP ^ cmd_reg ^ ERR_UNKNOWN;
                error_latched <= 1'b1;
            end

            tx_index <= 0;
            state <= SEND;
        end

        SEND: begin
            if(!tx_busy_i && !tx_start_o) begin
                case(tx_index)
                    0: tx_data_o <= rsp0;
                    1: tx_data_o <= rsp1;
                    2: tx_data_o <= rsp2;
                    3: tx_data_o <= rsp3;
                endcase
                tx_start_o <= 1'b1;

                if(tx_index == 3) begin
                    tx_index <= 0;
                    busy_o <= 1'b0;
                    done_count <= 25'd8100000;
                    state <= WAIT_SOF;
                end else begin
                    tx_index <= tx_index + 1'b1;
                end
            end
        end
        default: state <= WAIT_SOF;
        endcase
    end
end
endmodule
