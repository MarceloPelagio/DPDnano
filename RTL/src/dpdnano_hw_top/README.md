# DPDnano-Lite Hardware Top _vr02

Copy the `.v` files into:

```text
fpga_DPDnano_lite_v3_2\src\dpdnano_hw_top
```

## Real Gowin PLL integration

This version uses the generated module:

```verilog
Gowin_PLLVR
```

from:

```text
src\gowin_pllvr\gowin_pllvr.v
```

Expected ports:

```text
clkout
lock
clkin
```

## Clock domains

- External board clock: 27 MHz
- UART and protocol: 27 MHz
- DPDnano-Lite: approximately 100.286 MHz from PLL

## Improvements over _vr01

- RX FIFO
- TX FIFO
- UART framing-error indication
- FIFO overflow indication
- separated protocol and DPD controllers
- dual-clock BSRAM
- start/status CDC
- PLL lock reset handling

## Important

The `dpd_core` interface is assumed to be:

```text
clk
rst
in_valid
din_re
din_im
out_valid
dout_re
dout_im
overflow
overflow_re
overflow_im
```

Set `dpdnano_hw_top` as the Gowin top module.

Before synthesis, add:

- all files from `src\rtl_v3_1`
- `src\gowin_pllvr\gowin_pllvr.v`
- all files from `src\dpdnano_hw_top`


## Coefficient-bank integration in _vr03

The frozen `coeff_bank` is instantiated by `dpdnano_hw_top`.

Mapping:

```text
c0_r/c0_i -> dpd_core coef1_re/coef1_im (linear term)
c1_r/c1_i -> dpd_core coef3_re/coef3_im (cubic term)
c2_r/c2_i -> reserved
```

The overflow ports are connected only when
`DPD_ENABLE_OVERFLOW_FLAGS` is enabled in `config.vh`.
