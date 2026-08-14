`timescale 1ns/1ps
`include "../rtl_v3_1/config.vh"

module tb_dpdnano_lite_TMQ010_RepeatabilityCharacterization;

// ============================================================
// DPDnano-Lite TMQ Suite
// ============================================================

localparam integer ASSAY_SAMPLES     = 1024;
localparam integer NUM_RUNS          = 1000;
localparam integer NUM_SAMPLES       = ASSAY_SAMPLES * NUM_RUNS;
localparam integer TIMEOUT_CYCLES    = NUM_SAMPLES * 12;
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
integer run_idx;
integer sample_idx;
integer first_input_cycle;
integer first_output_cycle;
integer pipeline_latency;
integer overflow_total;
integer overflow_total_re;
integer overflow_total_im;
integer saturated_output_count;
integer xz_errors;
integer mismatch_count;
integer mismatch_re_count;
integer mismatch_im_count;
integer first_mismatch_run;
integer first_mismatch_sample;
integer first_mismatch_expected_re;
integer first_mismatch_expected_im;
integer first_mismatch_observed_re;
integer first_mismatch_observed_im;
integer output_index_in_run;
integer pattern_sel;
integer base_amp;
integer expected_re;
integer expected_im;

reg first_input_seen;
reg first_output_seen;
reg signed [`DATA_WIDTH-1:0] assay_re [0:ASSAY_SAMPLES-1];
reg signed [`DATA_WIDTH-1:0] assay_im [0:ASSAY_SAMPLES-1];
reg signed [`DATA_WIDTH-1:0] golden_re [0:ASSAY_SAMPLES-1];
reg signed [`DATA_WIDTH-1:0] golden_im [0:ASSAY_SAMPLES-1];
reg [31:0] lfsr_seed;

real delivery_rate;
real overflow_rate;
real repeatability_pct;
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
            output_index_in_run = rx % ASSAY_SAMPLES;

            if (rx < ASSAY_SAMPLES) begin
                golden_re[output_index_in_run] <= dout_re;
                golden_im[output_index_in_run] <= dout_im;
            end
            else begin
                expected_re = golden_re[output_index_in_run];
                expected_im = golden_im[output_index_in_run];

                if (dout_re !== expected_re || dout_im !== expected_im) begin
                    mismatch_count <= mismatch_count + 1;

                    if (dout_re !== expected_re)
                        mismatch_re_count <= mismatch_re_count + 1;

                    if (dout_im !== expected_im)
                        mismatch_im_count <= mismatch_im_count + 1;

                    if (first_mismatch_run < 0) begin
                        first_mismatch_run <= rx / ASSAY_SAMPLES;
                        first_mismatch_sample <= output_index_in_run;
                        first_mismatch_expected_re <= expected_re;
                        first_mismatch_expected_im <= expected_im;
                        first_mismatch_observed_re <= dout_re;
                        first_mismatch_observed_im <= dout_im;
                    end
                end
            end
        end
    end

    if (overflow)
        overflow_total <= overflow_total + 1;

    if (overflow_re)
        overflow_total_re <= overflow_total_re + 1;

    if (overflow_im)
        overflow_total_im <= overflow_total_im + 1;

    if (out_valid && (overflow || overflow_re || overflow_im))
        saturated_output_count <= saturated_output_count + 1;
end

initial begin
    rst               = 1'b1;
    in_valid          = 1'b0;
    din_re            = '0;
    din_im            = '0;
    coef1_re          = 16'sh6C00;  // 0.843750
    coef1_im          = 16'sh2800;  // 0.312500
    coef3_re          = 16'sh3400;  // 0.406250
    coef3_im          = -16'sh1800; // -0.187500
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
    saturated_output_count = 0;
    xz_errors         = 0;
    mismatch_count    = 0;
    mismatch_re_count = 0;
    mismatch_im_count = 0;
    first_mismatch_run = -1;
    first_mismatch_sample = -1;
    first_mismatch_expected_re = 0;
    first_mismatch_expected_im = 0;
    first_mismatch_observed_re = 0;
    first_mismatch_observed_im = 0;
    first_input_seen  = 1'b0;
    first_output_seen = 1'b0;
    lfsr_seed         = 32'h1357_9BDF;
    coef1_re_real     = 27648.0 / 32768.0;
    coef1_im_real     = 10240.0 / 32768.0;
    coef3_re_real     = 13312.0 / 32768.0;
    coef3_im_real     = -6144.0 / 32768.0;

    for (sample_idx = 0; sample_idx < ASSAY_SAMPLES; sample_idx = sample_idx + 1) begin
        lfsr_seed = {lfsr_seed[30:0], lfsr_seed[31] ^ lfsr_seed[21] ^ lfsr_seed[1] ^ lfsr_seed[0]};
        base_amp = 20000 + ((lfsr_seed[11:0] * 9) % 12000);
        if (base_amp > 30000)
            base_amp = 30000;
        pattern_sel = sample_idx % 4;

        case (pattern_sel)
            0: begin
                assay_re[sample_idx] = base_amp[`DATA_WIDTH-1:0];
                assay_im[sample_idx] = (base_amp >>> 1);
            end
            1: begin
                assay_re[sample_idx] = -($signed(base_amp >>> 1));
                assay_im[sample_idx] = base_amp[`DATA_WIDTH-1:0];
            end
            2: begin
                assay_re[sample_idx] = base_amp[`DATA_WIDTH-1:0];
                assay_im[sample_idx] = -($signed(base_amp >>> 1));
            end
            default: begin
                assay_re[sample_idx] = -($signed(base_amp >>> 1));
                assay_im[sample_idx] = -($signed(base_amp));
            end
        endcase
    end

    repeat (4) @(posedge clk);
    rst = 1'b0;

    $display("");
    $display("======================================================================");
    $display("                 DPDnano-Lite TMQ Validation Suite");
    $display("======================================================================");
    $display("TEST         : TMQ010_RepeatabilityCharacterization");
    $display("Description  : Repeatability Under Saturation and Stress");
    $display("Assay Samples: %0d", ASSAY_SAMPLES);
    $display("Runs         : %0d", NUM_RUNS);
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

    for (run_idx = 0; run_idx < NUM_RUNS; run_idx = run_idx + 1) begin
        for (sample_idx = 0; sample_idx < ASSAY_SAMPLES; sample_idx = sample_idx + 1) begin
            @(posedge clk);
            in_valid = 1'b1;
            din_re   = assay_re[sample_idx];
            din_im   = assay_im[sample_idx];
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
    repeatability_pct = (100.0 * ((NUM_SAMPLES - ASSAY_SAMPLES) - mismatch_count)) /
                        (NUM_SAMPLES - ASSAY_SAMPLES);

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
    $display("Repeatability");
    $display("----------------------------------------------");
    $display("Reference Assay Samples  : %0d", ASSAY_SAMPLES);
    $display("Repeated Runs            : %0d", NUM_RUNS);
    $display("Compared Samples         : %0d", NUM_SAMPLES - ASSAY_SAMPLES);
    $display("Bitwise Mismatches       : %0d", mismatch_count);
    $display("Mismatch RE              : %0d", mismatch_re_count);
    $display("Mismatch IM              : %0d", mismatch_im_count);
    $display("Repeatability            : %0.12f %%", repeatability_pct);

    if (first_mismatch_run >= 0) begin
        $display("First Mismatch Run       : %0d", first_mismatch_run);
        $display("First Mismatch Sample    : %0d", first_mismatch_sample);
        $display("Expected RE/IM           : %0d / %0d", first_mismatch_expected_re, first_mismatch_expected_im);
        $display("Observed RE/IM           : %0d / %0d", first_mismatch_observed_re, first_mismatch_observed_im);
    end

    $display("");
    $display("Overflow Statistics");
    $display("----------------------------------------------");
    $display("Overflow Events          : %0d", overflow_total);
    $display("Overflow RE              : %0d", overflow_total_re);
    $display("Overflow IM              : %0d", overflow_total_im);
    $display("Saturated Outputs        : %0d", saturated_output_count);
    $display("Overflow Rate            : %0.6f %%", overflow_rate);
    $display("X/Z Errors               : %0d", xz_errors);

    $display("");
    $display("Overall Result");
    $display("----------------------------------------------");

    if ((rx == tx) &&
        (pipeline_latency == EXPECTED_LATENCY) &&
        (mismatch_count == 0) &&
        (xz_errors == 0) &&
        (timeout < TIMEOUT_CYCLES))
        $display("PASS");
    else
        $display("FAIL");

    summary_fd = $fopen("../tb_v3_2/tmq010_repeatability_summary.txt", "w");
    if (summary_fd != 0) begin
        $fwrite(summary_fd, "test_name=TMQ010_RepeatabilityCharacterization\n");
        $fwrite(summary_fd, "description=Repeatability Under Saturation and Stress\n");
        $fwrite(summary_fd, "assay_samples=%0d\n", ASSAY_SAMPLES);
        $fwrite(summary_fd, "num_runs=%0d\n", NUM_RUNS);
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
        $fwrite(summary_fd, "mismatch_count=%0d\n", mismatch_count);
        $fwrite(summary_fd, "mismatch_re_count=%0d\n", mismatch_re_count);
        $fwrite(summary_fd, "mismatch_im_count=%0d\n", mismatch_im_count);
        $fwrite(summary_fd, "repeatability_pct=%0.12f\n", repeatability_pct);
        $fwrite(summary_fd, "first_mismatch_run=%0d\n", first_mismatch_run);
        $fwrite(summary_fd, "first_mismatch_sample=%0d\n", first_mismatch_sample);
        $fwrite(summary_fd, "first_mismatch_expected_re=%0d\n", first_mismatch_expected_re);
        $fwrite(summary_fd, "first_mismatch_expected_im=%0d\n", first_mismatch_expected_im);
        $fwrite(summary_fd, "first_mismatch_observed_re=%0d\n", first_mismatch_observed_re);
        $fwrite(summary_fd, "first_mismatch_observed_im=%0d\n", first_mismatch_observed_im);
        $fwrite(summary_fd, "overflow_total=%0d\n", overflow_total);
        $fwrite(summary_fd, "overflow_total_re=%0d\n", overflow_total_re);
        $fwrite(summary_fd, "overflow_total_im=%0d\n", overflow_total_im);
        $fwrite(summary_fd, "saturated_output_count=%0d\n", saturated_output_count);
        $fwrite(summary_fd, "overflow_rate_pct=%0.6f\n", overflow_rate);
        $fwrite(summary_fd, "xz_errors=%0d\n", xz_errors);
        $fwrite(summary_fd, "simulation_cycles=%0d\n", cycle_cnt);
        $fwrite(summary_fd, "simulation_time_ns=%0d\n", cycle_cnt * 10);
        $fwrite(summary_fd, "timeout_cycles=%0d\n", timeout);
        $fwrite(summary_fd, "pass_flag=%0d\n",
            ((rx == tx) &&
             (pipeline_latency == EXPECTED_LATENCY) &&
             (mismatch_count == 0) &&
             (xz_errors == 0) &&
             (timeout < TIMEOUT_CYCLES)));
        $fclose(summary_fd);
    end

    $finish;
end

endmodule
