`timescale 1ns/1ps
`include "../rtl/config.vh"

module tb_fixed_mult;

reg signed [15:0] a,b;
wire signed [16:0] p;

fixed_mult dut(.a(a),.b(b),.p(p));

initial begin
  a=16'sh4000; b=16'sh4000; #1;
  if(p!==17'sd8192) $display("FAIL");
  else $display("PASS");
  $stop;
end

endmodule
