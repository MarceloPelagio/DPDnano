`timescale 1ns/1ps

/******************************************************************************
* HW008 Protocol
*
* Request frame (9 bytes):
*   A5 CMD AH AL D3 D2 D1 D0 CHECKSUM
*
* Response frame (9 bytes):
*   5A CMD AH AL D3 D2 D1 D0 CHECKSUM
*
* Commands:
*   0x01 PING
*   0x02 VERSION
*   0x20 WRITE INPUT MEMORY
*   0x21 READ INPUT MEMORY
*   0x31 READ OUTPUT MEMORY
*   0x40 PROCESS/COPY
*
* PROCESS command:
*   Address field = start address
*   Data[15:0]    = number of words
*   Count 0       = 256 words
*
* Result:
*   output_memory[start + n] = input_memory[start + n]
******************************************************************************/

module protocol_hw008 (
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

localparam [7:0] CMD_PING      = 8'h01;
localparam [7:0] CMD_VERSION   = 8'h02;
localparam [7:0] CMD_WRITE_IN  = 8'h20;
localparam [7:0] CMD_READ_IN   = 8'h21;
localparam [7:0] CMD_READ_OUT  = 8'h31;
localparam [7:0] CMD_PROCESS   = 8'h40;

localparam [31:0] ERR_UNKNOWN  = 32'h000000E1;
localparam [31:0] ERR_CSUM     = 32'h000000E2;
localparam [31:0] ERR_ADDR     = 32'h000000E3;
localparam [31:0] ERR_COUNT    = 32'h000000E4;

localparam [4:0]
    ST_WAIT_SOF   = 5'd0,
    ST_GET_CMD    = 5'd1,
    ST_GET_AH     = 5'd2,
    ST_GET_AL     = 5'd3,
    ST_GET_D3     = 5'd4,
    ST_GET_D2     = 5'd5,
    ST_GET_D1     = 5'd6,
    ST_GET_D0     = 5'd7,
    ST_GET_CSUM   = 5'd8,
    ST_READ_INPUT = 5'd9,
    ST_READ_OUTPUT= 5'd10,
    ST_PROC_READ_REQ  = 5'd11,
    ST_PROC_READ_WAIT = 5'd12,
    ST_PROC_WRITE = 5'd13,
    ST_SEND       = 5'd14;

reg [4:0] state;

reg [7:0] cmd_reg;
reg [7:0] addr_hi_reg;
reg [7:0] addr_lo_reg;
reg [31:0] data_reg;

reg [7:0] response [0:8];
reg [3:0] tx_index;

reg [24:0] done_count;
reg error_latched;

/* Input memory interface */
reg         in_wr_en;
reg [7:0]   in_wr_addr;
reg [31:0]  in_wr_data;
reg         in_rd_en;
reg [7:0]   in_rd_addr;
wire [31:0] in_rd_data;
wire        in_rd_valid;

/* Output memory interface */
reg         out_wr_en;
reg [7:0]   out_wr_addr;
reg [31:0]  out_wr_data;
reg         out_rd_en;
reg [7:0]   out_rd_addr;
wire [31:0] out_rd_data;
wire        out_rd_valid;

/* Processing controller */
reg [7:0] proc_addr;
reg [8:0] proc_remaining;
reg [31:0] proc_data_hold;
reg [15:0] proc_start_address;
reg [15:0] proc_requested_count;

wire [15:0] address = {addr_hi_reg, addr_lo_reg};

wire [7:0] request_checksum =
    SOF_REQ ^ cmd_reg ^ addr_hi_reg ^ addr_lo_reg ^
    data_reg[31:24] ^ data_reg[23:16] ^
    data_reg[15:8] ^ data_reg[7:0];

assign done_o  = (done_count != 0);
assign error_o = error_latched;

memory_256x32 u_input_memory (
    .clk(clk),
    .wr_en_i(in_wr_en),
    .wr_addr_i(in_wr_addr),
    .wr_data_i(in_wr_data),
    .rd_en_i(in_rd_en),
    .rd_addr_i(in_rd_addr),
    .rd_data_o(in_rd_data),
    .rd_valid_o(in_rd_valid)
);

memory_256x32 u_output_memory (
    .clk(clk),
    .wr_en_i(out_wr_en),
    .wr_addr_i(out_wr_addr),
    .wr_data_i(out_wr_data),
    .rd_en_i(out_rd_en),
    .rd_addr_i(out_rd_addr),
    .rd_data_o(out_rd_data),
    .rd_valid_o(out_rd_valid)
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

        in_wr_en<=0; in_wr_addr<=0; in_wr_data<=0;
        in_rd_en<=0; in_rd_addr<=0;
        out_wr_en<=0; out_wr_addr<=0; out_wr_data<=0;
        out_rd_en<=0; out_rd_addr<=0;

        proc_addr<=0;
        proc_remaining<=0;
        proc_data_hold<=0;
        proc_start_address<=0;
        proc_requested_count<=0;
    end else begin
        tx_start_o <= 1'b0;
        in_wr_en   <= 1'b0;
        in_rd_en   <= 1'b0;
        out_wr_en  <= 1'b0;
        out_rd_en  <= 1'b0;

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

                CMD_WRITE_IN: begin
                    if(address < 16'd256) begin
                        in_wr_en   <= 1'b1;
                        in_wr_addr <= address[7:0];
                        in_wr_data <= data_reg;
                        build_response(CMD_WRITE_IN,address,32'h00000000);
                    end else begin
                        build_response(CMD_WRITE_IN,address,ERR_ADDR);
                        error_latched <= 1'b1;
                    end
                    tx_index <= 0;
                    state <= ST_SEND;
                end

                CMD_READ_IN: begin
                    if(address < 16'd256) begin
                        in_rd_en   <= 1'b1;
                        in_rd_addr <= address[7:0];
                        state <= ST_READ_INPUT;
                    end else begin
                        build_response(CMD_READ_IN,address,ERR_ADDR);
                        error_latched <= 1'b1;
                        tx_index <= 0;
                        state <= ST_SEND;
                    end
                end

                CMD_READ_OUT: begin
                    if(address < 16'd256) begin
                        out_rd_en   <= 1'b1;
                        out_rd_addr <= address[7:0];
                        state <= ST_READ_OUTPUT;
                    end else begin
                        build_response(CMD_READ_OUT,address,ERR_ADDR);
                        error_latched <= 1'b1;
                        tx_index <= 0;
                        state <= ST_SEND;
                    end
                end

                CMD_PROCESS: begin
                    proc_start_address <= address;
                    proc_requested_count <= data_reg[15:0];

                    if(address >= 16'd256) begin
                        build_response(CMD_PROCESS,address,ERR_ADDR);
                        error_latched <= 1'b1;
                        tx_index <= 0;
                        state <= ST_SEND;
                    end else if(
                        (data_reg[15:0] != 16'd0) &&
                        (address + data_reg[15:0] > 16'd256)
                    ) begin
                        build_response(CMD_PROCESS,address,ERR_COUNT);
                        error_latched <= 1'b1;
                        tx_index <= 0;
                        state <= ST_SEND;
                    end else if(
                        (data_reg[15:0] == 16'd0) &&
                        (address != 16'd0)
                    ) begin
                        build_response(CMD_PROCESS,address,ERR_COUNT);
                        error_latched <= 1'b1;
                        tx_index <= 0;
                        state <= ST_SEND;
                    end else begin
                        proc_addr <= address[7:0];

                        if(data_reg[15:0] == 16'd0)
                            proc_remaining <= 9'd256;
                        else
                            proc_remaining <= data_reg[8:0];

                        state <= ST_PROC_READ_REQ;
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

        ST_READ_INPUT: begin
            if(in_rd_valid) begin
                build_response(CMD_READ_IN,address,in_rd_data);
                tx_index <= 0;
                state <= ST_SEND;
            end
        end

        ST_READ_OUTPUT: begin
            if(out_rd_valid) begin
                build_response(CMD_READ_OUT,address,out_rd_data);
                tx_index <= 0;
                state <= ST_SEND;
            end
        end

        ST_PROC_READ_REQ: begin
            in_rd_en   <= 1'b1;
            in_rd_addr <= proc_addr;
            state <= ST_PROC_READ_WAIT;
        end

        ST_PROC_READ_WAIT: begin
            if(in_rd_valid) begin
                proc_data_hold <= in_rd_data;
                state <= ST_PROC_WRITE;
            end
        end

        ST_PROC_WRITE: begin
            out_wr_en   <= 1'b1;
            out_wr_addr <= proc_addr;
            out_wr_data <= proc_data_hold;

            if(proc_remaining == 9'd1) begin
                build_response(
                    CMD_PROCESS,
                    proc_start_address,
                    {16'h0000,proc_requested_count}
                );
                tx_index <= 0;
                state <= ST_SEND;
            end else begin
                proc_addr      <= proc_addr + 1'b1;
                proc_remaining <= proc_remaining - 1'b1;
                state <= ST_PROC_READ_REQ;
            end
        end

        ST_SEND: begin
            if(!tx_busy_i && !tx_start_o) begin
                tx_data_o  <= response[tx_index];
                tx_start_o <= 1'b1;

                if(tx_index==4'd8) begin
                    tx_index<=0;
                    busy_o<=0;
                    done_count<=25'd8100000;
                    state<=ST_WAIT_SOF;
                end else begin
                    tx_index<=tx_index+1'b1;
                end
            end
        end

        default: state<=ST_WAIT_SOF;
        endcase
    end
end

endmodule
