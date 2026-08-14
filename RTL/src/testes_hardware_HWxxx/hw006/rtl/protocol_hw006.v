`timescale 1ns/1ps

module protocol_hw006 (
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

localparam [7:0] SOF_REQ=8'hA5, SOF_RSP=8'h5A;
localparam [7:0] CMD_PING=8'h01, CMD_VERSION=8'h02;
localparam [7:0] CMD_WRITE=8'h20, CMD_READ=8'h21;
localparam [31:0] ERR_UNKNOWN=32'h000000E1;
localparam [31:0] ERR_CSUM=32'h000000E2;
localparam [31:0] ERR_ADDR=32'h000000E3;

localparam [3:0]
    ST_WAIT_SOF=4'd0,
    ST_GET_CMD =4'd1,
    ST_GET_AH  =4'd2,
    ST_GET_AL  =4'd3,
    ST_GET_D3  =4'd4,
    ST_GET_D2  =4'd5,
    ST_GET_D1  =4'd6,
    ST_GET_D0  =4'd7,
    ST_GET_CSUM=4'd8,
    ST_MEM_READ=4'd9,
    ST_SEND    =4'd10;

reg [3:0] state;
reg [7:0] cmd_reg, addr_hi_reg, addr_lo_reg;
reg [31:0] data_reg;
reg [7:0] response [0:8];
reg [3:0] tx_index;
reg [24:0] done_count;
reg error_latched;

reg        mem_wr_en;
reg [7:0]  mem_wr_addr;
reg [31:0] mem_wr_data;
reg        mem_rd_en;
reg [7:0]  mem_rd_addr;
wire [31:0] mem_rd_data;
wire        mem_rd_valid;

wire [15:0] address = {addr_hi_reg, addr_lo_reg};

wire [7:0] request_checksum =
    SOF_REQ ^ cmd_reg ^ addr_hi_reg ^ addr_lo_reg ^
    data_reg[31:24] ^ data_reg[23:16] ^
    data_reg[15:8] ^ data_reg[7:0];

assign done_o  = (done_count != 0);
assign error_o = error_latched;

input_memory_256x32 u_input_memory (
    .clk       (clk),
    .wr_en_i   (mem_wr_en),
    .wr_addr_i (mem_wr_addr),
    .wr_data_i (mem_wr_data),
    .rd_en_i   (mem_rd_en),
    .rd_addr_i (mem_rd_addr),
    .rd_data_o (mem_rd_data),
    .rd_valid_o(mem_rd_valid)
);

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
    if(!rst_n) begin
        state<=ST_WAIT_SOF;
        cmd_reg<=0; addr_hi_reg<=0; addr_lo_reg<=0; data_reg<=0;
        tx_data_o<=0; tx_start_o<=0; tx_index<=0;
        busy_o<=0; done_count<=0; error_latched<=0;
        mem_wr_en<=0; mem_wr_addr<=0; mem_wr_data<=0;
        mem_rd_en<=0; mem_rd_addr<=0;
    end else begin
        tx_start_o <= 1'b0;
        mem_wr_en  <= 1'b0;
        mem_rd_en  <= 1'b0;

        if(done_count != 0)
            done_count <= done_count - 1'b1;

        if(rx_frame_error_i)
            error_latched <= 1'b1;

        case(state)
        ST_WAIT_SOF: begin
            busy_o <= 1'b0;
            if(rx_valid_i && rx_data_i==SOF_REQ) begin
                busy_o <= 1'b1;
                state <= ST_GET_CMD;
            end
        end

        ST_GET_CMD: if(rx_valid_i) begin
            cmd_reg <= rx_data_i;
            state <= ST_GET_AH;
        end

        ST_GET_AH: if(rx_valid_i) begin
            addr_hi_reg <= rx_data_i;
            state <= ST_GET_AL;
        end

        ST_GET_AL: if(rx_valid_i) begin
            addr_lo_reg <= rx_data_i;
            state <= ST_GET_D3;
        end

        ST_GET_D3: if(rx_valid_i) begin
            data_reg[31:24] <= rx_data_i;
            state <= ST_GET_D2;
        end

        ST_GET_D2: if(rx_valid_i) begin
            data_reg[23:16] <= rx_data_i;
            state <= ST_GET_D1;
        end

        ST_GET_D1: if(rx_valid_i) begin
            data_reg[15:8] <= rx_data_i;
            state <= ST_GET_D0;
        end

        ST_GET_D0: if(rx_valid_i) begin
            data_reg[7:0] <= rx_data_i;
            state <= ST_GET_CSUM;
        end

        ST_GET_CSUM: if(rx_valid_i) begin
            if(rx_data_i != request_checksum) begin
                build_response(cmd_reg,address,ERR_CSUM);
                error_latched <= 1'b1;
                tx_index <= 0;
                state <= ST_SEND;
            end else begin
                case(cmd_reg)
                CMD_PING: begin
                    build_response(CMD_PING,address,32'h00000000);
                    tx_index <= 0;
                    state <= ST_SEND;
                end

                CMD_VERSION: begin
                    build_response(CMD_VERSION,address,32'h00000302);
                    tx_index <= 0;
                    state <= ST_SEND;
                end

                CMD_WRITE: begin
                    if(address < 16'd256) begin
                        mem_wr_en   <= 1'b1;
                        mem_wr_addr <= address[7:0];
                        mem_wr_data <= data_reg;
                        build_response(CMD_WRITE,address,32'h00000000);
                    end else begin
                        build_response(CMD_WRITE,address,ERR_ADDR);
                        error_latched <= 1'b1;
                    end
                    tx_index <= 0;
                    state <= ST_SEND;
                end

                CMD_READ: begin
                    if(address < 16'd256) begin
                        mem_rd_en   <= 1'b1;
                        mem_rd_addr <= address[7:0];
                        state <= ST_MEM_READ;
                    end else begin
                        build_response(CMD_READ,address,ERR_ADDR);
                        error_latched <= 1'b1;
                        tx_index <= 0;
                        state <= ST_SEND;
                    end
                end

                default: begin
                    build_response(cmd_reg,address,ERR_UNKNOWN);
                    error_latched <= 1'b1;
                    tx_index <= 0;
                    state <= ST_SEND;
                end
                endcase
            end
        end

        ST_MEM_READ: begin
            if(mem_rd_valid) begin
                build_response(CMD_READ,address,mem_rd_data);
                tx_index <= 0;
                state <= ST_SEND;
            end
        end

        ST_SEND: begin
            if(!tx_busy_i && !tx_start_o) begin
                tx_data_o <= response[tx_index];
                tx_start_o <= 1'b1;

                if(tx_index==4'd8) begin
                    tx_index<=0;
                    busy_o<=0;
                    done_count<=25'd8100000;
                    state<=ST_WAIT_SOF;
                end else
                    tx_index<=tx_index+1'b1;
            end
        end

        default: state<=ST_WAIT_SOF;
        endcase
    end
end

endmodule
