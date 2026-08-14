`timescale 1ns/1ps
`include "config.vh"

//------------------------------------------------------------------------------
// Module      : saturator
// Description : Saturate Q5.30 to Q1.15
// Verilog-2001
//------------------------------------------------------------------------------

module saturator
(
    input                               clk,
    input                               rst,
    input                               in_valid,

    input  signed [`TERM_WIDTH-1:0]     din_re,
    input  signed [`TERM_WIDTH-1:0]     din_im,

    output reg                          out_valid,

    output reg signed [`DATA_WIDTH-1:0] dout_re,
    output reg signed [`DATA_WIDTH-1:0] dout_im
);

localparam signed [`TERM_WIDTH-1:0] MAX_Q530 = 36'sd1073709056; // 32767 << 15
localparam signed [`TERM_WIDTH-1:0] MIN_Q530 = -36'sd1073741824; // -32768 << 15

reg signed [`DATA_WIDTH-1:0] re_next;
reg signed [`DATA_WIDTH-1:0] im_next;

always @* begin

    if (din_re > MAX_Q530)
        re_next = 16'sh7FFF;
    else if (din_re < MIN_Q530)
        re_next = 16'sh8000;
    else
        re_next = din_re[30:15];

    if (din_im > MAX_Q530)
        im_next = 16'sh7FFF;
    else if (din_im < MIN_Q530)
        im_next = 16'sh8000;
    else
        im_next = din_im[30:15];

end

always @(posedge clk) begin
    if (rst) begin
        out_valid <= 1'b0;
        dout_re   <= {`DATA_WIDTH{1'b0}};
        dout_im   <= {`DATA_WIDTH{1'b0}};
    end
    else begin
        out_valid <= in_valid;
        if (in_valid) begin
            dout_re <= re_next;
            dout_im <= im_next;
        end
    end
end

endmodule
