`timescale 1ns/1ps
`default_nettype none
`include "../rtl/config.vh"
module tb_dpd_core;
reg clk=0,rst=1,valid_in=0;
reg signed [`DATA_WIDTH-1:0] vin_i,vin_q;
wire valid_out;
wire signed [`DATA_WIDTH-1:0] vout_i,vout_q;
dpd_core dut(.clk(clk),.rst(rst),.valid_in(valid_in),.vin_i(vin_i),.vin_q(vin_q),.valid_out(valid_out),.vout_i(vout_i),.vout_q(vout_q));
always #5 clk=~clk;
initial begin
#12 rst=0; valid_in=1;
vin_i=1000; vin_q=500; @(posedge clk);
vin_i=0; vin_q=0; @(posedge clk);
#2;
$display("VALID=%0d OUT_I=%0d OUT_Q=%0d",valid_out,vout_i,vout_q);
$finish;
end
endmodule
`default_nettype wire
