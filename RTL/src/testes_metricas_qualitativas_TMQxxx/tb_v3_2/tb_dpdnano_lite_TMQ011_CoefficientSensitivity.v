`timescale 1ns/1ps
`include "../rtl_v3_1/config.vh"

module tb_dpdnano_lite_TMQ011_CoefficientSensitivity;

// ============================================================
// DPDnano-Lite TMQ Suite
// ============================================================

localparam integer COEF_INDEX_MIN    = -32;
localparam integer COEF_INDEX_MAX    = 32;
localparam integer COEF_STEP_Q15     = 1024;
localparam integer INPUT_INDEX_MIN   = -128;
localparam integer INPUT_INDEX_MAX   = 128;
localparam integer INPUT_STEP_Q15    = 256;
localparam integer NUM_COEF_LEVELS   = COEF_INDEX_MAX - COEF_INDEX_MIN + 1;
localparam integer NUM_INPUT_LEVELS  = INPUT_INDEX_MAX - INPUT_INDEX_MIN + 1;
localparam integer NUM_COMBOS        = NUM_COEF_LEVELS * NUM_COEF_LEVELS;
localparam integer NUM_SAMPLES       = NUM_COMBOS * NUM_INPUT_LEVELS;
localparam integer TIMEOUT_CYCLES    = NUM_SAMPLES * 16;
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
integer combo_idx;
integer input_idx;
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
integer current_coef1_q15;
integer current_coef3_q15;
integer current_safe_flag;
integer margin_lsb;
integer best_safe_score;
integer best_safe_c1_q15;
integer best_safe_c3_q15;
integer best_safe_margin_lsb;
integer max_safe_abs_c1_q15;
integer max_safe_abs_c3_q15;
integer first_unsafe_c1_q15;
integer first_unsafe_c3_q15;
integer first_unsafe_seen;
integer safe_pct_milli;
integer sample_abs_re;
integer sample_abs_im;
integer sample_abs_out;
integer c1_idx;
integer c3_idx;
integer score_abs;
integer c1_abs;
integer c3_abs;

reg first_input_seen;
reg first_output_seen;

real delivery_rate;
real safe_ratio_pct;
real best_safe_c1_real;
real best_safe_c3_real;
real max_safe_abs_c1_real;
real max_safe_abs_c3_real;

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

function integer coef_from_index;
    input integer idx;
begin
    if (idx >= COEF_INDEX_MAX)
        coef_from_index = 32767;
    else
        coef_from_index = idx * COEF_STEP_Q15;
end
endfunction

function integer input_from_index;
    input integer idx;
begin
    if (idx >= INPUT_INDEX_MAX)
        input_from_index = 32767;
    else
        input_from_index = idx * INPUT_STEP_Q15;
end
endfunction

task run_combo;
    input integer c1_value_q15;
    input integer c3_value_q15;
begin
    current_coef1_q15        = c1_value_q15;
    current_coef3_q15        = c3_value_q15;
    current_combo_rx         = 0;
    current_combo_overflow   = 0;
    current_combo_xz         = 0;
    current_combo_max_abs_out= 0;

    coef1_re = c1_value_q15[`COEF_WIDTH-1:0];
    coef1_im = 16'sd0;
    coef3_re = c3_value_q15[`COEF_WIDTH-1:0];
    coef3_im = 16'sd0;

    for (input_idx = INPUT_INDEX_MIN; input_idx <= INPUT_INDEX_MAX; input_idx = input_idx + 1) begin
        @(posedge clk);
        in_valid = 1'b1;
        din_re   = input_from_index(input_idx);
        din_im   = 16'sd0;
    end

    @(posedge clk);
    in_valid = 1'b0;
    din_re   = 16'sd0;
    din_im   = 16'sd0;

    wait (current_combo_rx == NUM_INPUT_LEVELS);

    current_safe_flag = (current_combo_overflow == 0) && (current_combo_xz == 0);
    margin_lsb = 32767 - current_combo_max_abs_out;

    if (current_safe_flag != 0) begin
        safe_count = safe_count + 1;

        c1_abs = (c1_value_q15 < 0) ? -c1_value_q15 : c1_value_q15;
        c3_abs = (c3_value_q15 < 0) ? -c3_value_q15 : c3_value_q15;
        score_abs = c1_abs + c3_abs;

        if (score_abs > best_safe_score) begin
            best_safe_score      = score_abs;
            best_safe_c1_q15     = c1_value_q15;
            best_safe_c3_q15     = c3_value_q15;
            best_safe_margin_lsb = margin_lsb;
        end

        if ((c3_value_q15 == 0) && (c1_abs > max_safe_abs_c1_q15))
            max_safe_abs_c1_q15 = c1_abs;

        if ((c1_value_q15 == 0) && (c3_abs > max_safe_abs_c3_q15))
            max_safe_abs_c3_q15 = c3_abs;
    end
    else begin
        unsafe_count = unsafe_count + 1;
        if (first_unsafe_seen == 0) begin
            first_unsafe_seen = 1;
            first_unsafe_c1_q15 = c1_value_q15;
            first_unsafe_c3_q15 = c3_value_q15;
        end
    end

    $fwrite(
        csv_fd,
        "%0d,%0d,%0d,%0d,%0.12f,%0.12f,%0d,%0d,%0d,%0d\n",
        combo_idx,
        c1_value_q15,
        c3_value_q15,
        current_safe_flag,
        c1_value_q15 / 32768.0,
        c3_value_q15 / 32768.0,
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
    rst                  = 1'b1;
    in_valid             = 1'b0;
    din_re               = '0;
    din_im               = '0;
    coef1_re             = '0;
    coef1_im             = '0;
    coef3_re             = '0;
    coef3_im             = '0;
    combo_idx            = 0;
    cycle_cnt            = 0;
    total_tx             = 0;
    total_rx             = 0;
    timeout              = 0;
    first_input_cycle    = -1;
    first_output_cycle   = -1;
    pipeline_latency     = -1;
    safe_count           = 0;
    unsafe_count         = 0;
    current_combo_rx     = 0;
    current_combo_overflow = 0;
    current_combo_xz     = 0;
    current_combo_max_abs_out = 0;
    current_coef1_q15    = 0;
    current_coef3_q15    = 0;
    current_safe_flag    = 0;
    margin_lsb           = 0;
    best_safe_score      = -1;
    best_safe_c1_q15     = 0;
    best_safe_c3_q15     = 0;
    best_safe_margin_lsb = 0;
    max_safe_abs_c1_q15  = 0;
    max_safe_abs_c3_q15  = 0;
    first_unsafe_c1_q15  = 0;
    first_unsafe_c3_q15  = 0;
    first_unsafe_seen    = 0;
    safe_pct_milli       = 0;
    first_input_seen     = 1'b0;
    first_output_seen    = 1'b0;

    csv_fd = $fopen("../tb_v3_2/tmq011_coefficient_sensitivity_map.csv", "w");
    if (csv_fd == 0) begin
        $display("[FAIL] Unable to open TMQ011 CSV output file.");
        $finish;
    end

    $fwrite(
        csv_fd,
        "combo_idx,coef1_q15,coef3_q15,safe_flag,coef1_real,coef3_real,overflow_events,xz_events,max_abs_out,margin_lsb\n"
    );

    repeat (4) @(posedge clk);
    rst = 1'b0;

    $display("");
    $display("======================================================================");
    $display("                 DPDnano-Lite TMQ Validation Suite");
    $display("======================================================================");
    $display("TEST         : TMQ011_CoefficientSensitivity");
    $display("Description  : Safe coefficient region without saturation");
    $display("Coefficient Grid : %0d x %0d", NUM_COEF_LEVELS, NUM_COEF_LEVELS);
    $display("Input Sweep      : %0d levels from -32768 to +32767 (imag=0)", NUM_INPUT_LEVELS);
    $display("Total Combos     : %0d", NUM_COMBOS);
    $display("Expected Latency : %0d cycles", EXPECTED_LATENCY);
    $display("======================================================================");
    $display("");

    for (c1_idx = COEF_INDEX_MIN; c1_idx <= COEF_INDEX_MAX; c1_idx = c1_idx + 1) begin
        for (c3_idx = COEF_INDEX_MIN; c3_idx <= COEF_INDEX_MAX; c3_idx = c3_idx + 1) begin
            run_combo(coef_from_index(c1_idx), coef_from_index(c3_idx));
        end
    end

    wait (total_rx == total_tx);

    if (first_input_seen && first_output_seen)
        pipeline_latency = first_output_cycle - first_input_cycle;

    delivery_rate = (total_tx > 0) ? ((100.0 * total_rx) / total_tx) : 0.0;
    safe_ratio_pct = (NUM_COMBOS > 0) ? ((100.0 * safe_count) / NUM_COMBOS) : 0.0;
    safe_pct_milli = (NUM_COMBOS > 0) ? ((safe_count * 100000) / NUM_COMBOS) : 0;

    best_safe_c1_real = best_safe_c1_q15 / 32768.0;
    best_safe_c3_real = best_safe_c3_q15 / 32768.0;
    max_safe_abs_c1_real = max_safe_abs_c1_q15 / 32768.0;
    max_safe_abs_c3_real = max_safe_abs_c3_q15 / 32768.0;

    summary_fd = $fopen("../tb_v3_2/tmq011_coefficient_sensitivity_summary.txt", "w");
    if (summary_fd == 0) begin
        $display("[FAIL] Unable to open TMQ011 summary output file.");
        $finish;
    end

    $fwrite(summary_fd, "test_name=TMQ011_CoefficientSensitivity\n");
    $fwrite(summary_fd, "total_combos=%0d\n", NUM_COMBOS);
    $fwrite(summary_fd, "safe_combos=%0d\n", safe_count);
    $fwrite(summary_fd, "unsafe_combos=%0d\n", unsafe_count);
    $fwrite(summary_fd, "safe_ratio_pct=%0.12f\n", safe_ratio_pct);
    $fwrite(summary_fd, "safe_ratio_pct_milli=%0d\n", safe_pct_milli);
    $fwrite(summary_fd, "delivery_rate_pct=%0.12f\n", delivery_rate);
    $fwrite(summary_fd, "expected_latency=%0d\n", EXPECTED_LATENCY);
    $fwrite(summary_fd, "measured_latency=%0d\n", pipeline_latency);
    $fwrite(summary_fd, "best_safe_c1_q15=%0d\n", best_safe_c1_q15);
    $fwrite(summary_fd, "best_safe_c3_q15=%0d\n", best_safe_c3_q15);
    $fwrite(summary_fd, "best_safe_c1_real=%0.12f\n", best_safe_c1_real);
    $fwrite(summary_fd, "best_safe_c3_real=%0.12f\n", best_safe_c3_real);
    $fwrite(summary_fd, "best_safe_margin_lsb=%0d\n", best_safe_margin_lsb);
    $fwrite(summary_fd, "max_safe_abs_c1_q15=%0d\n", max_safe_abs_c1_q15);
    $fwrite(summary_fd, "max_safe_abs_c3_q15=%0d\n", max_safe_abs_c3_q15);
    $fwrite(summary_fd, "max_safe_abs_c1_real=%0.12f\n", max_safe_abs_c1_real);
    $fwrite(summary_fd, "max_safe_abs_c3_real=%0.12f\n", max_safe_abs_c3_real);
    $fwrite(summary_fd, "first_unsafe_c1_q15=%0d\n", first_unsafe_c1_q15);
    $fwrite(summary_fd, "first_unsafe_c3_q15=%0d\n", first_unsafe_c3_q15);
    $fwrite(summary_fd, "first_unsafe_seen=%0d\n", first_unsafe_seen);
    $fwrite(summary_fd, "simulation_cycles=%0d\n", cycle_cnt);
    $fwrite(summary_fd, "simulation_time_ns=%0d\n", cycle_cnt * 10);
    $fwrite(summary_fd, "pass_flag=%0d\n", (pipeline_latency == EXPECTED_LATENCY));
    $fclose(summary_fd);

    $display("TMQ011 summary");
    $display("  Safe combos          : %0d / %0d (%0.3f%%)", safe_count, NUM_COMBOS, safe_ratio_pct);
    $display("  Max |c1| safe @ c3=0 : %0d (%0.6f)", max_safe_abs_c1_q15, max_safe_abs_c1_real);
    $display("  Max |c3| safe @ c1=0 : %0d (%0.6f)", max_safe_abs_c3_q15, max_safe_abs_c3_real);
    $display("  Best safe combo      : c1=%0d, c3=%0d", best_safe_c1_q15, best_safe_c3_q15);
    $display("  First unsafe combo   : c1=%0d, c3=%0d", first_unsafe_c1_q15, first_unsafe_c3_q15);
    $display("  Delivery rate        : %0.6f%%", delivery_rate);
    $display("  Pipeline latency     : %0d cycles", pipeline_latency);
    $display("  RESULT               : %s", (pipeline_latency == EXPECTED_LATENCY) ? "PASS" : "FAIL");

    $fclose(csv_fd);
    $finish;
end

always @(posedge clk) begin
    if (!rst && (total_rx < total_tx || in_valid)) begin
        timeout <= timeout + 1;
        if (timeout > TIMEOUT_CYCLES) begin
            $display("[FAIL] TMQ011 timeout after %0d cycles.", timeout);
            $finish;
        end
    end
end

endmodule
