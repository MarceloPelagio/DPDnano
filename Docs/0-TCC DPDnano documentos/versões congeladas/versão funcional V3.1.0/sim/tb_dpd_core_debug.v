`timescale 1ns/1ps
`default_nettype none
`include "../rtl/config.vh"

module tb_dpd_core_debug;

reg clk=0,rst=1,valid_in=0;
reg signed [`DATA_WIDTH-1:0] vin_i,vin_q;

wire valid_out;
wire signed [`DATA_WIDTH-1:0] vout_i,vout_q;

dpd_core DUT(
    .clk(clk),.rst(rst),.valid_in(valid_in),
    .vin_i(vin_i),.vin_q(vin_q),
    .valid_out(valid_out),
    .vout_i(vout_i),.vout_q(vout_q));

always #5 clk=~clk;

task dump_state;
begin
    $display("----------------------------------------");
    $display("t0=(%0d,%0d)", DUT.t0_r, DUT.t0_i);
    $display("t1=(%0d,%0d)", DUT.t1_r, DUT.t1_i);
    $display("t2=(%0d,%0d)", DUT.t2_r, DUT.t2_i);
    $display("acc=(%0d,%0d)", DUT.acc_r, DUT.acc_i);
    $display("rnd=(%0d,%0d)", DUT.rnd_r, DUT.rnd_i);
    $display("out=(%0d,%0d)", vout_i, vout_q);
end
endtask

initial begin
    #12 rst=0;
    valid_in=1;

    vin_i=1000; vin_q=0;   @(posedge clk); #1; dump_state();
    vin_i=800;  vin_q=300; @(posedge clk); #1; dump_state();
    vin_i=-600; vin_q=200; @(posedge clk); #1; dump_state();
    vin_i=0;    vin_q=0;   @(posedge clk); #1; dump_state();

    $finish;
end

endmodule
`default_nettype wire
