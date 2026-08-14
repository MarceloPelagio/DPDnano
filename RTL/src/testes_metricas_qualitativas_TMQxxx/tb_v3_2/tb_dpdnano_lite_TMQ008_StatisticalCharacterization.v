`timescale 1ns/1ps
`include "../rtl_v3_1/config.vh"

module tb_dpdnano_lite_TMQ008_StatisticalCharacterization;

// ============================================================
// DPDnano-Lite TMQ Suite
// ============================================================

localparam integer NUM_SAMPLES      = 100000;
localparam integer TIMEOUT_CYCLES   = NUM_SAMPLES * 24;
localparam integer EXPECTED_LATENCY = 5;
localparam integer HIST_BINS        = 8;

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
integer first_input_cycle;
integer first_output_cycle;
integer pipeline_latency;
integer overflow_total;
integer overflow_total_re;
integer overflow_total_im;
integer xz_errors;
integer bin_index_re;
integer bin_index_im;
integer hist_re [0:HIST_BINS-1];
integer hist_im [0:HIST_BINS-1];
integer sample_idx;
integer sample_value_re;
integer sample_value_im;
integer min_re;
integer max_re;
integer min_im;
integer max_im;
integer mid_bin_re;
integer mid_bin_im;

reg first_input_seen;
reg first_output_seen;
reg [31:0] lfsr_a;
reg [31:0] lfsr_b;

real delivery_rate;
real overflow_rate;
real coef1_re_real;
real coef1_im_real;
real coef3_re_real;
real coef3_im_real;
real sum_re;
real sum_im;
real sum_mag;
real sumsq_re;
real sumsq_im;
real mean_re;
real mean_im;
real variance_re;
real variance_im;
real stddev_re;
real stddev_im;
real value_re_real;
real value_im_real;
real value_mag_real;
real min_re_real;
real max_re_real;
real min_im_real;
real max_im_real;

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

function integer histogram_bin;
    input integer value;
    integer shifted;
begin
    shifted = value + 32768;
    if (shifted < 0)
        histogram_bin = 0;
    else if (shifted >= 65536)
        histogram_bin = HIST_BINS - 1;
    else
        histogram_bin = (shifted * HIST_BINS) / 65536;
end
endfunction

always @(posedge clk) begin
    cycle_cnt <= cycle_cnt + 1;

    if (in_valid && !first_input_seen) begin
        first_input_seen  <= 1'b1;
        first_input_cycle <= cycle_cnt;
    end

    if (out_valid) begin
        rx <= rx + 1;

        if (!first_output_seen) begin
            first_output_seen  <= 1'b1;
            first_output_cycle <= cycle_cnt;
        end

        if ((^dout_re === 1'bx) || (^dout_im === 1'bx) ||
            (^out_valid === 1'bx) || (^overflow === 1'bx) ||
            (^overflow_re === 1'bx) || (^overflow_im === 1'bx)) begin
            xz_errors <= xz_errors + 1;
        end
        else begin
            sample_value_re = dout_re;
            sample_value_im = dout_im;

            if (sample_value_re < min_re)
                min_re <= sample_value_re;

            if (sample_value_re > max_re)
                max_re <= sample_value_re;

            if (sample_value_im < min_im)
                min_im <= sample_value_im;

            if (sample_value_im > max_im)
                max_im <= sample_value_im;

            value_re_real = sample_value_re / 32768.0;
            value_im_real = sample_value_im / 32768.0;
            value_mag_real = $sqrt((value_re_real * value_re_real) +
                                   (value_im_real * value_im_real));

            sum_re <= sum_re + value_re_real;
            sum_im <= sum_im + value_im_real;
            sum_mag <= sum_mag + value_mag_real;
            sumsq_re <= sumsq_re + (value_re_real * value_re_real);
            sumsq_im <= sumsq_im + (value_im_real * value_im_real);

            bin_index_re = histogram_bin(sample_value_re);
            bin_index_im = histogram_bin(sample_value_im);
            hist_re[bin_index_re] <= hist_re[bin_index_re] + 1;
            hist_im[bin_index_im] <= hist_im[bin_index_im] + 1;
        end
    end

    if (overflow)
        overflow_total <= overflow_total + 1;

    if (overflow_re)
        overflow_total_re <= overflow_total_re + 1;

    if (overflow_im)
        overflow_total_im <= overflow_total_im + 1;
end

initial begin
    rst               = 1'b1;
    in_valid          = 1'b0;
    din_re            = '0;
    din_im            = '0;
    coef1_re          = 16'sh4600;  // 0.546875
    coef1_im          = 16'sh1600;  // 0.171875
    coef3_re          = 16'sh1800;  // 0.187500
    coef3_im          = -16'sh0A00; // -0.078125
    tx                = 0;
    rx                = 0;
    timeout           = 0;
    cycle_cnt         = 0;
    first_input_cycle = -1;
    first_output_cycle= -1;
    pipeline_latency  = -1;
    overflow_total    = 0;
    overflow_total_re = 0;
    overflow_total_im = 0;
    xz_errors         = 0;
    first_input_seen  = 1'b0;
    first_output_seen = 1'b0;
    lfsr_a            = 32'hC3D2_E1F0;
    lfsr_b            = 32'h1A2B_3C4D;
    sum_re            = 0.0;
    sum_im            = 0.0;
    sum_mag           = 0.0;
    sumsq_re          = 0.0;
    sumsq_im          = 0.0;
    min_re            = 32767;
    max_re            = -32768;
    min_im            = 32767;
    max_im            = -32768;
    coef1_re_real     = 17920.0 / 32768.0;
    coef1_im_real     = 5632.0 / 32768.0;
    coef3_re_real     = 6144.0 / 32768.0;
    coef3_im_real     = -2560.0 / 32768.0;

    for (sample_idx = 0; sample_idx < HIST_BINS; sample_idx = sample_idx + 1) begin
        hist_re[sample_idx] = 0;
        hist_im[sample_idx] = 0;
    end

    repeat (4) @(posedge clk);
    rst = 1'b0;

    $display("");
    $display("======================================================================");
    $display("                 DPDnano-Lite TMQ Validation Suite");
    $display("======================================================================");
    $display("TEST         : TMQ008_StatisticalCharacterization");
    $display("Description  : Statistical Characterization");
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

        lfsr_a = {lfsr_a[30:0], lfsr_a[31] ^ lfsr_a[27] ^ lfsr_a[5] ^ lfsr_a[0]};
        lfsr_b = {lfsr_b[30:0], lfsr_b[31] ^ lfsr_b[22] ^ lfsr_b[2] ^ lfsr_b[1]};

        din_re = lfsr_a[15:0];
        din_im = lfsr_b[15:0];
    end

    @(posedge clk);
    in_valid = 1'b0;
    din_re   = '0;
    din_im   = '0;

    while ((rx < NUM_SAMPLES) && (timeout < TIMEOUT_CYCLES)) begin
        @(posedge clk);
        timeout = timeout + 1;
    end

    pipeline_latency = first_output_cycle - first_input_cycle;
    delivery_rate = (100.0 * rx) / NUM_SAMPLES;
    overflow_rate = (100.0 * overflow_total) / NUM_SAMPLES;

    if (rx > 0) begin
        mean_re = sum_re / rx;
        mean_im = sum_im / rx;
        variance_re = (sumsq_re / rx) - (mean_re * mean_re);
        variance_im = (sumsq_im / rx) - (mean_im * mean_im);

        if (variance_re < 0.0)
            variance_re = 0.0;

        if (variance_im < 0.0)
            variance_im = 0.0;

        stddev_re = $sqrt(variance_re);
        stddev_im = $sqrt(variance_im);
    end
    else begin
        mean_re = 0.0;
        mean_im = 0.0;
        variance_re = 0.0;
        variance_im = 0.0;
        stddev_re = 0.0;
        stddev_im = 0.0;
    end

    min_re_real = min_re / 32768.0;
    max_re_real = max_re / 32768.0;
    min_im_real = min_im / 32768.0;
    max_im_real = max_im / 32768.0;

    mid_bin_re = hist_re[3] + hist_re[4];
    mid_bin_im = hist_im[3] + hist_im[4];

    $display("");
    $display("Execution");
    $display("----------------------------------------------");
    $display("Vectors TX               : %0d", tx);
    $display("Vectors RX               : %0d", rx);
    $display("Delivery Rate            : %0.2f %%", delivery_rate);

    $display("");
    $display("Pipeline");
    $display("----------------------------------------------");
    $display("Expected Latency         : %0d", EXPECTED_LATENCY);
    $display("Measured Latency         : %0d", pipeline_latency);

    $display("");
    $display("Statistical Characterization");
    $display("----------------------------------------------");
    $display("Mean RE                  : %0.12f", mean_re);
    $display("Mean IM                  : %0.12f", mean_im);
    $display("Variance RE              : %0.12f", variance_re);
    $display("Variance IM              : %0.12f", variance_im);
    $display("StdDev RE                : %0.12f", stddev_re);
    $display("StdDev IM                : %0.12f", stddev_im);
    $display("Min RE                   : %0.12f", min_re_real);
    $display("Max RE                   : %0.12f", max_re_real);
    $display("Min IM                   : %0.12f", min_im_real);
    $display("Max IM                   : %0.12f", max_im_real);
    $display("Mean Magnitude           : %0.12f", sum_mag / rx);
    $display("Distribution Mid RE      : %0d", mid_bin_re);
    $display("Distribution Mid IM      : %0d", mid_bin_im);
    $display("X/Z Errors               : %0d", xz_errors);
    $display("Overflow Events          : %0d", overflow_total);

    $display("");
    $display("Histogram RE");
    $display("----------------------------------------------");
    $display("Bin0 [-1.000,-0.750)     : %0d", hist_re[0]);
    $display("Bin1 [-0.750,-0.500)     : %0d", hist_re[1]);
    $display("Bin2 [-0.500,-0.250)     : %0d", hist_re[2]);
    $display("Bin3 [-0.250, 0.000)     : %0d", hist_re[3]);
    $display("Bin4 [ 0.000, 0.250)     : %0d", hist_re[4]);
    $display("Bin5 [ 0.250, 0.500)     : %0d", hist_re[5]);
    $display("Bin6 [ 0.500, 0.750)     : %0d", hist_re[6]);
    $display("Bin7 [ 0.750, 1.000]     : %0d", hist_re[7]);

    $display("");
    $display("Histogram IM");
    $display("----------------------------------------------");
    $display("Bin0 [-1.000,-0.750)     : %0d", hist_im[0]);
    $display("Bin1 [-0.750,-0.500)     : %0d", hist_im[1]);
    $display("Bin2 [-0.500,-0.250)     : %0d", hist_im[2]);
    $display("Bin3 [-0.250, 0.000)     : %0d", hist_im[3]);
    $display("Bin4 [ 0.000, 0.250)     : %0d", hist_im[4]);
    $display("Bin5 [ 0.250, 0.500)     : %0d", hist_im[5]);
    $display("Bin6 [ 0.500, 0.750)     : %0d", hist_im[6]);
    $display("Bin7 [ 0.750, 1.000]     : %0d", hist_im[7]);

    $display("");
    $display("Overall Result");
    $display("----------------------------------------------");

    if ((rx == tx) &&
        (pipeline_latency == EXPECTED_LATENCY) &&
        (xz_errors == 0) &&
        (timeout < TIMEOUT_CYCLES))
        $display("PASS");
    else
        $display("FAIL");

    summary_fd = $fopen("../tb_v3_2/tmq008_statistical_summary.txt", "w");
    if (summary_fd != 0) begin
        $fwrite(summary_fd, "test_name=TMQ008_StatisticalCharacterization\n");
        $fwrite(summary_fd, "description=Statistical Characterization\n");
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
        $fwrite(summary_fd, "expected_latency=%0d\n", EXPECTED_LATENCY);
        $fwrite(summary_fd, "measured_latency=%0d\n", pipeline_latency);
        $fwrite(summary_fd, "overflow_total=%0d\n", overflow_total);
        $fwrite(summary_fd, "overflow_total_re=%0d\n", overflow_total_re);
        $fwrite(summary_fd, "overflow_total_im=%0d\n", overflow_total_im);
        $fwrite(summary_fd, "overflow_rate_pct=%0.6f\n", overflow_rate);
        $fwrite(summary_fd, "xz_errors=%0d\n", xz_errors);
        $fwrite(summary_fd, "mean_re=%0.12f\n", mean_re);
        $fwrite(summary_fd, "mean_im=%0.12f\n", mean_im);
        $fwrite(summary_fd, "variance_re=%0.12f\n", variance_re);
        $fwrite(summary_fd, "variance_im=%0.12f\n", variance_im);
        $fwrite(summary_fd, "stddev_re=%0.12f\n", stddev_re);
        $fwrite(summary_fd, "stddev_im=%0.12f\n", stddev_im);
        $fwrite(summary_fd, "min_re=%0.12f\n", min_re_real);
        $fwrite(summary_fd, "max_re=%0.12f\n", max_re_real);
        $fwrite(summary_fd, "min_im=%0.12f\n", min_im_real);
        $fwrite(summary_fd, "max_im=%0.12f\n", max_im_real);
        $fwrite(summary_fd, "mean_magnitude=%0.12f\n", sum_mag / rx);
        $fwrite(summary_fd, "hist_re_0=%0d\n", hist_re[0]);
        $fwrite(summary_fd, "hist_re_1=%0d\n", hist_re[1]);
        $fwrite(summary_fd, "hist_re_2=%0d\n", hist_re[2]);
        $fwrite(summary_fd, "hist_re_3=%0d\n", hist_re[3]);
        $fwrite(summary_fd, "hist_re_4=%0d\n", hist_re[4]);
        $fwrite(summary_fd, "hist_re_5=%0d\n", hist_re[5]);
        $fwrite(summary_fd, "hist_re_6=%0d\n", hist_re[6]);
        $fwrite(summary_fd, "hist_re_7=%0d\n", hist_re[7]);
        $fwrite(summary_fd, "hist_im_0=%0d\n", hist_im[0]);
        $fwrite(summary_fd, "hist_im_1=%0d\n", hist_im[1]);
        $fwrite(summary_fd, "hist_im_2=%0d\n", hist_im[2]);
        $fwrite(summary_fd, "hist_im_3=%0d\n", hist_im[3]);
        $fwrite(summary_fd, "hist_im_4=%0d\n", hist_im[4]);
        $fwrite(summary_fd, "hist_im_5=%0d\n", hist_im[5]);
        $fwrite(summary_fd, "hist_im_6=%0d\n", hist_im[6]);
        $fwrite(summary_fd, "hist_im_7=%0d\n", hist_im[7]);
        $fwrite(summary_fd, "simulation_cycles=%0d\n", cycle_cnt);
        $fwrite(summary_fd, "simulation_time_ns=%0d\n", cycle_cnt * 10);
        $fwrite(summary_fd, "timeout_cycles=%0d\n", timeout);
        $fwrite(summary_fd, "pass_flag=%0d\n",
            ((rx == tx) &&
             (pipeline_latency == EXPECTED_LATENCY) &&
             (xz_errors == 0) &&
             (timeout < TIMEOUT_CYCLES)));
        $fclose(summary_fd);
    end

    $finish;
end

endmodule
