`timescale 1ns/1ps
`include "../rtl_v3_1/config.vh"

module tb_dpdnano_lite_TMQ005_NumericalPrecision;

// ============================================================
// DPDnano-Lite TMQ Suite
// ============================================================

localparam integer NUM_LEVELS        = 3072;
localparam integer REPEATS_PER_LEVEL = 4;
localparam integer NUM_SAMPLES       = NUM_LEVELS * REPEATS_PER_LEVEL;
localparam integer TIMEOUT_CYCLES    = NUM_SAMPLES * 20;
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
integer repeat_idx;
integer pattern_sel;
integer current_amp;
integer first_input_cycle;
integer first_output_cycle;
integer pipeline_latency;
integer stable_outputs;
integer overflow_total;
integer overflow_total_re;
integer overflow_total_im;
integer saturation_points;
integer max_error_source;

reg first_input_seen;
reg first_output_seen;
reg stable_hist [0:NUM_SAMPLES-1];
reg signed [`DATA_WIDTH-1:0] in_re_hist [0:NUM_SAMPLES-1];
reg signed [`DATA_WIDTH-1:0] in_im_hist [0:NUM_SAMPLES-1];

real delivery_rate;
real overflow_rate;
real coef1_re_real;
real coef1_im_real;
real coef3_re_real;
real coef3_im_real;
real x_re_real;
real x_im_real;
real mag2_real;
real ideal_re_real;
real ideal_im_real;
real ideal_re_q15_real;
real ideal_im_q15_real;
real clipped_re_q15_real;
real clipped_im_q15_real;
real fixed_re_q15_real;
real fixed_im_q15_real;
real error_re_real;
real error_im_real;
real error_mag_real;
real ideal_mag_real;
real sum_error_sq_re;
real sum_error_sq_im;
real sum_error_sq_mag;
real sum_ideal_mag;
real max_abs_error_re_lsb;
real max_abs_error_im_lsb;
real max_abs_error_mag_lsb;
real percent_error_rms_mag;
real percent_error_max_mag;

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

        if (^dout_re === 1'bx || ^dout_im === 1'bx) begin
            $display("[FAIL] X/Z detected on DUT output.");
            $finish;
        end

        if (stable_hist[rx]) begin
            stable_outputs <= stable_outputs + 1;

            x_re_real = in_re_hist[rx] / 32768.0;
            x_im_real = in_im_hist[rx] / 32768.0;
            mag2_real = (x_re_real * x_re_real) + (x_im_real * x_im_real);

            ideal_re_real =
                ((coef1_re_real * x_re_real) - (coef1_im_real * x_im_real)) +
                (((coef3_re_real * x_re_real) - (coef3_im_real * x_im_real)) * mag2_real);

            ideal_im_real =
                ((coef1_re_real * x_im_real) + (coef1_im_real * x_re_real)) +
                (((coef3_re_real * x_im_real) + (coef3_im_real * x_re_real)) * mag2_real);

            ideal_re_q15_real = ideal_re_real * 32768.0;
            ideal_im_q15_real = ideal_im_real * 32768.0;

            if (ideal_re_q15_real > 32767.0) begin
                clipped_re_q15_real = 32767.0;
                saturation_points <= saturation_points + 1;
            end
            else if (ideal_re_q15_real < -32768.0) begin
                clipped_re_q15_real = -32768.0;
                saturation_points <= saturation_points + 1;
            end
            else begin
                clipped_re_q15_real = ideal_re_q15_real;
            end

            if (ideal_im_q15_real > 32767.0) begin
                clipped_im_q15_real = 32767.0;
                saturation_points <= saturation_points + 1;
            end
            else if (ideal_im_q15_real < -32768.0) begin
                clipped_im_q15_real = -32768.0;
                saturation_points <= saturation_points + 1;
            end
            else begin
                clipped_im_q15_real = ideal_im_q15_real;
            end

            fixed_re_q15_real = dout_re;
            fixed_im_q15_real = dout_im;

            error_re_real = clipped_re_q15_real - fixed_re_q15_real;
            error_im_real = clipped_im_q15_real - fixed_im_q15_real;
            error_mag_real =
                $sqrt((error_re_real * error_re_real) + (error_im_real * error_im_real));

            ideal_mag_real =
                $sqrt((clipped_re_q15_real * clipped_re_q15_real) +
                      (clipped_im_q15_real * clipped_im_q15_real));

            sum_error_sq_re <= sum_error_sq_re + (error_re_real * error_re_real);
            sum_error_sq_im <= sum_error_sq_im + (error_im_real * error_im_real);
            sum_error_sq_mag <= sum_error_sq_mag + (error_mag_real * error_mag_real);
            sum_ideal_mag <= sum_ideal_mag + ideal_mag_real;

            if (((error_re_real < 0.0) ? -error_re_real : error_re_real) > max_abs_error_re_lsb)
                max_abs_error_re_lsb <= ((error_re_real < 0.0) ? -error_re_real : error_re_real);

            if (((error_im_real < 0.0) ? -error_im_real : error_im_real) > max_abs_error_im_lsb)
                max_abs_error_im_lsb <= ((error_im_real < 0.0) ? -error_im_real : error_im_real);

            if (error_mag_real > max_abs_error_mag_lsb) begin
                max_abs_error_mag_lsb <= error_mag_real;
                if (overflow)
                    max_error_source <= 3;
                else if (dut.clip_re || dut.clip_im)
                    max_error_source <= 2;
                else
                    max_error_source <= 1;
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
    coef1_re          = 16'sh4800;  //  0.562500000000
    coef1_im          = 16'sh1400;  //  0.156250000000
    coef3_re          = 16'sh1C00;  //  0.218750000000
    coef3_im          = -16'sh0C00; // -0.093750000000
    tx                = 0;
    rx                = 0;
    timeout           = 0;
    cycle_cnt         = 0;
    first_input_seen  = 1'b0;
    first_output_seen = 1'b0;
    first_input_cycle = -1;
    first_output_cycle= -1;
    pipeline_latency  = -1;
    stable_outputs    = 0;
    overflow_total    = 0;
    overflow_total_re = 0;
    overflow_total_im = 0;
    saturation_points = 0;
    max_error_source  = 0;
    sum_error_sq_re   = 0.0;
    sum_error_sq_im   = 0.0;
    sum_error_sq_mag  = 0.0;
    sum_ideal_mag     = 0.0;
    max_abs_error_re_lsb = 0.0;
    max_abs_error_im_lsb = 0.0;
    max_abs_error_mag_lsb = 0.0;
    coef1_re_real     = 18432.0 / 32768.0;
    coef1_im_real     = 5120.0 / 32768.0;
    coef3_re_real     = 7168.0 / 32768.0;
    coef3_im_real     = -3072.0 / 32768.0;

    repeat (4) @(posedge clk);
    rst = 1'b0;

    $display("");
    $display("======================================================================");
    $display("                 DPDnano-Lite TMQ Validation Suite");
    $display("======================================================================");
    $display("TEST         : TMQ005_NumericalPrecision");
    $display("Description  : Numerical Precision");
    $display("Levels       : %0d", NUM_LEVELS);
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
        current_amp = (level_idx + 1) * 10;
        pattern_sel = level_idx % 4;

        if (current_amp > 30720)
            current_amp = 30720;

        for (repeat_idx = 0; repeat_idx < REPEATS_PER_LEVEL; repeat_idx = repeat_idx + 1) begin
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

            in_re_hist[tx]  = din_re;
            in_im_hist[tx]  = din_im;
            stable_hist[tx] = (repeat_idx == (REPEATS_PER_LEVEL - 1));

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
    delivery_rate    = (100.0 * rx) / NUM_SAMPLES;
    overflow_rate    = (100.0 * overflow_total) / NUM_SAMPLES;
    percent_error_rms_mag = 0.0;
    percent_error_max_mag = 0.0;

    if (stable_outputs > 0 && sum_ideal_mag > 0.0) begin
        percent_error_rms_mag =
            (100.0 * $sqrt(sum_error_sq_mag / stable_outputs)) / (sum_ideal_mag / stable_outputs);
        percent_error_max_mag =
            (100.0 * max_abs_error_mag_lsb) / (sum_ideal_mag / stable_outputs);
    end

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
    $display("Numerical Precision");
    $display("----------------------------------------------");
    $display("Stable Outputs           : %0d", stable_outputs);
    $display("RMS Error RE [LSB]       : %0.12f", $sqrt(sum_error_sq_re / stable_outputs));
    $display("RMS Error IM [LSB]       : %0.12f", $sqrt(sum_error_sq_im / stable_outputs));
    $display("RMS Error MAG [LSB]      : %0.12f", $sqrt(sum_error_sq_mag / stable_outputs));
    $display("Max Error RE [LSB]       : %0.12f", max_abs_error_re_lsb);
    $display("Max Error IM [LSB]       : %0.12f", max_abs_error_im_lsb);
    $display("Max Error MAG [LSB]      : %0.12f", max_abs_error_mag_lsb);
    $display("RMS Error MAG [%%]       : %0.12f", percent_error_rms_mag);
    $display("Max Error MAG [%%]       : %0.12f", percent_error_max_mag);
    $display("Saturation Points        : %0d", saturation_points);

    $display("");
    $display("Overflow Statistics");
    $display("----------------------------------------------");
    $display("Overflow Events          : %0d", overflow_total);
    $display("Overflow RE              : %0d", overflow_total_re);
    $display("Overflow IM              : %0d", overflow_total_im);
    $display("Overflow Rate            : %0.2f %%", overflow_rate);

    $display("");
    $display("Simulation");
    $display("----------------------------------------------");
    $display("Simulation Cycles        : %0d", cycle_cnt);
    $display("Simulation Time          : %0d ns", cycle_cnt * 10);

    $display("");
    $display("Overall Result");
    $display("----------------------------------------------");

    if ((rx == tx) &&
        (pipeline_latency == EXPECTED_LATENCY) &&
        (stable_outputs == NUM_LEVELS) &&
        (timeout < TIMEOUT_CYCLES))
        $display("PASS");
    else
        $display("FAIL");

    summary_fd = $fopen("../tb_v3_2/tmq005_numerical_precision_summary.txt", "w");
    if (summary_fd != 0) begin
        $fwrite(summary_fd, "test_name=TMQ005_NumericalPrecision\n");
        $fwrite(summary_fd, "description=Numerical Precision\n");
        $fwrite(summary_fd, "num_levels=%0d\n", NUM_LEVELS);
        $fwrite(summary_fd, "repeats_per_level=%0d\n", REPEATS_PER_LEVEL);
        $fwrite(summary_fd, "num_samples=%0d\n", NUM_SAMPLES);
        $fwrite(summary_fd, "vectors_tx=%0d\n", tx);
        $fwrite(summary_fd, "vectors_rx=%0d\n", rx);
        $fwrite(summary_fd, "delivery_rate_pct=%0.6f\n", delivery_rate);
        $fwrite(summary_fd, "expected_latency=%0d\n", EXPECTED_LATENCY);
        $fwrite(summary_fd, "measured_latency=%0d\n", pipeline_latency);
        $fwrite(summary_fd, "stable_outputs=%0d\n", stable_outputs);
        $fwrite(summary_fd, "coef1_q15=%0d\n", coef1_re);
        $fwrite(summary_fd, "coef1_im_q15=%0d\n", coef1_im);
        $fwrite(summary_fd, "coef3_q15=%0d\n", coef3_re);
        $fwrite(summary_fd, "coef3_im_q15=%0d\n", coef3_im);
        $fwrite(summary_fd, "coef1_re_real=%0.12f\n", coef1_re_real);
        $fwrite(summary_fd, "coef1_im_real=%0.12f\n", coef1_im_real);
        $fwrite(summary_fd, "coef3_re_real=%0.12f\n", coef3_re_real);
        $fwrite(summary_fd, "coef3_im_real=%0.12f\n", coef3_im_real);
        $fwrite(summary_fd, "sum_error_sq_re=%0.12f\n", sum_error_sq_re);
        $fwrite(summary_fd, "sum_error_sq_im=%0.12f\n", sum_error_sq_im);
        $fwrite(summary_fd, "sum_error_sq_mag=%0.12f\n", sum_error_sq_mag);
        $fwrite(summary_fd, "sum_ideal_mag=%0.12f\n", sum_ideal_mag);
        $fwrite(summary_fd, "max_abs_error_re_lsb=%0.12f\n", max_abs_error_re_lsb);
        $fwrite(summary_fd, "max_abs_error_im_lsb=%0.12f\n", max_abs_error_im_lsb);
        $fwrite(summary_fd, "max_abs_error_mag_lsb=%0.12f\n", max_abs_error_mag_lsb);
        $fwrite(summary_fd, "percent_error_rms_mag=%0.12f\n", percent_error_rms_mag);
        $fwrite(summary_fd, "percent_error_max_mag=%0.12f\n", percent_error_max_mag);
        $fwrite(summary_fd, "saturation_points=%0d\n", saturation_points);
        $fwrite(summary_fd, "max_error_source=%0d\n", max_error_source);
        $fwrite(summary_fd, "overflow_total=%0d\n", overflow_total);
        $fwrite(summary_fd, "overflow_total_re=%0d\n", overflow_total_re);
        $fwrite(summary_fd, "overflow_total_im=%0d\n", overflow_total_im);
        $fwrite(summary_fd, "overflow_rate_pct=%0.6f\n", overflow_rate);
        $fwrite(summary_fd, "simulation_cycles=%0d\n", cycle_cnt);
        $fwrite(summary_fd, "simulation_time_ns=%0d\n", cycle_cnt * 10);
        $fwrite(summary_fd, "timeout_cycles=%0d\n", timeout);
        $fwrite(summary_fd, "pass_flag=%0d\n",
            ((rx == tx) &&
             (pipeline_latency == EXPECTED_LATENCY) &&
             (stable_outputs == NUM_LEVELS) &&
             (timeout < TIMEOUT_CYCLES)));
        $fclose(summary_fd);
    end

    $finish;
end

endmodule
