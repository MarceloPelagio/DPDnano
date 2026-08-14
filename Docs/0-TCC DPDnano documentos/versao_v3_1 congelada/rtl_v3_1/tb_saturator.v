`timescale 1ns/1ps
`include "config.vh"

module tb_saturator;

reg clk=0;
always #5 clk=~clk;

reg rst;
reg din_valid;

reg signed [`ROUND_WIDTH-1:0] din_re;
reg signed [`ROUND_WIDTH-1:0] din_im;

reg clip_re;
reg clip_im;
reg clip_dir_re;
reg clip_dir_im;

wire dout_valid;
wire signed [`DATA_WIDTH-1:0] dout_re;
wire signed [`DATA_WIDTH-1:0] dout_im;

`ifdef DPD_ENABLE_OVERFLOW_FLAGS
wire overflow;
wire overflow_re;
wire overflow_im;
`endif

saturator dut(
    .clk(clk),
    .rst(rst),
    .din_valid(din_valid),

    .din_re(din_re),
    .din_im(din_im),

    .clip_re(clip_re),
    .clip_im(clip_im),
    .clip_dir_re(clip_dir_re),
    .clip_dir_im(clip_dir_im),

`ifdef DPD_ENABLE_OVERFLOW_FLAGS
    .overflow(overflow),
    .overflow_re(overflow_re),
    .overflow_im(overflow_im),
`endif

    .dout_valid(dout_valid),
    .dout_re(dout_re),
    .dout_im(dout_im)
);

integer pass=0;
integer fail=0;

task wait_out;
begin
    wait(dout_valid);
    @(posedge clk);
end
endtask

initial begin

    rst=1;
    din_valid=0;
    din_re=0;
    din_im=0;
    clip_re=0;
    clip_im=0;
    clip_dir_re=0;
    clip_dir_im=0;

    repeat(3) @(posedge clk);
    rst=0;

    // TC01 - Pass through
    @(posedge clk);
    din_valid<=1;
    din_re<=16'sd1000;
    din_im<=-16'sd2000;
    clip_re<=0;
    clip_im<=0;

    @(posedge clk);
    din_valid<=0;

    wait_out();

    if(dout_re==16'sd1000 && dout_im==-16'sd2000) begin
        pass=pass+1;
        $display("[PASS] TC01 Pass Through");
    end else begin
        fail=fail+1;
        $display("[FAIL] TC01");
    end

    // TC02 - Positive saturation
    @(posedge clk);
    din_valid<=1;
    clip_re<=1;
    clip_dir_re<=0;

    @(posedge clk);
    din_valid<=0;

    wait_out();

    if(dout_re==`SAT_MAX) begin
        pass=pass+1;
        $display("[PASS] TC02 Positive Saturation");
    end else begin
        fail=fail+1;
        $display("[FAIL] TC02");
    end

    // TC03 - Negative saturation
    @(posedge clk);
    din_valid<=1;
    clip_re<=1;
    clip_dir_re<=1;

    @(posedge clk);
    din_valid<=0;

    wait_out();

    if(dout_re==`SAT_MIN) begin
        pass=pass+1;
        $display("[PASS] TC03 Negative Saturation");
    end else begin
        fail=fail+1;
        $display("[FAIL] TC03");
    end

`ifdef DPD_ENABLE_OVERFLOW_FLAGS
    // TC04 - Overflow flags
    @(posedge clk);
    din_valid<=1;
    clip_re<=1;
    clip_im<=1;
    clip_dir_re<=0;
    clip_dir_im<=1;

    @(posedge clk);
    din_valid<=0;

    wait_out();

    if(overflow && overflow_re && overflow_im) begin
        pass=pass+1;
        $display("[PASS] TC04 Overflow Flags");
    end else begin
        fail=fail+1;
        $display("[FAIL] TC04");
    end
`endif

    $display("--------------------------------");
    $display("PASS = %0d",pass);
    $display("FAIL = %0d",fail);

    $stop;

end

endmodule
