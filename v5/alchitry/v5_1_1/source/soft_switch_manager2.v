module soft_switch_manager2 (
  input clk,
  input rst,
  input [15:0] addr_in,
  input addr_in_en,
  input rw,
  input bus_reset,
  output reg [2:0] c8_select,
  output reg slot_access,
  output reg [16:0] addr_decode,
  output reg addr_decode_en
  );

  localparam SS80STORE = 7'h00;
  localparam AUXREAD = 7'h01;
  localparam AUXWRITE = 7'h02;
  localparam INTCXROM = 7'h03;
  localparam ALTZP = 7'h04;
  localparam SLOTC3ROM = 7'h05;
  localparam PAGE2 = 7'h2a;
  localparam HIRES = 7'h2b;

  reg ss_80store;
  reg ss_auxread;
  reg ss_auxwrite;
  reg ss_intcxrom;
  reg ss_altzp;
  reg ss_slotc3rom;
  reg ss_page2;
  reg ss_hires;
  reg ss_lcram_bank1;
  reg ss_lcram_writeinh;
  reg ss_lcram_writeinh_last;
  reg ss_lcram_read;
  reg [2:0] ss_c8_select;
  reg ss_slot_access;
  reg [16:0] ss_addr_decode;
  reg ss_addr_decode_en;
  
  // sequential logic
  always @(posedge clk) begin
    if (rst) begin
      ss_80store <= 0;
      ss_auxread <= 0;
      ss_altzp <= 0;
      ss_page2 <= 0;
      ss_hires <= 0;
      ss_lcram_bank1 <= 0;
      ss_lcram_writeinh <= 0;
      ss_lcram_writeinh_last <= 0;
      ss_lcram_read <= 0;
      ss_c8_select <= 3'h0;
      ss_slot_access <= 0;
      ss_addr_decode <= 17'h000;
      ss_addr_decode_en <= 0;
    end
    else if (!bus_reset) begin
      ss_80store <= 0;
      ss_auxread <= 0;
      ss_altzp <= 0;
      ss_page2 <= 0;
      ss_hires <= 0;
      ss_lcram_bank1 <= 0;
      ss_lcram_writeinh <= 0;
      ss_lcram_writeinh_last <= 0;
      ss_lcram_read <= 0;
      ss_c8_select <= 3'h0;
      ss_slot_access <= 0;
      ss_addr_decode <= 17'h000;
      ss_addr_decode_en <= 0;
    end
    else if (addr_in_en) begin
      // update direct soft switch state based on
      // writes to ss addresses
      if (!rw && addr_in[15:8] == 8'hc0) begin
        case (addr_in[7:1])
          SS80STORE: ss_80store <= addr_in[0];
          AUXREAD: ss_auxread <= addr_in[0];
          AUXWRITE: ss_auxwrite <= addr_in[0];
          INTCXROM: ss_intcxrom <= addr_in[0];
          ALTZP: ss_altzp <= addr_in[0];
          SLOTC3ROM: ss_slotc3rom <= addr_in[0];
          PAGE2: ss_page2 <= addr_in[0];
          HIRES: ss_hires = addr_in[0];
        endcase
      end
      
      // handle language card soft switches
      if (addr_in[15:4] == 12'hc08) begin
        ss_lcram_writeinh_last <= addr_in[0] & rw;
        ss_lcram_bank1 <= addr_in[3];
        ss_lcram_read <= (addr_in[1] == addr_in[0]);
        // if the last access would enable lcram writes, and this access would as well,
        // then we CLEAR the writeinh state (make writable).  If this access would enable
        // it but the previous access wouldn't, we leave it alone.  If this access would
        // disable it, we disable it without worrying about the prior state.
        if (addr_in[15:4] == 12'hc08) begin
          if (ss_lcram_writeinh_last && rw) begin
            ss_lcram_writeinh <= 0;
          end
        else
          ss_lcram_writeinh <= 1;
        end
      end
      
      // handle slot_access and c8_select
      ss_slot_access <= 0;
      if (addr_in[15:12] == 4'hc) begin
        if (addr_in[11] == 0 && addr_in[10:8] != 3'h0) begin
          // c1xx-c7xx
          if (!ss_intcxrom) begin
            ss_c8_select <= addr_in[10:8];
            ss_slot_access <= 1;
          end
          if (addr_in[10:8] == 3'h3) begin
            if (!ss_slotc3rom) begin
              ss_c8_select <= 3'h0;
              ss_slot_access <= 0;
            end
          end
        end
      end
      
      // handle cfff release of c8_select
      if (addr_in == 16'hcfff) begin
        ss_c8_select <= 3'h0;
      end
      
      // calculate addr_decode
      addr_decode[15:0] <= addr_in;
      addr_decode[16] <= 0;
      addr_decode_en <= 0;
      if (addr_in[15:12] == 4'hc) begin
        // nothing is ram in cxxx
        addr_decode_en <= 0;
      end else if (addr_in[15:9] == 7'h00) begin
        // 00xx-01xx, zp and stack
        addr_decode_en <= 1;
        addr_decode[16] <= ss_altzp;
      end else if (addr_in[15:14] == 2'h3) begin
        // since cxxx is already checked, this
        // catches dxxx-fxxx
        addr_decode[16] <= ss_altzp;
        if (ss_lcram_bank1 && addr_in[13:12] == 2'h1) begin
          // access to d, bank1 changes the decode to c
          addr_decode[12] <= 0;
        end
        if (rw && ss_lcram_read) begin
          addr_decode_en <= 1;
        end
        if (!rw && !ss_lcram_writeinh) begin
          addr_decode_en <= 1;
        end
      end else begin
        addr_decode_en <= 1;
        if (rw) begin
          addr_decode[16] <= ss_auxread;
        end else begin
          addr_decode[16] <= ss_auxwrite;
        end
      end
    end
    c8_select <= ss_c8_select;
    slot_access <= ss_slot_access;
    addr_decode <= ss_addr_decode;
    addr_decode_en <= ss_addr_decode_en;
  end
  
endmodule
