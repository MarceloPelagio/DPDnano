`timescale 1ns/1ps

module input_read_cdc_hw_dpd(
    input  wire       fast_clk,
    input  wire       fast_rst,
    input  wire       fast_rd_en_i,
    input  wire [7:0] fast_rd_addr_i,
    output reg  [31:0] fast_rd_data_o,
    output reg        fast_rd_valid_o,

    input  wire       host_clk,
    input  wire       host_rst,
    output reg        host_rd_en_o,
    output reg  [7:0] host_rd_addr_o,
    input  wire [31:0] host_rd_data_i,
    input  wire       host_rd_valid_i
);

reg        req_toggle_fast;
reg [7:0]  req_addr_fast;
reg        fast_busy;
reg [1:0]  resp_sync_fast;
reg        resp_toggle_fast_d;

reg [1:0]  req_sync_host;
reg        req_toggle_host_d;
reg [7:0]  req_addr_host1, req_addr_host2;
reg [31:0] resp_data_host;
reg        resp_toggle_host;
reg        host_waiting_data;
reg        host_capture_pending;

always @(posedge fast_clk or posedge fast_rst) begin
    if (fast_rst) begin
        req_toggle_fast     <= 1'b0;
        req_addr_fast       <= 8'd0;
        fast_busy           <= 1'b0;
        fast_rd_data_o      <= 32'd0;
        fast_rd_valid_o     <= 1'b0;
        resp_sync_fast      <= 2'b00;
        resp_toggle_fast_d  <= 1'b0;
    end else begin
        fast_rd_valid_o <= 1'b0;
        resp_sync_fast <= {resp_sync_fast[0], resp_toggle_host};

        if (fast_rd_en_i && !fast_busy) begin
            req_addr_fast   <= fast_rd_addr_i;
            req_toggle_fast <= ~req_toggle_fast;
            fast_busy       <= 1'b1;
        end

        if (resp_sync_fast[1] != resp_toggle_fast_d) begin
            resp_toggle_fast_d <= resp_sync_fast[1];
            fast_rd_data_o     <= resp_data_host;
            fast_rd_valid_o    <= 1'b1;
            fast_busy          <= 1'b0;
        end
    end
end

always @(posedge host_clk or posedge host_rst) begin
    if (host_rst) begin
        req_sync_host      <= 2'b00;
        req_toggle_host_d  <= 1'b0;
        req_addr_host1     <= 8'd0;
        req_addr_host2     <= 8'd0;
        host_rd_en_o       <= 1'b0;
        host_rd_addr_o     <= 8'd0;
        resp_data_host     <= 32'd0;
        resp_toggle_host   <= 1'b0;
        host_waiting_data  <= 1'b0;
        host_capture_pending <= 1'b0;
    end else begin
        host_rd_en_o   <= 1'b0;
        req_sync_host  <= {req_sync_host[0], req_toggle_fast};
        req_addr_host1 <= req_addr_fast;
        req_addr_host2 <= req_addr_host1;

        if ((req_sync_host[1] != req_toggle_host_d) && !host_waiting_data && !host_capture_pending) begin
            req_toggle_host_d <= req_sync_host[1];
            host_capture_pending <= 1'b1;
        end

        if (host_capture_pending) begin
            host_rd_addr_o       <= req_addr_host2;
            host_rd_en_o         <= 1'b1;
            host_waiting_data    <= 1'b1;
            host_capture_pending <= 1'b0;
        end

        if (host_waiting_data && host_rd_valid_i) begin
            resp_data_host    <= host_rd_data_i;
            resp_toggle_host  <= ~resp_toggle_host;
            host_waiting_data <= 1'b0;
        end
    end
end

endmodule
