# DPDnano-Lite RTL v3.1 Architecture Specification

**Status:** Frozen\
**Target FPGA:** Tang Nano 4K (Gowin GW1NSR-LV4C)\
**HDL:** Verilog-2001

------------------------------------------------------------------------

# 1. Purpose

This document is the authoritative architectural specification for the
DPDnano-Lite RTL v3.1 implementation.

Any functional modification shall be reflected here before being
considered part of the frozen architecture.

------------------------------------------------------------------------

# 2. Design Goals

-   Low FPGA resource utilization.
-   Compatibility with Tang Nano 4K.
-   Deterministic fixed-point implementation.
-   Fully synthesizable Verilog-2001.
-   Modular RTL.
-   Self-checking testbenches.

------------------------------------------------------------------------

# 3. Directory Structure

``` text
rtl_v3_1/
tb_v3_1/
scripts_v3_1/
```

------------------------------------------------------------------------

# 4. Top-Level Modules

  Module         Function
  -------------- -------------------------------------------
  config.vh      Numeric configuration
  coeff_pkg.vh   Coefficient definitions
  fixed_mult     Fixed-point multiplier
  complex_mult   Complex multiplication
  complex_add    Complex addition
  iq_delay       Memory depth delay
  coeff_bank     Polynomial coefficients
  poly_kernel    Polynomial kernel generation
  poly_branch    Polynomial branch scaling
  rounding       Fixed-point rounding and scale conversion
  saturator      Output saturation and output register
  dpd_core       Top-level DPD pipeline

------------------------------------------------------------------------

# 5. Processing Pipeline

``` text
Input (Q1.15)
      |
      v
IQ Delay
      |
      v
Poly Kernel
      |
      v
Poly Branch
      |
      v
Accumulator (Q4.30)
      |
      v
Rounding
 - arithmetic rounding
 - scale conversion
      |
      v
Saturator
 - saturation
 - output register
      |
      v
Output (Q1.15)
```

------------------------------------------------------------------------

# 6. Module Responsibilities

## rounding

Responsible for:

-   arithmetic rounding
-   fixed-point scale conversion
-   output numeric format generation

This is the **only** module allowed to perform scale conversion.

## saturator

Responsible only for:

-   output saturation
-   output register

No arithmetic scaling is performed.

------------------------------------------------------------------------

# 7. Fixed-Point Formats

  Signal           Format
  ---------------- --------
  Input            Q1.15
  Coefficients     Q1.15
                   x
  Cubic term       Q4.45
  Branch           Q3.30
  Accumulator      Q4.30
  Rounded output   Q1.15
  Final output     Q1.15

------------------------------------------------------------------------

# 8. Numeric Configuration

  Define             Value
  ---------------- -------
  DATA_WIDTH            16
  COEF_WIDTH            16
  DATA_FRAC_BITS        15
  COEF_FRAC_BITS        15
  MAG2_WIDTH            33
  TERM_WIDTH            49
  CUBIC_WIDTH           49
  BRANCH_WIDTH          33
  BRANCH_FRAC           30
  ACC_WIDTH             34
  ACC_FRAC              30
  ROUND_WIDTH           33
  ROUND_FRAC            30
  IQ_DELAY               2

------------------------------------------------------------------------

# 9. Interface Convention

Inputs

-   clk
-   rst
-   in_valid
-   din_re
-   din_im

Outputs

-   out_valid
-   dout_re
-   dout_im

------------------------------------------------------------------------

# 10. Coding Rules

-   Verilog-2001 only.
-   English comments.
-   One module per file.
-   Registered interfaces whenever practical.
-   Frozen numeric architecture.

------------------------------------------------------------------------

# 11. Verification

Current frozen validation:

  Test                    Status
  ----------------------- --------
  TC001 Reset             PASS
  TC002 Zero Input        PASS
  TC003 Linear Positive   PASS
  TC004 Linear Negative   PASS
  TC005 Cubic Branch      PASS

Upcoming:

-   TC006 Positive Saturation
-   TC007 Negative Saturation
-   TC008 IQ Simultaneous
-   TC009 Pipeline Latency
-   TC010 Random Vectors

------------------------------------------------------------------------

# 12. Frozen Architectural Decisions

-   Memory depth = 2.
-   Polynomial architecture.
-   Complex coefficients.
-   Tang Nano 4K compatible.
-   Rounding performs scale conversion.
-   Saturator performs only saturation and output registration.

------------------------------------------------------------------------

# 13. Revision History

## v3.0

Initial frozen architecture.

## v3.1

-   Removed redundant scale conversion from `saturator`.
-   Scale conversion moved exclusively to `rounding`.
-   Updated architectural documentation.
-   TC005 validated after correction.

------------------------------------------------------------------------

# 14. Future Work

Reserved for future releases only.

-   Higher-order polynomial
-   Adaptive coefficients
-   GMP architecture
-   Performance version

These items are **not** part of the frozen RTL v3.1.
