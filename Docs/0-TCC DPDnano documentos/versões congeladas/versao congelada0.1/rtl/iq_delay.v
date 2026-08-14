`timescale 1ns/1ps
`default_nettype none
`include "config.vh"

module iq_delay(
    input  wire clk,
    input  wire rst,
    input  wire valid_in,
    input  wire signed [`DATA_WIDTH-1:0] din_i,
    input  wire signed [`DATA_WIDTH-1:0] din_q,

    output wire signed [`DATA_WIDTH-1:0] x0_i,
    output wire signed [`DATA_WIDTH-1:0] x0_q,
    output wire signed [`DATA_WIDTH-1:0] x1_i,
    output wire signed [`DATA_WIDTH-1:0] x1_q,
    output wire signed [`DATA_WIDTH-1:0] x2_i,
    output wire signed [`DATA_WIDTH-1:0] x2_q,
    output wire valid_out
);

reg signed [`DATA_WIDTH-1:0] s0_i,s0_q;
reg signed [`DATA_WIDTH-1:0] s1_i,s1_q;
reg signed [`DATA_WIDTH-1:0] s2_i,s2_q;
reg v0,v1,v2;

always @(posedge clk) begin
    if (rst) begin
        s0_i<=0; s0_q<=0;
        s1_i<=0; s1_q<=0;
        s2_i<=0; s2_q<=0;
        v0<=0; v1<=0; v2<=0;
    end else begin
        if (valid_in) begin
            s2_i<=s1_i; s2_q<=s1_q;
            s1_i<=s0_i; s1_q<=s0_q;
            s0_i<=din_i; s0_q<=din_q;
        end
        v2<=v1;
        v1<=v0;
        v0<=valid_in;
    end
end

assign x0_i=s0_i;
assign x0_q=s0_q;
assign x1_i=s1_i;
assign x1_q=s1_q;
assign x2_i=s2_i;
assign x2_q=s2_q;
assign valid_out=v2;

endmodule

`default_nettype wire
