`timescale 1ns/1ps
module dpd_controller #(
    parameter ADDR_WIDTH = 10
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  start,
    input  wire [ADDR_WIDTH:0]   sample_count,

    output reg  [ADDR_WIDTH-1:0] input_rd_addr,
    input  wire [31:0]           input_rd_data,

    output reg                    dpd_in_valid,
    output reg signed [15:0]      dpd_din_re,
    output reg signed [15:0]      dpd_din_im,

    input  wire                   dpd_out_valid,
    input  wire signed [15:0]     dpd_dout_re,
    input  wire signed [15:0]     dpd_dout_im,
    input  wire                   dpd_overflow,

    output reg                    output_wr_en,
    output reg [ADDR_WIDTH-1:0]   output_wr_addr,
    output reg [39:0]             output_wr_data,

    output reg                    busy,
    output reg                    done,
    output reg [31:0]             cycle_count,
    output reg [31:0]             samples_processed,
    output reg [31:0]             overflow_count
);
localparam [2:0] ST_IDLE=0, ST_READ=1, ST_FEED=2, ST_DRAIN=3, ST_DONE=4;
reg [2:0] state;
reg [ADDR_WIDTH:0] input_count;
reg [ADDR_WIDTH:0] output_count;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state             <= ST_IDLE;
        input_rd_addr     <= 0;
        input_count       <= 0;
        output_count      <= 0;
        dpd_in_valid      <= 0;
        dpd_din_re        <= 0;
        dpd_din_im        <= 0;
        output_wr_en      <= 0;
        output_wr_addr    <= 0;
        output_wr_data    <= 0;
        busy              <= 0;
        done              <= 0;
        cycle_count       <= 0;
        samples_processed <= 0;
        overflow_count    <= 0;
    end else begin
        dpd_in_valid <= 1'b0;
        output_wr_en <= 1'b0;
        done         <= 1'b0;

        if (busy)
            cycle_count <= cycle_count + 1'b1;

        if (dpd_out_valid && busy) begin
            output_wr_en   <= 1'b1;
            output_wr_addr <= output_count[ADDR_WIDTH-1:0];
            output_wr_data <= {7'd0, dpd_overflow, dpd_dout_im, dpd_dout_re};
            output_count   <= output_count + 1'b1;
            samples_processed <= samples_processed + 1'b1;
            if (dpd_overflow)
                overflow_count <= overflow_count + 1'b1;
        end

        case (state)
            ST_IDLE: begin
                busy <= 1'b0;
                if (start && sample_count != 0) begin
                    busy              <= 1'b1;
                    input_count       <= 0;
                    output_count      <= 0;
                    input_rd_addr     <= 0;
                    cycle_count       <= 0;
                    samples_processed <= 0;
                    overflow_count    <= 0;
                    state             <= ST_READ;
                end
            end

            ST_READ: state <= ST_FEED;

            ST_FEED: begin
                dpd_din_re   <= input_rd_data[15:0];
                dpd_din_im   <= input_rd_data[31:16];
                dpd_in_valid <= 1'b1;
                input_count  <= input_count + 1'b1;

                if (input_count + 1'b1 >= sample_count) begin
                    state <= ST_DRAIN;
                end else begin
                    input_rd_addr <= input_rd_addr + 1'b1;
                    state <= ST_READ;
                end
            end

            ST_DRAIN: begin
                if (output_count >= sample_count)
                    state <= ST_DONE;
            end

            ST_DONE: begin
                busy <= 1'b0;
                done <= 1'b1;
                state <= ST_IDLE;
            end

            default: state <= ST_IDLE;
        endcase
    end
end
endmodule
