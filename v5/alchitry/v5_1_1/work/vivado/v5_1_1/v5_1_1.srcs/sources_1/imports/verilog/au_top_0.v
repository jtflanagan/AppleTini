/*
   This file was generated automatically by Alchitry Labs version 1.2.7.
   Do not edit this file directly. Instead edit the original Lucid source.
   This is a temporary file and any changes made to it will be destroyed.
*/

module au_top_0 (
    input clk,
    input rst_n,
    output reg [7:0] led,
    input usb_rx,
    output reg usb_tx,
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
    input ft_clk,
    input ft_rxf,
    input ft_txe,
    inout [15:0] ft_data,
    inout [1:0] ft_be,
    output reg ft_rd,
    output reg ft_wr,
    output reg ft_oe,
    inout [7:0] data_pin,
    inout [15:0] addr_pin,
    inout rw_pin,
    input phi0_pin,
    input m2sel_pin,
    input q3_pin,
    input p7m_pin,
    input m2b0_pin,
    inout inh_pin,
    inout res_pin,
    inout irq_pin,
    inout rdy_pin,
    inout nmi_pin,
    inout dma_pin,
    output reg oe_pin,
    output reg oe_bar_pin,
    input board_5v_pin,
    output reg addr_dir_pin,
    output reg data_dir_pin
  );
  
  reg [7:0] IO_data_pin_enable;
  wire [7:0] IO_data_pin_read;
  reg [7:0] IO_data_pin_write;
  genvar GEN_data_pin;
  generate
    for (GEN_data_pin = 0; GEN_data_pin < 8; GEN_data_pin = GEN_data_pin + 1) begin
      assign data_pin[GEN_data_pin] = IO_data_pin_enable[GEN_data_pin] ? IO_data_pin_write[GEN_data_pin] : 1'bz;
    end
  endgenerate
  assign IO_data_pin_read = data_pin;
  reg [15:0] IO_addr_pin_enable;
  wire [15:0] IO_addr_pin_read;
  reg [15:0] IO_addr_pin_write;
  genvar GEN_addr_pin;
  generate
    for (GEN_addr_pin = 0; GEN_addr_pin < 16; GEN_addr_pin = GEN_addr_pin + 1) begin
      assign addr_pin[GEN_addr_pin] = IO_addr_pin_enable[GEN_addr_pin] ? IO_addr_pin_write[GEN_addr_pin] : 1'bz;
    end
  endgenerate
  assign IO_addr_pin_read = addr_pin;
  reg [0:0] IO_rw_pin_enable;
  wire [0:0] IO_rw_pin_read;
  reg [0:0] IO_rw_pin_write;
  assign rw_pin = IO_rw_pin_enable ? IO_rw_pin_write : 1'bz;
  assign IO_rw_pin_read = rw_pin;
  reg [0:0] IO_inh_pin_enable;
  wire [0:0] IO_inh_pin_read;
  reg [0:0] IO_inh_pin_write;
  assign inh_pin = IO_inh_pin_enable ? IO_inh_pin_write : 1'bz;
  assign IO_inh_pin_read = inh_pin;
  reg [0:0] IO_res_pin_enable;
  wire [0:0] IO_res_pin_read;
  reg [0:0] IO_res_pin_write;
  assign res_pin = IO_res_pin_enable ? IO_res_pin_write : 1'bz;
  assign IO_res_pin_read = res_pin;
  reg [0:0] IO_irq_pin_enable;
  wire [0:0] IO_irq_pin_read;
  reg [0:0] IO_irq_pin_write;
  assign irq_pin = IO_irq_pin_enable ? IO_irq_pin_write : 1'bz;
  assign IO_irq_pin_read = irq_pin;
  reg [0:0] IO_rdy_pin_enable;
  wire [0:0] IO_rdy_pin_read;
  reg [0:0] IO_rdy_pin_write;
  assign rdy_pin = IO_rdy_pin_enable ? IO_rdy_pin_write : 1'bz;
  assign IO_rdy_pin_read = rdy_pin;
  reg [0:0] IO_nmi_pin_enable;
  wire [0:0] IO_nmi_pin_read;
  reg [0:0] IO_nmi_pin_write;
  assign nmi_pin = IO_nmi_pin_enable ? IO_nmi_pin_write : 1'bz;
  assign IO_nmi_pin_read = nmi_pin;
  reg [0:0] IO_dma_pin_enable;
  wire [0:0] IO_dma_pin_read;
  reg [0:0] IO_dma_pin_write;
  assign dma_pin = IO_dma_pin_enable ? IO_dma_pin_write : 1'bz;
  assign IO_dma_pin_read = dma_pin;
  
  
  wire [1-1:0] M_clk_wiz_clk_out1;
  wire [1-1:0] M_clk_wiz_clk_out2;
  wire [1-1:0] M_clk_wiz_locked;
  reg [1-1:0] M_clk_wiz_reset;
  reg [1-1:0] M_clk_wiz_clk_in1;
  clk_wiz_0 clk_wiz (
    .reset(M_clk_wiz_reset),
    .clk_in1(M_clk_wiz_clk_in1),
    .clk_out1(M_clk_wiz_clk_out1),
    .clk_out2(M_clk_wiz_clk_out2),
    .locked(M_clk_wiz_locked)
  );
  
  reg rst;
  
  always @* begin
    M_clk_wiz_clk_in1 = clk;
    M_clk_wiz_reset = !rst_n;
  end
  
  wire [1-1:0] M_data_mgr_rst;
  wire [1-1:0] M_data_mgr_ui_clk;
  wire [14-1:0] M_data_mgr_ddr3_addr;
  wire [3-1:0] M_data_mgr_ddr3_ba;
  wire [1-1:0] M_data_mgr_ddr3_ras_n;
  wire [1-1:0] M_data_mgr_ddr3_cas_n;
  wire [1-1:0] M_data_mgr_ddr3_we_n;
  wire [1-1:0] M_data_mgr_ddr3_reset_n;
  wire [1-1:0] M_data_mgr_ddr3_ck_p;
  wire [1-1:0] M_data_mgr_ddr3_ck_n;
  wire [1-1:0] M_data_mgr_ddr3_cke;
  wire [1-1:0] M_data_mgr_ddr3_cs_n;
  wire [2-1:0] M_data_mgr_ddr3_dm;
  wire [1-1:0] M_data_mgr_ddr3_odt;
  wire [8-1:0] M_data_mgr_data_out;
  wire [1-1:0] M_data_mgr_data_out_en;
  wire [1-1:0] M_data_mgr_inhibit_assert;
  wire [1-1:0] M_data_mgr_irq_assert;
  reg [16-1:0] M_data_mgr_addr_in;
  reg [1-1:0] M_data_mgr_addr_in_en;
  reg [1-1:0] M_data_mgr_rw;
  reg [8-1:0] M_data_mgr_data_in;
  reg [1-1:0] M_data_mgr_data_in_en;
  reg [1-1:0] M_data_mgr_reset_pin_in;
  reg [1-1:0] M_data_mgr_data_begin_in;
  data_manager_1 data_mgr (
    .clk1(M_clk_wiz_clk_out1),
    .clk2(M_clk_wiz_clk_out2),
    .clk_locked(M_clk_wiz_locked),
    .ddr3_dq(ddr3_dq),
    .ddr3_dqs_n(ddr3_dqs_n),
    .ddr3_dqs_p(ddr3_dqs_p),
    .addr_in(M_data_mgr_addr_in),
    .addr_in_en(M_data_mgr_addr_in_en),
    .rw(M_data_mgr_rw),
    .data_in(M_data_mgr_data_in),
    .data_in_en(M_data_mgr_data_in_en),
    .reset_pin_in(M_data_mgr_reset_pin_in),
    .data_begin_in(M_data_mgr_data_begin_in),
    .rst(M_data_mgr_rst),
    .ui_clk(M_data_mgr_ui_clk),
    .ddr3_addr(M_data_mgr_ddr3_addr),
    .ddr3_ba(M_data_mgr_ddr3_ba),
    .ddr3_ras_n(M_data_mgr_ddr3_ras_n),
    .ddr3_cas_n(M_data_mgr_ddr3_cas_n),
    .ddr3_we_n(M_data_mgr_ddr3_we_n),
    .ddr3_reset_n(M_data_mgr_ddr3_reset_n),
    .ddr3_ck_p(M_data_mgr_ddr3_ck_p),
    .ddr3_ck_n(M_data_mgr_ddr3_ck_n),
    .ddr3_cke(M_data_mgr_ddr3_cke),
    .ddr3_cs_n(M_data_mgr_ddr3_cs_n),
    .ddr3_dm(M_data_mgr_ddr3_dm),
    .ddr3_odt(M_data_mgr_ddr3_odt),
    .data_out(M_data_mgr_data_out),
    .data_out_en(M_data_mgr_data_out_en),
    .inhibit_assert(M_data_mgr_inhibit_assert),
    .irq_assert(M_data_mgr_irq_assert)
  );
  
  always @* begin
    rst = M_data_mgr_rst;
    ddr3_addr = M_data_mgr_ddr3_addr;
    ddr3_ba = M_data_mgr_ddr3_ba;
    ddr3_ras_n = M_data_mgr_ddr3_ras_n;
    ddr3_cas_n = M_data_mgr_ddr3_cas_n;
    ddr3_we_n = M_data_mgr_ddr3_we_n;
    ddr3_reset_n = M_data_mgr_ddr3_reset_n;
    ddr3_ck_p = M_data_mgr_ddr3_ck_p;
    ddr3_ck_n = M_data_mgr_ddr3_ck_n;
    ddr3_cke = M_data_mgr_ddr3_cke;
    ddr3_cs_n = M_data_mgr_ddr3_cs_n;
    ddr3_dm = M_data_mgr_ddr3_dm;
    ddr3_odt = M_data_mgr_ddr3_odt;
  end
  
  wire [32-1:0] M_bus_event_fifo_dout;
  wire [1-1:0] M_bus_event_fifo_full;
  wire [1-1:0] M_bus_event_fifo_empty;
  wire [1-1:0] M_bus_event_fifo_prog_full;
  reg [32-1:0] M_bus_event_fifo_din;
  reg [1-1:0] M_bus_event_fifo_wr_en;
  reg [1-1:0] M_bus_event_fifo_rd_en;
  fifo_generator_2 bus_event_fifo (
    .clk(M_data_mgr_ui_clk),
    .srst(rst),
    .din(M_bus_event_fifo_din),
    .wr_en(M_bus_event_fifo_wr_en),
    .rd_en(M_bus_event_fifo_rd_en),
    .dout(M_bus_event_fifo_dout),
    .full(M_bus_event_fifo_full),
    .empty(M_bus_event_fifo_empty),
    .prog_full(M_bus_event_fifo_prog_full)
  );
  wire [1-1:0] M_ft600_ft_rd;
  wire [1-1:0] M_ft600_ft_wr;
  wire [1-1:0] M_ft600_ft_oe;
  wire [4-1:0] M_ft600_tx_out;
  wire [32-1:0] M_ft600_ui_dout;
  wire [1-1:0] M_ft600_ui_dout_empty;
  wire [1-1:0] M_ft600_ui_dout_len_empty;
  reg [1-1:0] M_ft600_ft_rxf;
  reg [1-1:0] M_ft600_ft_txe;
  reg [68-1:0] M_ft600_tx_in;
  reg [1-1:0] M_ft600_ui_dout_read;
  reg [1-1:0] M_ft600_ui_dout_len_read;
  ft600_module_2 ft600 (
    .clk(M_data_mgr_ui_clk),
    .rst(rst),
    .ft_clk(ft_clk),
    .ft_data(ft_data),
    .ft_be(ft_be),
    .ft_rxf(M_ft600_ft_rxf),
    .ft_txe(M_ft600_ft_txe),
    .tx_in(M_ft600_tx_in),
    .ui_dout_read(M_ft600_ui_dout_read),
    .ui_dout_len_read(M_ft600_ui_dout_len_read),
    .ft_rd(M_ft600_ft_rd),
    .ft_wr(M_ft600_ft_wr),
    .ft_oe(M_ft600_ft_oe),
    .tx_out(M_ft600_tx_out),
    .ui_dout(M_ft600_ui_dout),
    .ui_dout_empty(M_ft600_ui_dout_empty),
    .ui_dout_len_empty(M_ft600_ui_dout_len_empty)
  );
  wire [1-1:0] M_myBlinker_blink;
  reg [1-1:0] M_myBlinker_counted_event;
  blinker_3 myBlinker (
    .clk(M_data_mgr_ui_clk),
    .rst(rst),
    .counted_event(M_myBlinker_counted_event),
    .blink(M_myBlinker_blink)
  );
  reg [19:0] M_addr_misc_bus_d, M_addr_misc_bus_q = 1'h0;
  wire [1-1:0] M_bus_timer_addr_phase_begin;
  wire [1-1:0] M_bus_timer_addr_phase_snap_bus;
  wire [1-1:0] M_bus_timer_data_phase_emit;
  wire [1-1:0] M_bus_timer_data_phase_snap_bus;
  reg [1-1:0] M_bus_timer_phi0_clean;
  bus_timing_4 bus_timer (
    .clk(M_data_mgr_ui_clk),
    .rst(rst),
    .phi0_clean(M_bus_timer_phi0_clean),
    .addr_phase_begin(M_bus_timer_addr_phase_begin),
    .addr_phase_snap_bus(M_bus_timer_addr_phase_snap_bus),
    .data_phase_emit(M_bus_timer_data_phase_emit),
    .data_phase_snap_bus(M_bus_timer_data_phase_snap_bus)
  );
  localparam IDLE_bus_emit_state = 1'd0;
  localparam EMIT_PHASE_bus_emit_state = 1'd1;
  
  reg M_bus_emit_state_d, M_bus_emit_state_q = IDLE_bus_emit_state;
  localparam IDLE_bus_event_flush_state = 2'd0;
  localparam BUS_HEADER_bus_event_flush_state = 2'd1;
  localparam BUS_DATA_bus_event_flush_state = 2'd2;
  
  reg [1:0] M_bus_event_flush_state_d, M_bus_event_flush_state_q = IDLE_bus_event_flush_state;
  reg [7:0] M_bus_event_flush_counter_d, M_bus_event_flush_counter_q = 1'h0;
  reg [7:0] M_led_val_d, M_led_val_q = 1'h0;
  localparam IDLE_host_cmd_state = 2'd0;
  localparam LED_SET_host_cmd_state = 2'd1;
  localparam UNKNOWN_host_cmd_state = 2'd2;
  
  reg [1:0] M_host_cmd_state_d, M_host_cmd_state_q = IDLE_host_cmd_state;
  reg [7:0] M_host_cmd_counter_d, M_host_cmd_counter_q = 1'h0;
  wire [(5'h10+0)-1:0] M_addr_clean_out;
  reg [(5'h10+0)-1:0] M_addr_clean_in;
  
  genvar GEN_addr_clean0;
  generate
  for (GEN_addr_clean0=0;GEN_addr_clean0<5'h10;GEN_addr_clean0=GEN_addr_clean0+1) begin: addr_clean_gen_0
    pipeline_5 addr_clean (
      .clk(M_data_mgr_ui_clk),
      .in(M_addr_clean_in[GEN_addr_clean0*(1)+(1)-1-:(1)]),
      .out(M_addr_clean_out[GEN_addr_clean0*(1)+(1)-1-:(1)])
    );
  end
  endgenerate
  wire [(4'h8+0)-1:0] M_data_clean_out;
  reg [(4'h8+0)-1:0] M_data_clean_in;
  
  genvar GEN_data_clean0;
  generate
  for (GEN_data_clean0=0;GEN_data_clean0<4'h8;GEN_data_clean0=GEN_data_clean0+1) begin: data_clean_gen_0
    pipeline_5 data_clean (
      .clk(M_data_mgr_ui_clk),
      .in(M_data_clean_in[GEN_data_clean0*(1)+(1)-1-:(1)]),
      .out(M_data_clean_out[GEN_data_clean0*(1)+(1)-1-:(1)])
    );
  end
  endgenerate
  wire [(4'hc+0)-1:0] M_misc_clean_out;
  reg [(4'hc+0)-1:0] M_misc_clean_in;
  
  genvar GEN_misc_clean0;
  generate
  for (GEN_misc_clean0=0;GEN_misc_clean0<4'hc;GEN_misc_clean0=GEN_misc_clean0+1) begin: misc_clean_gen_0
    pipeline_5 misc_clean (
      .clk(M_data_mgr_ui_clk),
      .in(M_misc_clean_in[GEN_misc_clean0*(1)+(1)-1-:(1)]),
      .out(M_misc_clean_out[GEN_misc_clean0*(1)+(1)-1-:(1)])
    );
  end
  endgenerate
  
  always @* begin
    M_bus_event_flush_state_d = M_bus_event_flush_state_q;
    M_host_cmd_state_d = M_host_cmd_state_q;
    M_bus_emit_state_d = M_bus_emit_state_q;
    M_led_val_d = M_led_val_q;
    M_host_cmd_counter_d = M_host_cmd_counter_q;
    M_bus_event_flush_counter_d = M_bus_event_flush_counter_q;
    M_addr_misc_bus_d = M_addr_misc_bus_q;
    
    led = 8'h00;
    usb_tx = usb_rx;
    M_ft600_ft_rxf = ft_rxf;
    M_ft600_ft_txe = ft_txe;
    ft_rd = M_ft600_ft_rd;
    ft_wr = M_ft600_ft_wr;
    ft_oe = M_ft600_ft_oe;
    M_ft600_tx_in[0+0+0-:1] = 1'h0;
    M_ft600_tx_in[0+1+31-:32] = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
    M_ft600_tx_in[0+33+0-:1] = 1'h0;
    M_ft600_tx_in[34+0+0-:1] = 1'h0;
    M_ft600_tx_in[34+1+31-:32] = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
    M_ft600_tx_in[34+33+0-:1] = 1'h0;
    M_ft600_ui_dout_len_read = 1'h0;
    M_ft600_ui_dout_read = 1'h0;
    M_bus_event_fifo_din = 1'bx;
    M_bus_event_fifo_wr_en = 1'h0;
    M_bus_event_fifo_rd_en = 1'h0;
    
    case (M_bus_event_flush_state_q)
      IDLE_bus_event_flush_state: begin
        if (M_bus_event_fifo_prog_full) begin
          M_ft600_tx_in[0+0+0-:1] = 1'h1;
          M_bus_event_flush_state_d = BUS_HEADER_bus_event_flush_state;
        end
      end
      BUS_HEADER_bus_event_flush_state: begin
        M_ft600_tx_in[0+0+0-:1] = 1'h1;
        if (M_ft600_tx_out[0+0+0-:1] && !M_ft600_tx_out[0+1+0-:1]) begin
          M_ft600_tx_in[0+1+31-:32] = 32'h000001ff;
          M_ft600_tx_in[0+33+0-:1] = 1'h1;
          M_bus_event_flush_counter_d = 8'hff;
          M_bus_event_flush_state_d = BUS_DATA_bus_event_flush_state;
        end
      end
      BUS_DATA_bus_event_flush_state: begin
        M_ft600_tx_in[0+0+0-:1] = 1'h1;
        if (M_bus_event_flush_counter_q == 1'h0) begin
          M_ft600_tx_in[0+0+0-:1] = 1'h0;
          M_ft600_tx_in[0+33+0-:1] = 1'h0;
          M_bus_event_flush_state_d = IDLE_bus_event_flush_state;
        end
        if (M_ft600_tx_out[0+0+0-:1] && !M_ft600_tx_out[0+1+0-:1]) begin
          M_bus_event_flush_counter_d = M_bus_event_flush_counter_q - 1'h1;
          M_ft600_tx_in[0+1+31-:32] = M_bus_event_fifo_dout;
          M_bus_event_fifo_rd_en = 1'h1;
          M_ft600_tx_in[0+33+0-:1] = 1'h1;
        end
      end
    endcase
    
    case (M_host_cmd_state_q)
      IDLE_host_cmd_state: begin
        if (!M_ft600_ui_dout_len_empty) begin
          M_ft600_ui_dout_read = 1'h1;
          M_host_cmd_counter_d = M_ft600_ui_dout[0+7-:8];
          if (M_ft600_ui_dout[8+7-:8] == 8'h02) begin
            M_host_cmd_state_d = LED_SET_host_cmd_state;
          end else begin
            M_host_cmd_state_d = UNKNOWN_host_cmd_state;
          end
        end
      end
      LED_SET_host_cmd_state: begin
        if (M_host_cmd_counter_q == 8'h01) begin
          M_led_val_d = M_ft600_ui_dout[0+7-:8];
        end
      end
    endcase
    if (M_host_cmd_state_q != IDLE_host_cmd_state) begin
      M_ft600_ui_dout_read = 1'h1;
      M_host_cmd_counter_d = M_host_cmd_counter_q - 1'h1;
      if (M_host_cmd_counter_q == 1'h0) begin
        M_ft600_ui_dout_len_read = 1'h1;
        M_host_cmd_state_d = IDLE_host_cmd_state;
      end
    end
    addr_dir_pin = 1'h0;
    data_dir_pin = 1'h0;
    IO_addr_pin_write = 16'h0000;
    IO_addr_pin_enable = 16'h0000;
    IO_data_pin_write = 8'h00;
    IO_data_pin_enable = 8'h00;
    IO_rw_pin_write = 1'h0;
    IO_rw_pin_enable = 1'h0;
    IO_inh_pin_write = 1'h0;
    IO_inh_pin_enable = M_data_mgr_inhibit_assert;
    IO_res_pin_write = 1'h0;
    IO_res_pin_enable = 1'h0;
    IO_irq_pin_write = 1'h0;
    IO_irq_pin_enable = M_data_mgr_irq_assert;
    IO_rdy_pin_write = 1'h0;
    IO_rdy_pin_enable = 1'h0;
    IO_nmi_pin_write = 1'h0;
    IO_nmi_pin_enable = 1'h0;
    IO_dma_pin_write = 1'h0;
    IO_dma_pin_enable = 1'h0;
    M_addr_clean_in = IO_addr_pin_read;
    M_data_clean_in = IO_data_pin_read;
    M_misc_clean_in[0+0-:1] = IO_rw_pin_read;
    M_misc_clean_in[1+0-:1] = IO_res_pin_read;
    M_misc_clean_in[2+0-:1] = m2sel_pin;
    M_misc_clean_in[3+0-:1] = m2b0_pin;
    M_misc_clean_in[4+0-:1] = IO_irq_pin_read;
    M_misc_clean_in[5+0-:1] = p7m_pin;
    M_misc_clean_in[6+0-:1] = q3_pin;
    M_misc_clean_in[7+0-:1] = IO_dma_pin_read;
    M_misc_clean_in[8+0-:1] = IO_rdy_pin_read;
    M_misc_clean_in[9+0-:1] = IO_nmi_pin_read;
    M_misc_clean_in[10+0-:1] = IO_inh_pin_read;
    M_misc_clean_in[11+0-:1] = phi0_pin;
    M_data_mgr_addr_in = M_addr_clean_out;
    M_data_mgr_addr_in_en = 1'h0;
    M_data_mgr_rw = M_misc_clean_out[0+0-:1];
    M_data_mgr_data_in = M_data_clean_out;
    M_data_mgr_data_in_en = 1'h0;
    M_data_mgr_reset_pin_in = M_misc_clean_out[1+0-:1];
    M_data_mgr_data_begin_in = M_bus_timer_addr_phase_begin;
    if (board_5v_pin) begin
      oe_pin = 1'h0;
      oe_bar_pin = 1'h1;
    end else begin
      oe_pin = 1'h1;
      oe_bar_pin = 1'h0;
    end
    M_bus_timer_phi0_clean = M_misc_clean_out[11+0-:1];
    led = M_led_val_q;
    M_myBlinker_counted_event = M_bus_timer_addr_phase_begin;
    if (M_myBlinker_blink) begin
      led = M_led_val_q;
    end else begin
      led = M_led_val_q ^ 8'hff;
    end
    
    case (M_bus_emit_state_q)
      EMIT_PHASE_bus_emit_state: begin
        data_dir_pin = M_data_mgr_data_out_en;
        IO_data_pin_enable = {4'h8{M_data_mgr_data_out_en}};
        IO_data_pin_write = M_data_mgr_data_out;
      end
      default: begin
        data_dir_pin = 1'h0;
        IO_data_pin_enable = 8'h00;
      end
    endcase
    if (M_bus_timer_addr_phase_begin) begin
      M_bus_emit_state_d = IDLE_bus_emit_state;
    end
    if (M_bus_timer_addr_phase_snap_bus) begin
      M_addr_misc_bus_d[0+15-:16] = M_addr_clean_out;
      M_addr_misc_bus_d[16+3-:4] = M_misc_clean_out[0+3-:4];
      M_data_mgr_addr_in_en = 1'h1;
    end
    if (M_bus_timer_data_phase_emit) begin
      M_bus_emit_state_d = EMIT_PHASE_bus_emit_state;
    end
    if (M_bus_timer_data_phase_snap_bus) begin
      if (!M_bus_event_fifo_full) begin
        M_bus_event_fifo_din[0+19-:20] = M_addr_misc_bus_q;
        M_bus_event_fifo_din[20+7-:8] = M_data_clean_out;
        M_bus_event_fifo_din[28+3-:4] = 4'hf;
        M_bus_event_fifo_wr_en = 1'h1;
      end
      M_data_mgr_data_in_en = 1'h1;
    end
  end
  
  always @(posedge M_data_mgr_ui_clk) begin
    if (rst == 1'b1) begin
      M_addr_misc_bus_q <= 1'h0;
      M_bus_event_flush_counter_q <= 1'h0;
      M_led_val_q <= 1'h0;
      M_host_cmd_counter_q <= 1'h0;
      M_bus_emit_state_q <= 1'h0;
      M_bus_event_flush_state_q <= 1'h0;
      M_host_cmd_state_q <= 1'h0;
    end else begin
      M_addr_misc_bus_q <= M_addr_misc_bus_d;
      M_bus_event_flush_counter_q <= M_bus_event_flush_counter_d;
      M_led_val_q <= M_led_val_d;
      M_host_cmd_counter_q <= M_host_cmd_counter_d;
      M_bus_emit_state_q <= M_bus_emit_state_d;
      M_bus_event_flush_state_q <= M_bus_event_flush_state_d;
      M_host_cmd_state_q <= M_host_cmd_state_d;
    end
  end
  
endmodule
