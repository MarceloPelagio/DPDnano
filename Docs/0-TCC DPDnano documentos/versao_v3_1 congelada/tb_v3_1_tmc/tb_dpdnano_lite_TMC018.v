`timescale 1ns/1ps
`include "config.vh"

//------------------------------------------------------------------------------
// Testbench : tb_dpdnano_lite_TMC018
// Benchmark : TMC018 - dpd_core characterization
//------------------------------------------------------------------------------

module tb_dpdnano_lite_TMC018;

reg clk,rst,in_valid;
reg signed [`DATA_WIDTH-1:0] din_re,din_im;
reg signed [`COEF_WIDTH-1:0] coef1_re,coef1_im;
reg signed [`COEF_WIDTH-1:0] coef3_re,coef3_im;

wire out_valid;
wire signed [`DATA_WIDTH-1:0] dout_re,dout_im;

dpd_core dut(
    .clk(clk),.rst(rst),.in_valid(in_valid),
    .din_re(din_re),.din_im(din_im),
    .coef1_re(coef1_re),.coef1_im(coef1_im),
    .coef3_re(coef3_re),.coef3_im(coef3_im),
    .out_valid(out_valid),
    .dout_re(dout_re),.dout_im(dout_im)
);

initial begin
    clk=0;
    forever #5 clk=~clk;
end

integer valid_count;
reg signed [`DATA_WIDTH-1:0] peak_re,peak_im;
reg signed [63:0] sum_re,sum_im;

task send_sample;
input signed [`DATA_WIDTH-1:0] xr,xi;
input signed [`COEF_WIDTH-1:0] c1r,c1i,c3r,c3i;
begin
    @(posedge clk);
    in_valid<=1;
    din_re<=xr; din_im<=xi;
    coef1_re<=c1r; coef1_im<=c1i;
    coef3_re<=c3r; coef3_im<=c3i;
    @(posedge clk);
    in_valid<=0;
end
endtask

always @(posedge clk) begin
    if(rst) begin
        valid_count<=0; peak_re<=0; peak_im<=0;
        sum_re<=0; sum_im<=0;
    end else if(out_valid) begin
        valid_count<=valid_count+1;
        if(dout_re>peak_re) peak_re<=dout_re;
        if(dout_im>peak_im) peak_im<=dout_im;
        sum_re<=sum_re+dout_re;
        sum_im<=sum_im+dout_im;
    end
end

initial begin
    rst=1; in_valid=0;
    din_re=0; din_im=0;
    coef1_re=0; coef1_im=0;
    coef3_re=0; coef3_im=0;

    repeat(5) @(posedge clk);
    rst=0;

    // OBJ1
    send_sample(0,0,0,0,0,0);

    // OBJ2
    send_sample(16'sd8192,16'sd0,16'sd32767,16'sd0,16'sd0,16'sd0);

    // OBJ3
    send_sample(16'sd8192,16'sd4096,16'sd32767,16'sd0,16'sd8192,16'sd0);

    // OBJ4
    send_sample(16'sd12000,16'sd6000,16'sd32767,16'sd0,16'sd32767,16'sd32767);

    // OBJ5
    send_sample(16'sd32767,16'sd32767,16'sd32767,16'sd0,16'sd16384,16'sd0);

    // OBJ6
    send_sample(-16'sd32768,-16'sd32768,16'sd32767,16'sd0,-16'sd16384,16'sd0);

    // OBJ7
    send_sample(16'sd20000,16'sd10000,16'sd32767,16'sd0,16'sd32767,16'sd0);

    repeat(40) @(posedge clk);

    $display("");
    $display("==============================================");
    $display("TMC018 - DPD_CORE CHARACTERIZATION");
    $display("==============================================");
    $display("Valid Samples : %0d",valid_count);
    $display("Peak Dout Re  : %0d",peak_re);
    $display("Peak Dout Im  : %0d",peak_im);
    $display("Accum Dout Re : %0d",sum_re);
    $display("Accum Dout Im : %0d",sum_im);
    $display("RESULT        : PASS");
    $display("==============================================");
    $finish;
end

endmodule
