`timescale 1ns/1ps
`include "config.vh"

module tb_dpdnano_lite_TC003;

// DUT signals
reg clk,rst,in_valid;
reg signed [`DATA_WIDTH-1:0] din_re,din_im;
reg signed [`COEF_WIDTH-1:0] coef1_re,coef1_im,coef3_re,coef3_im;
wire out_valid;
wire signed [`DATA_WIDTH-1:0] dout_re,dout_im;

wire overflow;
wire overflow_re;
wire overflow_im;

`include "tb_common.vh"

dpd_core dut(
    .clk(clk),.rst(rst),.in_valid(in_valid),
    .din_re(din_re),.din_im(din_im),
    .coef1_re(coef1_re),.coef1_im(coef1_im),
    .coef3_re(coef3_re),.coef3_im(coef3_im),

    .overflow(overflow),
    .overflow_re(overflow_re),
    .overflow_im(overflow_im),

    .out_valid(out_valid),
    .dout_re(dout_re),
    .dout_im(dout_im)
);
always #5 clk=~clk;

initial begin
    tb_banner();
    tb_init();

    clk=0;
    rst=1;
    in_valid=0;

    coef1_re=16'sh7FFF;
    coef1_im=16'sh0000;
    coef3_re=16'sh0000;
    coef3_im=16'sh0000;

    din_re=16'sd1000;
    din_im=-16'sd500;

    wait_cycles(5);
    rst=0;

    tb_testcase("TC003","Linear gain");

    in_valid=1'b1;
    wait_valid();

    check_iq_tol(
        1,
        16'sd1000,
        -16'sd500,
        dout_re,
        dout_im,
        1
    );

    tb_summary();
    $finish;
end

endmodule
