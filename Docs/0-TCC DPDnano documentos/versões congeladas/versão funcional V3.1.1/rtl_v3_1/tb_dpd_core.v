`timescale 1ns/1ps
`include "config.vh"

module tb_dpd_core;

reg clk = 0;
always #5 clk = ~clk;

reg rst;
reg din_valid;

reg signed [`DATA_WIDTH-1:0] din_i;
reg signed [`DATA_WIDTH-1:0] din_q;

wire dout_valid;
wire signed [`DATA_WIDTH-1:0] dout_i;
wire signed [`DATA_WIDTH-1:0] dout_q;

dpd_core dut (
    .clk(clk),
    .rst(rst),
    .din_valid(din_valid),
    .din_i(din_i),
    .din_q(din_q),
    .dout_valid(dout_valid),
    .dout_i(dout_i),
    .dout_q(dout_q)
);

initial begin
    rst = 1;
    din_valid = 0;
    din_i = 0;
    din_q = 0;

    repeat(5) @(posedge clk);
    rst = 0;

    @(posedge clk);
    din_valid <= 1;
    din_i <= 16'sd1000;
    din_q <= 16'sd500;

    @(posedge clk);
    din_i <= -16'sd2000;
    din_q <= 16'sd1000;

    @(posedge clk);
    din_i <= 16'sd0;
    din_q <= 16'sd0;

    @(posedge clk);
    din_valid <= 0;

    repeat(20) @(posedge clk);

    $display("================================");
    $display("DPDnano-Lite tb_dpd_core finished");
    $display("================================");

    $stop;
end

endmodule
