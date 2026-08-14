`ifndef __CONFIG_VH__
`define __CONFIG_VH__

//==============================================================
// DPDnano-Lite
// Global Configuration
// Architecture Revision 3.0 (Frozen)
//==============================================================

// Input / Output
`define DATA_WIDTH          16
`define DATA_FRAC_BITS      15

// Complex Coefficients
`define COEF_WIDTH          16
`define COEF_FRAC_BITS      15

// |x|^2 -> Q3.30
`define MAG2_WIDTH          33
`define MAG2_FRAC_BITS      30

// x*|x|^2 -> Q4.45 (internal)
`define CUBIC_WIDTH         49
`define CUBIC_FRAC_BITS     45

// poly_branch output -> Q5.30
`define TERM_WIDTH          36
`define TERM_FRAC_BITS      30

// Accumulator -> Q7.30
`define ACC_WIDTH           38
`define ACC_FRAC_BITS       30

`define MULT_WIDTH          32

`define DPD_MEMORY_DEPTH    2
`define DPD_ORDER           3
`define NUM_BRANCHES        (`DPD_MEMORY_DEPTH+1)

`define DATA_MAX            16'sh7FFF
`define DATA_MIN           -16'sh8000

`endif
