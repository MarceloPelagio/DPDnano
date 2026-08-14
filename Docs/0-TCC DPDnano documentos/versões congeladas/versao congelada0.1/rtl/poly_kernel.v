`timescale 1ns/1ps
`include "config.vh"

//------------------------------------------------------------------------------
// Module : poly_kernel
// Function : Third-order polynomial kernel
//            term = x * |x|^2
// Verilog-2001
//------------------------------------------------------------------------------

module poly_kernel
(
    input                           clk,
    input                           rst,
    input                           in_valid,

    input  signed [`DATA_WIDTH-1:0]  x_re,
    input  signed [`DATA_WIDTH-1:0]  x_im,

    output reg                       out_valid,

    output reg signed [`MAG2_WIDTH-1:0]   mag2,
    output reg signed [`CUBIC_WIDTH-1:0]  term_re,
    output reg signed [`CUBIC_WIDTH-1:0]  term_im
);

reg signed [31:0] i2;
reg signed [31:0] q2;
reg signed [`MAG2_WIDTH-1:0] mag2_next;
reg signed [`CUBIC_WIDTH-1:0] term_re_next;
reg signed [`CUBIC_WIDTH-1:0] term_im_next;

always @* begin
    i2 = x_re * x_re;
    q2 = x_im * x_im;

    mag2_next = i2 + q2;

    term_re_next = $signed(x_re) * $signed(mag2_next);
    term_im_next = $signed(x_im) * $signed(mag2_next);
end

always @(posedge clk) begin
    if (rst) begin
        out_valid <= 1'b0;
        mag2      <= {`MAG2_WIDTH{1'b0}};
        term_re   <= {`CUBIC_WIDTH{1'b0}};
        term_im   <= {`CUBIC_WIDTH{1'b0}};
    end
    else begin
        out_valid <= in_valid;
        if (in_valid) begin
            mag2    <= mag2_next;
            term_re <= term_re_next;
            term_im <= term_im_next;
        end
    end
end

endmodule
