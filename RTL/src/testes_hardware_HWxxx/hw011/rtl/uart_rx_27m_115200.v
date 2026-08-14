`timescale 1ns/1ps
module uart_rx_27m_115200(
    input wire clk, input wire rst_n, input wire rx_i,
    output reg [7:0] data_o, output reg data_valid_o,
    output reg busy_o, output reg frame_error_o
);
localparam [8:0] CLKS_PER_BIT=9'd234, HALF_BIT=9'd117;
localparam [2:0] IDLE=0, START=1, DATA=2, STOP=3;
reg [2:0] state;
reg [8:0] count;
reg [2:0] bit_index;
reg [7:0] shift;
reg rx_meta, rx_sync;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin rx_meta<=1'b1; rx_sync<=1'b1; end
    else begin rx_meta<=rx_i; rx_sync<=rx_meta; end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state<=IDLE; count<=0; bit_index<=0; shift<=0; data_o<=0;
        data_valid_o<=0; busy_o<=0; frame_error_o<=0;
    end else begin
        data_valid_o<=0; frame_error_o<=0;
        case(state)
        IDLE: begin
            busy_o<=0; count<=0; bit_index<=0;
            if(!rx_sync) begin busy_o<=1; state<=START; end
        end
        START: begin
            if(count==HALF_BIT-1) begin
                count<=0;
                if(!rx_sync) state<=DATA;
                else begin busy_o<=0; state<=IDLE; end
            end else count<=count+1'b1;
        end
        DATA: begin
            if(count==CLKS_PER_BIT-1) begin
                count<=0; shift[bit_index]<=rx_sync;
                if(bit_index==7) begin bit_index<=0; state<=STOP; end
                else bit_index<=bit_index+1'b1;
            end else count<=count+1'b1;
        end
        STOP: begin
            if(count==CLKS_PER_BIT-1) begin
                count<=0; busy_o<=0; state<=IDLE;
                if(rx_sync) begin data_o<=shift; data_valid_o<=1; end
                else frame_error_o<=1;
            end else count<=count+1'b1;
        end
        default: state<=IDLE;
        endcase
    end
end
endmodule
