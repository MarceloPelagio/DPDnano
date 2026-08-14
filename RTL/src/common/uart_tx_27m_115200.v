`timescale 1ns/1ps
module uart_tx_27m_115200(
    input wire clk, input wire rst_n, input wire start_i,
    input wire [7:0] data_i, output reg tx_o, output reg busy_o
);
localparam [8:0] CLKS_PER_BIT=9'd234;
localparam [2:0] IDLE=0, START=1, DATA=2, STOP=3;
reg [2:0] state;
reg [8:0] count;
reg [2:0] bit_index;
reg [7:0] data_reg;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state<=IDLE; count<=0; bit_index<=0; data_reg<=0; tx_o<=1; busy_o<=0;
    end else begin
        case(state)
        IDLE: begin
            tx_o<=1; busy_o<=0; count<=0; bit_index<=0;
            if(start_i) begin data_reg<=data_i; busy_o<=1; state<=START; end
        end
        START: begin
            tx_o<=0;
            if(count==CLKS_PER_BIT-1) begin count<=0; state<=DATA; end
            else count<=count+1'b1;
        end
        DATA: begin
            tx_o<=data_reg[bit_index];
            if(count==CLKS_PER_BIT-1) begin
                count<=0;
                if(bit_index==7) begin bit_index<=0; state<=STOP; end
                else bit_index<=bit_index+1'b1;
            end else count<=count+1'b1;
        end
        STOP: begin
            tx_o<=1;
            if(count==CLKS_PER_BIT-1) begin count<=0; busy_o<=0; state<=IDLE; end
            else count<=count+1'b1;
        end
        default: state<=IDLE;
        endcase
    end
end
endmodule
