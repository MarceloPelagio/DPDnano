`timescale 1ns/1ps
`include "../rtl_v3_1/config.vh"

module tb_dpdnano_lite_TMQ013_OperationalLimitStressTest;

// ============================================================
// DPDnano-Lite TMQ Suite
// ============================================================

localparam integer NUM_LEVELS          = 48;
localparam integer SAMPLES_PER_LEVEL   = 256;
localparam integer NUM_SAMPLES         = NUM_LEVELS * SAMPLES_PER_LEVEL;
localparam integer TIMEOUT_CYCLES      = NUM_SAMPLES * 20;
localparam integer EXPECTED_LATENCY    = 5;
localparam integer PERSIST_THRESHOLD   = 32;

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
integer sample_idx;
integer current_amp;
integer first_input_cycle;
integer first_output_cycle;
integer pipeline_latency;
integer xz_errors;
integer overflow_total;
integer overflow_total_re;
integer overflow_total_im;
integer saturated_output_count;
integer safe_output_count;
integer current_level_output_count;
integer current_level_saturated_count;
integer current_level_overflow_count;
integer current_level_xz_count;
integer current_level_max_abs_out;
integer current_level_first_sat_output;
integer current_level_last_sat_output;
integer current_level_safe_flag;
integer first_saturation_level;
integer first_saturation_sample;
integer first_saturation_seen;
integer first_persistent_level;
integer first_persistent_sample;
integer first_persistent_seen;
integer persistent_run_len;
integer max_persistent_run_len;
integer longest_safe_run_before_sat;
integer safe_run_len;
integer current_output_level_idx;
integer level_hist [0:NUM_SAMPLES-1];
integer pattern_hist [0:NUM_SAMPLES-1];
integer amp_hist [0:NUM_SAMPLES-1];
integer sample_abs_re;
integer sample_abs_im;
integer sample_abs_out;
integer boundary_score;
integer worst_safe_level;
integer worst_safe_margin_lsb;
integer worst_safe_amp_q15;
integer level_margin_lsb;
integer saturation_ratio_milli;
integer persistent_ratio_milli;
integer output_idx_in_level;
integer safe_ratio_milli;

reg first_input_seen;
reg first_output_seen;
reg [31:0] lfsr_a;
reg [31:0] lfsr_b;

real delivery_rate;
real saturation_ratio_pct;
real persistent_ratio_pct;
real overflow_rate_pct;
real coef1_re_real;
real coef1_im_real;
real coef3_re_real;
real coef3_im_real;
real stress_score;
real boundary_amplitude_real;
real worst_safe_amplitude_real;
real safe_ratio_pct;

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

task prepare_level;
begin
    current_level_output_count = 0;
    current_level_saturated_count = 0;
    current_level_overflow_count = 0;
    current_level_xz_count = 0;
    current_level_max_abs_out = 0;
    current_level_first_sat_output = -1;
    current_level_last_sat_output = -1;
end
endtask

task emit_stimulus;
    input integer amp_q15;
    input integer pattern_sel;
begin
    case (pattern_sel)
        0: begin
            din_re = amp_q15[`DATA_WIDTH-1:0];
            din_im = (amp_q15 >>> 1);
        end
        1: begin
            din_re = (amp_q15 >>> 1);
            din_im = amp_q15[`DATA_WIDTH-1:0];
        end
        2: begin
            din_re = amp_q15[`DATA_WIDTH-1:0];
            din_im = -($signed(amp_q15 >>> 1));
        end
        default: begin
            din_re = -($signed(amp_q15 >>> 1));
            din_im = amp_q15[`DATA_WIDTH-1:0];
        end
    endcase
end
endtask

always @(posedge clk) begin
    cycle_cnt <= cycle_cnt + 1;

    if (in_valid) begin
        tx <= tx + 1;
        if (!first_input_seen) begin
            first_input_seen  <= 1'b1;
            first_input_cycle <= cycle_cnt;
        end
    end

    if (out_valid) begin
        rx <= rx + 1;

        if (!first_output_seen) begin
            first_output_seen  <= 1'b1;
            first_output_cycle <= cycle_cnt;
        end

        current_output_level_idx = level_hist[rx];
        current_level_output_count <= current_level_output_count + 1;

        if ((^dout_re === 1'bx) || (^dout_im === 1'bx) ||
            (^overflow === 1'bx) || (^overflow_re === 1'bx) ||
            (^overflow_im === 1'bx)) begin
            xz_errors <= xz_errors + 1;
            current_level_xz_count <= current_level_xz_count + 1;
        end
        else begin
            sample_abs_re = (dout_re < 0) ? -dout_re : dout_re;
            sample_abs_im = (dout_im < 0) ? -dout_im : dout_im;
            sample_abs_out = (sample_abs_re > sample_abs_im) ? sample_abs_re : sample_abs_im;
            if (sample_abs_out > current_level_max_abs_out)
                current_level_max_abs_out <= sample_abs_out;

            if (overflow || overflow_re || overflow_im) begin
                overflow_total <= overflow_total + 1;
                saturated_output_count <= saturated_output_count + 1;
                current_level_saturated_count <= current_level_saturated_count + 1;
                current_level_overflow_count <= current_level_overflow_count + 1;

                if (!first_saturation_seen) begin
                    first_saturation_seen <= 1'b1;
                    first_saturation_level <= current_output_level_idx;
                    first_saturation_sample <= rx;
                end

                if (current_level_first_sat_output < 0)
                    current_level_first_sat_output <= current_level_output_count;
                current_level_last_sat_output <= current_level_output_count;

                persistent_run_len <= persistent_run_len + 1;
                if ((persistent_run_len + 1) > max_persistent_run_len)
                    max_persistent_run_len <= persistent_run_len + 1;

                if (!first_persistent_seen && ((persistent_run_len + 1) >= PERSIST_THRESHOLD)) begin
                    first_persistent_seen <= 1'b1;
                    first_persistent_level <= current_output_level_idx;
                    first_persistent_sample <= rx;
                end

                safe_run_len <= 0;
            end
            else begin
                safe_output_count <= safe_output_count + 1;
                safe_run_len <= safe_run_len + 1;
                if ((safe_run_len + 1) > longest_safe_run_before_sat)
                    longest_safe_run_before_sat <= safe_run_len + 1;
                persistent_run_len <= 0;
            end
        end
    end

    if (overflow_re)
        overflow_total_re <= overflow_total_re + 1;

    if (overflow_im)
        overflow_total_im <= overflow_total_im + 1;
end

initial begin
    rst                     = 1'b1;
    in_valid                = 1'b0;
    din_re                  = '0;
    din_im                  = '0;
    coef1_re                = 16'sh6800;  // 0.812500
    coef1_im                = 16'sh2000;  // 0.250000
    coef3_re                = 16'sh3000;  // 0.375000
    coef3_im                = -16'sh1400; // -0.156250
    tx                      = 0;
    rx                      = 0;
    timeout                 = 0;
    cycle_cnt               = 0;
    first_input_cycle       = -1;
    first_output_cycle      = -1;
    pipeline_latency        = -1;
    xz_errors               = 0;
    overflow_total          = 0;
    overflow_total_re       = 0;
    overflow_total_im       = 0;
    saturated_output_count  = 0;
    safe_output_count       = 0;
    first_saturation_level  = -1;
    first_saturation_sample = -1;
    first_saturation_seen   = 1'b0;
    first_persistent_level  = -1;
    first_persistent_sample = -1;
    first_persistent_seen   = 1'b0;
    persistent_run_len      = 0;
    max_persistent_run_len  = 0;
    longest_safe_run_before_sat = 0;
    safe_run_len            = 0;
    current_output_level_idx= 0;
    boundary_score          = 0;
    worst_safe_level        = -1;
    worst_safe_margin_lsb   = 32767;
    worst_safe_amp_q15      = 0;
    saturation_ratio_milli  = 0;
    persistent_ratio_milli  = 0;
    safe_ratio_milli        = 0;
    first_input_seen        = 1'b0;
    first_output_seen       = 1'b0;
    lfsr_a                  = 32'hD4E1_6A2B;
    lfsr_b                  = 32'h91C3_5F07;
    coef1_re_real           = 26624.0 / 32768.0;
    coef1_im_real           = 8192.0 / 32768.0;
    coef3_re_real           = 12288.0 / 32768.0;
    coef3_im_real           = -5120.0 / 32768.0;

    csv_fd = $fopen("../tb_v3_2/tmq013_operational_limit_stress_samples.csv", "w");
    if (csv_fd == 0) begin
        $display("[FAIL] Unable to open TMQ013 CSV output file.");
        $finish;
    end

    $fwrite(
        csv_fd,
        "level_idx,sample_idx,input_amp_q15,overflow_events,saturated_outputs,max_abs_out,margin_lsb,safe_flag\n"
    );

    repeat (4) @(posedge clk);
    rst = 1'b0;

    $display("");
    $display("======================================================================");
    $display("                 DPDnano-Lite TMQ Validation Suite");
    $display("======================================================================");
    $display("TEST         : TMQ013_OperationalLimitStressTest");
    $display("Description  : Operational Limit Stress Test");
    $display("Levels       : %0d", NUM_LEVELS);
    $display("Samples/Level: %0d", SAMPLES_PER_LEVEL);
    $display("Samples      : %0d", NUM_SAMPLES);
    $display("coef1_re [real]          : %0.12f", coef1_re_real);
    $display("coef1_im [real]          : %0.12f", coef1_im_real);
    $display("coef3_re [real]          : %0.12f", coef3_re_real);
    $display("coef3_im [real]          : %0.12f", coef3_im_real);
    $display("======================================================================");
    $display("");

    for (level_idx = 0; level_idx < NUM_LEVELS; level_idx = level_idx + 1) begin
        prepare_level();

        current_amp = 4096 + (level_idx * 576);
        if (current_amp > 32767)
            current_amp = 32767;

        for (sample_idx = 0; sample_idx < SAMPLES_PER_LEVEL; sample_idx = sample_idx + 1) begin
            lfsr_a = {lfsr_a[30:0], lfsr_a[31] ^ lfsr_a[21] ^ lfsr_a[1] ^ lfsr_a[0]};
            lfsr_b = {lfsr_b[30:0], lfsr_b[31] ^ lfsr_b[6] ^ lfsr_b[4] ^ lfsr_b[2]};

            @(posedge clk);
            in_valid = 1'b1;
            emit_stimulus(current_amp, sample_idx % 4);

            level_hist[tx] = level_idx;
            pattern_hist[tx] = sample_idx % 4;
            amp_hist[tx] = current_amp;
        end

        @(posedge clk);
        in_valid = 1'b0;
        din_re   = 16'sd0;
        din_im   = 16'sd0;

        wait (current_level_output_count == SAMPLES_PER_LEVEL);

        level_margin_lsb = 32767 - current_level_max_abs_out;
        current_level_safe_flag = (current_level_saturated_count == 0) && (current_level_xz_count == 0);

        if ((current_level_safe_flag != 0) && (level_margin_lsb < worst_safe_margin_lsb)) begin
            worst_safe_margin_lsb = level_margin_lsb;
            worst_safe_level = level_idx;
            worst_safe_amp_q15 = current_amp;
        end

        $fwrite(
            csv_fd,
            "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d\n",
            level_idx,
            SAMPLES_PER_LEVEL,
            current_amp,
            current_level_overflow_count,
            current_level_saturated_count,
            current_level_max_abs_out,
            level_margin_lsb,
            current_level_safe_flag
        );
    end

    wait (rx == tx);

    if (first_input_seen && first_output_seen)
        pipeline_latency = first_output_cycle - first_input_cycle;

    delivery_rate = (tx > 0) ? ((100.0 * rx) / tx) : 0.0;
    saturation_ratio_pct = (rx > 0) ? ((100.0 * saturated_output_count) / rx) : 0.0;
    overflow_rate_pct = saturation_ratio_pct;
    persistent_ratio_pct = (rx > 0) ? ((100.0 * max_persistent_run_len) / rx) : 0.0;
    safe_ratio_pct = (rx > 0) ? ((100.0 * safe_output_count) / rx) : 0.0;
    saturation_ratio_milli = (rx > 0) ? ((saturated_output_count * 100000) / rx) : 0;
    persistent_ratio_milli = (rx > 0) ? ((max_persistent_run_len * 100000) / rx) : 0;
    safe_ratio_milli = (rx > 0) ? ((safe_output_count * 100000) / rx) : 0;
    boundary_amplitude_real = (first_saturation_level >= 0) ?
        ((4096.0 + (first_saturation_level * 576.0)) / 32768.0) : 0.0;
    worst_safe_amplitude_real = worst_safe_amp_q15 / 32768.0;
    stress_score = saturation_ratio_pct + persistent_ratio_pct + overflow_rate_pct;

    summary_fd = $fopen("../tb_v3_2/tmq013_operational_limit_stress_summary.txt", "w");
    if (summary_fd == 0) begin
        $display("[FAIL] Unable to open TMQ013 summary output file.");
        $finish;
    end

    $fwrite(summary_fd, "test_name=TMQ013_OperationalLimitStressTest\n");
    $fwrite(summary_fd, "num_levels=%0d\n", NUM_LEVELS);
    $fwrite(summary_fd, "samples_per_level=%0d\n", SAMPLES_PER_LEVEL);
    $fwrite(summary_fd, "delivery_rate_pct=%0.12f\n", delivery_rate);
    $fwrite(summary_fd, "expected_latency=%0d\n", EXPECTED_LATENCY);
    $fwrite(summary_fd, "measured_latency=%0d\n", pipeline_latency);
    $fwrite(summary_fd, "overflow_total=%0d\n", overflow_total);
    $fwrite(summary_fd, "overflow_total_re=%0d\n", overflow_total_re);
    $fwrite(summary_fd, "overflow_total_im=%0d\n", overflow_total_im);
    $fwrite(summary_fd, "saturated_output_count=%0d\n", saturated_output_count);
    $fwrite(summary_fd, "safe_output_count=%0d\n", safe_output_count);
    $fwrite(summary_fd, "safe_ratio_pct=%0.12f\n", safe_ratio_pct);
    $fwrite(summary_fd, "saturation_ratio_pct=%0.12f\n", saturation_ratio_pct);
    $fwrite(summary_fd, "persistent_ratio_pct=%0.12f\n", persistent_ratio_pct);
    $fwrite(summary_fd, "first_saturation_seen=%0d\n", first_saturation_seen);
    $fwrite(summary_fd, "first_saturation_level=%0d\n", first_saturation_level);
    $fwrite(summary_fd, "first_saturation_sample=%0d\n", first_saturation_sample);
    $fwrite(summary_fd, "first_saturation_amplitude_real=%0.12f\n", boundary_amplitude_real);
    $fwrite(summary_fd, "first_persistent_seen=%0d\n", first_persistent_seen);
    $fwrite(summary_fd, "first_persistent_level=%0d\n", first_persistent_level);
    $fwrite(summary_fd, "first_persistent_sample=%0d\n", first_persistent_sample);
    $fwrite(summary_fd, "max_persistent_run_len=%0d\n", max_persistent_run_len);
    $fwrite(summary_fd, "longest_safe_run_before_sat=%0d\n", longest_safe_run_before_sat);
    $fwrite(summary_fd, "worst_safe_level=%0d\n", worst_safe_level);
    $fwrite(summary_fd, "worst_safe_amp_q15=%0d\n", worst_safe_amp_q15);
    $fwrite(summary_fd, "worst_safe_amplitude_real=%0.12f\n", worst_safe_amplitude_real);
    $fwrite(summary_fd, "worst_safe_margin_lsb=%0d\n", worst_safe_margin_lsb);
    $fwrite(summary_fd, "xz_errors=%0d\n", xz_errors);
    $fwrite(summary_fd, "stress_score=%0.12f\n", stress_score);
    $fwrite(summary_fd, "simulation_cycles=%0d\n", cycle_cnt);
    $fwrite(summary_fd, "simulation_time_ns=%0d\n", cycle_cnt * 10);
    $fwrite(summary_fd, "pass_flag=%0d\n", (pipeline_latency == EXPECTED_LATENCY));
    $fclose(summary_fd);

    $display("TMQ013 summary");
    $display("  First saturation level       : %0d", first_saturation_level);
    $display("  First persistent level       : %0d", first_persistent_level);
    $display("  Saturated outputs            : %0d", saturated_output_count);
    $display("  Safe output ratio            : %0.6f%%", safe_ratio_pct);
    $display("  Max persistent run length    : %0d", max_persistent_run_len);
    $display("  Worst safe level             : %0d", worst_safe_level);
    $display("  Worst safe amplitude [real]  : %0.6f", worst_safe_amplitude_real);
    $display("  First saturation amplitude   : %0.6f", boundary_amplitude_real);
    $display("  RESULT                       : %s", (pipeline_latency == EXPECTED_LATENCY) ? "PASS" : "FAIL");

    $fclose(csv_fd);
    $finish;
end

always @(posedge clk) begin
    if (!rst && (rx < tx || in_valid)) begin
        timeout <= timeout + 1;
        if (timeout > TIMEOUT_CYCLES) begin
            $display("[FAIL] TMQ013 timeout after %0d cycles.", timeout);
            $finish;
        end
    end
end

endmodule
