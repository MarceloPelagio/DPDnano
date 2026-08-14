`timescale 1ns/1ps
`include "config.vh"

module dpd_stress_engine_hw023 (
    input  wire        clk,
    input  wire        rst,
    input  wire        start_i,
    input  wire [31:0] target_samples_i,
    output reg         busy_o,
    output reg         done_o,
    output reg         error_o,
    output reg [31:0]  samples_sent_o,
    output reg [31:0]  samples_received_o,
    output reg [15:0]  latency_min_o,
    output reg [15:0]  latency_max_o,
    output reg [31:0]  latency_sum_o,
    output reg [31:0]  total_cycles_o,
    output reg [31:0]  overflow_events_o,
    output reg [31:0]  saturation_positive_o,
    output reg [31:0]  saturation_negative_o,
    output reg [31:0]  coefficient_updates_o,
    output reg [31:0]  high_amplitude_samples_o,
    output reg [31:0]  fifo_errors_o,
    output reg [31:0]  losses_o,
    output reg [31:0]  duplicates_o,
    output reg [31:0]  reorder_o,
    output reg [31:0]  input_signature_o,
    output reg [31:0]  output_signature_o,
    input  wire [3:0]  checkpoint_addr_i,
    output reg [31:0]  checkpoint_cycle_o
);

localparam [31:0] MAX_SAMPLES = 32'd1000000;
localparam [31:0] CHECKPOINT_STEP = 32'd100000;

reg dpd_in_valid;
reg signed [`DATA_WIDTH-1:0] dpd_din_re;
reg signed [`DATA_WIDTH-1:0] dpd_din_im;

wire dpd_out_valid;
wire signed [`DATA_WIDTH-1:0] dpd_dout_re;
wire signed [`DATA_WIDTH-1:0] dpd_dout_im;
wire dpd_overflow;
wire dpd_overflow_re;
wire dpd_overflow_im;

reg signed [`COEF_WIDTH-1:0] coef1_re_selected;
reg signed [`COEF_WIDTH-1:0] coef3_re_selected;
reg [2:0] coefficient_profile;

reg [31:0] timestamp_fifo [0:7];
reg [19:0] sequence_fifo [0:7];
reg [2:0] fifo_wr_ptr;
reg [2:0] fifo_rd_ptr;
reg [3:0] fifo_count;

reg [31:0] cycle_counter;
reg [19:0] input_sequence;
reg [19:0] expected_sequence;
reg [31:0] target_samples_latched;

reg [31:0] lfsr_i;
reg [31:0] lfsr_q;
reg [31:0] lfsr_mode;

reg [31:0] measured_latency;
reg [19:0] returned_sequence;

reg [31:0] checkpoint_cycles [0:9];
reg [3:0] checkpoint_index;
reg [31:0] next_checkpoint_sample;
reg [2:0] startup_reset_count;
wire core_rst;
wire startup_hold;

wire lfsr_i_feedback = lfsr_i[31] ^ lfsr_i[21] ^ lfsr_i[1] ^ lfsr_i[0];
wire lfsr_q_feedback = lfsr_q[31] ^ lfsr_q[6] ^ lfsr_q[4] ^ lfsr_q[2];
wire lfsr_mode_feedback = lfsr_mode[31] ^ lfsr_mode[28] ^ lfsr_mode[3] ^ lfsr_mode[1];
wire high_amplitude_mode = (lfsr_mode[7:0] < 8'd26);
wire signed [15:0] random_i_full = lfsr_i[15:0];
wire signed [15:0] random_q_full = lfsr_q[15:0];
wire signed [15:0] random_i_normal = $signed(lfsr_i[15:0]) >>> 2;
wire signed [15:0] random_q_normal = $signed(lfsr_q[15:0]) >>> 2;
wire signed [15:0] next_input_i = high_amplitude_mode ? random_i_full : random_i_normal;
wire signed [15:0] next_input_q = high_amplitude_mode ? random_q_full : random_q_normal;
wire issue_sample = busy_o && !startup_hold && (samples_sent_o < target_samples_latched) && (fifo_count < 8);
wire consume_sample = busy_o && dpd_out_valid && (fifo_count != 0);
assign startup_hold = (startup_reset_count != 0);
assign core_rst = rst | startup_hold;

integer i;

function [31:0] signature_next;
    input [31:0] current_signature;
    input [31:0] sample_data;
    reg [31:0] rotated;
    begin
        rotated = {current_signature[26:0], current_signature[31:27]};
        signature_next = rotated ^ sample_data ^ 32'h9E3779B9;
    end
endfunction

always @(*) begin
    case (coefficient_profile)
        3'd0: begin coef1_re_selected = 16'sh570A; coef3_re_selected = 16'sh30A4; end
        3'd1: begin coef1_re_selected = 16'sh5852; coef3_re_selected = 16'sh31EC; end
        3'd2: begin coef1_re_selected = 16'sh599A; coef3_re_selected = 16'sh3333; end
        3'd3: begin coef1_re_selected = 16'sh5AE1; coef3_re_selected = 16'sh347B; end
        3'd4: begin coef1_re_selected = 16'sh5C29; coef3_re_selected = 16'sh35C3; end
        default: begin coef1_re_selected = 16'sh599A; coef3_re_selected = 16'sh3333; end
    endcase
end

dpd_core u_dpd_core (
    .clk(clk),
    .rst(core_rst),
    .in_valid(dpd_in_valid),
    .din_re(dpd_din_re),
    .din_im(dpd_din_im),
    .coef1_re(coef1_re_selected),
    .coef1_im(16'sh0000),
    .coef3_re(coef3_re_selected),
    .coef3_im(16'sh0000),
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
    case (checkpoint_addr_i)
        4'd0: checkpoint_cycle_o = checkpoint_cycles[0];
        4'd1: checkpoint_cycle_o = checkpoint_cycles[1];
        4'd2: checkpoint_cycle_o = checkpoint_cycles[2];
        4'd3: checkpoint_cycle_o = checkpoint_cycles[3];
        4'd4: checkpoint_cycle_o = checkpoint_cycles[4];
        4'd5: checkpoint_cycle_o = checkpoint_cycles[5];
        4'd6: checkpoint_cycle_o = checkpoint_cycles[6];
        4'd7: checkpoint_cycle_o = checkpoint_cycles[7];
        4'd8: checkpoint_cycle_o = checkpoint_cycles[8];
        4'd9: checkpoint_cycle_o = checkpoint_cycles[9];
        default: checkpoint_cycle_o = 32'hFFFFFFFF;
    endcase
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        busy_o <= 1'b0;
        done_o <= 1'b0;
        error_o <= 1'b0;
        samples_sent_o <= 32'd0;
        samples_received_o <= 32'd0;
        latency_min_o <= 16'hFFFF;
        latency_max_o <= 16'd0;
        latency_sum_o <= 32'd0;
        total_cycles_o <= 32'd0;
        overflow_events_o <= 32'd0;
        saturation_positive_o <= 32'd0;
        saturation_negative_o <= 32'd0;
        coefficient_updates_o <= 32'd0;
        high_amplitude_samples_o <= 32'd0;
        fifo_errors_o <= 32'd0;
        losses_o <= 32'd0;
        duplicates_o <= 32'd0;
        reorder_o <= 32'd0;
        input_signature_o <= 32'h13579BDF;
        output_signature_o <= 32'h2468ACE0;
        dpd_in_valid <= 1'b0;
        dpd_din_re <= 16'sd0;
        dpd_din_im <= 16'sd0;
        coefficient_profile <= 3'd0;
        fifo_wr_ptr <= 3'd0;
        fifo_rd_ptr <= 3'd0;
        fifo_count <= 4'd0;
        cycle_counter <= 32'd0;
        input_sequence <= 20'd0;
        expected_sequence <= 20'd0;
        target_samples_latched <= 32'd0;
        lfsr_i <= 32'h1A2B3C4D;
        lfsr_q <= 32'h89ABCDEF;
        lfsr_mode <= 32'hC001D00D;
        checkpoint_index <= 4'd0;
        next_checkpoint_sample <= CHECKPOINT_STEP;
        startup_reset_count <= 3'd0;
        for (i = 0; i < 10; i = i + 1)
            checkpoint_cycles[i] <= 32'd0;
    end else begin
        done_o <= 1'b0;
        dpd_in_valid <= 1'b0;

        if (startup_reset_count != 0)
            startup_reset_count <= startup_reset_count - 1'b1;

        if (start_i && !busy_o) begin
            if (target_samples_i == 0 || target_samples_i > MAX_SAMPLES) begin
                error_o <= 1'b1;
            end else begin
                busy_o <= 1'b1;
                error_o <= 1'b0;
                samples_sent_o <= 32'd0;
                samples_received_o <= 32'd0;
                latency_min_o <= 16'hFFFF;
                latency_max_o <= 16'd0;
                latency_sum_o <= 32'd0;
                total_cycles_o <= 32'd0;
                overflow_events_o <= 32'd0;
                saturation_positive_o <= 32'd0;
                saturation_negative_o <= 32'd0;
                coefficient_updates_o <= 32'd0;
                high_amplitude_samples_o <= 32'd0;
                fifo_errors_o <= 32'd0;
                losses_o <= 32'd0;
                duplicates_o <= 32'd0;
                reorder_o <= 32'd0;
                input_signature_o <= 32'h13579BDF;
                output_signature_o <= 32'h2468ACE0;
                coefficient_profile <= 3'd0;
                fifo_wr_ptr <= 3'd0;
                fifo_rd_ptr <= 3'd0;
                fifo_count <= 4'd0;
                cycle_counter <= 32'd0;
                input_sequence <= 20'd0;
                expected_sequence <= 20'd0;
                target_samples_latched <= target_samples_i;
                lfsr_i <= 32'h1A2B3C4D;
                lfsr_q <= 32'h89ABCDEF;
                lfsr_mode <= 32'hC001D00D;
                checkpoint_index <= 4'd0;
                next_checkpoint_sample <= CHECKPOINT_STEP;
                startup_reset_count <= 3'd4;
                for (i = 0; i < 10; i = i + 1)
                    checkpoint_cycles[i] <= 32'd0;
            end
        end else if (busy_o) begin
            cycle_counter <= cycle_counter + 1'b1;
            total_cycles_o <= total_cycles_o + 1'b1;
            lfsr_i <= {lfsr_i[30:0], lfsr_i_feedback};
            lfsr_q <= {lfsr_q[30:0], lfsr_q_feedback};
            lfsr_mode <= {lfsr_mode[30:0], lfsr_mode_feedback};

            if (issue_sample) begin
                dpd_in_valid <= 1'b1;
                dpd_din_re <= next_input_i;
                dpd_din_im <= next_input_q;
                timestamp_fifo[fifo_wr_ptr] <= cycle_counter;
                sequence_fifo[fifo_wr_ptr] <= input_sequence;
                fifo_wr_ptr <= fifo_wr_ptr + 1'b1;
                samples_sent_o <= samples_sent_o + 1'b1;
                input_sequence <= input_sequence + 1'b1;
                input_signature_o <= signature_next(input_signature_o, {next_input_i, next_input_q});
                if (high_amplitude_mode)
                    high_amplitude_samples_o <= high_amplitude_samples_o + 1'b1;
                if (samples_sent_o[7:0] == 8'hFF) begin
                    coefficient_updates_o <= coefficient_updates_o + 1'b1;
                    if (coefficient_profile == 4)
                        coefficient_profile <= 0;
                    else
                        coefficient_profile <= coefficient_profile + 1'b1;
                end
            end

            if (dpd_overflow || dpd_overflow_re || dpd_overflow_im)
                overflow_events_o <= overflow_events_o + 1'b1;

            if (dpd_out_valid) begin
                if (fifo_count == 0) begin
                    fifo_errors_o <= fifo_errors_o + 1'b1;
                    duplicates_o <= duplicates_o + 1'b1;
                    error_o <= 1'b1;
                end else begin
                    measured_latency = cycle_counter - timestamp_fifo[fifo_rd_ptr];
                    returned_sequence = sequence_fifo[fifo_rd_ptr];
                    fifo_rd_ptr <= fifo_rd_ptr + 1'b1;
                    samples_received_o <= samples_received_o + 1'b1;
                    latency_sum_o <= latency_sum_o + measured_latency;
                    if (measured_latency < latency_min_o)
                        latency_min_o <= measured_latency[15:0];
                    if (measured_latency > latency_max_o)
                        latency_max_o <= measured_latency[15:0];
                    if (returned_sequence != expected_sequence) begin
                        if (returned_sequence < expected_sequence)
                            duplicates_o <= duplicates_o + 1'b1;
                        else begin
                            reorder_o <= reorder_o + 1'b1;
                            losses_o <= losses_o + (returned_sequence - expected_sequence);
                        end
                    end
                    expected_sequence <= returned_sequence + 1'b1;
                    output_signature_o <= signature_next(output_signature_o, {dpd_dout_re, dpd_dout_im});
                    if (dpd_dout_re == 16'sh7FFF || dpd_dout_im == 16'sh7FFF)
                        saturation_positive_o <= saturation_positive_o + 1'b1;
                    if (dpd_dout_re == 16'sh8000 || dpd_dout_im == 16'sh8000)
                        saturation_negative_o <= saturation_negative_o + 1'b1;
                    if (samples_received_o + 1'b1 == next_checkpoint_sample) begin
                        if (checkpoint_index < 10) begin
                            checkpoint_cycles[checkpoint_index] <= cycle_counter;
                            checkpoint_index <= checkpoint_index + 1'b1;
                            next_checkpoint_sample <= next_checkpoint_sample + CHECKPOINT_STEP;
                        end
                    end
                    if (samples_received_o + 1'b1 == target_samples_latched) begin
                        busy_o <= 1'b0;
                        done_o <= 1'b1;
                    end
                end
            end

            case ({issue_sample, consume_sample})
                2'b10: fifo_count <= fifo_count + 1'b1;
                2'b01: fifo_count <= fifo_count - 1'b1;
                2'b11: fifo_count <= fifo_count;
                default: fifo_count <= fifo_count;
            endcase
        end
    end
end

endmodule
