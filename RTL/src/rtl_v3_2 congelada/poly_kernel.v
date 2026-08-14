`timescale 1ns/1ps
`include "config.vh"

//------------------------------------------------------------------------------
// Module : poly_kernel
// Function : Third-order polynomial kernel
//            term = x * |x|^2
// Verilog-2001
//------------------------------------------------------------------------------
//
// DPDnano-Lite RTL v3.1
// Change:
//   - Reset standardized to asynchronous (posedge rst)
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
reg signed [`DATA_WIDTH-1:0] x_re_d;
reg signed [`DATA_WIDTH-1:0] x_im_d;
reg signed [`DATA_WIDTH-1:0] x_re_d2;
reg signed [`DATA_WIDTH-1:0] x_im_d2;
reg signed [`MAG2_WIDTH-1:0] mag2_d;
reg stage1_valid;
reg stage2_valid;

always @* begin
    i2 = x_re * x_re;
    q2 = x_im * x_im;

    mag2_next = i2 + q2;

    term_re_next = $signed(x_re_d2) * $signed(mag2_d);
    term_im_next = $signed(x_im_d2) * $signed(mag2_d);
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        out_valid <= 1'b0;
        stage1_valid <= 1'b0;
        stage2_valid <= 1'b0;
        x_re_d    <= {`DATA_WIDTH{1'b0}};
        x_im_d    <= {`DATA_WIDTH{1'b0}};
        x_re_d2   <= {`DATA_WIDTH{1'b0}};
        x_im_d2   <= {`DATA_WIDTH{1'b0}};
        mag2_d    <= {`MAG2_WIDTH{1'b0}};
        mag2      <= {`MAG2_WIDTH{1'b0}};
        term_re   <= {`CUBIC_WIDTH{1'b0}};
        term_im   <= {`CUBIC_WIDTH{1'b0}};
    end
    else begin
        stage1_valid <= in_valid;
        if (in_valid) begin
            x_re_d <= x_re;
            x_im_d <= x_im;
            mag2_d <= mag2_next;
        end

        stage2_valid <= stage1_valid;
        if (stage1_valid) begin
            x_re_d2 <= x_re_d;
            x_im_d2 <= x_im_d;
            mag2    <= mag2_d;
        end

        out_valid <= stage2_valid;
        if (stage2_valid) begin
            term_re <= term_re_next;
            term_im <= term_im_next;
        end
    end
end

endmodule
