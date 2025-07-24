`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/23/2025 02:35:41 PM
// Design Name: 
// Module Name: au_top
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

module au_top(
    input clk_pin,
    input rst_n,
    output reg [7:0] led,
    input usb_rx,
    output reg usb_tx,

    /* DDR3 Connections */
    inout [15:0] ddr3_dq,
    inout [1:0] ddr3_dqs_n,
    inout [1:0] ddr3_dqs_p,
    output reg [13:0] ddr3_addr,
    output reg [2:0] ddr3_ba,
    output reg ddr3_ras_n,
    output reg ddr3_cas_n,
    output reg ddr3_we_n,
    output reg ddr3_reset_n,
    output reg ddr3_ck_p,
    output reg ddr3_ck_n,
    output reg ddr3_cke,
    output reg ddr3_cs_n,
    output reg [1:0] ddr3_dm,
    output reg ddr3_odt,

    /* FT600 Connections */
    input ft_clk,
    input ft_rxf,
    input ft_txe,
    inout [31:0] ft_data,
    inout [3:0] ft_be,
    output reg ft_rd,
    output reg ft_wr,
    output reg ft_oe,
    output reg ft_wakeup,
    output reg ft_reset,

    /* Tini Connections */
    inout [7:0] apple_data_pin,
    inout [15:0] apple_addr_pin,
    inout apple_rw_pin,
    input apple_phi0_pin,
    input apple_m2sel_pin,
    input apple_m2b0_pin,
    inout apple_inh_pin,
    inout apple_res_pin,
    inout apple_irq_pin,
    inout apple_rdy_pin,
    inout apple_dma_pin,
    output reg tini_oe_pin,
    input tini_5v_pin,
    output reg tini_addr_dir_pin,
    output reg tini_data_dir_pin
);

logic clk_out1;
logic clk_out2;
logic clk_locked;

clk_wiz_0 clk_wiz (
    .resetn(rst_n),
    .clk_in1(clk_pin),
    .clk_out1(clk_out1),
    .clk_out2(clk_out2),
    .locked(clk_locked)
);

globals::Memory_in M_mig_mem_in;
globals::Memory_out M_mig_mem_out;

logic mig_ui_clk;
logic mig_sync_rst;

mig_wrapper mig (
    .ddr3_dq(ddr3_dq),
    .ddr3_dqs_n(ddr3_dqs_n),
    .ddr3_dqs_p(ddr3_dqs_p),
    .sys_rst(!clk_locked),
    .sys_clk(clk_out1),
    .clk_ref(clk_out2),
    .mem_in(M_mig_mem_in),
    .mem_out(M_mig_mem_out),
    .ui_clk(mig_ui_clk),
    .sync_rst(mig_sync_rst)
);

always @* begin
    ddr3_addr = mig.ddr3_addr;
    ddr3_ba = mig.ddr3_ba;
    ddr3_ras_n = mig.ddr3_ras_n;
    ddr3_cas_n = mig.ddr3_cas_n;
    ddr3_we_n = mig.ddr3_we_n;
    ddr3_reset_n = mig.ddr3_reset_n;
    ddr3_ck_p = mig.ddr3_ck_p;
    ddr3_ck_n = mig.ddr3_ck_n;
    ddr3_cke = mig.ddr3_cke;
    ddr3_cs_n = mig.ddr3_cs_n;
    ddr3_dm = mig.ddr3_dm;
    ddr3_odt = mig.ddr3_odt;
    M_mig_mem_in = {{28'bxxxxxxxxxxxxxxxxxxxxxxxxxxxx, 3'bxxx, 1'h0, 128'hxxxxxxxxxxxx, 1'h0, 16'h0}};
    usb_tx = usb_rx;
end

globals::AppleBus_read ab_read;
globals::AppleBus_write ab_write;
globals::RegOpWrite reg_write;
logic watchdog_fired;

apple_bus_wrapper abus(
    .clk(mig_ui_clk),
    .rst(mig_sync_rst),
    // .clk(clk_wiz.clk_out1),
    // .rst(!clk_wiz.locked),
    .apple_data_pin(apple_data_pin),
    .apple_addr_pin(apple_addr_pin),
    .apple_rw_pin(apple_rw_pin),
    .apple_phi0_pin(apple_phi0_pin),
    .apple_m2sel_pin(apple_m2sel_pin),
    .apple_m2b0_pin(apple_m2b0_pin),
    .apple_inh_pin(apple_inh_pin),
    .apple_res_pin(apple_res_pin),
    .apple_irq_pin(apple_irq_pin),
    .apple_rdy_pin(apple_rdy_pin),
    .apple_dma_pin(apple_dma_pin),
    .tini_5v_pin(tini_5v_pin),
    .tini_oe_pin(tini_oe_pin),
    .tini_addr_dir_pin(tini_addr_dir_pin),
    .tini_data_dir_pin(tini_data_dir_pin),
    .ab_read(ab_read),
    .ab_write(ab_write)
);

globals::SoftSwitchState sss;

soft_switch_manager ssm(
    .clk(mig_ui_clk),
    .rst(mig_sync_rst),
    .ab_read(ab_read),
    .sss(sss)
);

logic[15:0] vbl_cycle;
logic vbl_is_60hz;
logic is_vbl;

vbl_manager vblm(
    .clk(mig_ui_clk),
    .rst(mig_sync_rst),
    .ab_read(ab_read),
    .vbl_cycle(vbl_cycle),
    .vbl_is_60hz(vbl_is_60hz),
    .is_vbl(is_vbl)
);

globals::AppleBus_write mb1_ab_write;
// hardcode the slot assignment for now
logic [2:0] mb1_slot_assign = 3'h5;

mockingboard mb1(
    .clk(mig_ui_clk),
    .rst(mig_sync_rst),
    .slot_assign(mb1_slot_assign),
    .sss(sss),
    .ab_read(ab_read),
    .ab_write(mb1_ab_write)
);

globals::AppleBus_write mouse_ab_write;
logic [2:0] mouse_slot_assign = 3'h4;
TxRequest mouse_tx_client();
logic [7:0] mouse_debug_led;

mouse_driver mouse_driver(
    .clk(mig_ui_clk),
    .rst(mig_sync_rst),
    .slot_assign(mouse_slot_assign),
    .sss(sss),
    .ab_read(ab_read),
    .is_vbl(is_vbl),
    .ab_write(mouse_ab_write),
    .tx_client(mouse_tx_client),
    .debug_led(mouse_debug_led)
);



logic nsc_enabled = 1;
globals::NSC_time nsc_input_time;
logic nsc_input_time_en;
globals::AppleBus_write nsc_ab_write;
logic [7:0] knock_max;

no_slot_clock nsc(
    .clk(mig_ui_clk),
    .rst(mig_sync_rst),
    .enabled(nsc_enabled),
    .input_time(nsc_input_time),
    .input_time_en(nsc_input_time_en),
    .ab_read(ab_read),
    .sss(sss),
    .ab_write(nsc_ab_write)
);

apple_bus_write_arbiter #(.NUM_CLIENTS(3)) 
ab_write_arb(
    .client_writes({nsc_ab_write, mb1_ab_write, mouse_ab_write}),
    .ab_write(ab_write)
);

TxRequest bus_event_tx_client();
globals::RegOpRead bus_event_reg_read;

bus_event_manager bus_event_mgr(
    .clk(mig_ui_clk),
    .rst(mig_sync_rst),
    .ab_read(ab_read),
    .reg_write(reg_write),
    .reg_read(bus_event_reg_read),
    .tx_client(bus_event_tx_client)
);

(* MARK_DEBUG = "TRUE" *) logic ft600_tx_data_en;
(* MARK_DEBUG = "TRUE" *) logic [31:0] ft600_tx_data;
(* MARK_DEBUG = "TRUE" *) logic ft600_tx_data_full;
(* MARK_DEBUG = "TRUE" *) logic ft600_rx_data_en;
(* MARK_DEBUG = "TRUE" *) logic [31:0] ft600_rx_data;
(* MARK_DEBUG = "TRUE" *) logic ft600_rx_data_empty;

ft600_fifo ft600(
    .clk(mig_ui_clk),
    .ft_clk(ft_clk),
    .rst(mig_sync_rst),

    // FT600 field passthrough
    .ftdi_rxf_n(ft_rxf),
    .ftdi_txe_n(ft_txe),
    .ftdi_data(ft_data),
    .ftdi_be(ft_be),
    .ftdi_wr_n(ft_wr),
    .ftdi_rd_n(ft_rd),
    .ftdi_oe_n(ft_oe),
    .ftdi_wakeup(ft_wakeup),
    .ftdi_reset(ft_reset),

    // fifo interface
    .tx_data_en(ft600_tx_data_en),
    .tx_data(ft600_tx_data),
    .tx_data_full(ft600_tx_data_full),
    .rx_data_en(ft600_rx_data_en),
    .rx_data(ft600_rx_data),
    .rx_data_empty(ft600_rx_data_empty)
);

assign ft600_outport_rd_en = 0;

logic blink_out;

blinker blink(
    .clk(mig_ui_clk),
    .rst(mig_sync_rst),
    .counted_event(ab_read.data_en),
    //.counted_event(1),
    .blink(blink_out)
);

TxRequest top_utility_tx_client();
globals::RegOpRead top_utility_reg_read;
logic [7:0] led_reg_led;


top_utility_regs #(.ADDR_BASE(0),.VERSION('h20250518))
top_utility_handler (
    .clk(mig_ui_clk),
    .rst(mig_sync_rst),
    .reg_write(reg_write),
    .reg_read(top_utility_reg_read),
    .tx_client(top_utility_tx_client),
    .led(led_reg_led),
    .watchdog_fired(watchdog_fired),
    .nsc_time(nsc_input_time),
    .nsc_time_en(nsc_input_time_en)
);


tini_bus_arbiter #(.NUM_REG_CLIENTS(2),.NUM_TX_CLIENTS(3))
tini_bus(
    .clk(mig_ui_clk),
    .rst(mig_sync_rst),
    .reg_write(reg_write),
    .reg_read_clients({bus_event_reg_read, top_utility_reg_read}),
    .tx_clients({bus_event_tx_client, top_utility_tx_client, mouse_tx_client}),
    .ft600_tx_data_en(ft600_tx_data_en),
    .ft600_tx_data(ft600_tx_data),
    .ft600_tx_data_full(ft600_tx_data_full),
    .ft600_rx_data_en(ft600_rx_data_en),
    .ft600_rx_data(ft600_rx_data),
    .ft600_rx_data_empty(ft600_rx_data_empty)
);

//assign led[7:0] = {8{tini_5v_pin}};
//assign led = led_reg_led;
assign led = mouse_debug_led;
//assign led[7:0] = {8{blink_out}};
//assign led[3:0] = nsc_input_time.second_lo; //led_reg_led;
//assign led[7:4] = nsc_input_time.second_hi;

ila_0 ila(
    .clk(clk_out1),
    .probe0(ft600.tx_data),
    .probe1(ft600.tx_fifo_dout),
    .probe2(ft600.tx_fifo_rd_en),
    .probe3(ft600.tx_data_en),
    .probe4(ft600.tx_data_full),
    .probe5(ft600.tx_fifo_empty),
    .probe6(ft_txe),
    .probe7(ft_rxf),
    .probe8(ft_rd),
    .probe9(ft_wr),
    .probe10(ft_oe),
    .probe11(ft600.wr_rst_busy),
    .probe12(ft600.rd_rst_busy),
    .probe13(0),
    .probe14(0),
    .probe15(ft600.ft_state_q)
);

endmodule
