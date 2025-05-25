`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/08/2025 05:06:32 PM
// Design Name: 
// Module Name: bus_event_manager
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


module bus_event_manager #(parameter ADDR_BASE = 'h1000) (
    input clk,
    input rst,
    input globals::AppleBus_read ab_read,
    input globals::RegOpWrite reg_write,
    output globals::RegOpRead reg_read,
    TxRequest.client tx_client,
    input watchdog_fired
);

logic bus_event_fifo_wr_en;
logic bus_event_fifo_rd_en;
logic [31:0] bus_event_fifo_din;
logic [31:0] bus_event_fifo_dout;
logic bus_event_fifo_full;
logic bus_event_fifo_empty;
logic bus_event_fifo_prog_full;

typedef enum {IDLE, REQ_OVERFLOW, REQ_BUS_EVENTS} bus_event_state_sm;

bus_event_state_sm bus_event_state_d, bus_event_state_q = IDLE;

logic event_enable_d, event_enable_q = 0;
logic overflow_flag_d, overflow_flag_q = 0;
logic overflow_req_d, overflow_req_q = 0;
logic [7:0] bus_read_count_d, bus_read_count_q = 0;

// note that the bus event fifo remains in reset
// (and thus is emptied and remains empty)
// when events are not enabled.
fifo_sync_32x512 bus_event_fifo(
    .srst(rst || !event_enable_q),
    .clk(clk),
    .wr_en(bus_event_fifo_wr_en),
    .rd_en(bus_event_fifo_rd_en),
    .din(bus_event_fifo_din),
    .dout(bus_event_fifo_dout),
    .full(bus_event_fifo_full),
    .empty(bus_event_fifo_empty),
    .prog_full(bus_event_fifo_prog_full)
);

always_comb begin
    bus_event_state_d = bus_event_state_q;
    event_enable_d = event_enable_q;
    overflow_flag_d = overflow_flag_q;
    overflow_req_d = overflow_req_q;
    bus_read_count_d = bus_read_count_q;
    reg_read.rd_data = 32'h0;
    reg_read.rd_ready = 0;
    bus_event_fifo_rd_en = 0;
    bus_event_fifo_din = 32'hxxxxxxxx;
    bus_event_fifo_wr_en = 0;
    tx_client.tx_request = 0;
    tx_client.address = 0;
    tx_client.length = 0;
    tx_client.addr_incr = 0;

    if (!overflow_flag_q && bus_event_fifo_prog_full && bus_read_count_q == 0) begin
        bus_read_count_d = 251;
    end
    if (bus_event_fifo_full && !overflow_flag_q) begin
        overflow_flag_d = 1;
        overflow_req_d = 1;
        event_enable_d = 0;
        bus_read_count_d = 0;
    end
    if (watchdog_fired) begin
        event_enable_d = 0;
        bus_read_count_d = 0;
    end

    if (event_enable_q && ab_read.data_en) begin
        bus_event_fifo_din[15:0] = ab_read.addr;
        //bus_event_fifo_din[19:16] = {ab_read.rw, ab_read.res, ab_read.m2sel, ab_read.m2b0};
        bus_event_fifo_din[19:16] = {ab_read.m2b0, ab_read.m2sel, ab_read.res, ab_read.rw};
        bus_event_fifo_din[27:20] = ab_read.data;
        bus_event_fifo_din[31:28] = 4'hf;
        bus_event_fifo_wr_en = 1;
    end

    if (reg_write.new_cmd) begin
        case (reg_write.address)
        ADDR_BASE: begin
            reg_read.rd_data = {30'b0, overflow_flag_q, event_enable_q};
            reg_read.rd_ready = 1;
            if (reg_write.is_write) begin
                event_enable_d = reg_write.wr_data[0];
                if (reg_write.wr_data[0]) begin
                    // (re-)enabling events clears overflow
                    overflow_flag_d = 0;
                end
            end
        end
        ADDR_BASE+4: begin
            reg_read.rd_data = bus_event_fifo_dout;
            reg_read.rd_ready = 1;
            bus_event_fifo_rd_en = 1;
            if (bus_read_count_q != 0) begin
                bus_read_count_d = bus_read_count_q - 1;
            end
        end
        endcase
    end

    case (bus_event_state_q)
    IDLE: begin
        if (overflow_req_q) begin
            // overflow positive edge, issue an overflow notification
            bus_event_state_d = REQ_OVERFLOW;
            overflow_req_d = 0;
        end else if (bus_read_count_q == 251) begin
            bus_event_state_d = REQ_BUS_EVENTS;
            bus_read_count_d = 250;
        end
    end
    REQ_OVERFLOW: begin
        tx_client.tx_request = 1;
        if (tx_client.tx_ack) begin
            tx_client.address = ADDR_BASE;
            tx_client.length = 1;
            tx_client.addr_incr = 0;
            bus_event_state_d = IDLE;
        end
    end
    REQ_BUS_EVENTS: begin
        tx_client.tx_request = 1;
        if (tx_client.tx_ack) begin
            tx_client.address = ADDR_BASE+4;
            tx_client.length = 250;
            tx_client.addr_incr = 0;
            bus_event_state_d = IDLE;
        end
    end
    endcase
end

always @(posedge clk) begin
    if (rst) begin
        bus_event_state_q <= IDLE;
        event_enable_q <= 0;
        overflow_flag_q <= 0;
        overflow_req_q <= 0;
        bus_read_count_q <= 0;
    end else begin
        bus_event_state_q <= bus_event_state_d;
        event_enable_q <= event_enable_d;
        overflow_flag_q <= overflow_flag_d;
        overflow_req_q <= overflow_req_d;
        bus_read_count_q <= bus_read_count_d;
    end
end

endmodule
