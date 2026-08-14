`timescale 1ns/1ps
`include "../rtl_v3_1/config.vh"

module tb_dpdnano_lite_TC009_Apocalypse;

// ============================================================
// TC009_Apocalypse v002
// Dynamic Coefficient Stress Test
// Report format aligned with Validation Suite
// ============================================================

localparam integer NUM_SAMPLES = 300000;

reg clk=0;
always #5 clk=~clk;

reg rst,in_valid;
reg signed [`DATA_WIDTH-1:0] din_re,din_im;
reg signed [`COEF_WIDTH-1:0] coef1_re,coef1_im,coef3_re,coef3_im;

wire out_valid;
wire signed [`DATA_WIDTH-1:0] dout_re,dout_im;
wire overflow,overflow_re,overflow_im;

integer tx,rx;
integer ovf,ovfr,ovfi;
integer cycle_cnt,timeout;
integer first_input_cycle,first_output_cycle,pipeline_latency;
reg first_input_seen,first_output_seen;
reg [31:0] lfsr;

// New statistics
integer coef_updates,coef_set_0,coef_set_1,coef_set_2,coef_random;
integer overflow_burst,max_overflow_burst;
real delivery_rate,overflow_percent;

// NOTE:
// Preserve the DUT instantiation and stimulus generation from the
// validated v001 implementation.
// Replace all occurrences of 100000 by NUM_SAMPLES.
// Add the following report at the end:
//
// ======================================================================
//                 DPDnano-Lite RTL Validation Suite
// ======================================================================
// TEST         : TC009_Apocalypse
// Description  : Dynamic Coefficient Stress Test
// Samples      : NUM_SAMPLES
//
// Execution
//   Vectors Sent
//   Vectors Received
//   Dropped Vectors
//   Delivery Rate
//
// Pipeline
//   Expected Latency
//   Measured Latency
//   Latency Check
//   Pipeline Flush
//
// Coefficient Statistics
//   Coefficient Mode
//   Update Interval
//   Total Updates
//   Set 0
//   Set 1
//   Set 2
//   Random Sets
//
// Overflow Statistics
//   Overflow Events
//   Overflow RE
//   Overflow IM
//   Overflow Rate
//   Max Burst
//
// Simulation
//   Simulation Cycles
//   Simulation Time
//
// Overall Result : PASS/FAIL
//
// The functional behavior remains identical to v001.
// Only statistics, sample count and report formatting change.

endmodule
