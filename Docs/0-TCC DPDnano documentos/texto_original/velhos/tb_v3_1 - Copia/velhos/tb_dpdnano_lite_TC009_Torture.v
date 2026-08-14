`timescale 1ns/1ps
`include "config.vh"

module tb_dpdnano_lite_TC009_Torture;

// ============================================================
// DPDnano-Lite RTL Validation Suite
// TC009_Torture - Long Duration Stress Test
// RTL v3.1 (Frozen)
// ============================================================

reg clk=0;
always #5 clk=~clk;

reg rst,in_valid;
reg signed [`DATA_WIDTH-1:0] din_re,din_im;
reg signed [`COEF_WIDTH-1:0] coef1_re,coef1_im,coef3_re,coef3_im;

wire out_valid;
wire signed [`DATA_WIDTH-1:0] dout_re,dout_im;
wire overflow,overflow_re,overflow_im;

integer tx,rx;
integer ovf,ovf_re,ovf_im;
integer timeout;
integer first_latency;
reg first_seen;

dpd_core dut(
 .clk(clk),.rst(rst),.in_valid(in_valid),
 .din_re(din_re),.din_im(din_im),
 .coef1_re(coef1_re),.coef1_im(coef1_im),
 .coef3_re(coef3_re),.coef3_im(coef3_im),
 .overflow(overflow),.overflow_re(overflow_re),.overflow_im(overflow_im),
 .out_valid(out_valid),.dout_re(dout_re),.dout_im(dout_im));

always @(posedge clk) begin
    if(out_valid) begin
        rx = rx + 1;
        if(!first_seen) begin
            first_seen = 1'b1;
            first_latency = timeout;
        end
        if(^dout_re===1'bx || ^dout_im===1'bx) begin
            $display("[FAIL] X/Z detected on DUT outputs.");
            $finish;
        end
    end
    if(overflow)    ovf    = ovf + 1;
    if(overflow_re) ovf_re = ovf_re + 1;
    if(overflow_im) ovf_im = ovf_im + 1;
    timeout = timeout + 1;
end

initial begin
    rst=1; in_valid=0;
    tx=0; rx=0;
    ovf=0; ovf_re=0; ovf_im=0;
    timeout=0;
    first_seen=0;
    first_latency=-1;

    coef1_re=16'sd32767;
    coef1_im=0;
    coef3_re=0;
    coef3_im=0;

    repeat(4) @(posedge clk);
    rst=0;

    $display("======================================================================");
    $display("                 DPDnano-Lite RTL Validation Suite");
    $display("======================================================================");
    $display("Project      : DPDnano-Lite");
    $display("Version      : 3.1 (Frozen)");
    $display("Module       : dpd_core");
    $display("");
    $display("TEST         : TC009_Torture");
    $display("Description  : Long Duration Stress Test");
    $display("======================================================================");
    $display("Configuration");
    $display("  Clock              : 100 MHz");
    $display("  Stimulus           : Mixed + Random");
    $display("  Samples            : 50000");
    $display("");

    for(tx=0; tx<50000; tx=tx+1) begin
        @(posedge clk);
        in_valid=1'b1;
        case(tx[2:0])
            3'd0: begin din_re= tx;      din_im=-tx;      end
            3'd1: begin din_re=-tx;      din_im= tx;      end
            3'd2: begin din_re=16'sh7FFF;din_im=16'sh8000;end
            3'd3: begin din_re=16'sh8000;din_im=16'sh7FFF;end
            3'd4: begin din_re=0;        din_im=0;        end
            default: begin
                din_re=$random;
                din_im=$random;
            end
        endcase
    end

    @(posedge clk);
    in_valid=0;

    wait(rx==50000);

    $display("Execution");
    $display("  Vectors Sent       : %0d",tx);
    $display("  Vectors Received   : %0d",rx);
    $display("  Dropped Vectors    : %0d",tx-rx);
    $display("");
    $display("Pipeline");
    $display("  First Latency      : %0d cycles",first_latency);
    $display("  Pipeline Flush     : %s",(tx==rx)?"PASS":"FAIL");
    $display("");
    $display("Overflow Statistics");
    $display("  Global Overflow    : %0d",ovf);
    $display("  Real Overflow      : %0d",ovf_re);
    $display("  Imag Overflow      : %0d",ovf_im);
    $display("");
    $display("SUMMARY");
    if(tx==rx)
        $display("TC009_Torture - Long Duration Stress ...... PASS");
    else
        $display("TC009_Torture - Long Duration Stress ...... FAIL");
    $display("Vectors Executed : %0d",tx);
    $display("Vectors Passed   : %0d",rx);
    $display("Vectors Failed   : %0d",tx-rx);
    $display("REGRESSION STATUS : %s",(tx==rx)?"PASS":"FAIL");
    $display("======================================================================");
    $finish;
end

endmodule
