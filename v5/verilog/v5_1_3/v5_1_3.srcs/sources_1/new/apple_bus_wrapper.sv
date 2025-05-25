`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/23/2025 06:29:26 PM
// Design Name: 
// Module Name: apple_bus_wrapper
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


module apple_bus_wrapper(
    input clk,
    input rst,
    inout [7:0] apple_data_pin,
    inout [15:0] apple_addr_pin,
    inout apple_rw_pin,
    input apple_phi0_pin,
    input apple_m2sel_pin,
    input apple_q3_pin,
    input apple_7m_pin,
    input apple_m2b0_pin,
    inout apple_inh_pin,
    inout apple_res_pin,
    inout apple_irq_pin,
    inout apple_rdy_pin,
    inout apple_nmi_pin,
    inout apple_dma_pin,
    output reg tini_oe_pin,
    output reg tini_oe_bar_pin,
    input tini_5v_pin,
    output reg tini_addr_dir_pin,
    output reg tini_data_dir_pin,
    output globals::AppleBus_read ab_read,
    input globals::AppleBus_write ab_write
);

logic [7:0] data_clean;
logic [15:0] addr_clean;
logic [11:0] misc_clean;

synchronizer #(.WIDTH(8))
data_clean_sync(
    .clk(clk),
    .rst(rst),
    .in(apple_data_pin),
    .out(data_clean)
);

synchronizer #(.WIDTH(16))
addr_clean_sync(
    .clk(clk),
    .rst(rst),
    .in(apple_addr_pin),
    .out(addr_clean)
);

synchronizer #(.WIDTH(12))
misc_clean_sync(
    .clk(clk),
    .rst(rst),
    .in({apple_rw_pin, apple_phi0_pin, apple_m2sel_pin, apple_q3_pin,
        apple_7m_pin, apple_m2b0_pin, apple_inh_pin, apple_res_pin,
        apple_irq_pin, apple_rdy_pin, apple_nmi_pin, apple_dma_pin}),
    .out(misc_clean)
);

logic prev_phi0_d, prev_phi0_q = 0;
logic [28:0] addr_pipe_d, addr_pipe_q = 29'b0;
logic [45:0] data_pipe_d, data_pipe_q = 46'b0;
globals::AppleBus_read ab_read_d, ab_read_q = 0;
logic bus_emit_state_d, bus_emit_state_q = 0;

logic addr_edge;
logic data_edge;

logic addr_phase_begin;
logic addr_phase_snap_bus;
logic addr_phase_sss_ready;
logic addr_phase_inh_deadline;
logic data_phase_emit;
logic data_phase_snap_bus;

logic apple_data_enable;
logic apple_addr_rw_enable;

logic apple_inh_assert_d, apple_inh_assert_q = 0;

assign apple_data_enable = bus_emit_state_q && ab_write.wr_data_en;

assign tini_data_dir_pin = apple_data_enable;
assign apple_data_pin = apple_data_enable ? ab_write.wr_data : 8'hzz;
assign apple_addr_pin = apple_addr_rw_enable ? ab_write.wr_addr : 16'hzzzz;
assign apple_rw_pin = apple_addr_rw_enable ? ab_write.wr_rw : 1'hz;

// irq pin can assert or unassert at any time, doesn't need timing control
assign apple_irq_pin = ab_write.assert_irq ? 1'h0 : 1'hz;

// inh can only be asserted or released in a particular time range so it needs
// timed control via flip_flop
assign apple_inh_pin = apple_inh_assert_q ? 1'h0 : 1'hz;

always @* begin
    addr_pipe_d = addr_pipe_q;
    data_pipe_d = data_pipe_q;
    prev_phi0_d = prev_phi0_q;
    ab_read_d = ab_read_q;
    ab_read = ab_read_q;
    bus_emit_state_d = bus_emit_state_q;
    apple_inh_assert_d = apple_inh_assert_q;
    apple_addr_rw_enable = 0;
    addr_edge = 0;
    data_edge = 0;
    if (tini_5v_pin) begin
        tini_oe_pin = 1'b0;
        tini_oe_bar_pin = 1'b1;
    end
    else begin
        tini_oe_pin = 1'b1;
        tini_oe_bar_pin = 1'b0;
    end
    tini_addr_dir_pin = 1'b0;

    if (misc_clean[10] == 1 && prev_phi0_q == 0) begin
        data_edge = 1;
        prev_phi0_d = 1;
    end else begin
        if (misc_clean[10] == 0 && prev_phi0_q == 1) begin
            addr_edge = 1;
            prev_phi0_d = 0;
        end
    end
    addr_pipe_d[28:1] = addr_pipe_q[27:0];
    addr_pipe_d[0] = addr_edge;
    data_pipe_d[45:1] = data_pipe_q[44:0];
    data_pipe_d[0] = data_edge;
    addr_phase_begin = addr_edge;
    addr_phase_snap_bus = addr_pipe_q[19];
    addr_phase_sss_ready = addr_pipe_q[20];
    // maybe can tweak the INH deadline, could be a few cycles
    // later maybe, but 9 cycles from addr ready to inh being stable
    // should be plenty
    addr_phase_inh_deadline = addr_pipe_q[28];
    data_phase_emit = data_pipe_q[34];
    data_phase_snap_bus = data_pipe_q[44];
    ab_read_d.addr_en = 0;
    ab_read_d.data_en = 0;
    ab_read_d.sss_en = 0;
    
    // always resnap the clocks
    ab_read_d.phi0 = misc_clean[10];
    ab_read_d.q3 = misc_clean[8];
    ab_read_d.m7m = misc_clean[7];
    if (addr_phase_snap_bus) begin
        // resnap addr/misc signals
        ab_read_d.addr = addr_clean;
        ab_read_d.rw = misc_clean[11];
        ab_read_d.m2sel = misc_clean[9];
        ab_read_d.m2b0 = misc_clean[6];
        ab_read_d.inh = misc_clean[5];
        ab_read_d.res = misc_clean[4];
        ab_read_d.irq = misc_clean[3];
        ab_read_d.rdy = misc_clean[2];
        ab_read_d.nmi = misc_clean[1];
        ab_read_d.dma = misc_clean[0];
        ab_read_d.addr_en = 1;
    end else if (addr_phase_sss_ready) begin
        ab_read_d.sss_en = 1;
    end else if (data_phase_snap_bus) begin
        // resnap data
        ab_read_d.data = data_clean;
        ab_read_d.data_en = 1;
    end
    if (addr_phase_begin) begin
        bus_emit_state_d = 0;
        apple_inh_assert_d = 0;
    end
    if (data_phase_emit) begin
        bus_emit_state_d = 1;
    end;
    if (addr_phase_inh_deadline) begin
        apple_inh_assert_d = ab_write.assert_inh;
    end
end

always @(posedge clk) begin
    if (rst == 1'b1) begin
        addr_pipe_q <= 1'b0;
        prev_phi0_q <= 1'b0;
        data_pipe_q <= 1'b0;
        ab_read_q <= 1'b0;
        bus_emit_state_q <= 1'b0;
        apple_inh_assert_q <= 1'b0;
    end else begin
        addr_pipe_q <= addr_pipe_d;
        prev_phi0_q <= prev_phi0_d;
        data_pipe_q <= data_pipe_d;
        ab_read_q <= ab_read_d;
        bus_emit_state_q <= bus_emit_state_d;
        apple_inh_assert_q <= apple_inh_assert_d;
    end
end

endmodule
