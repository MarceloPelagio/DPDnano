`timescale 1ns/1ps
`include "../rtl_v3_1/config.vh"

module tb_dpdnano_lite_TMQ012_ComplexCoefficientSensitivity;

// ============================================================
// DPDnano-Lite TMQ Suite
// ============================================================

localparam integer COEF_LEVELS         = 9;
localparam integer COEF_MAG_STEP_Q15   = 4096;
localparam integer COEF_PHASES         = 8;
localparam integer INPUT_AMPLITUDES    = 17;
localparam integer INPUT_PHASES        = 16;
localparam integer INPUT_MAG_STEP_Q15  = 2048;
localparam integer NUM_COMBOS          = COEF_LEVELS * COEF_LEVELS;
localparam integer NUM_SAMPLES_PER_COMBO =
    COEF_PHASES * COEF_PHASES * INPUT_AMPLITUDES * INPUT_PHASES;
localparam integer NUM_SAMPLES         = NUM_COMBOS * NUM_SAMPLES_PER_COMBO;
localparam integer TIMEOUT_CYCLES      = NUM_SAMPLES * 20;
localparam integer EXPECTED_LATENCY    = 5;
localparam integer Q15_ONE             = 32767;

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
integer combo_idx;
integer c1_mag_idx;
integer c3_mag_idx;
integer c1_phase_idx;
integer c3_phase_idx;
integer in_amp_idx;
integer in_phase_idx;
integer cycle_cnt;
integer total_tx;
integer total_rx;
integer timeout;
integer first_input_cycle;
integer first_output_cycle;
integer pipeline_latency;
integer safe_count;
integer unsafe_count;
integer current_combo_rx;
integer current_combo_overflow;
integer current_combo_xz;
integer current_combo_max_abs_out;
integer current_c1_mag_q15;
integer current_c3_mag_q15;
integer current_safe_flag;
integer margin_lsb;
integer best_safe_score;
integer best_safe_c1_mag_q15;
integer best_safe_c3_mag_q15;
integer best_safe_margin_lsb;
integer max_safe_abs_c1_mag_q15;
integer max_safe_abs_c3_mag_q15;
integer first_unsafe_c1_mag_q15;
integer first_unsafe_c3_mag_q15;
integer first_unsafe_seen;
integer safe_pct_milli;
integer sample_abs_re;
integer sample_abs_im;
integer sample_abs_out;
integer score_abs;
integer c1_mag_abs;
integer c3_mag_abs;
integer c1_cos_q15;
integer c1_sin_q15;
integer c3_cos_q15;
integer c3_sin_q15;
integer in_cos_q15;
integer in_sin_q15;
integer in_mag_q15;
integer coeff_phase_failures;
integer tested_coeff_phase_pairs;
integer tested_input_vectors;

reg first_input_seen;
reg first_output_seen;

real delivery_rate;
real safe_ratio_pct;
real best_safe_c1_mag_real;
real best_safe_c3_mag_real;
real max_safe_abs_c1_mag_real;
real max_safe_abs_c3_mag_real;

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

function integer coef_mag_from_index;
    input integer idx;
begin
    if (idx >= COEF_LEVELS - 1)
        coef_mag_from_index = Q15_ONE;
    else
        coef_mag_from_index = idx * COEF_MAG_STEP_Q15;
end
endfunction

function integer input_mag_from_index;
    input integer idx;
begin
    if (idx <= 0)
        input_mag_from_index = 0;
    else if (idx >= INPUT_AMPLITUDES - 1)
        input_mag_from_index = Q15_ONE;
    else
        input_mag_from_index = idx * INPUT_MAG_STEP_Q15;
end
endfunction

function integer cos8_q15;
    input integer idx;
begin
    case (idx)
        0: cos8_q15 = 32767;
        1: cos8_q15 = 23170;
        2: cos8_q15 = 0;
        3: cos8_q15 = -23170;
        4: cos8_q15 = -32768;
        5: cos8_q15 = -23170;
        6: cos8_q15 = 0;
        default: cos8_q15 = 23170;
    endcase
end
endfunction

function integer sin8_q15;
    input integer idx;
begin
    case (idx)
        0: sin8_q15 = 0;
        1: sin8_q15 = 23170;
        2: sin8_q15 = 32767;
        3: sin8_q15 = 23170;
        4: sin8_q15 = 0;
        5: sin8_q15 = -23170;
        6: sin8_q15 = -32768;
        default: sin8_q15 = -23170;
    endcase
end
endfunction

function integer cos16_q15;
    input integer idx;
begin
    case (idx)
        0:  cos16_q15 = 32767;
        1:  cos16_q15 = 30274;
        2:  cos16_q15 = 23170;
        3:  cos16_q15 = 12540;
        4:  cos16_q15 = 0;
        5:  cos16_q15 = -12540;
        6:  cos16_q15 = -23170;
        7:  cos16_q15 = -30274;
        8:  cos16_q15 = -32768;
        9:  cos16_q15 = -30274;
        10: cos16_q15 = -23170;
        11: cos16_q15 = -12540;
        12: cos16_q15 = 0;
        13: cos16_q15 = 12540;
        14: cos16_q15 = 23170;
        default: cos16_q15 = 30274;
    endcase
end
endfunction

function integer sin16_q15;
    input integer idx;
begin
    case (idx)
        0:  sin16_q15 = 0;
        1:  sin16_q15 = 12540;
        2:  sin16_q15 = 23170;
        3:  sin16_q15 = 30274;
        4:  sin16_q15 = 32767;
        5:  sin16_q15 = 30274;
        6:  sin16_q15 = 23170;
        7:  sin16_q15 = 12540;
        8:  sin16_q15 = 0;
        9:  sin16_q15 = -12540;
        10: sin16_q15 = -23170;
        11: sin16_q15 = -30274;
        12: sin16_q15 = -32768;
        13: sin16_q15 = -30274;
        14: sin16_q15 = -23170;
        default: sin16_q15 = -12540;
    endcase
end
endfunction

task set_complex_coefficients;
    input integer c1_mag_q15;
    input integer c1_phase_sel;
    input integer c3_mag_q15;
    input integer c3_phase_sel;
begin
    c1_cos_q15 = cos8_q15(c1_phase_sel);
    c1_sin_q15 = sin8_q15(c1_phase_sel);
    c3_cos_q15 = cos8_q15(c3_phase_sel);
    c3_sin_q15 = sin8_q15(c3_phase_sel);

    coef1_re = (c1_mag_q15 * c1_cos_q15) >>> 15;
    coef1_im = (c1_mag_q15 * c1_sin_q15) >>> 15;
    coef3_re = (c3_mag_q15 * c3_cos_q15) >>> 15;
    coef3_im = (c3_mag_q15 * c3_sin_q15) >>> 15;
end
endtask

task set_complex_input;
    input integer mag_q15;
    input integer phase_sel;
begin
    in_cos_q15 = cos16_q15(phase_sel);
    in_sin_q15 = sin16_q15(phase_sel);

    din_re = (mag_q15 * in_cos_q15) >>> 15;
    din_im = (mag_q15 * in_sin_q15) >>> 15;
end
endtask

task run_combo;
    input integer c1_mag_q15;
    input integer c3_mag_q15;
begin
    current_c1_mag_q15        = c1_mag_q15;
    current_c3_mag_q15        = c3_mag_q15;
    current_combo_rx          = 0;
    current_combo_overflow    = 0;
    current_combo_xz          = 0;
    current_combo_max_abs_out = 0;
    coeff_phase_failures      = 0;

    for (c1_phase_idx = 0; c1_phase_idx < COEF_PHASES; c1_phase_idx = c1_phase_idx + 1) begin
        for (c3_phase_idx = 0; c3_phase_idx < COEF_PHASES; c3_phase_idx = c3_phase_idx + 1) begin
            set_complex_coefficients(c1_mag_q15, c1_phase_idx, c3_mag_q15, c3_phase_idx);
            tested_coeff_phase_pairs = tested_coeff_phase_pairs + 1;

            for (in_amp_idx = 0; in_amp_idx < INPUT_AMPLITUDES; in_amp_idx = in_amp_idx + 1) begin
                in_mag_q15 = input_mag_from_index(in_amp_idx);

                for (in_phase_idx = 0; in_phase_idx < INPUT_PHASES; in_phase_idx = in_phase_idx + 1) begin
                    @(posedge clk);
                    in_valid = 1'b1;
                    set_complex_input(in_mag_q15, in_phase_idx);
                    tested_input_vectors = tested_input_vectors + 1;
                end
            end
        end
    end

    @(posedge clk);
    in_valid = 1'b0;
    din_re   = 16'sd0;
    din_im   = 16'sd0;

    wait (current_combo_rx == NUM_SAMPLES_PER_COMBO);

    current_safe_flag = (current_combo_overflow == 0) && (current_combo_xz == 0);
    margin_lsb = 32767 - current_combo_max_abs_out;

    if (current_safe_flag != 0) begin
        safe_count = safe_count + 1;

        c1_mag_abs = (c1_mag_q15 < 0) ? -c1_mag_q15 : c1_mag_q15;
        c3_mag_abs = (c3_mag_q15 < 0) ? -c3_mag_q15 : c3_mag_q15;
        score_abs = c1_mag_abs + c3_mag_abs;

        if (score_abs > best_safe_score) begin
            best_safe_score       = score_abs;
            best_safe_c1_mag_q15  = c1_mag_q15;
            best_safe_c3_mag_q15  = c3_mag_q15;
            best_safe_margin_lsb  = margin_lsb;
        end

        if ((c3_mag_q15 == 0) && (c1_mag_abs > max_safe_abs_c1_mag_q15))
            max_safe_abs_c1_mag_q15 = c1_mag_abs;

        if ((c1_mag_q15 == 0) && (c3_mag_abs > max_safe_abs_c3_mag_q15))
            max_safe_abs_c3_mag_q15 = c3_mag_abs;
    end
    else begin
        unsafe_count = unsafe_count + 1;
        if (first_unsafe_seen == 0) begin
            first_unsafe_seen = 1;
            first_unsafe_c1_mag_q15 = c1_mag_q15;
            first_unsafe_c3_mag_q15 = c3_mag_q15;
        end
    end

    $fwrite(
        csv_fd,
        "%0d,%0d,%0d,%0d,%0.12f,%0.12f,%0d,%0d,%0d,%0d\n",
        combo_idx,
        c1_mag_q15,
        c3_mag_q15,
        current_safe_flag,
        c1_mag_q15 / 32768.0,
        c3_mag_q15 / 32768.0,
        current_combo_overflow,
        current_combo_xz,
        current_combo_max_abs_out,
        margin_lsb
    );

    combo_idx = combo_idx + 1;
end
endtask

always @(posedge clk) begin
    cycle_cnt <= cycle_cnt + 1;

    if (in_valid) begin
        total_tx <= total_tx + 1;
        if (!first_input_seen) begin
            first_input_seen  <= 1'b1;
            first_input_cycle <= cycle_cnt;
        end
    end

    if (out_valid) begin
        total_rx <= total_rx + 1;
        current_combo_rx <= current_combo_rx + 1;

        if (!first_output_seen) begin
            first_output_seen  <= 1'b1;
            first_output_cycle <= cycle_cnt;
        end

        if ((^dout_re === 1'bx) || (^dout_im === 1'bx) ||
            (^overflow === 1'bx) || (^overflow_re === 1'bx) ||
            (^overflow_im === 1'bx)) begin
            current_combo_xz <= current_combo_xz + 1;
        end
        else begin
            if (overflow || overflow_re || overflow_im)
                current_combo_overflow <= current_combo_overflow + 1;

            sample_abs_re = (dout_re < 0) ? -dout_re : dout_re;
            sample_abs_im = (dout_im < 0) ? -dout_im : dout_im;
            sample_abs_out = (sample_abs_re > sample_abs_im) ? sample_abs_re : sample_abs_im;
            if (sample_abs_out > current_combo_max_abs_out)
                current_combo_max_abs_out <= sample_abs_out;
        end
    end
end

initial begin
    rst                      = 1'b1;
    in_valid                 = 1'b0;
    din_re                   = '0;
    din_im                   = '0;
    coef1_re                 = '0;
    coef1_im                 = '0;
    coef3_re                 = '0;
    coef3_im                 = '0;
    combo_idx                = 0;
    cycle_cnt                = 0;
    total_tx                 = 0;
    total_rx                 = 0;
    timeout                  = 0;
    first_input_cycle        = -1;
    first_output_cycle       = -1;
    pipeline_latency         = -1;
    safe_count               = 0;
    unsafe_count             = 0;
    current_combo_rx         = 0;
    current_combo_overflow   = 0;
    current_combo_xz         = 0;
    current_combo_max_abs_out= 0;
    current_c1_mag_q15       = 0;
    current_c3_mag_q15       = 0;
    current_safe_flag        = 0;
    margin_lsb               = 0;
    best_safe_score          = -1;
    best_safe_c1_mag_q15     = 0;
    best_safe_c3_mag_q15     = 0;
    best_safe_margin_lsb     = 0;
    max_safe_abs_c1_mag_q15  = 0;
    max_safe_abs_c3_mag_q15  = 0;
    first_unsafe_c1_mag_q15  = 0;
    first_unsafe_c3_mag_q15  = 0;
    first_unsafe_seen        = 0;
    safe_pct_milli           = 0;
    coeff_phase_failures     = 0;
    tested_coeff_phase_pairs = 0;
    tested_input_vectors     = 0;
    first_input_seen         = 1'b0;
    first_output_seen        = 1'b0;

    csv_fd = $fopen("../tb_v3_2/tmq012_complex_coefficient_sensitivity_map.csv", "w");
    if (csv_fd == 0) begin
        $display("[FAIL] Unable to open TMQ012 CSV output file.");
        $finish;
    end

    $fwrite(
        csv_fd,
        "combo_idx,c1_mag_q15,c3_mag_q15,safe_flag,c1_mag_real,c3_mag_real,overflow_events,xz_events,max_abs_out,margin_lsb\n"
    );

    repeat (4) @(posedge clk);
    rst = 1'b0;

    $display("");
    $display("======================================================================");
    $display("                 DPDnano-Lite TMQ Validation Suite");
    $display("======================================================================");
    $display("TEST         : TMQ012_ComplexCoefficientSensitivity");
    $display("Description  : Safe complex coefficient magnitude region without saturation");
    $display("Magnitude Grid        : %0d x %0d", COEF_LEVELS, COEF_LEVELS);
    $display("Coefficient Phases    : %0d x %0d", COEF_PHASES, COEF_PHASES);
    $display("Input Radius/Phases   : %0d x %0d", INPUT_AMPLITUDES, INPUT_PHASES);
    $display("Samples per Combo     : %0d", NUM_SAMPLES_PER_COMBO);
    $display("Expected Latency      : %0d cycles", EXPECTED_LATENCY);
    $display("======================================================================");
    $display("");

    for (c1_mag_idx = 0; c1_mag_idx < COEF_LEVELS; c1_mag_idx = c1_mag_idx + 1) begin
        for (c3_mag_idx = 0; c3_mag_idx < COEF_LEVELS; c3_mag_idx = c3_mag_idx + 1) begin
            run_combo(coef_mag_from_index(c1_mag_idx), coef_mag_from_index(c3_mag_idx));
        end
    end

    wait (total_rx == total_tx);

    if (first_input_seen && first_output_seen)
        pipeline_latency = first_output_cycle - first_input_cycle;

    delivery_rate = (total_tx > 0) ? ((100.0 * total_rx) / total_tx) : 0.0;
    safe_ratio_pct = (NUM_COMBOS > 0) ? ((100.0 * safe_count) / NUM_COMBOS) : 0.0;
    safe_pct_milli = (NUM_COMBOS > 0) ? ((safe_count * 100000) / NUM_COMBOS) : 0;

    best_safe_c1_mag_real = best_safe_c1_mag_q15 / 32768.0;
    best_safe_c3_mag_real = best_safe_c3_mag_q15 / 32768.0;
    max_safe_abs_c1_mag_real = max_safe_abs_c1_mag_q15 / 32768.0;
    max_safe_abs_c3_mag_real = max_safe_abs_c3_mag_q15 / 32768.0;

    summary_fd = $fopen("../tb_v3_2/tmq012_complex_coefficient_sensitivity_summary.txt", "w");
    if (summary_fd == 0) begin
        $display("[FAIL] Unable to open TMQ012 summary output file.");
        $finish;
    end

    $fwrite(summary_fd, "test_name=TMQ012_ComplexCoefficientSensitivity\n");
    $fwrite(summary_fd, "total_combos=%0d\n", NUM_COMBOS);
    $fwrite(summary_fd, "samples_per_combo=%0d\n", NUM_SAMPLES_PER_COMBO);
    $fwrite(summary_fd, "tested_coeff_phase_pairs=%0d\n", tested_coeff_phase_pairs);
    $fwrite(summary_fd, "tested_input_vectors=%0d\n", tested_input_vectors);
    $fwrite(summary_fd, "safe_combos=%0d\n", safe_count);
    $fwrite(summary_fd, "unsafe_combos=%0d\n", unsafe_count);
    $fwrite(summary_fd, "safe_ratio_pct=%0.12f\n", safe_ratio_pct);
    $fwrite(summary_fd, "safe_ratio_pct_milli=%0d\n", safe_pct_milli);
    $fwrite(summary_fd, "delivery_rate_pct=%0.12f\n", delivery_rate);
    $fwrite(summary_fd, "expected_latency=%0d\n", EXPECTED_LATENCY);
    $fwrite(summary_fd, "measured_latency=%0d\n", pipeline_latency);
    $fwrite(summary_fd, "best_safe_c1_mag_q15=%0d\n", best_safe_c1_mag_q15);
    $fwrite(summary_fd, "best_safe_c3_mag_q15=%0d\n", best_safe_c3_mag_q15);
    $fwrite(summary_fd, "best_safe_c1_mag_real=%0.12f\n", best_safe_c1_mag_real);
    $fwrite(summary_fd, "best_safe_c3_mag_real=%0.12f\n", best_safe_c3_mag_real);
    $fwrite(summary_fd, "best_safe_margin_lsb=%0d\n", best_safe_margin_lsb);
    $fwrite(summary_fd, "max_safe_abs_c1_mag_q15=%0d\n", max_safe_abs_c1_mag_q15);
    $fwrite(summary_fd, "max_safe_abs_c3_mag_q15=%0d\n", max_safe_abs_c3_mag_q15);
    $fwrite(summary_fd, "max_safe_abs_c1_mag_real=%0.12f\n", max_safe_abs_c1_mag_real);
    $fwrite(summary_fd, "max_safe_abs_c3_mag_real=%0.12f\n", max_safe_abs_c3_mag_real);
    $fwrite(summary_fd, "first_unsafe_c1_mag_q15=%0d\n", first_unsafe_c1_mag_q15);
    $fwrite(summary_fd, "first_unsafe_c3_mag_q15=%0d\n", first_unsafe_c3_mag_q15);
    $fwrite(summary_fd, "first_unsafe_seen=%0d\n", first_unsafe_seen);
    $fwrite(summary_fd, "simulation_cycles=%0d\n", cycle_cnt);
    $fwrite(summary_fd, "simulation_time_ns=%0d\n", cycle_cnt * 10);
    $fwrite(summary_fd, "pass_flag=%0d\n", (pipeline_latency == EXPECTED_LATENCY));
    $fclose(summary_fd);

    $display("TMQ012 summary");
    $display("  Safe combos           : %0d / %0d (%0.3f%%)", safe_count, NUM_COMBOS, safe_ratio_pct);
    $display("  Max |c1| safe @ c3=0  : %0d (%0.6f)", max_safe_abs_c1_mag_q15, max_safe_abs_c1_mag_real);
    $display("  Max |c3| safe @ c1=0  : %0d (%0.6f)", max_safe_abs_c3_mag_q15, max_safe_abs_c3_mag_real);
    $display("  Best safe magnitude   : |c1|=%0d, |c3|=%0d", best_safe_c1_mag_q15, best_safe_c3_mag_q15);
    $display("  First unsafe magnitude: |c1|=%0d, |c3|=%0d", first_unsafe_c1_mag_q15, first_unsafe_c3_mag_q15);
    $display("  Delivery rate         : %0.6f%%", delivery_rate);
    $display("  Pipeline latency      : %0d cycles", pipeline_latency);
    $display("  RESULT                : %s", (pipeline_latency == EXPECTED_LATENCY) ? "PASS" : "FAIL");

    $fclose(csv_fd);
    $finish;
end

always @(posedge clk) begin
    if (!rst && (total_rx < total_tx || in_valid)) begin
        timeout <= timeout + 1;
        if (timeout > TIMEOUT_CYCLES) begin
            $display("[FAIL] TMQ012 timeout after %0d cycles.", timeout);
            $finish;
        end
    end
end

endmodule
