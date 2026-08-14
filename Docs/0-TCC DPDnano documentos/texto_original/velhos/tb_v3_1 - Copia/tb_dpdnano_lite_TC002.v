`timescale 1ns/1ps

`include "config.vh"

module tb_dpdnano_lite_TC002;

// ============================================================================
// DUT Signals
// ============================================================================

reg clk;
reg rst;
reg in_valid;

reg  signed [`DATA_WIDTH-1:0] din_re;
reg  signed [`DATA_WIDTH-1:0] din_im;

reg  signed [`COEF_WIDTH-1:0] coef1_re;
reg  signed [`COEF_WIDTH-1:0] coef1_im;
reg  signed [`COEF_WIDTH-1:0] coef3_re;
reg  signed [`COEF_WIDTH-1:0] coef3_im;

wire out_valid;
wire signed [`DATA_WIDTH-1:0] dout_re;
wire signed [`DATA_WIDTH-1:0] dout_im;

wire overflow;
wire overflow_re;
wire overflow_im;

`include "tb_common.vh"

// ============================================================================
// DUT
// ============================================================================

dpd_core dut (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid),
    .din_re(din_re),
    .din_im(din_im),
    .coef1_re(coef1_re),
    .coef1_im(coef1_im),
    .coef3_re(coef3_re),
    .coef3_im(coef3_im),
    .out_valid(out_valid),
    .dout_re(dout_re),
    .dout_im(dout_im)
);

// ============================================================================

always #5 clk = ~clk;

// ============================================================================
// TC002 - Zero Input
// ============================================================================

initial begin

    tb_banner();
    tb_init();

    clk      = 0;
    rst      = 1;
    in_valid = 0;

    din_re   = 0;
    din_im   = 0;

    coef1_re = 16'sh7FFF;
    coef1_im = 16'sh0000;
    coef3_re = 16'sh0000;
    coef3_im = 16'sh0000;

    wait_cycles(5);
    rst = 0;

    tb_testcase("TC002","Zero input");

    in_valid = 1'b1;
    din_re   = 16'sd0;
    din_im   = 16'sd0;

    wait_valid();

    check_iq(
        1,
        16'sd0,
        16'sd0,
        dout_re,
        dout_im
    );

    tb_summary();
    $finish;

end

endmodule
