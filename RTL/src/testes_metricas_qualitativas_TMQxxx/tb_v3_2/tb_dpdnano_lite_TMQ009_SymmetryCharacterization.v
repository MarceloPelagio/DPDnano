`timescale 1ns/1ps
`include "../rtl_v3_1/config.vh"

module tb_dpdnano_lite_TMQ009_SymmetryCharacterization;

// ============================================================
// DPDnano-Lite TMQ Suite
// ============================================================

localparam integer NUM_LEVELS        = 2048;
localparam integer NUM_PATTERNS      = 4;
localparam integer NUM_PAIRS         = NUM_LEVELS * NUM_PATTERNS;
localparam integer NUM_SAMPLES       = NUM_PAIRS * 2;
localparam integer TIMEOUT_CYCLES    = NUM_SAMPLES * 24;
localparam integer EXPECTED_LATENCY  = 5;

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
integer level_idx;
integer pattern_sel;
integer current_amp;
integer first_input_cycle;
integer first_output_cycle;
integer pipeline_latency;
integer overflow_total;
integer overflow_total_re;
integer overflow_total_im;
integer xz_errors;
integer pair_count;
integer max_abs_symmetry_error_re_lsb;
integer max_abs_symmetry_error_im_lsb;
integer max_abs_symmetry_error_mag_lsb;
integer sample_sign_hist [0:NUM_SAMPLES-1];
integer pair_id_hist [0:NUM_SAMPLES-1];
integer pos_out_re_q15;
integer pos_out_im_q15;
integer sym_error_re_lsb;
integer sym_error_im_lsb;
integer abs_error_re_lsb;
integer abs_error_im_lsb;
integer abs_error_mag_lsb;

reg first_input_seen;
reg first_output_seen;
reg have_pending_positive;

real delivery_rate;
real overflow_rate;
real coef1_re_real;
real coef1_im_real;
real coef3_re_real;
real coef3_im_real;
real sum_abs_symmetry_error_re;
real sum_abs_symmetry_error_im;
real sum_symmetry_error_sq_mag;
real mean_abs_symmetry_error_re;
real mean_abs_symmetry_error_im;
real rms_symmetry_error_mag;
real max_abs_symmetry_error_re_real;
real max_abs_symmetry_error_im_real;
real max_abs_symmetry_error_mag_real;

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
            if (sample_sign_hist[rx] == 1) begin
                pos_out_re_q15 <= dout_re;
                pos_out_im_q15 <= dout_im;
                have_pending_positive <= 1'b1;
            end
            else if (have_pending_positive) begin
                sym_error_re_lsb = pos_out_re_q15 + dout_re;
                sym_error_im_lsb = pos_out_im_q15 + dout_im;

                abs_error_re_lsb =
                    (sym_error_re_lsb < 0) ? -sym_error_re_lsb : sym_error_re_lsb;
                abs_error_im_lsb =
                    (sym_error_im_lsb < 0) ? -sym_error_im_lsb : sym_error_im_lsb;
                abs_error_mag_lsb = $rtoi($sqrt(
                    (sym_error_re_lsb * sym_error_re_lsb) +
                    (sym_error_im_lsb * sym_error_im_lsb)
                ));

                pair_count <= pair_count + 1;
                sum_abs_symmetry_error_re <= sum_abs_symmetry_error_re + abs_error_re_lsb;
                sum_abs_symmetry_error_im <= sum_abs_symmetry_error_im + abs_error_im_lsb;
                sum_symmetry_error_sq_mag <=
                    sum_symmetry_error_sq_mag + (abs_error_mag_lsb * abs_error_mag_lsb);

                if (abs_error_re_lsb > max_abs_symmetry_error_re_lsb)
                    max_abs_symmetry_error_re_lsb <= abs_error_re_lsb;

                if (abs_error_im_lsb > max_abs_symmetry_error_im_lsb)
                    max_abs_symmetry_error_im_lsb <= abs_error_im_lsb;

                if (abs_error_mag_lsb > max_abs_symmetry_error_mag_lsb)
                    max_abs_symmetry_error_mag_lsb <= abs_error_mag_lsb;

                have_pending_positive <= 1'b0;
            end
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
    coef1_re          = 16'sh4400;  // 0.531250
    coef1_im          = 16'sh1400;  // 0.156250
    coef3_re          = 16'sh1A00;  // 0.203125
    coef3_im          = -16'sh0C00; // -0.093750
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
    pair_count        = 0;
    max_abs_symmetry_error_re_lsb = 0;
    max_abs_symmetry_error_im_lsb = 0;
    max_abs_symmetry_error_mag_lsb = 0;
    pos_out_re_q15    = 0;
    pos_out_im_q15    = 0;
    first_input_seen  = 1'b0;
    first_output_seen = 1'b0;
    have_pending_positive = 1'b0;
    sum_abs_symmetry_error_re = 0.0;
    sum_abs_symmetry_error_im = 0.0;
    sum_symmetry_error_sq_mag = 0.0;
    coef1_re_real     = 17408.0 / 32768.0;
    coef1_im_real     = 5120.0 / 32768.0;
    coef3_re_real     = 6656.0 / 32768.0;
    coef3_im_real     = -3072.0 / 32768.0;

    repeat (4) @(posedge clk);
    rst = 1'b0;

    $display("");
    $display("======================================================================");
    $display("                 DPDnano-Lite TMQ Validation Suite");
    $display("======================================================================");
    $display("TEST         : TMQ009_SymmetryCharacterization");
    $display("Description  : Symmetry Characterization");
    $display("Levels       : %0d", NUM_LEVELS);
    $display("Pairs        : %0d", NUM_PAIRS);
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

    for (level_idx = 0; level_idx < NUM_LEVELS; level_idx = level_idx + 1) begin
        current_amp = (level_idx + 1) * 12;
        if (current_amp > 24576)
            current_amp = 24576;

        for (pattern_sel = 0; pattern_sel < NUM_PATTERNS; pattern_sel = pattern_sel + 1) begin
            @(posedge clk);
            in_valid = 1'b1;
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
                default: begin
                    din_re = -($signed(current_amp >>> 1));
                    din_im = current_amp[`DATA_WIDTH-1:0];
                end
            endcase
            sample_sign_hist[tx] = 1;
            pair_id_hist[tx] = (level_idx * NUM_PATTERNS) + pattern_sel;
            tx = tx + 1;

            @(posedge clk);
            in_valid = 1'b1;
            din_re = -din_re;
            din_im = -din_im;
            sample_sign_hist[tx] = -1;
            pair_id_hist[tx] = (level_idx * NUM_PATTERNS) + pattern_sel;
            tx = tx + 1;
        end
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

    if (pair_count > 0) begin
        mean_abs_symmetry_error_re = sum_abs_symmetry_error_re / pair_count;
        mean_abs_symmetry_error_im = sum_abs_symmetry_error_im / pair_count;
        rms_symmetry_error_mag = $sqrt(sum_symmetry_error_sq_mag / pair_count);
    end
    else begin
        mean_abs_symmetry_error_re = 0.0;
        mean_abs_symmetry_error_im = 0.0;
        rms_symmetry_error_mag = 0.0;
    end

    max_abs_symmetry_error_re_real = max_abs_symmetry_error_re_lsb / 32768.0;
    max_abs_symmetry_error_im_real = max_abs_symmetry_error_im_lsb / 32768.0;
    max_abs_symmetry_error_mag_real = max_abs_symmetry_error_mag_lsb / 32768.0;

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
    $display("Symmetry Error");
    $display("----------------------------------------------");
    $display("Symmetry Pairs           : %0d", pair_count);
    $display("Mean |Error| RE [LSB]    : %0.12f", mean_abs_symmetry_error_re);
    $display("Mean |Error| IM [LSB]    : %0.12f", mean_abs_symmetry_error_im);
    $display("RMS Error MAG [LSB]      : %0.12f", rms_symmetry_error_mag);
    $display("Max |Error| RE [LSB]     : %0d", max_abs_symmetry_error_re_lsb);
    $display("Max |Error| IM [LSB]     : %0d", max_abs_symmetry_error_im_lsb);
    $display("Max |Error| MAG [LSB]    : %0d", max_abs_symmetry_error_mag_lsb);
    $display("Max |Error| RE [real]    : %0.12f", max_abs_symmetry_error_re_real);
    $display("Max |Error| IM [real]    : %0.12f", max_abs_symmetry_error_im_real);
    $display("Max |Error| MAG [real]   : %0.12f", max_abs_symmetry_error_mag_real);

    $display("");
    $display("Overflow Statistics");
    $display("----------------------------------------------");
    $display("Overflow Events          : %0d", overflow_total);
    $display("Overflow RE              : %0d", overflow_total_re);
    $display("Overflow IM              : %0d", overflow_total_im);
    $display("Overflow Rate            : %0.2f %%", overflow_rate);
    $display("X/Z Errors               : %0d", xz_errors);

    $display("");
    $display("Overall Result");
    $display("----------------------------------------------");

    if ((rx == tx) &&
        (pair_count == NUM_PAIRS) &&
        (pipeline_latency == EXPECTED_LATENCY) &&
        (xz_errors == 0) &&
        (timeout < TIMEOUT_CYCLES))
        $display("PASS");
    else
        $display("FAIL");

    summary_fd = $fopen("../tb_v3_2/tmq009_symmetry_summary.txt", "w");
    if (summary_fd != 0) begin
        $fwrite(summary_fd, "test_name=TMQ009_SymmetryCharacterization\n");
        $fwrite(summary_fd, "description=Symmetry Characterization\n");
        $fwrite(summary_fd, "num_levels=%0d\n", NUM_LEVELS);
        $fwrite(summary_fd, "num_pairs=%0d\n", NUM_PAIRS);
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
        $fwrite(summary_fd, "pair_count=%0d\n", pair_count);
        $fwrite(summary_fd, "mean_abs_symmetry_error_re_lsb=%0.12f\n", mean_abs_symmetry_error_re);
        $fwrite(summary_fd, "mean_abs_symmetry_error_im_lsb=%0.12f\n", mean_abs_symmetry_error_im);
        $fwrite(summary_fd, "rms_symmetry_error_mag_lsb=%0.12f\n", rms_symmetry_error_mag);
        $fwrite(summary_fd, "max_abs_symmetry_error_re_lsb=%0d\n", max_abs_symmetry_error_re_lsb);
        $fwrite(summary_fd, "max_abs_symmetry_error_im_lsb=%0d\n", max_abs_symmetry_error_im_lsb);
        $fwrite(summary_fd, "max_abs_symmetry_error_mag_lsb=%0d\n", max_abs_symmetry_error_mag_lsb);
        $fwrite(summary_fd, "max_abs_symmetry_error_re_real=%0.12f\n", max_abs_symmetry_error_re_real);
        $fwrite(summary_fd, "max_abs_symmetry_error_im_real=%0.12f\n", max_abs_symmetry_error_im_real);
        $fwrite(summary_fd, "max_abs_symmetry_error_mag_real=%0.12f\n", max_abs_symmetry_error_mag_real);
        $fwrite(summary_fd, "overflow_total=%0d\n", overflow_total);
        $fwrite(summary_fd, "overflow_total_re=%0d\n", overflow_total_re);
        $fwrite(summary_fd, "overflow_total_im=%0d\n", overflow_total_im);
        $fwrite(summary_fd, "overflow_rate_pct=%0.6f\n", overflow_rate);
        $fwrite(summary_fd, "xz_errors=%0d\n", xz_errors);
        $fwrite(summary_fd, "simulation_cycles=%0d\n", cycle_cnt);
        $fwrite(summary_fd, "simulation_time_ns=%0d\n", cycle_cnt * 10);
        $fwrite(summary_fd, "timeout_cycles=%0d\n", timeout);
        $fwrite(summary_fd, "pass_flag=%0d\n",
            ((rx == tx) &&
             (pair_count == NUM_PAIRS) &&
             (pipeline_latency == EXPECTED_LATENCY) &&
             (xz_errors == 0) &&
             (timeout < TIMEOUT_CYCLES)));
        $fclose(summary_fd);
    end

    $finish;
end

endmodule
