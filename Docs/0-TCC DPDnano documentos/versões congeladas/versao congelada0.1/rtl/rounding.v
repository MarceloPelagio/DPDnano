`timescale 1ns/1ps
`include "config.vh"

//------------------------------------------------------------------------------
// Module      : rounding
// Description : Round accumulator result to Q5.30
// Verilog-2001
//------------------------------------------------------------------------------

module rounding
(
    input                               clk,
    input                               rst,
    input                               in_valid,

    input  signed [`ACC_WIDTH-1:0]      din_re,
    input  signed [`ACC_WIDTH-1:0]      din_im,

    output reg                          out_valid,

    output reg signed [`TERM_WIDTH-1:0] dout_re,
    output reg signed [`TERM_WIDTH-1:0] dout_im
);

localparam integer SHIFT = 30;

reg signed [`ACC_WIDTH-1:0] round_const;
reg signed [`ACC_WIDTH-1:0] re_round;
reg signed [`ACC_WIDTH-1:0] im_round;

always @* begin

    round_const = {{(`ACC_WIDTH-SHIFT){1'b0}},
                    1'b1,
                    {(SHIFT-1){1'b0}}};

    // Round-to-nearest
    re_round = din_re + round_const;
    im_round = din_im + round_const;

end

always @(posedge clk) begin

    if (rst) begin
        out_valid <= 1'b0;
        dout_re   <= {`TERM_WIDTH{1'b0}};
        dout_im   <= {`TERM_WIDTH{1'b0}};
    end
    else begin
        out_valid <= in_valid;

        if (in_valid) begin
            dout_re <= re_round >>> SHIFT;
            dout_im <= im_round >>> SHIFT;
        end
    end

end

endmodule
