`timescale 1ns/1ps
`include "../rtl_v3_1/config.vh"

module tb_dpdnano_lite_TMQ007_StabilityTest;

// ============================================================
// DPDnano-Lite TMQ Suite
// ============================================================

localparam integer NUM_SAMPLES      = 100000;
localparam integer TIMEOUT_CYCLES   = NUM_SAMPLES * 24;
localparam integer EXPECTED_LATENCY = 5;

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
integer glitch_errors;
integer logical_nan_errors;
integer stall_errors;
integer oscillation_flags;
integer stable_output_count;
integer same_output_run;
integer max_same_output_run;
integer last_dout_re;
integer last_dout_im;

reg first_input_seen;
reg first_output_seen;
reg have_last_output;
reg prev_round_valid;
reg [31:0] lfsr_a;
reg [31:0] lfsr_b;

real delivery_rate;
real overflow_rate;
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
    prev_round_valid <= dut.round_valid;

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

        stable_output_count <= stable_output_count + 1;

        if ((^dout_re === 1'bx) || (^dout_im === 1'bx) ||
            (^out_valid === 1'bx) || (^overflow === 1'bx) ||
            (^overflow_re === 1'bx) || (^overflow_im === 1'bx)) begin
            xz_errors <= xz_errors + 1;
        end

        if ((overflow && !(overflow_re || overflow_im)) ||
            (!overflow && (overflow_re || overflow_im))) begin
            logical_nan_errors <= logical_nan_errors + 1;
        end

        if (have_last_output) begin
            // A synchronously valid output must come from the previous
            // rounding-valid stage. If not, flag a spurious valid pulse.
            if (!prev_round_valid) begin
                glitch_errors <= glitch_errors + 1;
            end

            if (dout_re === last_dout_re && dout_im === last_dout_im) begin
                same_output_run <= same_output_run + 1;
                if ((same_output_run + 1) > max_same_output_run)
                    max_same_output_run <= same_output_run + 1;
            end
            else begin
                if (same_output_run > 64)
                    oscillation_flags <= oscillation_flags + 1;
                same_output_run <= 1;
            end
        end
        else begin
            have_last_output <= 1'b1;
            same_output_run <= 1;
            max_same_output_run <= 1;
        end

        last_dout_re <= dout_re;
        last_dout_im <= dout_im;
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
    coef1_re          = 16'sh4200;  // 0.515625
    coef1_im          = 16'sh1200;  // 0.140625
    coef3_re          = 16'sh1600;  // 0.171875
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
    glitch_errors     = 0;
    logical_nan_errors= 0;
    stall_errors      = 0;
    oscillation_flags = 0;
    stable_output_count = 0;
    same_output_run   = 0;
    max_same_output_run = 0;
    last_dout_re      = 0;
    last_dout_im      = 0;
    first_input_seen  = 1'b0;
    first_output_seen = 1'b0;
    have_last_output  = 1'b0;
    prev_round_valid  = 1'b0;
    lfsr_a            = 32'hA5A5_5A5A;
    lfsr_b            = 32'h3C6E_F372;
    coef1_re_real     = 16896.0 / 32768.0;
    coef1_im_real     = 4608.0 / 32768.0;
    coef3_re_real     = 5632.0 / 32768.0;
    coef3_im_real     = -2560.0 / 32768.0;

    repeat (4) @(posedge clk);
    rst = 1'b0;

    $display("");
    $display("======================================================================");
    $display("                 DPDnano-Lite TMQ Validation Suite");
    $display("======================================================================");
    $display("TEST         : TMQ007_StabilityTest");
    $display("Description  : Stability Test");
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

        lfsr_a = {lfsr_a[30:0], lfsr_a[31] ^ lfsr_a[21] ^ lfsr_a[1] ^ lfsr_a[0]};
        lfsr_b = {lfsr_b[30:0], lfsr_b[31] ^ lfsr_b[6] ^ lfsr_b[4] ^ lfsr_b[2]};

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

    if (rx < NUM_SAMPLES)
        stall_errors = stall_errors + 1;

    pipeline_latency = first_output_cycle - first_input_cycle;
    delivery_rate = (100.0 * rx) / NUM_SAMPLES;
    overflow_rate = (100.0 * overflow_total) / NUM_SAMPLES;

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
    $display("Stability Checks");
    $display("----------------------------------------------");
    $display("Overflow Events          : %0d", overflow_total);
    $display("Overflow RE              : %0d", overflow_total_re);
    $display("Overflow IM              : %0d", overflow_total_im);
    $display("X/Z Errors               : %0d", xz_errors);
    $display("Logical NaN Errors       : %0d", logical_nan_errors);
    $display("Glitch Errors            : %0d", glitch_errors);
    $display("Stall Errors             : %0d", stall_errors);
    $display("Oscillation Flags        : %0d", oscillation_flags);
    $display("Max Same Output Run      : %0d", max_same_output_run);

    $display("");
    $display("Overall Result");
    $display("----------------------------------------------");

    if ((rx == tx) &&
        (pipeline_latency == EXPECTED_LATENCY) &&
        (xz_errors == 0) &&
        (logical_nan_errors == 0) &&
        (glitch_errors == 0) &&
        (stall_errors == 0) &&
        (oscillation_flags == 0) &&
        (timeout < TIMEOUT_CYCLES))
        $display("PASS");
    else
        $display("FAIL");

    summary_fd = $fopen("../tb_v3_2/tmq007_stability_summary.txt", "w");
    if (summary_fd != 0) begin
        $fwrite(summary_fd, "test_name=TMQ007_StabilityTest\n");
        $fwrite(summary_fd, "description=Stability Test\n");
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
        $fwrite(summary_fd, "logical_nan_errors=%0d\n", logical_nan_errors);
        $fwrite(summary_fd, "glitch_errors=%0d\n", glitch_errors);
        $fwrite(summary_fd, "stall_errors=%0d\n", stall_errors);
        $fwrite(summary_fd, "oscillation_flags=%0d\n", oscillation_flags);
        $fwrite(summary_fd, "max_same_output_run=%0d\n", max_same_output_run);
        $fwrite(summary_fd, "simulation_cycles=%0d\n", cycle_cnt);
        $fwrite(summary_fd, "simulation_time_ns=%0d\n", cycle_cnt * 10);
        $fwrite(summary_fd, "timeout_cycles=%0d\n", timeout);
        $fwrite(summary_fd, "pass_flag=%0d\n",
            ((rx == tx) &&
             (pipeline_latency == EXPECTED_LATENCY) &&
             (xz_errors == 0) &&
             (logical_nan_errors == 0) &&
             (glitch_errors == 0) &&
             (stall_errors == 0) &&
             (oscillation_flags == 0) &&
             (timeout < TIMEOUT_CYCLES)));
        $fclose(summary_fd);
    end

    $finish;
end

endmodule
