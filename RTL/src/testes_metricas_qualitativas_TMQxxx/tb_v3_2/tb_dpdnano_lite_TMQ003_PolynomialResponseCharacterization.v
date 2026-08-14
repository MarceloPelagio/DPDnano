`timescale 1ns/1ps
`include "../rtl_v3_1/config.vh"

module tb_dpdnano_lite_TMQ003_PolynomialResponseCharacterization;

// ============================================================
// DPDnano-Lite TMQ Suite
// ============================================================

localparam integer NUM_LEVELS        = 512;
localparam integer REPEATS_PER_LEVEL = 8;
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

integer csv_fd;
integer summary_fd;
integer tx;
integer rx;
integer timeout;
integer cycle_cnt;
integer level_idx;
integer repeat_idx;
integer current_amp;
integer current_level;
integer overflow_total;
integer overflow_total_re;
integer overflow_total_im;
integer first_input_cycle;
integer first_output_cycle;
integer pipeline_latency;
integer stable_outputs;
integer max_output_abs;
integer max_linear_abs;
integer max_poly_abs;
integer linear_q15_tmp;
integer poly_q15_tmp;
integer output_abs_tmp;
integer linear_abs_tmp;
integer poly_abs_tmp;

reg first_input_seen;
reg first_output_seen;

reg signed [`DATA_WIDTH-1:0] amp_hist [0:NUM_SAMPLES-1];
reg [15:0] level_hist [0:NUM_SAMPLES-1];
reg stable_hist [0:NUM_SAMPLES-1];

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

        linear_q15_tmp = dut.lin_re_d >>> 15;
        poly_q15_tmp   = dut.poly_re >>> 15;

        output_abs_tmp = (dout_re < 0) ? -dout_re : dout_re;
        linear_abs_tmp = (linear_q15_tmp < 0) ? -linear_q15_tmp : linear_q15_tmp;
        poly_abs_tmp   = (poly_q15_tmp < 0) ? -poly_q15_tmp : poly_q15_tmp;

        if (stable_hist[rx]) begin
            stable_outputs <= stable_outputs + 1;

            if (output_abs_tmp > max_output_abs)
                max_output_abs <= output_abs_tmp;

            if (linear_abs_tmp > max_linear_abs)
                max_linear_abs <= linear_abs_tmp;

            if (poly_abs_tmp > max_poly_abs)
                max_poly_abs <= poly_abs_tmp;
        end

        $fwrite(
            csv_fd,
            "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d\n",
            rx,
            cycle_cnt,
            level_hist[rx],
            amp_hist[rx],
            linear_q15_tmp,
            poly_q15_tmp,
            dout_re,
            stable_hist[rx],
            overflow,
            overflow_re,
            overflow_im
        );
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
    coef1_re          = 16'sh4000;
    coef1_im          = 16'sh0000;
    coef3_re          = 16'sh2000;
    coef3_im          = 16'sh0000;
    tx                = 0;
    rx                = 0;
    timeout           = 0;
    cycle_cnt         = 0;
    overflow_total    = 0;
    overflow_total_re = 0;
    overflow_total_im = 0;
    first_input_seen  = 1'b0;
    first_output_seen = 1'b0;
    first_input_cycle = -1;
    first_output_cycle= -1;
    pipeline_latency  = -1;
    stable_outputs    = 0;
    max_output_abs    = 0;
    max_linear_abs    = 0;
    max_poly_abs      = 0;
    coef1_re_real     = 16384.0 / 32768.0;
    coef1_im_real     = 0.0;
    coef3_re_real     = 8192.0 / 32768.0;
    coef3_im_real     = 0.0;

    csv_fd = $fopen("../tb_v3_2/tmq003_polynomial_response_samples.csv", "w");
    if (csv_fd == 0) begin
        $display("[FAIL] Unable to open TMQ003 CSV output file.");
        $finish;
    end

    $fwrite(
        csv_fd,
        "sample_idx,cycle,level_idx,input_re,linear_re_q15,poly_re_q15,output_re,is_stable,overflow,overflow_re,overflow_im\n"
    );

    repeat (4) @(posedge clk);
    rst = 1'b0;

    $display("");
    $display("======================================================================");
    $display("                 DPDnano-Lite TMQ Validation Suite");
    $display("======================================================================");
    $display("TEST         : TMQ003_PolynomialResponseCharacterization");
    $display("Description  : Polynomial Response Characterization");
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
        current_level = level_idx + 1;
        current_amp = current_level * 48;

        if (current_amp > 24576)
            current_amp = 24576;

        for (repeat_idx = 0; repeat_idx < REPEATS_PER_LEVEL; repeat_idx = repeat_idx + 1) begin
            @(posedge clk);
            in_valid = 1'b1;
            din_re   = current_amp[`DATA_WIDTH-1:0];
            din_im   = 16'sd0;

            amp_hist[tx]    = current_amp[`DATA_WIDTH-1:0];
            level_hist[tx]  = current_level[15:0];
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
    $display("Response Peaks");
    $display("----------------------------------------------");
    $display("Stable Outputs           : %0d", stable_outputs);
    $display("Max |Linear|             : %0d", max_linear_abs);
    $display("Max |Polynomial|         : %0d", max_poly_abs);
    $display("Max |Output|             : %0d", max_output_abs);

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

    summary_fd = $fopen("../tb_v3_2/tmq003_polynomial_response_summary.txt", "w");
    if (summary_fd != 0) begin
        $fwrite(summary_fd, "test_name=TMQ003_PolynomialResponseCharacterization\n");
        $fwrite(summary_fd, "description=Polynomial Response Characterization\n");
        $fwrite(summary_fd, "num_levels=%0d\n", NUM_LEVELS);
        $fwrite(summary_fd, "repeats_per_level=%0d\n", REPEATS_PER_LEVEL);
        $fwrite(summary_fd, "num_samples=%0d\n", NUM_SAMPLES);
        $fwrite(summary_fd, "coef1_re_q15=%0d\n", coef1_re);
        $fwrite(summary_fd, "coef1_im_q15=%0d\n", coef1_im);
        $fwrite(summary_fd, "coef3_re_q15=%0d\n", coef3_re);
        $fwrite(summary_fd, "coef3_im_q15=%0d\n", coef3_im);
        $fwrite(summary_fd, "coef1_re_real=%0.12f\n", coef1_re_real);
        $fwrite(summary_fd, "coef1_im_real=%0.12f\n", coef1_im_real);
        $fwrite(summary_fd, "coef3_re_real=%0.12f\n", coef3_re_real);
        $fwrite(summary_fd, "coef3_im_real=%0.12f\n", coef3_im_real);
        $fwrite(summary_fd, "vectors_tx=%0d\n", tx);
        $fwrite(summary_fd, "vectors_rx=%0d\n", rx);
        $fwrite(summary_fd, "delivery_rate_pct=%0.6f\n", delivery_rate);
        $fwrite(summary_fd, "expected_latency=%0d\n", EXPECTED_LATENCY);
        $fwrite(summary_fd, "measured_latency=%0d\n", pipeline_latency);
        $fwrite(summary_fd, "stable_outputs=%0d\n", stable_outputs);
        $fwrite(summary_fd, "max_linear_abs=%0d\n", max_linear_abs);
        $fwrite(summary_fd, "max_poly_abs=%0d\n", max_poly_abs);
        $fwrite(summary_fd, "max_output_abs=%0d\n", max_output_abs);
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

    $fclose(csv_fd);
    $finish;
end

endmodule
