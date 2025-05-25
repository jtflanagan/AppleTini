`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/17/2025 04:40:17 PM
// Design Name: 
// Module Name: host_read_request
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_utility_regs #(parameter ADDR_BASE = 0, VERSION = 0) (
    input clk,
    input rst,
    input globals::RegOpWrite reg_write,
    output globals::RegOpRead reg_read,
    TxRequest.client tx_client,
    output logic [7:0] led,
    output logic watchdog_fired
    );

logic [7:0] led_d, led_q = 0;
logic [31:0] watchdog_d, watchdog_q = 0;
logic [31:0] host_read_addr_d, host_read_addr_q = 0;
logic [7:0] host_read_len_d, host_read_len_q = 0;
logic host_read_incr_d, host_read_incr_q = 0;
logic watchdog_enabled_d, watchdog_enabled_q = 0;
logic host_read_ready_d, host_read_ready_q = 0;

always_comb begin
    reg_read.rd_data = 32'h0;
    reg_read.rd_ready = 0;
    led_d = led_q;
    watchdog_enabled_d = watchdog_enabled_q;
    host_read_ready_d = host_read_ready_q;
    watchdog_d = watchdog_q;
    led = led_q;
    watchdog_fired = 1;
    if (!watchdog_enabled_q) begin
        watchdog_fired = 0;
    end
    if (watchdog_q != 0) begin
        watchdog_d = watchdog_q - 1;
        watchdog_fired = 0;
    end
    host_read_addr_d = host_read_addr_q;
    host_read_len_d = host_read_len_q;
    host_read_incr_d = host_read_incr_q;
    tx_client.address = 0;
    tx_client.length = 0;
    tx_client.addr_incr = 0;
    tx_client.tx_request = 0;

    if (reg_write.new_cmd) begin
        case (reg_write.address)
        ADDR_BASE: begin
            // version
            reg_read.rd_data = VERSION;
            reg_read.rd_ready = 1;
        end
        ADDR_BASE+4: begin
            // led
            reg_read.rd_data = led_q;
            reg_read.rd_ready = 1;
            if (reg_write.is_write) begin
                led_d = reg_write.wr_data[7:0];
            end
        end
        ADDR_BASE+8: begin
            reg_read.rd_data = watchdog_q;
            reg_read.rd_ready = 1;
            if (reg_write.is_write) begin
                if (reg_write.wr_data == -1) begin
                    watchdog_enabled_d = 0;
                    watchdog_d = 0;
                end else begin
                    watchdog_enabled_d = 1;
                    watchdog_d = reg_write.wr_data;
                end
            end
        end
        ADDR_BASE+12: begin
            reg_read.rd_data = {host_read_incr_q, 23'b0, host_read_len_q};
            reg_read.rd_ready = 1;
            if (reg_write.is_write) begin
                host_read_len_d = reg_write.wr_data[7:0];
                host_read_incr_d = reg_write.wr_data[31];
            end
        end
        ADDR_BASE+16: begin
            reg_read.rd_data = host_read_addr_q;
            reg_read.rd_ready = 1;
            if (reg_write.is_write) begin
                host_read_addr_d = reg_write.wr_data;
                host_read_ready_d = 1;
            end
        end
        endcase
    end
    if (host_read_ready_q) begin
        tx_client.tx_request = 1;
        if (tx_client.tx_ack) begin
            tx_client.address = host_read_addr_q;
            tx_client.length = host_read_len_q[7:0];
            tx_client.addr_incr = host_read_incr_q;
            host_read_ready_d = 0; 
        end
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        host_read_ready_q <= 0;
        led_q <= 0;
        watchdog_enabled_q <= 0;
        watchdog_q <= 0;
        host_read_addr_q <= 0;
        host_read_len_q <= 0;
        host_read_incr_q <= 0;
    end else begin
        host_read_ready_q <= host_read_ready_d;
        led_q <= led_d;
        watchdog_enabled_q <= watchdog_enabled_d;
        watchdog_q <= watchdog_d;
        host_read_addr_q <= host_read_addr_d;
        host_read_len_q <= host_read_len_d;
        host_read_incr_q <= host_read_incr_d;
    end
end


endmodule

