`timescale 1ns/1ps

module dpdnano_hw_bringup_top (
    input  wire clk_27mhz,
    input  wire rst_n,
    output wire led_o
);

wire clk_dpd;
wire pll_lock;

Gowin_PLLVR u_gowin_pllvr (
    .clkout(clk_dpd),
    .lock  (pll_lock),
    .clkin (clk_27mhz)
);

localparam [26:0] ONE_SECOND_COUNT = 27'd101249999;

reg [26:0] second_counter;
reg        heartbeat;

always @(posedge clk_dpd or negedge rst_n) begin
    if (!rst_n) begin
        second_counter <= 27'd0;
        heartbeat      <= 1'b0;
    end
    else if (!pll_lock) begin
        second_counter <= 27'd0;
        heartbeat      <= 1'b0;
    end
    else if (second_counter == ONE_SECOND_COUNT) begin
        second_counter <= 27'd0;
        heartbeat      <= ~heartbeat;
    end
    else begin
        second_counter <= second_counter + 1'b1;
    end
end

assign led_o = pll_lock & heartbeat;

endmodule
