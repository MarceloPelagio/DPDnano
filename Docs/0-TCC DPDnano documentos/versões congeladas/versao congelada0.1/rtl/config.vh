`ifndef CONFIG_VH
`define CONFIG_VH

//------------------------------------------------------------------------------
// DPDnano-Lite RTL v3.0
// Global configuration
//------------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Fixed-point widths
//-----------------------------------------------------------------------------

`define DATA_WIDTH         16      // Q1.15
`define COEF_WIDTH         16      // Q1.15

`define MAG2_WIDTH         33      // Q3.30
`define CUBIC_WIDTH        49      // Q4.45

`define TERM_WIDTH         36      // Q5.30
`define BRANCH_WIDTH       66      // Complex branch output
`define ACC_WIDTH          67      // Accumulator (2 polynomial branches)

//-----------------------------------------------------------------------------
// Architecture
//-----------------------------------------------------------------------------

`define DPD_MEMORY_DEPTH    2
`define DPD_ORDER           3

//-----------------------------------------------------------------------------
// Pipeline
//-----------------------------------------------------------------------------

`define PIPELINE_STAGES     1

`endif
