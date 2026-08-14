`timescale 1ns/1ps
`include "../rtl_v3_1/config.vh"

module tb_dpdnano_lite_TMQ001_DynamicRangeCharacterization;

// ============================================================
// DPDnano-Lite TMQ Suite
// ============================================================

localparam integer NUM_SAMPLES       = 131072;
localparam integer TIMEOUT_CYCLES    = NUM_SAMPLES * 20;
localparam integer EXPECTED_LATENCY  = 5;
localparam integer CSV_FILE_ID       = 32'h8000_0001;
localparam integer SUMMARY_FILE_ID   = 32'h8000_0002;

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

integer tx;
integer rx;
integer timeout;
integer cycle_cnt;
integer overflow_total;
integer overflow_total_re;
integer overflow_total_im;
integer overflow_burst;
integer max_overflow_burst;
integer input_zero_vectors;
integer input_fullscale_vectors;
integer csv_fd;
integer summary_fd;
integer first_input_cycle;
integer first_output_cycle;
integer pipeline_latency;

reg first_input_seen;
reg first_output_seen;

reg [31:0] lfsr;

reg signed [`DATA_WIDTH-1:0] tx_hist_re [0:NUM_SAMPLES-1];
reg signed [`DATA_WIDTH-1:0] tx_hist_im [0:NUM_SAMPLES-1];

real delivery_rate;
real overflow_rate;
real coef1_re_real;
real coef1_im_real;
real coef3_re_real;
real coef3_im_real;

integer amp_code;
integer pattern_sel;
integer signed sample_re_int;
integer signed sample_im_int;
integer signed current_tx_re;
integer signed current_tx_im;

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

function integer abs_int;
    input integer value;
    begin
        if (value < 0)
            abs_int = -value;
        else
            abs_int = value;
    end
endfunction

function integer dyn_amp_code;
    input integer idx;
    integer span;
    integer dense_idx;
    integer dense_val;
    begin
        if (idx < 4096) begin
            dyn_amp_code = idx;
        end
        else if (idx < 16384) begin
            dense_idx = idx - 4096;
            dense_val = (dense_idx * dense_idx) / 4096;
            if (dense_val > 32767)
                dense_val = 32767;
            dyn_amp_code = dense_val;
        end
        else begin
            span = NUM_SAMPLES - 16384 - 1;
            dyn_amp_code = ((idx - 16384) * 32767) / span;
        end
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

        if (^dout_re === 1'bx || ^dout_im === 1'bx) begin
            $display("[FAIL] X/Z detected on DUT output.");
            $finish;
        end

        current_tx_re = tx_hist_re[rx];
        current_tx_im = tx_hist_im[rx];

        $fwrite(
            csv_fd,
            "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d\n",
            rx,
            cycle_cnt,
            current_tx_re,
            current_tx_im,
            dout_re,
            dout_im,
            overflow,
            overflow_re,
            overflow_im,
            abs_int(current_tx_re),
            abs_int(current_tx_im)
        );
    end

    if (overflow) begin
        overflow_total <= overflow_total + 1;
        overflow_burst <= overflow_burst + 1;

        if ((overflow_burst + 1) > max_overflow_burst)
            max_overflow_burst <= overflow_burst + 1;
    end
    else begin
        overflow_burst <= 0;
    end

    if (overflow_re)
        overflow_total_re <= overflow_total_re + 1;

    if (overflow_im)
        overflow_total_im <= overflow_total_im + 1;
end

initial begin
    rst                  = 1'b1;
    in_valid             = 1'b0;
    din_re               = '0;
    din_im               = '0;
    coef1_re             = 16'sh4000;
    coef1_im             = 16'sh0000;
    coef3_re             = 16'sh1000;
    coef3_im             = 16'sh0000;
    tx                   = 0;
    rx                   = 0;
    timeout              = 0;
    cycle_cnt            = 0;
    overflow_total       = 0;
    overflow_total_re    = 0;
    overflow_total_im    = 0;
    overflow_burst       = 0;
    max_overflow_burst   = 0;
    input_zero_vectors   = 0;
    input_fullscale_vectors = 0;
    first_input_seen     = 1'b0;
    first_output_seen    = 1'b0;
    first_input_cycle    = -1;
    first_output_cycle   = -1;
    pipeline_latency     = -1;
    lfsr                 = 32'hA5A5_5A5A;
    coef1_re_real        = 16384.0 / 32768.0;
    coef1_im_real        = 0.0;
    coef3_re_real        = 4096.0 / 32768.0;
    coef3_im_real        = 0.0;

    csv_fd = $fopen("../tb_v3_2/tmq001_dynamic_range_samples.csv", "w");
    if (csv_fd == 0) begin
        $display("[FAIL] Unable to open TMQ001 CSV output file.");
        $finish;
    end

    $fwrite(
        csv_fd,
        "sample_idx,cycle,input_re,input_im,output_re,output_im,overflow,overflow_re,overflow_im,input_abs_re,input_abs_im\n"
    );

    repeat (4) @(posedge clk);
    rst = 1'b0;

    $display("");
    $display("======================================================================");
    $display("                 DPDnano-Lite TMQ Validation Suite");
    $display("======================================================================");
    $display("TEST         : TMQ001_DynamicRangeCharacterization");
    $display("Description  : Dynamic Range Characterization");
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

        lfsr = {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
        amp_code = dyn_amp_code(tx);
        pattern_sel = tx[2:0];

        case (pattern_sel)
            3'd0: begin
                sample_re_int = amp_code;
                sample_im_int = amp_code;
            end
            3'd1: begin
                sample_re_int = -amp_code;
                sample_im_int = -amp_code;
            end
            3'd2: begin
                sample_re_int = amp_code;
                sample_im_int = -amp_code;
            end
            3'd3: begin
                sample_re_int = -amp_code;
                sample_im_int = amp_code;
            end
            3'd4: begin
                sample_re_int = amp_code;
                sample_im_int = 0;
            end
            3'd5: begin
                sample_re_int = 0;
                sample_im_int = amp_code;
            end
            3'd6: begin
                sample_re_int = ((($signed({1'b0, lfsr[14:0]}) * amp_code) / 32767) - (amp_code >>> 1));
                sample_im_int = ((($signed({1'b0, lfsr[30:16]}) * amp_code) / 32767) - (amp_code >>> 1));
            end
            default: begin
                sample_re_int = ((($signed({1'b0, lfsr[7:0],  lfsr[15:8]}) * amp_code) / 32767) - (amp_code >>> 1));
                sample_im_int = ((($signed({1'b0, lfsr[23:16], lfsr[31:24]}) * amp_code) / 32767) - (amp_code >>> 1));
            end
        endcase

        if (tx[11:0] == 12'h000) begin
            sample_re_int = 32767;
            sample_im_int = -32768;
            input_fullscale_vectors = input_fullscale_vectors + 1;
        end
        else if (tx[11:0] == 12'h800) begin
            sample_re_int = -32768;
            sample_im_int = 32767;
            input_fullscale_vectors = input_fullscale_vectors + 1;
        end
        else if (amp_code == 0) begin
            input_zero_vectors = input_zero_vectors + 1;
        end

        din_re = sample_re_int[`DATA_WIDTH-1:0];
        din_im = sample_im_int[`DATA_WIDTH-1:0];

        tx_hist_re[tx] = sample_re_int[`DATA_WIDTH-1:0];
        tx_hist_im[tx] = sample_im_int[`DATA_WIDTH-1:0];
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
    $display("Stimulus Statistics");
    $display("----------------------------------------------");
    $display("Zero-Level Inputs        : %0d", input_zero_vectors);
    $display("Full-Scale Inputs        : %0d", input_fullscale_vectors);

    $display("");
    $display("Overflow Statistics");
    $display("----------------------------------------------");
    $display("Overflow Events          : %0d", overflow_total);
    $display("Overflow RE              : %0d", overflow_total_re);
    $display("Overflow IM              : %0d", overflow_total_im);
    $display("Overflow Rate            : %0.2f %%", overflow_rate);
    $display("Max Overflow Burst       : %0d", max_overflow_burst);

    $display("");
    $display("Simulation");
    $display("----------------------------------------------");
    $display("Simulation Cycles        : %0d", cycle_cnt);
    $display("Simulation Time          : %0d ns", cycle_cnt * 10);

    $display("");
    $display("Artifacts");
    $display("----------------------------------------------");
    $display("CSV                      : ../tb_v3_2/tmq001_dynamic_range_samples.csv");
    $display("Summary                  : ../tb_v3_2/tmq001_dynamic_range_summary.txt");

    $display("");
    $display("Overall Result");
    $display("----------------------------------------------");

    if ((rx == tx) &&
        (pipeline_latency == EXPECTED_LATENCY) &&
        (timeout < TIMEOUT_CYCLES))
        $display("PASS");
    else
        $display("FAIL");

    summary_fd = $fopen("../tb_v3_2/tmq001_dynamic_range_summary.txt", "w");
    if (summary_fd != 0) begin
        $fwrite(summary_fd, "test_name=TMQ001_DynamicRangeCharacterization\n");
        $fwrite(summary_fd, "description=Dynamic Range Characterization\n");
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
        $fwrite(summary_fd, "overflow_total=%0d\n", overflow_total);
        $fwrite(summary_fd, "overflow_total_re=%0d\n", overflow_total_re);
        $fwrite(summary_fd, "overflow_total_im=%0d\n", overflow_total_im);
        $fwrite(summary_fd, "overflow_rate_pct=%0.6f\n", overflow_rate);
        $fwrite(summary_fd, "max_overflow_burst=%0d\n", max_overflow_burst);
        $fwrite(summary_fd, "input_zero_vectors=%0d\n", input_zero_vectors);
        $fwrite(summary_fd, "input_fullscale_vectors=%0d\n", input_fullscale_vectors);
        $fwrite(summary_fd, "simulation_cycles=%0d\n", cycle_cnt);
        $fwrite(summary_fd, "simulation_time_ns=%0d\n", cycle_cnt * 10);
        $fwrite(summary_fd, "timeout_cycles=%0d\n", timeout);
        $fwrite(summary_fd, "pass_flag=%0d\n",
            ((rx == tx) && (pipeline_latency == EXPECTED_LATENCY) && (timeout < TIMEOUT_CYCLES)));
        $fclose(summary_fd);
    end

    $fclose(csv_fd);
    $finish;
end

endmodule
