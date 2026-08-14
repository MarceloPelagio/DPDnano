`timescale 1ns/1ps
`include "config.vh"

module tb_rounding;

reg clk = 0;
always #5 clk = ~clk;

reg rst;
reg din_valid;

reg signed [`ACC_WIDTH-1:0] din_re;
reg signed [`ACC_WIDTH-1:0] din_im;

wire dout_valid;

wire signed [`ROUND_WIDTH-1:0] dout_re;
wire signed [`ROUND_WIDTH-1:0] dout_im;

wire clip_re;
wire clip_im;
wire clip_dir_re;
wire clip_dir_im;


rounding dut
(
    .clk(clk),
    .rst(rst),
    .din_valid(din_valid),

    .din_re(din_re),
    .din_im(din_im),

    .dout_valid(dout_valid),

    .dout_re(dout_re),
    .dout_im(dout_im),

    .clip_re(clip_re),
    .clip_im(clip_im),

    .clip_dir_re(clip_dir_re),
    .clip_dir_im(clip_dir_im)
);


integer pass;
integer fail;


task check;

input expect_clip_re;
input expect_clip_im;

begin

    wait(dout_valid);

    if ((clip_re == expect_clip_re) &&
        (clip_im == expect_clip_im))
    begin
        pass = pass + 1;
        $display("[PASS] clip_re=%0d clip_im=%0d",
                  clip_re, clip_im);
    end
    else
    begin
        fail = fail + 1;
        $display("[FAIL]");
        $display("clip_re=%0d expected=%0d",
                  clip_re, expect_clip_re);
        $display("clip_im=%0d expected=%0d",
                  clip_im, expect_clip_im);
    end

end

endtask



initial
begin

    pass = 0;
    fail = 0;

    rst = 1;
    din_valid = 0;
    din_re = 0;
    din_im = 0;

    repeat(3) @(posedge clk);

    rst = 0;

    //--------------------------------------------------
    // TC01
    //--------------------------------------------------

    @(posedge clk);

    din_valid <= 1;

    din_re <= 34'sd123456;
    din_im <= -34'sd654321;

    @(posedge clk);

    din_valid <= 0;

    check(0,0);



    //--------------------------------------------------
    // TC02
    // Positive clipping
    //--------------------------------------------------

    @(posedge clk);

    din_valid <= 1;

    din_re <= (`SAT_MAX <<< (`ACC_FRAC-`ROUND_FRAC)) + 1000;
    din_im <= 0;

    @(posedge clk);

    din_valid <= 0;

    wait(dout_valid);

    if (clip_re && !clip_dir_re)
    begin
        pass = pass + 1;
        $display("[PASS] Positive Clip");
    end
    else
    begin
        fail = fail + 1;
        $display("[FAIL] Positive Clip");
    end



    //--------------------------------------------------
    // TC03
    // Negative clipping
    //--------------------------------------------------

    @(posedge clk);

    din_valid <= 1;

    din_re <= (`SAT_MIN <<< (`ACC_FRAC-`ROUND_FRAC)) - 1000;
    din_im <= 0;

    @(posedge clk);

    din_valid <= 0;

    wait(dout_valid);

    if (clip_re && clip_dir_re)
    begin
        pass = pass + 1;
        $display("[PASS] Negative Clip");
    end
    else
    begin
        fail = fail + 1;
        $display("[FAIL] Negative Clip");
    end



    //--------------------------------------------------

    $display("----------------------------------------");
    $display("ROUNDING TEST SUMMARY");
    $display("----------------------------------------");
    $display("PASS = %0d",pass);
    $display("FAIL = %0d",fail);

    if(fail==0)
        $display("ROUNDING PASS");
    else
        $display("ROUNDING FAIL");

    $stop;

end

endmodule