`timescale 1ns/1ps
`include "config.vh"

//------------------------------------------------------------------------------
// Module      : poly_branch
// Description : Complex polynomial branch
//               (term_re + j term_im) * (coef_re + j coef_im)
// Verilog-2001
//------------------------------------------------------------------------------

module poly_branch
(
    input                               clk,
    input                               rst,
    input                               in_valid,

    input  signed [`CUBIC_WIDTH-1:0]    term_re,
    input  signed [`CUBIC_WIDTH-1:0]    term_im,

    input  signed [`COEF_WIDTH-1:0]     coef_re,
    input  signed [`COEF_WIDTH-1:0]     coef_im,

    output reg                          out_valid,

    output reg signed [`BRANCH_WIDTH-1:0] branch_re,
    output reg signed [`BRANCH_WIDTH-1:0] branch_im
);

// Internal products (49 x 16 = 65 bits)
reg signed [64:0] p0;
reg signed [64:0] p1;
reg signed [64:0] p2;
reg signed [64:0] p3;

reg signed [`BRANCH_WIDTH-1:0] branch_re_next;
reg signed [`BRANCH_WIDTH-1:0] branch_im_next;

always @* begin

    p0 = $signed(term_re) * $signed(coef_re);
    p1 = $signed(term_im) * $signed(coef_im);
    p2 = $signed(term_re) * $signed(coef_im);
    p3 = $signed(term_im) * $signed(coef_re);

    branch_re_next = p0 - p1;
    branch_im_next = p2 + p3;

end

always @(posedge clk) begin

    if (rst) begin
        out_valid <= 1'b0;
        branch_re <= {`BRANCH_WIDTH{1'b0}};
        branch_im <= {`BRANCH_WIDTH{1'b0}};
    end
    else begin
        out_valid <= in_valid;

        if (in_valid) begin
            branch_re <= branch_re_next;
            branch_im <= branch_im_next;
        end
    end

end

endmodule
