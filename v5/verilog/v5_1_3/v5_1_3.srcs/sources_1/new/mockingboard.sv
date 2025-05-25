`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/23/2025 04:49:14 PM
// Design Name: 
// Module Name: mockingboard
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


module mockingboard(
    input clk,
    input rst,
    input globals::AppleBus_read ab_read,
    input globals::SoftSwitchState sss,
    input logic [2:0] slot_assign,
    output globals::AppleBus_write ab_write
);

globals::AppleBus_write ab_write_d, ab_write_q = 0;

logic [2:0] slot_assign_d, slot_assign_q = 0;

logic via0_strobe;
logic via1_strobe;
logic via_slow_clock;
logic via0_irq;
logic via1_irq;
logic [7:0] via0_data_out;
logic [7:0] via0_porta_in = 0;
logic [7:0] via0_portb_in = 0;
logic via0_ca1_in = 0;
logic via0_ca2_in = 0;
logic via0_cb1_in = 0;
logic via0_cb2_in = 0;
logic [7:0] via0_porta_out;
logic [7:0] via0_portb_out;
logic via0_ca2_out;
logic via0_cb1_out;
logic via0_cb2_out;
logic [7:0] via1_data_out;
logic [7:0] via1_porta_in = 0;
logic [7:0] via1_portb_in = 0;
logic via1_ca1_in = 0;
logic via1_ca2_in = 0;
logic via1_cb1_in = 0;
logic via1_cb2_in = 0;
logic [7:0] via1_porta_out;
logic [7:0] via1_portb_out;
logic via1_ca2_out;
logic via1_cb1_out;
logic via1_cb2_out;

via6522 via0(
    .clk(clk),
    .reset(rst || !ab_read.res),
    .we(!ab_read.rw),
    .porta_in(via0_porta_in),
    .portb_in(via0_portb_in),
    .ca1_in(via0_ca1_in),
    .ca2_in(via0_ca2_in),
    .cb1_in(via0_cb1_in),
    .cb2_in(via0_cb2_in),
    .strobe(via0_strobe),
    .slow_clock(via_slow_clock),
    .addr(ab_read.addr[3:0]),
    .data_in(ab_read.data),
    .data_out(via0_data_out),
    .irq(via0_irq),
    .porta_out(via0_porta_out),
    .portb_out(via0_portb_out),
    .ca2_out(via0_ca2_out),
    .cb1_out(via0_cb1_out),
    .cb2_out(via0_cb2_out)
);

via6522 via1(
    .clk(clk),
    .reset(rst || !ab_read.res),
    .we(!ab_read.rw),
    .porta_in(via1_porta_in),
    .portb_in(via1_portb_in),
    .ca1_in(via1_ca1_in),
    .ca2_in(via1_ca2_in),
    .cb1_in(via1_cb1_in),
    .cb2_in(via1_cb2_in),
    .strobe(via1_strobe),
    .slow_clock(via_slow_clock),
    .addr(ab_read.addr[3:0]),
    .data_in(ab_read.data),
    .data_out(via1_data_out),
    .irq(via1_irq),
    .porta_out(via1_porta_out),
    .portb_out(via1_portb_out),
    .ca2_out(via1_ca2_out),
    .cb1_out(via1_cb1_out),
    .cb2_out(via1_cb2_out)
);

assign ab_write = ab_write_q;

always_comb begin
    ab_write_d = ab_write_q;
    slot_assign_d = slot_assign_q;
    via0_strobe = 0;
    via1_strobe = 0;
    via_slow_clock = 0;
    if (slot_assign)
    if (slot_assign != 0) begin
        //ab_write_d.assert_irq = 1;
        ab_write_d.assert_irq = via0_irq | via1_irq;
        if (ab_read.data_en) begin
            via_slow_clock = 1;
            if (sss.slot_access &&
                ab_read.addr[15:12] == 4'hc && 
                ab_read.addr[11:8] == {1'h0, slot_assign}) begin
                // slot access range
                if (ab_read.addr[7] == 0) begin
                    via0_strobe = 1;
                end else begin
                    via1_strobe = 1;
                end
            end 
        end
        if (ab_read.sss_en) begin
            if (sss.slot_access &&
                ab_read.addr[15:12] == 4'hc && 
                ab_read.addr[11:8] == {1'h0, slot_assign} &&
                ab_read.rw) begin
                // slot access range, read access.
                // need to provide emitted byte.
                if (ab_read.addr[7] == 0) begin
                    ab_write_d.wr_data = via0_data_out;
                    ab_write_d.wr_data_en = 1;
                end else begin
                    ab_write_d.wr_data = via1_data_out;
                    ab_write_d.wr_data_en = 1;
                end
            end else begin
                ab_write_d.wr_data = 0;
                ab_write_d.wr_data_en = 0;
            end
        end
    end else begin
        // if this slot is disabled, never touch the bus
        ab_write_d = 0;
    end
end

always @(posedge clk) begin
    if (rst) begin
        ab_write_q <= 0;
    end else begin
        ab_write_q <= ab_write_d;
    end
end

endmodule
