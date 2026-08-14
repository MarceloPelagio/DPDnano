
/******************************************************************************
 *
 *  Project     : DPDnano-Lite
 *  Module      : tb_common.vh
 *  RTL Version : 3.1 (Frozen)
 *  Library     : Verification Common Library
 *  Language    : Verilog-2001
 *
 ******************************************************************************/

`ifndef __TB_COMMON_VH__
`define __TB_COMMON_VH__

// ============================================================================
// Configuration
// ============================================================================

`define TB_PROJECT     "DPDnano-Lite"
`define TB_VERSION     "3.1 (Frozen)"
`define TB_MODULE      "dpd_core"

integer vector_total;
integer vector_pass;
integer vector_fail;

// ============================================================================
// Separator
// ============================================================================

task tb_separator;
begin
    $display("======================================================================");
end
endtask

// ============================================================================
// Banner
// ============================================================================

task tb_banner;
begin
    tb_separator();
    $display("");
    $display(" Project : %s", `TB_PROJECT);
    $display(" Version : %s", `TB_VERSION);
    $display(" Module  : %s", `TB_MODULE);
    $display("");
    tb_separator();
end
endtask

// ============================================================================
// Initialization
// ============================================================================

task tb_init;
begin
    vector_total = 0;
    vector_pass  = 0;
    vector_fail  = 0;
end
endtask

// ============================================================================
// Test Case Header
// ============================================================================

task tb_testcase;

input [8*32-1:0] tc_name;
input [8*64-1:0] description;

begin
    $display("");
    tb_separator();
    $display("TEST : %s", tc_name);
    $display("%s", description);
    tb_separator();
end

endtask

// ============================================================================
// PASS
// ============================================================================

task tb_pass;

input integer vector;

begin
    vector_total = vector_total + 1;
    vector_pass  = vector_pass  + 1;
    $display("[PASS ] Vector %03d", vector);
end

endtask

// ============================================================================
// FAIL
// ============================================================================

task tb_fail;

input integer vector;

begin
    vector_total = vector_total + 1;
    vector_fail  = vector_fail + 1;
    $display("[FAIL ] Vector %03d", vector);
end

endtask

// ============================================================================
// Integer Compare
// ============================================================================

task check_int;

input integer vector;
input integer expected;
input integer received;

begin

    if(expected === received)
    begin
        tb_pass(vector);
    end
    else
    begin
        tb_fail(vector);
        $display("Time      : %0t",$time);
        $display("Expected  : %0d",expected);
        $display("Received  : %0d",received);
        tb_separator();
    end

end

endtask

// ============================================================================
// Hex Compare
// ============================================================================

task check_hex;

input integer vector;
input [31:0] expected;
input [31:0] received;

begin

    if(expected === received)
    begin
        tb_pass(vector);
    end
    else
    begin
        tb_fail(vector);
        $display("Time      : %0t",$time);
        $display("Expected  : 0x%08h",expected);
        $display("Received  : 0x%08h",received);
        tb_separator();
    end

end

endtask

// ============================================================================
// IQ Compare
// ============================================================================

task check_iq;

input integer vector;
input signed [`DATA_WIDTH-1:0] exp_i;
input signed [`DATA_WIDTH-1:0] exp_q;
input signed [`DATA_WIDTH-1:0] got_i;
input signed [`DATA_WIDTH-1:0] got_q;

begin

    if((exp_i===got_i)&&(exp_q===got_q))
        tb_pass(vector);
    else
    begin
        tb_fail(vector);
        tb_separator();
        $display("Vector          : %03d",vector);
        $display("Simulation Time : %0t",$time);
        $display("Expected I = 0x%04h (%0d)",exp_i,exp_i);
        $display("Expected Q = 0x%04h (%0d)",exp_q,exp_q);
        $display("Received I = 0x%04h (%0d)",got_i,got_i);
        $display("Received Q = 0x%04h (%0d)",got_q,got_q);
        tb_separator();
    end

end

endtask

// ============================================================================
// Tolerance compare (IQ)
// Passes when absolute error is <= tol_lsb on both I and Q
// ============================================================================

task check_iq_tol;

input integer vector;

input signed [`DATA_WIDTH-1:0] exp_i;
input signed [`DATA_WIDTH-1:0] exp_q;

input signed [`DATA_WIDTH-1:0] got_i;
input signed [`DATA_WIDTH-1:0] got_q;

input integer tol_lsb;

integer err_i;
integer err_q;

begin

    err_i = got_i - exp_i;
    if (err_i < 0)
        err_i = -err_i;

    err_q = got_q - exp_q;
    if (err_q < 0)
        err_q = -err_q;

    if ((err_i <= tol_lsb) && (err_q <= tol_lsb)) begin

        tb_pass(vector);

    end
    else begin

        tb_fail(vector);

        $display("Expected I = %0d", exp_i);
        $display("Expected Q = %0d", exp_q);
        $display("Received I = %0d", got_i);
        $display("Received Q = %0d", got_q);
        $display("Tolerance = %0d LSB", tol_lsb);

    end

end

endtask


// ============================================================================
// Valid Check
// ============================================================================

task check_valid;

input integer vector;
input expected;
input received;

begin
    if(expected===received)
        tb_pass(vector);
    else
    begin
        tb_fail(vector);
        $display("Expected VALID : %0d",expected);
        $display("Received VALID : %0d",received);
        tb_separator();
    end
end

endtask

// ============================================================================
// Latency Check
// ============================================================================

task check_latency;

input integer expected;
input integer received;

begin
    if(expected==received)
        $display("[PASS ] Pipeline latency = %0d cycles",received);
    else
    begin
        $display("[FAIL ] Pipeline latency");
        $display("Expected : %0d cycles",expected);
        $display("Received : %0d cycles",received);
    end
end

endtask

// ============================================================================
// Wait N Clock Cycles
// ============================================================================

task wait_cycles;

input integer cycles;
integer i;

begin
    for(i=0;i<cycles;i=i+1)
        @(posedge clk);
end

endtask

// ============================================================================
// Wait out_valid
// ============================================================================

task wait_valid;

begin
    while(out_valid!==1'b1)
        @(posedge clk);
end

endtask

// ============================================================================
// Summary
// ============================================================================

task tb_summary;

begin
    $display("");
    tb_separator();
    $display("SUMMARY");
    $display("Vectors Executed : %0d",vector_total);
    $display("Vectors Passed   : %0d",vector_pass);
    $display("Vectors Failed   : %0d",vector_fail);
    if(vector_fail==0)
        $display("RESULT : PASS");
    else
        $display("RESULT : FAIL");
    tb_separator();
    $display("");
end

endtask

`endif
