`timescale 1ns/1ps
`include "config.vh"

module tb_rounding;

reg clk=0;
always #5 clk=~clk;

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

rounding dut(
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

integer pass=0;
integer fail=0;

task wait_result;
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

    repeat(3) @(posedge clk);
    rst=0;

    // TC01 - Normal conversion
    @(posedge clk);
    din_valid<=1;
    din_re<=34'sd123456;
    din_im<=-34'sd654321;

    @(posedge clk);
    din_valid<=0;

    wait_result();

    if(!clip_re && !clip_im) begin
        pass=pass+1;
        $display("[PASS] TC01 Normal Conversion");
    end
    else begin
        fail=fail+1;
        $display("[FAIL] TC01");
    end

    // TC02 - Positive clip
    @(posedge clk);
    din_valid<=1;
    din_re<=34'sd1073741823;
    din_im<=0;

    @(posedge clk);
    din_valid<=0;

    wait_result();

    if(clip_re && !clip_dir_re) begin
        pass=pass+1;
        $display("[PASS] TC02 Positive Clip");
    end
    else begin
        fail=fail+1;
        $display("[FAIL] TC02");
    end

    // TC03 - Negative clip
    @(posedge clk);
    din_valid<=1;
    din_re<=-34'sd1073741824;
    din_im<=0;

    @(posedge clk);
    din_valid<=0;

    wait_result();

    if(clip_re && clip_dir_re) begin
        pass=pass+1;
        $display("[PASS] TC03 Negative Clip");
    end
    else begin
        fail=fail+1;
        $display("[FAIL] TC03");
    end

    $display("--------------------------------");
    $display("PASS = %0d",pass);
    $display("FAIL = %0d",fail);

    $stop;

end

endmodule
