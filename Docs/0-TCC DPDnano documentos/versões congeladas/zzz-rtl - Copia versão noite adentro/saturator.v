`timescale 1ns/1ps
`default_nettype none
`include "config.vh"

module saturator
(
    input  wire signed [`DATA_WIDTH-1:0] din,
    output reg  signed [`DATA_WIDTH-1:0] dout
);

always @(*) begin
    if (din > `DATA_MAX)
        dout = `DATA_MAX;
    else if (din < `DATA_MIN)
        dout = `DATA_MIN;
    else
        dout = din;
end

endmodule

`default_nettype wire
