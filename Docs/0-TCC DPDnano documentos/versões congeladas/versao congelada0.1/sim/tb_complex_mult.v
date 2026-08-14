`timescale 1ns/1ps
`include "config.vh"

//------------------------------------------------------------------------------
// tb_complex_mult
// Verilog-2001
//------------------------------------------------------------------------------

// Pipeline latency : 1 cycle

module tb_complex_mult;

localparam CLK_PERIOD      = 10;
localparam TIMEOUT_CYCLES  = 20;

reg clk;
reg rst;
reg in_valid;

reg signed [`DATA_WIDTH-1:0] a_re,a_im,b_re,b_im;

wire out_valid;
wire signed [35:0] y_re,y_im;

integer pass,fail,timeout;

complex_mult dut(
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid),
    .a_re(a_re),
    .a_im(a_im),
    .b_re(b_re),
    .b_im(b_im),
    .out_valid(out_valid),
    .y_re(y_re),
    .y_im(y_im)
);

initial clk=1'b0;
always #(CLK_PERIOD/2) clk=~clk;

task reset_dut;
begin
    rst=1'b1;
    in_valid=1'b0;
    a_re=0; a_im=0; b_re=0; b_im=0;
    repeat(3) @(posedge clk);
    rst=1'b0;
    repeat(2) @(posedge clk);
end
endtask

task send_sample;
input signed [15:0] ar,ai,br,bi;
begin
    @(posedge clk);
    in_valid<=1'b1;
    a_re<=ar; a_im<=ai;
    b_re<=br; b_im<=bi;
    @(posedge clk);
    in_valid<=1'b0;
end
endtask

task wait_output;
begin
    timeout=TIMEOUT_CYCLES;
    while((out_valid!==1'b1)&&(timeout>0)) begin
        @(posedge clk);
        timeout=timeout-1;
    end
    if(timeout==0) begin
        $display("[FAIL] Timeout waiting out_valid");
        fail=fail+1;
    end
end
endtask

task check_result;
input integer tc;
input signed [35:0] er,ei;
begin
    if(timeout>0) begin
        if((y_re===er)&&(y_im===ei)) begin
            pass=pass+1;
            $display("[PASS] TC%02d",tc);
        end else begin
            fail=fail+1;
            $display("[FAIL] TC%02d RE=%0d IM=%0d EXP_RE=%0d EXP_IM=%0d",
                     tc,y_re,y_im,er,ei);
        end
    end
end
endtask

initial begin
    pass=0;
    fail=0;

    reset_dut();

    // TC01
    send_sample(16'sd1,16'sd0,16'sd1,16'sd0);
    wait_output();
    check_result(1,36'sd1,36'sd0);

    // TC02
    send_sample(16'sd2,16'sd3,16'sd4,16'sd5);
    wait_output();
    check_result(2,-36'sd7,36'sd22);

    // TC03
    send_sample(-16'sd2,16'sd1,16'sd3,-16'sd4);
    wait_output();
    check_result(3,-36'sd2,36'sd11);

    // TC04
    send_sample(16'sd0,16'sd0,16'sd5,16'sd7);
    wait_output();
    check_result(4,36'sd0,36'sd0);

    // TC05
    send_sample(-16'sd1,-16'sd1,-16'sd1,16'sd1);
    wait_output();
    check_result(5,36'sd2,36'sd0);

    $display("----------------------------------------");
    $display("PASS = %0d",pass);
    $display("FAIL = %0d",fail);

    if(fail==0)
        $display("ALL TESTS PASSED");
    else
        $display("TEST FAILED");

    $stop;
end

endmodule
