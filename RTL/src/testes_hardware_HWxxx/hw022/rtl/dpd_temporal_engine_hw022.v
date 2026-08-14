`timescale 1ns/1ps
`include "config.vh"

module dpd_temporal_engine_hw022 (
    input  wire        clk,
    input  wire        rst,
    input  wire        start_i,
    input  wire [2:0]  scenario_i,
    input  wire [15:0] sample_count_i,
    output reg         busy_o,
    output reg         done_o,
    output reg         error_o,
    output reg         overflow_seen_o,
    output reg [15:0]  latency_min_o,
    output reg [15:0]  latency_max_o,
    output reg [31:0]  latency_sum_o,
    output reg [15:0]  samples_sent_o,
    output reg [15:0]  samples_received_o,
    output reg [15:0]  losses_o,
    output reg [15:0]  duplicates_o,
    output reg [15:0]  reorder_o,
    output reg [31:0]  total_cycles_o
);

localparam [2:0]
    SC_CONTINUOUS = 3'd0,
    SC_GAP2       = 3'd1,
    SC_GAP4       = 3'd2,
    SC_GAP8       = 3'd3,
    SC_RANDOM     = 3'd4,
    SC_BURST      = 3'd5;

localparam signed [`COEF_WIDTH-1:0] COEF1_RE = 16'sh6000;
localparam signed [`COEF_WIDTH-1:0] COEF1_IM = 16'sh0000;
localparam signed [`COEF_WIDTH-1:0] COEF3_RE = 16'sh1000;
localparam signed [`COEF_WIDTH-1:0] COEF3_IM = 16'sh0000;

reg dpd_in_valid;
reg signed [`DATA_WIDTH-1:0] dpd_din_re;
reg signed [`DATA_WIDTH-1:0] dpd_din_im;

wire dpd_out_valid;
wire signed [`DATA_WIDTH-1:0] dpd_dout_re;
wire signed [`DATA_WIDTH-1:0] dpd_dout_im;
wire dpd_overflow;
wire dpd_overflow_re;
wire dpd_overflow_im;

reg [31:0] timestamp_fifo [0:7];
reg [15:0] sequence_fifo [0:7];

reg [2:0] fifo_wr_ptr;
reg [2:0] fifo_rd_ptr;
reg [3:0] fifo_count;

reg [31:0] cycle_counter;
reg [15:0] input_sequence;
reg [15:0] expected_output_sequence;
reg [7:0] gap_counter;
reg [5:0] burst_position;
reg [15:0] lfsr;

reg issue_sample;
reg [7:0] reload_gap;
reg [31:0] measured_latency;
reg [15:0] returned_sequence;

wire [3:0] random_gap_raw = lfsr[3:0];
wire [7:0] random_gap =
    (random_gap_raw >= 10) ? (random_gap_raw - 9) :
    ((random_gap_raw == 0) ? 1 : random_gap_raw);

dpd_core u_dpd_core (
    .clk(clk),
    .rst(rst),
    .in_valid(dpd_in_valid),
    .din_re(dpd_din_re),
    .din_im(dpd_din_im),
    .coef1_re(COEF1_RE),
    .coef1_im(COEF1_IM),
    .coef3_re(COEF3_RE),
    .coef3_im(COEF3_IM),
`ifdef DPD_ENABLE_OVERFLOW_FLAGS
    .overflow(dpd_overflow),
    .overflow_re(dpd_overflow_re),
    .overflow_im(dpd_overflow_im),
`endif
    .out_valid(dpd_out_valid),
    .dout_re(dpd_dout_re),
    .dout_im(dpd_dout_im)
);

`ifndef DPD_ENABLE_OVERFLOW_FLAGS
assign dpd_overflow = 1'b0;
assign dpd_overflow_re = 1'b0;
assign dpd_overflow_im = 1'b0;
`endif

always @(*) begin
    issue_sample = 1'b0;
    reload_gap = 8'd0;

    if (busy_o && samples_sent_o < sample_count_i && fifo_count < 8) begin
        case (scenario_i)
            SC_CONTINUOUS: issue_sample = 1'b1;
            SC_GAP2: if (gap_counter == 0) begin issue_sample = 1'b1; reload_gap = 8'd1; end
            SC_GAP4: if (gap_counter == 0) begin issue_sample = 1'b1; reload_gap = 8'd3; end
            SC_GAP8: if (gap_counter == 0) begin issue_sample = 1'b1; reload_gap = 8'd7; end
            SC_RANDOM: if (gap_counter == 0) begin issue_sample = 1'b1; reload_gap = random_gap - 1'b1; end
            SC_BURST: begin
                if (burst_position < 16)
                    issue_sample = 1'b1;
                else if (gap_counter == 0)
                    issue_sample = 1'b1;
            end
            default: issue_sample = 1'b0;
        endcase
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        busy_o <= 1'b0;
        done_o <= 1'b0;
        error_o <= 1'b0;
        overflow_seen_o <= 1'b0;
        latency_min_o <= 16'hFFFF;
        latency_max_o <= 16'd0;
        latency_sum_o <= 32'd0;
        samples_sent_o <= 16'd0;
        samples_received_o <= 16'd0;
        losses_o <= 16'd0;
        duplicates_o <= 16'd0;
        reorder_o <= 16'd0;
        total_cycles_o <= 32'd0;
        fifo_wr_ptr <= 3'd0;
        fifo_rd_ptr <= 3'd0;
        fifo_count <= 4'd0;
        cycle_counter <= 32'd0;
        input_sequence <= 16'd0;
        expected_output_sequence <= 16'd0;
        gap_counter <= 8'd0;
        burst_position <= 6'd0;
        lfsr <= 16'hACE1;
        dpd_in_valid <= 1'b0;
        dpd_din_re <= 0;
        dpd_din_im <= 0;
    end else begin
        done_o <= 1'b0;
        dpd_in_valid <= 1'b0;

        if (start_i && !busy_o) begin
            if (sample_count_i == 0 || sample_count_i > 256 || scenario_i > SC_BURST) begin
                error_o <= 1'b1;
            end else begin
                busy_o <= 1'b1;
                error_o <= 1'b0;
                overflow_seen_o <= 1'b0;
                latency_min_o <= 16'hFFFF;
                latency_max_o <= 16'd0;
                latency_sum_o <= 32'd0;
                samples_sent_o <= 16'd0;
                samples_received_o <= 16'd0;
                losses_o <= 16'd0;
                duplicates_o <= 16'd0;
                reorder_o <= 16'd0;
                total_cycles_o <= 32'd0;
                fifo_wr_ptr <= 3'd0;
                fifo_rd_ptr <= 3'd0;
                fifo_count <= 4'd0;
                cycle_counter <= 32'd0;
                input_sequence <= 16'd0;
                expected_output_sequence <= 16'd0;
                gap_counter <= 8'd0;
                burst_position <= 6'd0;
                lfsr <= 16'hACE1;
            end
        end else if (busy_o) begin
            cycle_counter <= cycle_counter + 1'b1;
            total_cycles_o <= total_cycles_o + 1'b1;
            lfsr <= { lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10] };

            if (gap_counter != 0)
                gap_counter <= gap_counter - 1'b1;

            if (issue_sample) begin
                dpd_in_valid <= 1'b1;
                dpd_din_re <= 16'sd1000 + $signed({1'b0, input_sequence[14:0]});
                dpd_din_im <= -(16'sd500 + $signed({1'b0, input_sequence[14:0]}));
                timestamp_fifo[fifo_wr_ptr] <= cycle_counter;
                sequence_fifo[fifo_wr_ptr] <= input_sequence;
                fifo_wr_ptr <= fifo_wr_ptr + 1'b1;
                fifo_count <= fifo_count + 1'b1;
                samples_sent_o <= samples_sent_o + 1'b1;
                input_sequence <= input_sequence + 1'b1;

                if (scenario_i == SC_BURST) begin
                    if (burst_position == 15) begin
                        burst_position <= 16;
                        gap_counter <= 8'd49;
                    end else if (burst_position >= 16) begin
                        burst_position <= 1;
                    end else begin
                        burst_position <= burst_position + 1'b1;
                    end
                end else begin
                    gap_counter <= reload_gap;
                end
            end

            if (dpd_overflow | dpd_overflow_re | dpd_overflow_im)
                overflow_seen_o <= 1'b1;

            if (dpd_out_valid) begin
                if (fifo_count == 0) begin
                    error_o <= 1'b1;
                    duplicates_o <= duplicates_o + 1'b1;
                end else begin
                    measured_latency = cycle_counter - timestamp_fifo[fifo_rd_ptr];
                    returned_sequence = sequence_fifo[fifo_rd_ptr];
                    fifo_rd_ptr <= fifo_rd_ptr + 1'b1;

                    if (!issue_sample)
                        fifo_count <= fifo_count - 1'b1;

                    samples_received_o <= samples_received_o + 1'b1;
                    latency_sum_o <= latency_sum_o + measured_latency;

                    if (measured_latency < latency_min_o)
                        latency_min_o <= measured_latency[15:0];

                    if (measured_latency > latency_max_o)
                        latency_max_o <= measured_latency[15:0];

                    if (returned_sequence != expected_output_sequence) begin
                        if (returned_sequence < expected_output_sequence) begin
                            duplicates_o <= duplicates_o + 1'b1;
                        end else begin
                            reorder_o <= reorder_o + 1'b1;
                            losses_o <= losses_o + (returned_sequence - expected_output_sequence);
                        end
                    end

                    expected_output_sequence <= returned_sequence + 1'b1;

                    if (samples_received_o + 1'b1 == sample_count_i) begin
                        busy_o <= 1'b0;
                        done_o <= 1'b1;
                    end
                end
            end
        end
    end
end

endmodule
