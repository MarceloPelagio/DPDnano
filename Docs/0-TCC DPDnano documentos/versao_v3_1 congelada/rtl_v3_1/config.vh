//============================================================
// DPDnano-Lite RTL v3.2
// Frozen numeric configuration
//============================================================
//
// Processing pipeline
//
//   Input (Q1.15)
//        |
//        v
//   poly_kernel
//        |
//        v
//   poly_branch
//        |
//        v
//   Accumulator (Q4.30)
//        |
//        v
//   rounding
//      - arithmetic rounding
//      - Q4.30 -> Q1.15
//        |
//        v
//   saturator
//      - output saturation
//      - overflow detection
//      - output register
//        |
//        v
//   Output (Q1.15)
//============================================================
//
// Revision history
//
// v3.0
//   Initial frozen numeric architecture.
//
// v3.1
//   Saturator no longer performs fixed-point scale conversion.
//
// v3.2
//   ROUND_WIDTH updated to output format (Q1.15).
//   Overflow signalling support added.
//============================================================

`ifndef DPDNANO_CONFIG_VH
`define DPDNANO_CONFIG_VH

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
`define ROUND_WIDTH       16      // Q1.15
`define ROUND_FRAC        15

// Misc
`define IQ_DELAY          2

// Saturation
`define SAT_MAX           16'sh7FFF
`define SAT_MIN          -16'sh8000

// Optional debug
`define DPD_ENABLE_OVERFLOW_FLAGS

`endif
