`timescale 1ns/1ps
`include "config.vh"

module tb_dpdnano_lite_TC005;

reg clk,rst,in_valid;
reg signed [`DATA_WIDTH-1:0] din_re,din_im;
reg signed [`COEF_WIDTH-1:0] coef1_re,coef1_im,coef3_re,coef3_im;

wire out_valid;
wire signed [`DATA_WIDTH-1:0] dout_re,dout_im;
wire overflow,overflow_re,overflow_im;

`include "tb_common.vh"

dpd_core dut(
    .clk(clk),.rst(rst),.in_valid(in_valid),
    .din_re(din_re),.din_im(din_im),
    .coef1_re(coef1_re),.coef1_im(coef1_im),
    .coef3_re(coef3_re),.coef3_im(coef3_im),
    .out_valid(out_valid),
    .dout_re(dout_re),
    .dout_im(dout_im)
);

always #5 clk=~clk;

reg signed [`DATA_WIDTH-1:0] expected_re, expected_im;

initial begin
    tb_banner();
    tb_init();

    clk=0;
    rst=1;
    in_valid=0;

    coef1_re=16'sd0;
    coef1_im=16'sd0;
    coef3_re=16'sh7FFF;
    coef3_im=16'sd0;

    din_re=16'sd8192;
    din_im=16'sd0;

    wait_cycles(5);
    rst=0;

    tb_testcase("TC005","Cubic branch");

    in_valid=1'b1;
    wait_valid();
    in_valid=1'b0;

    // Frozen golden reference from RTL v3.1
    expected_re=16'sd512;
    expected_im=16'sd0;

    check_iq(
        1,
        expected_re,
        expected_im,
        dout_re,
        dout_im
    );

    tb_summary();
    $finish;
end

endmodule
