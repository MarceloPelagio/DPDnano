`timescale 1ns/1ps
`include "../rtl_v3_1/config.vh"

module tb_dpdnano_lite_TMQ006_PipelineTimingCharacterization;

// ============================================================
// DPDnano-Lite TMQ Suite
// ============================================================

localparam integer NUM_SAMPLES      = 16384;
localparam integer TIMEOUT_CYCLES   = NUM_SAMPLES * 24;
localparam integer EXPECTED_LATENCY = 5;
localparam integer QUEUE_DEPTH      = NUM_SAMPLES + 64;

reg clk = 1'b0;
always #5 clk = ~clk;

reg rst;
reg in_valid;

reg signed [`DATA_WIDTH-1:0] din_re;
reg signed [`DATA_WIDTH-1:0] din_im;

reg signed [`COEF_WIDTH-1:0] coef1_re;
reg signed [`COEF_WIDTH-1:0] coef1_im;
reg signed [`COEF_WIDTH-1:0] coef3_re;
reg signed [`COEF_WIDTH-1:0] coef3_im;

wire out_valid;
wire signed [`DATA_WIDTH-1:0] dout_re;
wire signed [`DATA_WIDTH-1:0] dout_im;
wire overflow;
wire overflow_re;
wire overflow_im;

integer summary_fd;
integer tx;
integer rx;
integer timeout;
integer cycle_cnt;
integer pattern_sel;
integer current_amp;
integer latency_cycles;
integer input_gap;
integer output_gap;
integer last_input_cycle;
integer last_output_cycle;
integer first_input_cycle;
integer first_output_cycle;
integer latency_min;
integer latency_max;
integer input_gap_min;
integer input_gap_max;
integer output_gap_min;
integer output_gap_max;
integer overflow_total;
integer overflow_total_re;
integer overflow_total_im;
integer queue_wr_ptr;
integer queue_rd_ptr;
integer in_cycle_queue [0:QUEUE_DEPTH-1];
integer latency_count;
integer input_gap_count;
integer output_gap_count;

reg first_input_seen;
reg first_output_seen;

real delivery_rate;
real overflow_rate;
real latency_sum;
real input_gap_sum;
real output_gap_sum;
real latency_avg;
real input_gap_avg;
real output_gap_avg;
real throughput_vectors_per_cycle;
real throughput_vectors_per_us;
real throughput_vectors_per_second;
real coef1_re_real;
real coef1_im_real;
real coef3_re_real;
real coef3_im_real;

dpd_core dut(
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid),
    .din_re(din_re),
    .din_im(din_im),
    .coef1_re(coef1_re),
    .coef1_im(coef1_im),
    .coef3_re(coef3_re),
    .coef3_im(coef3_im),
    .overflow(overflow),
    .overflow_re(overflow_re),
    .overflow_im(overflow_im),
    .out_valid(out_valid),
    .dout_re(dout_re),
    .dout_im(dout_im)
);

always @(posedge clk) begin
    cycle_cnt <= cycle_cnt + 1;

    if (in_valid) begin
        if (!first_input_seen) begin
            first_input_seen  <= 1'b1;
            first_input_cycle <= cycle_cnt;
        end

        if (last_input_cycle >= 0) begin
            input_gap = cycle_cnt - last_input_cycle;
            input_gap_sum <= input_gap_sum + input_gap;
            input_gap_count <= input_gap_count + 1;

            if (input_gap < input_gap_min)
                input_gap_min <= input_gap;

            if (input_gap > input_gap_max)
                input_gap_max <= input_gap;
        end

        last_input_cycle <= cycle_cnt;
        in_cycle_queue[queue_wr_ptr] <= cycle_cnt;
        queue_wr_ptr <= queue_wr_ptr + 1;
    end

    if (out_valid) begin
        rx <= rx + 1;

        if (!first_output_seen) begin
            first_output_seen  <= 1'b1;
            first_output_cycle <= cycle_cnt;
        end

        latency_cycles = cycle_cnt - in_cycle_queue[queue_rd_ptr];
        queue_rd_ptr <= queue_rd_ptr + 1;
        latency_sum <= latency_sum + latency_cycles;
        latency_count <= latency_count + 1;

        if (latency_cycles < latency_min)
            latency_min <= latency_cycles;

        if (latency_cycles > latency_max)
            latency_max <= latency_cycles;

        if (last_output_cycle >= 0) begin
            output_gap = cycle_cnt - last_output_cycle;
            output_gap_sum <= output_gap_sum + output_gap;
            output_gap_count <= output_gap_count + 1;

            if (output_gap < output_gap_min)
                output_gap_min <= output_gap;

            if (output_gap > output_gap_max)
                output_gap_max <= output_gap;
        end

        last_output_cycle <= cycle_cnt;
    end

    if (overflow)
        overflow_total <= overflow_total + 1;

    if (overflow_re)
        overflow_total_re <= overflow_total_re + 1;

    if (overflow_im)
        overflow_total_im <= overflow_total_im + 1;
end

initial begin
    rst              = 1'b1;
    in_valid         = 1'b0;
    din_re           = '0;
    din_im           = '0;
    coef1_re         = 16'sh4400;  // 0.53125
    coef1_im         = 16'sh1000;  // 0.125
    coef3_re         = 16'sh1800;  // 0.1875
    coef3_im         = -16'sh0800; // -0.0625
    tx               = 0;
    rx               = 0;
    timeout          = 0;
    cycle_cnt        = 0;
    last_input_cycle = -1;
    last_output_cycle= -1;
    first_input_cycle= -1;
    first_output_cycle = -1;
    latency_min      = 32'h7fffffff;
    latency_max      = -1;
    input_gap_min    = 32'h7fffffff;
    input_gap_max    = -1;
    output_gap_min   = 32'h7fffffff;
    output_gap_max   = -1;
    overflow_total   = 0;
    overflow_total_re= 0;
    overflow_total_im= 0;
    queue_wr_ptr     = 0;
    queue_rd_ptr     = 0;
    latency_count    = 0;
    input_gap_count  = 0;
    output_gap_count = 0;
    first_input_seen = 1'b0;
    first_output_seen= 1'b0;
    latency_sum      = 0.0;
    input_gap_sum    = 0.0;
    output_gap_sum   = 0.0;
    coef1_re_real    = 17408.0 / 32768.0;
    coef1_im_real    = 4096.0 / 32768.0;
    coef3_re_real    = 6144.0 / 32768.0;
    coef3_im_real    = -2048.0 / 32768.0;

    repeat (4) @(posedge clk);
    rst = 1'b0;

    $display("");
    $display("======================================================================");
    $display("                 DPDnano-Lite TMQ Validation Suite");
    $display("======================================================================");
    $display("TEST         : TMQ006_PipelineTimingCharacterization");
    $display("Description  : Pipeline Timing Characterization");
    $display("Samples      : %0d", NUM_SAMPLES);
    $display("coef1_re [Q1.15]         : %0d", coef1_re);
    $display("coef1_im [Q1.15]         : %0d", coef1_im);
    $display("coef3_re [Q1.15]         : %0d", coef3_re);
    $display("coef3_im [Q1.15]         : %0d", coef3_im);
    $display("coef1_re [real]          : %0.12f", coef1_re_real);
    $display("coef1_im [real]          : %0.12f", coef1_im_real);
    $display("coef3_re [real]          : %0.12f", coef3_re_real);
    $display("coef3_im [real]          : %0.12f", coef3_im_real);
    $display("======================================================================");
    $display("");

    for (tx = 0; tx < NUM_SAMPLES; tx = tx + 1) begin
        @(posedge clk);
        in_valid = 1'b1;

        current_amp = ((tx % 3072) + 1) * 10;
        if (current_amp > 30000)
            current_amp = 30000;

        pattern_sel = tx % 6;
        case (pattern_sel)
            0: begin
                din_re = current_amp[`DATA_WIDTH-1:0];
                din_im = (current_amp >>> 1);
            end
            1: begin
                din_re = (current_amp >>> 1);
                din_im = current_amp[`DATA_WIDTH-1:0];
            end
            2: begin
                din_re = current_amp[`DATA_WIDTH-1:0];
                din_im = -($signed(current_amp >>> 1));
            end
            3: begin
                din_re = -($signed(current_amp >>> 1));
                din_im = current_amp[`DATA_WIDTH-1:0];
            end
            4: begin
                din_re = -($signed(current_amp));
                din_im = (current_amp >>> 2);
            end
            default: begin
                din_re = (current_amp >>> 2);
                din_im = -($signed(current_amp));
            end
        endcase
    end

    @(posedge clk);
    in_valid = 1'b0;
    din_re   = '0;
    din_im   = '0;

    while ((rx < NUM_SAMPLES) && (timeout < TIMEOUT_CYCLES)) begin
        @(posedge clk);
        timeout = timeout + 1;
    end

    latency_avg = (latency_count > 0) ? (latency_sum / latency_count) : 0.0;
    input_gap_avg = (input_gap_count > 0) ? (input_gap_sum / input_gap_count) : 0.0;
    output_gap_avg = (output_gap_count > 0) ? (output_gap_sum / output_gap_count) : 0.0;
    delivery_rate = (100.0 * rx) / NUM_SAMPLES;
    overflow_rate = (100.0 * overflow_total) / NUM_SAMPLES;
    throughput_vectors_per_cycle = (cycle_cnt > 0) ? (1.0 * rx / cycle_cnt) : 0.0;
    throughput_vectors_per_us = ((cycle_cnt * 10.0) > 0.0) ? (rx / (cycle_cnt * 10.0 / 1000.0)) : 0.0;
    throughput_vectors_per_second = ((cycle_cnt * 10.0) > 0.0) ? (rx / (cycle_cnt * 10.0 / 1.0e9)) : 0.0;

    $display("");
    $display("Execution");
    $display("----------------------------------------------");
    $display("Vectors TX               : %0d", tx);
    $display("Vectors RX               : %0d", rx);
    $display("Delivery Rate            : %0.2f %%", delivery_rate);

    $display("");
    $display("Latency Table");
    $display("----------------------------------------------");
    $display("Latency Min              : %0d", latency_min);
    $display("Latency Max              : %0d", latency_max);
    $display("Latency Average          : %0.6f", latency_avg);

    $display("");
    $display("Input Valid Interval");
    $display("----------------------------------------------");
    $display("Input Gap Min            : %0d", input_gap_min);
    $display("Input Gap Max            : %0d", input_gap_max);
    $display("Input Gap Average        : %0.6f", input_gap_avg);

    $display("");
    $display("Output Valid Interval");
    $display("----------------------------------------------");
    $display("Output Gap Min           : %0d", output_gap_min);
    $display("Output Gap Max           : %0d", output_gap_max);
    $display("Output Gap Average       : %0.6f", output_gap_avg);

    $display("");
    $display("Throughput");
    $display("----------------------------------------------");
    $display("Vectors/Cycle            : %0.9f", throughput_vectors_per_cycle);
    $display("Vectors/us               : %0.6f", throughput_vectors_per_us);
    $display("Vectors/s                : %0.3f", throughput_vectors_per_second);

    $display("");
    $display("Overflow Statistics");
    $display("----------------------------------------------");
    $display("Overflow Events          : %0d", overflow_total);
    $display("Overflow RE              : %0d", overflow_total_re);
    $display("Overflow IM              : %0d", overflow_total_im);
    $display("Overflow Rate            : %0.2f %%", overflow_rate);

    $display("");
    $display("Overall Result");
    $display("----------------------------------------------");

    if ((rx == tx) &&
        (latency_min == EXPECTED_LATENCY) &&
        (latency_max == EXPECTED_LATENCY) &&
        (timeout < TIMEOUT_CYCLES))
        $display("PASS");
    else
        $display("FAIL");

    summary_fd = $fopen("../tb_v3_2/tmq006_pipeline_timing_summary.txt", "w");
    if (summary_fd != 0) begin
        $fwrite(summary_fd, "test_name=TMQ006_PipelineTimingCharacterization\n");
        $fwrite(summary_fd, "description=Pipeline Timing Characterization\n");
        $fwrite(summary_fd, "num_samples=%0d\n", NUM_SAMPLES);
        $fwrite(summary_fd, "vectors_tx=%0d\n", tx);
        $fwrite(summary_fd, "vectors_rx=%0d\n", rx);
        $fwrite(summary_fd, "coef1_re_q15=%0d\n", coef1_re);
        $fwrite(summary_fd, "coef1_im_q15=%0d\n", coef1_im);
        $fwrite(summary_fd, "coef3_re_q15=%0d\n", coef3_re);
        $fwrite(summary_fd, "coef3_im_q15=%0d\n", coef3_im);
        $fwrite(summary_fd, "coef1_re_real=%0.12f\n", coef1_re_real);
        $fwrite(summary_fd, "coef1_im_real=%0.12f\n", coef1_im_real);
        $fwrite(summary_fd, "coef3_re_real=%0.12f\n", coef3_re_real);
        $fwrite(summary_fd, "coef3_im_real=%0.12f\n", coef3_im_real);
        $fwrite(summary_fd, "delivery_rate_pct=%0.6f\n", delivery_rate);
        $fwrite(summary_fd, "latency_min=%0d\n", latency_min);
        $fwrite(summary_fd, "latency_max=%0d\n", latency_max);
        $fwrite(summary_fd, "latency_avg=%0.12f\n", latency_avg);
        $fwrite(summary_fd, "input_gap_min=%0d\n", input_gap_min);
        $fwrite(summary_fd, "input_gap_max=%0d\n", input_gap_max);
        $fwrite(summary_fd, "input_gap_avg=%0.12f\n", input_gap_avg);
        $fwrite(summary_fd, "output_gap_min=%0d\n", output_gap_min);
        $fwrite(summary_fd, "output_gap_max=%0d\n", output_gap_max);
        $fwrite(summary_fd, "output_gap_avg=%0.12f\n", output_gap_avg);
        $fwrite(summary_fd, "throughput_vectors_per_cycle=%0.12f\n", throughput_vectors_per_cycle);
        $fwrite(summary_fd, "throughput_vectors_per_us=%0.12f\n", throughput_vectors_per_us);
        $fwrite(summary_fd, "throughput_vectors_per_second=%0.12f\n", throughput_vectors_per_second);
        $fwrite(summary_fd, "overflow_total=%0d\n", overflow_total);
        $fwrite(summary_fd, "overflow_total_re=%0d\n", overflow_total_re);
        $fwrite(summary_fd, "overflow_total_im=%0d\n", overflow_total_im);
        $fwrite(summary_fd, "overflow_rate_pct=%0.6f\n", overflow_rate);
        $fwrite(summary_fd, "simulation_cycles=%0d\n", cycle_cnt);
        $fwrite(summary_fd, "simulation_time_ns=%0d\n", cycle_cnt * 10);
        $fwrite(summary_fd, "timeout_cycles=%0d\n", timeout);
        $fwrite(summary_fd, "pass_flag=%0d\n",
            ((rx == tx) &&
             (latency_min == EXPECTED_LATENCY) &&
             (latency_max == EXPECTED_LATENCY) &&
             (timeout < TIMEOUT_CYCLES)));
        $fclose(summary_fd);
    end

    $finish;
end

endmodule
