`timescale 1ns/1ps
module crc16_ccitt(
    input  wire [15:0] crc_in,
    input  wire [7:0]  data_in,
    output reg  [15:0] crc_out
);
integer i;
reg [15:0] c;
always @* begin
    c = crc_in ^ (data_in << 8);
    for (i=0; i<8; i=i+1) begin
        if (c[15])
            c = (c << 1) ^ 16'h1021;
        else
            c = (c << 1);
    end
    crc_out = c;
end
endmodule
