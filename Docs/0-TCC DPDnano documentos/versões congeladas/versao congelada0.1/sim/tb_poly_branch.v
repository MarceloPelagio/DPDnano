`timescale 1ns/1ps
`include "config.vh"

module tb_poly_branch;

localparam CLK_PERIOD=10;
localparam TIMEOUT_CYCLES=20;

reg clk,rst,in_valid;
reg signed [`CUBIC_WIDTH-1:0] term_re,term_im;
reg signed [`COEF_WIDTH-1:0] coef_re,coef_im;

wire out_valid;
wire signed [`BRANCH_WIDTH-1:0] branch_re,branch_im;

integer pass,fail,timeout;

poly_branch dut(
 .clk(clk),.rst(rst),.in_valid(in_valid),
 .term_re(term_re),.term_im(term_im),
 .coef_re(coef_re),.coef_im(coef_im),
 .out_valid(out_valid),
 .branch_re(branch_re),.branch_im(branch_im));

initial clk=0;
always #(CLK_PERIOD/2) clk=~clk;

task reset_dut;
begin
 rst=1; in_valid=0;
 term_re=0; term_im=0; coef_re=0; coef_im=0;
 repeat(3) @(posedge clk);
 rst=0;
 repeat(2) @(posedge clk);
end
endtask

task send_sample;
input signed [`CUBIC_WIDTH-1:0] tr,ti;
input signed [`COEF_WIDTH-1:0] cr,ci;
begin
 @(posedge clk);
 in_valid<=1;
 term_re<=tr; term_im<=ti;
 coef_re<=cr; coef_im<=ci;
 @(posedge clk);
 in_valid<=0;
end
endtask

task wait_output;
begin
 timeout=TIMEOUT_CYCLES;
 while((out_valid!==1'b1)&&(timeout>0)) begin
   @(posedge clk);
   timeout=timeout-1;
 end
end
endtask

task check;
input integer tc;
input signed [`BRANCH_WIDTH-1:0] er,ei;
begin
 if(timeout==0) begin fail=fail+1; $display("[FAIL] TC%0d TIMEOUT",tc); end
 else if(branch_re!==er || branch_im!==ei) begin
   fail=fail+1;
   $display("[FAIL] TC%0d RE=%0d IM=%0d EXP_RE=%0d EXP_IM=%0d",tc,branch_re,branch_im,er,ei);
 end else begin
   pass=pass+1;
   $display("[PASS] TC%0d",tc);
 end
end
endtask

initial begin
 pass=0; fail=0;
 reset_dut();

 send_sample(49'sd1,49'sd0,16'sd1,16'sd0);
 wait_output();
 check(1,66'sd1,66'sd0);

 send_sample(49'sd10,49'sd5,16'sd2,16'sd3);
 wait_output();
 check(2,66'sd5,66'sd40);

 send_sample(49'sd0,49'sd0,16'sd7,16'sd8);
 wait_output();
 check(3,66'sd0,66'sd0);

 $display("----------------------------------------");
 $display("PASS = %0d",pass);
 $display("FAIL = %0d",fail);
 $stop;
end

endmodule
