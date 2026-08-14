`ifndef DPDNANO_CONFIG_VH
`define DPDNANO_CONFIG_VH

`define DATA_WIDTH        16
`define DATA_FRAC_BITS    15

`define COEF_WIDTH        16
`define COEF_FRAC_BITS    15

`define MAG2_WIDTH        33

`define TERM_WIDTH        49
`define TERM_FRAC         45

`define CUBIC_WIDTH       `TERM_WIDTH

`define BRANCH_WIDTH      33
`define BRANCH_FRAC       30

`define ACC_WIDTH         34
`define ACC_FRAC          30

`define ROUND_WIDTH       16
`define ROUND_FRAC        15

`define IQ_DELAY          2

`define SAT_MAX           16'sh7FFF
`define SAT_MIN          -16'sh8000

`endif
