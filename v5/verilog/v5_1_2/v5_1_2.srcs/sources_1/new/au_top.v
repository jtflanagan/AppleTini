`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/24/2025 06:43:44 PM
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


module au_top (
    input clk,
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
    inout [15:0] ft_data,
    inout [1:0] ft_be,
    output reg ft_rd,
    output reg ft_wr,
    output reg ft_oe,

    /* Tini Connections */
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
    output reg tini_data_dir_pin
  );

  wire clk_100;
  wire clk_200;
  wire clk_locked; 

  clk_wiz_0 clk_wiz(
    .resetn(rst_n),
    .clk_in1(clk),
    .clk_100(clk_100),
    .clk_200(clk_200),
    .locked(clk_locked)
  );

    wire [13:0] M_mig_ddr3_addr;
    wire [2:0] M_mig_ddr3_ba;
    wire M_mig_ddr3_ras_n;
    wire M_mig_ddr3_cas_n;
    wire M_mig_ddr3_we_n;
    wire M_mig_ddr3_reset_n;
    wire M_mig_ddr3_ck_p;
    wire M_mig_ddr3_ck_n;
    wire M_mig_ddr3_cke;
    wire M_mig_ddr3_cs_n;
    wire [1:0] M_mig_ddr3_dm;
    wire M_mig_ddr3_odt;
    reg M_mig_sys_clk_i;
    reg M_mig_clk_ref_i;
    reg [27:0] M_mig_app_addr;
    reg [2:0] M_mig_app_cmd;
    reg M_mig_app_en;
    reg [127:0] M_mig_app_wdf_data;
    reg M_mig_app_wdf_end;
    reg [15:0] M_mig_app_wdf_mask;
    reg M_mig_app_wdf_wren;
    wire [127:0] M_mig_app_rd_data;
    wire M_mig_app_rd_data_end;
    wire M_mig_app_rd_data_valid;
    wire M_mig_app_rdy;
    wire M_mig_app_wdf_rdy;
    reg M_mig_app_sr_req;
    reg M_mig_app_ref_req;
    reg M_mig_app_zq_req;
    wire M_mig_app_sr_active;
    wire M_mig_app_ref_ack;
    wire M_mig_app_zq_ack;
    wire M_mig_ui_clk;
    wire M_mig_ui_clk_sync_rst;
    wire M_mig_init_calib_complete;
    wire [11:0] M_mig_device_temp;
    reg M_mig_sys_rst;


  // mig_7series_0 mig(
  //   .ddr3_dq(ddr3_dq),
  //   .ddr3_dqs_n(ddr3_dqs_n),
  //   .ddr3_dqs_p(ddr3_dqs_p),
  //   .sys_clk_i(clk_100),
  //   .clk_ref_i(clk_200),
  //   .sys_rst(!clk_locked),
  //   .app_sr_req(app_sr_req),
  //   .app_ref_req(app_ref_req),
  //   .app_zq_req(app_zq_req),
  //   .app_wdf_data(app_wdf_data),
  //   .app_wdf_end(app_wdf_end),
  //   .app_wdf_wren(app_wdf_wren),
  //   .app_wdf_mask(app_wdf_mask),
  //   .app_cmd(app_cmd),
  //   .app_en(app_en),
  //   .app_addr(app_addr)
  // );
      mig_7series_0 mig (
        .ddr3_dq(ddr3_dq),
        .ddr3_dqs_n(ddr3_dqs_n),
        .ddr3_dqs_p(ddr3_dqs_p),
        .ddr3_addr(M_mig_ddr3_addr),
        .ddr3_ba(M_mig_ddr3_ba),
        .ddr3_ras_n(M_mig_ddr3_ras_n),
        .ddr3_cas_n(M_mig_ddr3_cas_n),
        .ddr3_we_n(M_mig_ddr3_we_n),
        .ddr3_reset_n(M_mig_ddr3_reset_n),
        .ddr3_ck_p(M_mig_ddr3_ck_p),
        .ddr3_ck_n(M_mig_ddr3_ck_n),
        .ddr3_cke(M_mig_ddr3_cke),
        .ddr3_cs_n(M_mig_ddr3_cs_n),
        .ddr3_dm(M_mig_ddr3_dm),
        .ddr3_odt(M_mig_ddr3_odt),
        .sys_clk_i(M_mig_sys_clk_i),
        .clk_ref_i(M_mig_clk_ref_i),
        .app_addr(M_mig_app_addr),
        .app_cmd(M_mig_app_cmd),
        .app_en(M_mig_app_en),
        .app_wdf_data(M_mig_app_wdf_data),
        .app_wdf_end(M_mig_app_wdf_end),
        .app_wdf_mask(M_mig_app_wdf_mask),
        .app_wdf_wren(M_mig_app_wdf_wren),
        .app_rd_data(M_mig_app_rd_data),
        .app_rd_data_end(M_mig_app_rd_data_end),
        .app_rd_data_valid(M_mig_app_rd_data_valid),
        .app_rdy(M_mig_app_rdy),
        .app_wdf_rdy(M_mig_app_wdf_rdy),
        .app_sr_req(M_mig_app_sr_req),
        .app_ref_req(M_mig_app_ref_req),
        .app_zq_req(M_mig_app_zq_req),
        .app_sr_active(M_mig_app_sr_active),
        .app_ref_ack(M_mig_app_ref_ack),
        .app_zq_ack(M_mig_app_zq_ack),
        .ui_clk(M_mig_ui_clk),
        .ui_clk_sync_rst(M_mig_ui_clk_sync_rst),
        .init_calib_complete(M_mig_init_calib_complete),
        .device_temp(M_mig_device_temp),
        .sys_rst(M_mig_sys_rst)
    );

    reg sync_rst;
    reg ui_clk;

    always @* begin
        ddr3_addr = M_mig_ddr3_addr;
        ddr3_ba = M_mig_ddr3_ba;
        ddr3_ras_n = M_mig_ddr3_ras_n;
        ddr3_cas_n = M_mig_ddr3_cas_n;
        ddr3_we_n = M_mig_ddr3_we_n;
        ddr3_reset_n = M_mig_ddr3_reset_n;
        ddr3_ck_p = M_mig_ddr3_ck_p;
        ddr3_ck_n = M_mig_ddr3_ck_n;
        ddr3_cke = M_mig_ddr3_cke;
        ddr3_cs_n = M_mig_ddr3_cs_n;
        ddr3_dm = M_mig_ddr3_dm;
        ddr3_odt = M_mig_ddr3_odt;
        M_mig_app_sr_req = 1'h0;
        M_mig_app_ref_req = 1'h0;
        M_mig_app_zq_req = 1'h0;
        M_mig_app_wdf_data = 128'b0;
        M_mig_app_wdf_end = 1'b0;
        M_mig_app_wdf_wren = 1'b0;
        M_mig_app_wdf_mask = 16'b0;
        M_mig_app_cmd = 1'b0;
        M_mig_app_en = 1'b0;
        M_mig_app_addr = 28'b0;
        //mem_out.rd_data = M_mig_app_rd_data;
        //mem_out.rd_valid = M_mig_app_rd_data_valid;
        //mem_out.rdy = M_mig_app_rdy;
        //mem_out.wr_rdy = M_mig_app_wdf_rdy;
        M_mig_sys_clk_i = clk_100;
        M_mig_clk_ref_i = clk_200;
        M_mig_sys_rst = !clk_locked;
        sync_rst = M_mig_ui_clk_sync_rst;
        ui_clk = M_mig_ui_clk;
    end

  always @* begin
    usb_tx = usb_rx;
  end
  
  // apple data bus inout pins [7:0]
  reg [7:0] IO_apple_data_pin_enable;
  wire [7:0] IO_apple_data_pin_read;
  reg [7:0] IO_apple_data_pin_write;
  genvar GEN_apple_data_pin;
  generate
    for (GEN_apple_data_pin = 0; GEN_apple_data_pin < 8; GEN_apple_data_pin = GEN_apple_data_pin + 1) begin
      assign apple_data_pin[GEN_apple_data_pin] = IO_apple_data_pin_enable[GEN_apple_data_pin] ? IO_apple_data_pin_write[GEN_apple_data_pin] : 1'bz;
    end
  endgenerate
  assign IO_apple_data_pin_read = apple_data_pin;

  // apple addr bus inout pins [15:0]
  reg [15:0] IO_apple_addr_pin_enable;
  wire [15:0] IO_apple_addr_pin_read;
  reg [15:0] IO_apple_addr_pin_write;
  genvar GEN_apple_addr_pin;
  generate
    for (GEN_apple_addr_pin = 0; GEN_apple_addr_pin < 16; GEN_apple_addr_pin = GEN_apple_addr_pin + 1) begin
      assign apple_addr_pin[GEN_apple_addr_pin] = IO_apple_addr_pin_enable[GEN_apple_addr_pin] ? IO_apple_addr_pin_write[GEN_apple_addr_pin] : 1'bz;
    end
  endgenerate
  assign IO_apple_addr_pin_read = apple_addr_pin;

  // apple misc ro pins
  wire [4:0] IO_apple_ro_pin_read;

  assign IO_apple_ro_pin_read[0] = apple_phi0_pin;
  assign IO_apple_ro_pin_read[1] = apple_m2sel_pin;
  assign IO_apple_ro_pin_read[2] = apple_q3_pin;
  assign IO_apple_ro_pin_read[3] = apple_7m_pin;
  assign IO_apple_ro_pin_read[4] = apple_m2b0_pin;
 
  // apple misc inout pins
  reg [6:0] IO_apple_inout_pin_enable;
  wire[6:0] IO_apple_inout_pin_read;
  reg [6:0] IO_apple_inout_pin_write;

  assign apple_rw_pin = IO_apple_inout_pin_enable[0] ? IO_apple_inout_pin_write[0] : 1'bz;
  assign IO_apple_inout_pin_read[0] = apple_rw_pin;
  assign apple_inh_pin = IO_apple_inout_pin_enable[1] ? IO_apple_inout_pin_write[1] : 1'bz;
  assign IO_apple_inout_pin_read[1] = apple_inh_pin;
  assign apple_res_pin = IO_apple_inout_pin_enable[2] ? IO_apple_inout_pin_write[2] : 1'bz;
  assign IO_apple_inout_pin_read[2] = apple_res_pin;
  assign apple_irq_pin = IO_apple_inout_pin_enable[3] ? IO_apple_inout_pin_write[3] : 1'bz;
  assign IO_apple_inout_pin_read[3] = apple_irq_pin;
  assign apple_rdy_pin = IO_apple_inout_pin_enable[4] ? IO_apple_inout_pin_write[4] : 1'bz;
  assign IO_apple_inout_pin_read[4] = apple_rdy_pin;
  assign apple_nmi_pin = IO_apple_inout_pin_enable[5] ? IO_apple_inout_pin_write[5] : 1'bz;
  assign IO_apple_inout_pin_read[5] = apple_nmi_pin;
  assign apple_dma_pin = IO_apple_inout_pin_enable[6] ? IO_apple_inout_pin_write[6] : 1'bz;
  assign IO_apple_inout_pin_read[6] = apple_dma_pin;

  wire [15:0] apple_addr_clean_w;
  synchronizer #(.WIDTH(16))
  addr_clean(
    .clk(ui_clk),
    .rst(rst),
    .in(IO_apple_addr_pin_read),
    .out(apple_addr_clean_w)
  );

  wire [7:0] apple_data_clean_w;
  synchronizer #(.WIDTH(8))
  data_clean(
    .clk(ui_clk),
    .rst(rst),
    .in(IO_apple_data_pin_read),
    .out(apple_data_clean_w)
  );

  wire [11:0] apple_misc_clean_w;
  synchronizer #(.WIDTH(12))
  misc_clean(
    .clk(ui_clk),
    .rst(rst),
    .in({IO_apple_ro_pin_read, IO_apple_inout_pin_read}),
    .out(apple_misc_clean_w)
  );

  // symbolic names for the signals in misc_clean
  // and IO_apple_inout write/enable
  localparam MISC_RW = 4'h0;
  localparam MISC_INH = 4'h1;
  localparam MISC_RES = 4'h2;
  localparam MISC_IRQ = 4'h3;
  localparam MISC_RDY = 4'h4;
  localparam MISC_NMI = 4'h5;
  localparam MISC_DMA = 4'h6;
  localparam MISC_PHI0 = 4'h7;
  localparam MISC_M2SEL = 4'h8;
  localparam MISC_Q3 = 4'h9;
  localparam MISC_7M = 4'ha;
  localparam MISC_M2B0 = 4'hb;

  wire bus_timer_addr_phase_begin_w;
  wire bus_timer_addr_phase_snap_bus_w;
  wire bus_timer_data_phase_emit_w;
  wire bus_timer_data_phase_snap_bus_w;

  // FT600 inouts
  reg [15:0] IO_ft_data_enable;
  wire [15:0] IO_ft_data_read;
  reg [15:0] IO_ft_data_write;
  genvar GEN_ft_data;
  generate
    for (GEN_ft_data = 0; GEN_ft_data < 16; GEN_ft_data = GEN_ft_data + 1) begin
      assign ft_data[GEN_ft_data] = IO_ft_data_enable[GEN_ft_data] ? IO_ft_data_write[GEN_ft_data] : 1'bz;
    end
  endgenerate
  assign IO_ft_data_read = ft_data;

  reg [1:0] IO_ft_be_enable;
  wire [1:0] IO_ft_be_read;
  reg [1:0] IO_ft_be_write;
  genvar GEN_ft_be;
  generate
    for (GEN_ft_be = 0; GEN_ft_be < 2; GEN_ft_be = GEN_ft_be + 1) begin
      assign ft_be[GEN_ft_be] = IO_ft_be_enable[GEN_ft_be] ? IO_ft_be_write[GEN_ft_be] : 1'bz;
    end
  endgenerate
  assign IO_ft_be_read = ft_be;

  reg ft600_inport_wr_en_r;
  reg ft600_outport_rd_en_r;
  reg [35:0] ft600_inport_data_r;
  wire ft600_inport_full_w;
  wire ft600_outport_empty_w;
  wire [35:0] ft600_outport_data_w;

  wire ftdi_wrn_w;
  wire ftdi_rdn_w;
  wire ftdi_oen_w;
  wire [1:0] ftdi_be_w;
  wire [15:0] ftdi_data_w;

  ft600_fifo ft600(
    .clk_i(ui_clk),
    .ft_clk_i(ft_clk),
    .rst_i(rst),
    .ftdi_rxf_i(ft_rxf),
    .ftdi_txe_i(ft_txe),
    .ftdi_data_in_i(IO_ft_data_read),
    .ftdi_be_in_i(IO_ft_be_read),
    .inport_wr_en_i(ft600_inport_wr_en_r),
    .inport_data_i(ft600_inport_data_r),
    .outport_rd_en_i(ft600_outport_rd_en_r),
    .ftdi_wrn_o(ftdi_wrn_w),
    .ftdi_rdn_o(ftdi_rdn_w),
    .ftdi_oen_o(ftdi_oen_w),
    .ftdi_data_out_o(ftdi_data_w),
    .ftdi_be_out_o(ftdi_be_w),
    .inport_full_o(ft600_inport_full_w),
    .outport_empty_o(ft600_outport_empty_w),
    .outport_data_o(ft600_outport_data_w)
  );

  always @* begin
    ft_wr = ftdi_wrn_w;
    ft_rd = ftdi_rdn_w;
    ft_oe = ftdi_oen_w;
    IO_ft_data_write = ftdi_data_w;
    IO_ft_be_write = ftdi_be_w;
    IO_ft_data_enable = ft_oe ? 16'hffff : 16'h0000;
    IO_ft_be_enable = ft_oe ? 2'b11 : 2'b00;
  end

  bus_timing bus_timer (
    .clk(ui_clk),
    .rst(rst),
    .phi0_clean(misc_clean.out[MISC_PHI0]),
    .addr_phase_begin(bus_timer_addr_phase_begin_w),
    .addr_phase_snap_bus(bus_timer_addr_phase_snap_bus_w),
    .data_phase_emit(bus_timer_data_phase_emit_w),
    .data_phase_snap_bus(bus_timer_data_phase_snap_bus_w)
  );

  wire [2:0] c8_select_w;
  wire slot_access_w;
  wire [16:0] addr_decode_w;
  wire addr_decode_en_w;

  soft_switch_manager2 ss_mgr(
    .clk(ui_clk),
    .rst(rst),
    .addr_in(apple_addr_clean_w),
    .addr_in_en(bus_timer_addr_phase_snap_bus_w),
    .rw(apple_misc_clean_w[MISC_RW]),
    .bus_reset(apple_misc_clean_w[MISC_RES]),
    .c8_select(c8_select_w),
    .slot_access(slot_access_w),
    .addr_decode(addr_decode_w),
    .addr_decode_en(addr_decode_en_w)
  );

  

  wire [1-1:0] M_myBlinker_blink;
  blinker myBlinker (
    .clk(ui_clk),
    .rst(rst),
    .counted_event(bus_timer_addr_phase_begin_w),
    .blink(M_myBlinker_blink)
  );

  reg [19:0] addr_misc_bus_d, addr_misc_bus_q = 20'h00000;
  reg bus_event_wr_en_r;
  wire bus_event_prog_full_w;
  reg [31:0] bus_event_din_r;
  reg bus_event_rd_en_r;
  wire [31:0] bus_event_dout_w;
  fifo_bus_events bus_event_fifo(
    .srst(rst),
    .clk(ui_clk),
    .din(bus_event_din_r),
    .wr_en(bus_event_wr_en_r),
    .rd_en(bus_event_rd_en_r),
    .dout(bus_event_dout_w),
    .full(),
    .prog_full(bus_event_prog_full_w),
    .empty()
  );

  always @* begin
    addr_misc_bus_d = addr_misc_bus_q;
    bus_event_din_r = 32'h00000000;
    bus_event_wr_en_r = 0;
    IO_apple_data_pin_enable = 8'h00;
    IO_apple_data_pin_write = 8'h00;
    IO_apple_addr_pin_enable = 16'h0000;
    IO_apple_addr_pin_write = 16'h0000;
    IO_apple_inout_pin_enable = 7'h00;
    IO_apple_inout_pin_write = 7'h00;
    if (tini_5v_pin) begin
      tini_oe_pin = 1'b0;
      tini_oe_bar_pin = 1'b1; 
    end
    else begin
      tini_oe_pin = 1'b1;
      tini_oe_bar_pin = 1'b0;
    end
    tini_addr_dir_pin = 1'b0;
    tini_data_dir_pin = 1'b0;

    if (bus_timer_addr_phase_snap_bus_w) begin
      addr_misc_bus_d[15:0] = apple_addr_clean_w;
      addr_misc_bus_d[16] = apple_misc_clean_w[MISC_RW];
      addr_misc_bus_d[17] = apple_misc_clean_w[MISC_RES];
      addr_misc_bus_d[18] = apple_misc_clean_w[MISC_M2SEL];
      addr_misc_bus_d[19] = apple_misc_clean_w[MISC_M2B0];
    end

    if (bus_timer_data_phase_snap_bus_w) begin
      bus_event_din_r[19:0] = addr_misc_bus_q;
      bus_event_din_r[27:20] = apple_data_clean_w;
      bus_event_din_r[31:28] = 4'hf;
      bus_event_wr_en_r = 1; 
    end
  end

  always @(posedge ui_clk) begin
    if (rst) begin
      addr_misc_bus_q = 0;
    end else begin
      addr_misc_bus_q = addr_misc_bus_d;
    end
  end

  localparam FLUSH_IDLE = 2'b00;
  localparam FLUSH_BUS_DATA = 2'b01;

  reg [1:0] bus_event_flush_state_d, bus_event_flush_state_q = FLUSH_IDLE;
  reg [7:0] bus_event_counter_d, bus_event_counter_q = 0;

  always @* begin
    bus_event_flush_state_d = bus_event_flush_state_q;
    bus_event_counter_d = bus_event_counter_q;
    ft600_inport_wr_en_r = 0;
    ft600_inport_data_r = 36'h00000;
    bus_event_rd_en_r = 0;
    case (bus_event_flush_state_q)
    FLUSH_IDLE: begin
      if (bus_event_prog_full_w && !ft600_inport_full_w) begin
        bus_event_flush_state_d = FLUSH_BUS_DATA;
        // 1 in high nibble signals message begin
        // 01 in message byte indicates bus events
        // ff in message length indicates 255 payload size
        ft600_inport_data_r = 36'h1000001ff;
        ft600_inport_wr_en_r = 1;
        bus_event_counter_d = 8'hff;
      end
    end
    FLUSH_BUS_DATA: begin
      if (!ft600_inport_full_w) begin
        if (bus_event_counter_q == 0) begin
          bus_event_flush_state_d = FLUSH_IDLE;
        end else begin
          bus_event_counter_d = bus_event_counter_q - 1;
          ft600_inport_data_r = {4'h0, bus_event_dout_w};
          ft600_inport_wr_en_r = 1;
          bus_event_rd_en_r = 1;
        end
      end
    end
    default:
      bus_event_flush_state_d = FLUSH_IDLE;
    endcase
  end

  always @(posedge ui_clk) begin
    if (rst) begin
      bus_event_flush_state_q = FLUSH_IDLE;
      bus_event_counter_q = 0;
    end else begin
      bus_event_flush_state_q = bus_event_flush_state_d;
      bus_event_counter_q = bus_event_counter_d;
    end
  end

  always @(posedge ui_clk) begin
    led <= {8{myBlinker.blink}};
  end


endmodule
