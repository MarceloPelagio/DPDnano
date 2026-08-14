`timescale 1ns/1ps

module output_write_cdc_hw_dpd(
    input  wire       fast_clk,
    input  wire       fast_rst,
    input  wire       fast_wr_en_i,
    input  wire [7:0] fast_wr_addr_i,
    input  wire [31:0] fast_wr_data_i,
    output wire       fast_wr_ready_o,

    input  wire       host_clk,
    input  wire       host_rst,
    output reg        host_wr_en_o,
    output reg  [7:0] host_wr_addr_o,
    output reg  [31:0] host_wr_data_o
);

reg        req_toggle_fast;
reg [7:0]  req_addr_fast;
reg [31:0] req_data_fast;
reg        fast_busy;
reg [1:0]  ack_sync_fast;
reg        ack_toggle_fast_d;

reg [1:0]  req_sync_host;
reg        req_toggle_host_d;
reg [7:0]  req_addr_host1, req_addr_host2;
reg [31:0] req_data_host1, req_data_host2;
reg        ack_toggle_host;
reg        host_write_pending;

assign fast_wr_ready_o = ~fast_busy;

always @(posedge fast_clk or posedge fast_rst) begin
    if (fast_rst) begin
        req_toggle_fast    <= 1'b0;
        req_addr_fast      <= 8'd0;
        req_data_fast      <= 32'd0;
        fast_busy          <= 1'b0;
        ack_sync_fast      <= 2'b00;
        ack_toggle_fast_d  <= 1'b0;
    end else begin
        ack_sync_fast <= {ack_sync_fast[0], ack_toggle_host};

        if (fast_wr_en_i && !fast_busy) begin
            req_addr_fast   <= fast_wr_addr_i;
            req_data_fast   <= fast_wr_data_i;
            req_toggle_fast <= ~req_toggle_fast;
            fast_busy       <= 1'b1;
        end

        if (ack_sync_fast[1] != ack_toggle_fast_d) begin
            ack_toggle_fast_d <= ack_sync_fast[1];
            fast_busy         <= 1'b0;
        end
    end
end

always @(posedge host_clk or posedge host_rst) begin
    if (host_rst) begin
        req_sync_host     <= 2'b00;
        req_toggle_host_d <= 1'b0;
        req_addr_host1    <= 8'd0;
        req_addr_host2    <= 8'd0;
        req_data_host1    <= 32'd0;
        req_data_host2    <= 32'd0;
        host_wr_en_o      <= 1'b0;
        host_wr_addr_o    <= 8'd0;
        host_wr_data_o    <= 32'd0;
        ack_toggle_host   <= 1'b0;
        host_write_pending <= 1'b0;
    end else begin
        host_wr_en_o   <= 1'b0;
        req_sync_host  <= {req_sync_host[0], req_toggle_fast};
        req_addr_host1 <= req_addr_fast;
        req_addr_host2 <= req_addr_host1;
        req_data_host1 <= req_data_fast;
        req_data_host2 <= req_data_host1;

        if ((req_sync_host[1] != req_toggle_host_d) && !host_write_pending) begin
            req_toggle_host_d <= req_sync_host[1];
            host_write_pending <= 1'b1;
        end

        if (host_write_pending) begin
            host_wr_addr_o    <= req_addr_host2;
            host_wr_data_o    <= req_data_host2;
            host_wr_en_o      <= 1'b1;
            ack_toggle_host   <= ~ack_toggle_host;
            host_write_pending <= 1'b0;
        end
    end
end

endmodule
