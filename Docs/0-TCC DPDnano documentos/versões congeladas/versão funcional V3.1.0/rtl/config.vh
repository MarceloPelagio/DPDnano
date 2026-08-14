`ifndef DPDNANO_CONFIG_VH
`define DPDNANO_CONFIG_VH

//============================================================
// DPDnano-Lite RTL v3.0
// Frozen numeric configuration
//============================================================

// External interfaces
`define DATA_WIDTH        16      // Q1.15
`define COEF_WIDTH        16      // Q1.15

// Compatibility
`define DATA_FRAC_BITS    15
`define COEF_FRAC_BITS    15

// Internal precision
`define MAG2_WIDTH        33      // Q3.30
`define TERM_WIDTH        49      // Q4.45
`define CUBIC_WIDTH       `TERM_WIDTH

// Common branch
`define BRANCH_WIDTH      33      // Q3.30
`define BRANCH_FRAC       30

// Accumulator
`define ACC_WIDTH         34      // Q4.30
`define ACC_FRAC          30

// Rounded output
`define ROUND_WIDTH       33
`define ROUND_FRAC        30

// Misc
`define IQ_DELAY          2

`endif
