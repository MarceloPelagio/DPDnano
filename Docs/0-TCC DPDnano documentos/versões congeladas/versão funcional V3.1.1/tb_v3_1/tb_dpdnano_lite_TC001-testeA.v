`timescale 1ns/1ps

`include "config.vh"

module tb_dpdnano_lite_TC001;

// ============================================================================
// DUT Signals
// ============================================================================

reg clk;
reg rst;
reg in_valid;

reg  signed [`DATA_WIDTH-1:0] din_i;
reg  signed [`DATA_WIDTH-1:0] din_q;

wire signed [`DATA_WIDTH-1:0] dout_i;
wire signed [`DATA_WIDTH-1:0] dout_q;
wire out_valid;

wire overflow;
wire overflow_re;
wire overflow_im;

// ============================================================================
// Common Verification Library
// ============================================================================

`include "tb_common.vh"

// ============================================================================
// DUT
// ============================================================================

// TODO: Update port names to match dpd_core RTL.
/*
dpd_core dut (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid),
    .din_i(din_i),
    .din_q(din_q),
    .dout_i(dout_i),
    .dout_q(dout_q),
    .out_valid(out_valid),
    .out_valid(out_valid),
    .dout_re(dout_re),
    .dout_im(dout_im)
);
*/

// ============================================================================
// Clock
// ============================================================================

always #5 clk = ~clk;

// ============================================================================
// Test
// ============================================================================

initial begin

    tb_banner();
    tb_init();

    clk      = 1'b0;
    rst      = 1'b1;
    in_valid = 1'b0;
    din_i    = 'd0;
    din_q    = 'd0;

    wait_cycles(5);

    rst = 1'b0;

    tb_testcase("TC001","Reset sequence");

    wait_cycles(10);

    tb_summary();

    $finish;

end

endmodule
