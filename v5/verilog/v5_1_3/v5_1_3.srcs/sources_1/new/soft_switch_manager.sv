module soft_switch_manager (
    input clk,
    input rst,
    input globals::AppleBus_read ab_read,
    output globals::SoftSwitchState sss
);

localparam SS80STORE = 7'h00;
localparam AUXREAD = 7'h01;
localparam AUXWRITE = 7'h02;
localparam INTCXROM = 7'h03;
localparam ALTZP = 7'h04;
localparam SLOTC3ROM = 7'h05;
localparam PAGE2 = 7'h2a;
localparam HIRES = 7'h2b;

logic ss_80store_d, ss_80store_q;
logic ss_auxread_d, ss_auxread_q;
logic ss_auxwrite_d, ss_auxwrite_q;
logic ss_intcxrom_d, ss_intcxrom_q;
logic ss_altzp_d, ss_altzp_q;
logic ss_slotc3rom_d, ss_slotc3rom_q;
logic ss_page2_d, ss_page2_q;
logic ss_hires_d, ss_hires_q;
logic ss_lcram_bank1_d, ss_lcram_bank1_q;
logic ss_lcram_writeinh_d, ss_lcram_writeinh_q;
logic ss_lcram_writeinh_last_d, ss_lcram_writeinh_last_q;
logic ss_lcram_read_d, ss_lcram_read_q;
logic [2:0] ss_c8_select_d, ss_c8_select_q;
logic ss_slot_access_d, ss_slot_access_q;
logic [16:0] ss_addr_decode_d, ss_addr_decode_q;
logic ss_addr_decode_en_d, ss_addr_decode_en_q;

always_comb begin
    ss_80store_d = ss_80store_q;
    ss_auxread_d = ss_auxread_q;
    ss_auxwrite_d = ss_auxwrite_q;
    ss_intcxrom_d = ss_intcxrom_q;
    ss_altzp_d = ss_altzp_q;
    ss_slotc3rom_d = ss_slotc3rom_q;
    ss_page2_d = ss_page2_q;
    ss_hires_d = ss_hires_q;
    ss_lcram_bank1_d = ss_lcram_bank1_q;
    ss_lcram_writeinh_d = ss_lcram_writeinh_q;
    ss_lcram_writeinh_last_d = ss_lcram_writeinh_last_q;
    ss_lcram_read_d = ss_lcram_read_q;
    ss_c8_select_d = ss_c8_select_q;
    ss_slot_access_d = ss_slot_access_q;
    ss_addr_decode_d = ss_addr_decode_q;
    ss_addr_decode_en_d = ss_addr_decode_en_q;
    if (ab_read.addr_en) begin
        // update direct soft switch state based on
        // writes to ss addresses
        if (!ab_read.rw && ab_read.addr[15:8] == 8'hc0) begin
            case (ab_read.addr[7:1])
            SS80STORE: ss_80store_d = ab_read.addr[0];
            AUXREAD: ss_auxread_d = ab_read.addr[0];
            AUXWRITE: ss_auxwrite_d = ab_read.addr[0];
            INTCXROM: ss_intcxrom_d = ab_read.addr[0];
            ALTZP: ss_altzp_d = ab_read.addr[0];
            SLOTC3ROM: ss_slotc3rom_d = ab_read.addr[0];
            PAGE2: ss_page2_d = ab_read.addr[0];
            HIRES: ss_hires_d = ab_read.addr[0];
            endcase
        end
        // handle language card soft switches
        if (ab_read.addr[15:4] == 12'hc08) begin
            ss_lcram_writeinh_last_d = ab_read.addr[0] & ab_read.rw;
            ss_lcram_bank1_d = ab_read.addr[3];
            ss_lcram_read_d = (ab_read.addr[1] == ab_read.addr[0]);
            // if the last access would enable lcram writes, and this access would as well,
            // then we CLEAR the writeinh state (make writable).  If this access would enable
            // it but the previous access wouldn't, we leave it alone.  If this access would
            // disable it, we disable it without worrying about the prior state.
            if (ab_read.addr[15:4] == 12'hc08) begin
                if (ss_lcram_writeinh_last_q && ab_read.rw) begin
                    ss_lcram_writeinh_d = 0;
                end
            else
                ss_lcram_writeinh_d = 1;
            end
        end
        // handle slot_access and c8_select
        ss_slot_access_d = 0;
        if (ab_read.addr[15:12] == 4'hc) begin
            if (ab_read.addr[11] == 0 && ab_read.addr[10:8] != 3'h0) begin
                // c1xx-c7xx
                if (!ss_intcxrom_q) begin
                    ss_c8_select_d = ab_read.addr[10:8];
                    ss_slot_access_d = 1;
                end
                if (ab_read.addr[10:8] == 3'h3) begin
                    if (!ss_slotc3rom_q) begin
                        ss_c8_select_d = 3'h0;
                        ss_slot_access_d = 0;
                    end
                end
            end
        end
        // handle cfff release of c8_select
        if (ab_read.addr == 16'hcfff) begin
            ss_c8_select_d = 3'h0;
        end
        // calculate addr_decode
        ss_addr_decode_d[15:0] = ab_read.addr;
        ss_addr_decode_d[16] = 0;
        ss_addr_decode_en_d = 0;
        if (ab_read.addr[15:12] == 4'hc) begin
            // nothing is ram in cxxx
            ss_addr_decode_en_d = 0;
        end else if (ab_read.addr[15:9] == 7'h00) begin
            // 00xx-01xx, zp and stack
            ss_addr_decode_en_d = 1;
            ss_addr_decode_d[16] = ss_altzp_q;
        end else if (ab_read.addr[15:14] == 2'h3) begin
            // since cxxx is already checked, this
            // catches dxxx-fxxx
            ss_addr_decode_d[16] = ss_altzp_q;
            if (ss_lcram_bank1_q && ab_read.addr[13:12] == 2'h1) begin
                // access to d, bank1 changes the decode to c
                ss_addr_decode_d[12] = 0;
            end
            if (ab_read.rw && ss_lcram_read_q) begin
                ss_addr_decode_en_d = 1;
            end
            if (!ab_read.rw && !ss_lcram_writeinh_q) begin
                ss_addr_decode_en_d = 1;
            end
        end else begin
            ss_addr_decode_en_d = 1;
            if (ab_read.rw) begin
                ss_addr_decode_d[16] = ss_auxread_q;
            end else begin
                ss_addr_decode_d[16] = ss_auxwrite_q;
            end
        end
    end
    sss.addr_decode = ss_addr_decode_q;
    sss.addr_decode_en = ss_addr_decode_q;
    sss.c8_select = ss_c8_select_q;
    sss.slot_access = ss_slot_access_q;
end

always @(posedge clk) begin
    if (rst || !ab_read.res) begin
        ss_80store_q <= 0;
        ss_auxread_q <= 0;
        ss_auxwrite_q <= 0;
        ss_intcxrom_q <= 0;
        ss_altzp_q <= 0;
        ss_slotc3rom_q <= 0;
        ss_page2_q <= 0;
        ss_hires_q <= 0;
        ss_lcram_bank1_q <= 0;
        ss_lcram_writeinh_q <= 0;
        ss_lcram_writeinh_last_q <= 0;
        ss_lcram_read_q <= 0;
        ss_c8_select_q <= 0;
        ss_slot_access_q <= 0;
        ss_addr_decode_q <= 0;
        ss_addr_decode_en_q <= 0;
    end else begin
        ss_80store_q <= ss_80store_d;
        ss_auxread_q <= ss_auxread_d;
        ss_auxwrite_q <= ss_auxwrite_d;
        ss_intcxrom_q <= ss_intcxrom_d;
        ss_altzp_q <= ss_altzp_d;
        ss_slotc3rom_q <= ss_slotc3rom_d;
        ss_page2_q <= ss_page2_d;
        ss_hires_q <= ss_hires_d;
        ss_lcram_bank1_q <= ss_lcram_bank1_d;
        ss_lcram_writeinh_q <= ss_lcram_writeinh_d;
        ss_lcram_writeinh_last_q <= ss_lcram_writeinh_last_d;
        ss_lcram_read_q <= ss_lcram_read_d;
        ss_c8_select_q <= ss_c8_select_d;
        ss_slot_access_q <= ss_slot_access_d;
        ss_addr_decode_q <= ss_addr_decode_d;
        ss_addr_decode_en_q <= ss_addr_decode_en_d;
    end
end
  
endmodule
