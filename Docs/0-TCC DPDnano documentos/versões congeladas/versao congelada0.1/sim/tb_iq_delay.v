`timescale 1ns/1ps
`default_nettype none
`include "../rtl/config.vh"

module tb_iq_delay;

reg clk=0,rst=1,valid_in=0;
reg signed [`DATA_WIDTH-1:0] din_i,din_q;
wire signed [`DATA_WIDTH-1:0] x0_i,x0_q,x1_i,x1_q,x2_i,x2_q;
wire valid_out;

iq_delay dut(
.clk(clk),.rst(rst),.valid_in(valid_in),
.din_i(din_i),.din_q(din_q),
.x0_i(x0_i),.x0_q(x0_q),
.x1_i(x1_i),.x1_q(x1_q),
.x2_i(x2_i),.x2_q(x2_q),
.valid_out(valid_out));

always #5 clk=~clk;

initial begin
  $display("=== iq_delay v2.1 ===");
  #12 rst=0;
  valid_in=1;
  din_i=10; din_q=20; @(posedge clk);
  #1 $display("C1 x0=%0d x1=%0d x2=%0d",x0_i,x1_i,x2_i);
  din_i=30; din_q=40; @(posedge clk);
  #1 $display("C2 x0=%0d x1=%0d x2=%0d",x0_i,x1_i,x2_i);
  din_i=50; din_q=60; @(posedge clk);
  #1 $display("C3 x0=%0d x1=%0d x2=%0d",x0_i,x1_i,x2_i);
  $finish;
end

endmodule
`default_nettype wire
