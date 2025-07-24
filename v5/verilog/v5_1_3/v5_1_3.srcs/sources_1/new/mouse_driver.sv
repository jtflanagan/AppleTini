`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/28/2025 04:12:47 PM
// Design Name: 
// Module Name: mouse_driver
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


module mouse_driver  #(parameter ADDR_BASE = 'h2000) (
    input clk,
    input rst,
    input globals::AppleBus_read ab_read,
    input globals::SoftSwitchState sss,
    input logic [2:0] slot_assign,
    input logic is_vbl,
    input globals::RegOpWrite reg_write,
    output globals::RegOpRead reg_read,
    output globals::AppleBus_write ab_write,
    TxRequest.client tx_client,
    output logic [7:0] debug_led
);

logic [7:0] mouse_rom [0:2047];  // 2k rom

initial begin
    $readmemh("mouse_rom.mem", mouse_rom, 0, 2047);
end

localparam STAT_PREV_BUTTON1 = 0;
localparam STAT_INT_MOVEMENT = 1;
localparam STAT_INT_BUTTON = 2;
localparam STAT_INT_VBL = 3;
localparam STAT_CURR_BUTTON1 = 4;
localparam STAT_MOVEMENT_SINCE_READMOUSE = 5;
localparam STAT_PREV_BUTTON0 = 6;
localparam STAT_CURR_BUTTON0 = 7;

localparam MODE_MOUSE_ON = 0;
localparam MODE_INT_MOVEMENT = 1;
localparam MODE_INT_BUTTON = 2;
localparam MODE_INT_VBL = 3;

globals::AppleBus_write ab_write_d, ab_write_q = 0;


logic m6821_cs;
logic m6821_rst;
logic [1:0] m6821_rs;
logic [7:0] m6821_din;
logic [7:0] m6821_dout;
logic [7:0] m6821_pa_in;
logic [7:0] m6821_pa_out;
logic [7:0] m6821_pb_in;
logic [7:0] m6821_pb_out;

m6821 mm(
    .clk(clk),
    .rst(m6821_rst),
    .cs(m6821_cs),
    .rw(ab_read.rw),
    .addr(ab_read.addr[1:0]),
    .data_in(m6821_din),
    .data_out(m6821_dout),
    .irqa(),
    .irqb(),
    .pa_i(m6821_pa_in),
    .pa_o(m6821_pa_out),
    .pa_oe(),
    .ca1(0),
    .ca2_i(0),
    .ca2_o(),
    .ca2_oe(),
    .pb_i(m6821_pb_in),
    .pb_o(m6821_pb_out),
    .pb_oe(),
    .cb1(0),
    .cb2_i(0),
    .cb2_o(),
    .cb2_oe()
);

typedef enum {IDLE, START_CMD, PROCESS_CMD, CMD_BYTES, CHECK_CLAMP} cmd_sm;

logic [15:0] prevx_d, prevx_q = 0;
logic [15:0] prevy_d, prevy_q = 0;
logic [1:0] prevb_d, prevb_q = 0;
logic [15:0] newx_d, newx_q = 0;
logic [15:0] newy_d, newy_q = 0;
logic [1:0] newb_d, newb_q = 0;
logic [15:0] minx_d, minx_q = 0;
logic [15:0] maxx_d, maxx_q = 16'h03ff;
logic [15:0] miny_d, miny_q = 0;
logic [15:0] maxy_d, maxy_q = 16'h03ff;
logic [7:0] mouse_state_d, mouse_state_q = 0;
logic [7:0] mouse_mode_d, mouse_mode_q = 0;
logic [7:0] portb_d, portb_q = 8'h40;
logic [7:0] cmd_d, cmd_q = 0;
logic [2:0] cmd_counter_d, cmd_counter_q = 0;
logic [31:0] cmd_shreg_d, cmd_shreg_q = 0;
logic [63:0] rsp_shreg_d, rsp_shreg_q = 0;

cmd_sm cmd_state_d, cmd_state_q = IDLE;

assign ab_write = ab_write_q;
assign m6821_rst = !rst & ab_read.res;

always_comb begin
    ab_write_d = ab_write_q;
    prevx_d = prevx_q;
    prevy_d = prevy_q;
    prevb_d = prevb_q;
    newx_d = newx_q;
    newy_d = newy_q;
    newb_d = newb_q;
    minx_d = minx_q;
    maxx_d = maxx_q;
    miny_d = miny_q;
    maxy_d = maxy_q;
    mouse_state_d = mouse_state_q;
    mouse_mode_d = mouse_mode_q;
    portb_d = portb_q;
    rsp_shreg_d = rsp_shreg_q;
    cmd_state_d = cmd_state_q;
    cmd_shreg_d = cmd_shreg_q;
    cmd_d = cmd_q;
    cmd_counter_d = cmd_counter_q;
    m6821_cs = 0;
    m6821_rs = ab_read.addr[1:0];
    m6821_din = ab_read.data;
    m6821_pa_in = rsp_shreg_q[7:0];
    m6821_pb_in = portb_q;
    reg_read.rd_data = 0;
    reg_read.rd_ready = 0;
    debug_led = cmd_q;
    if (slot_assign != 0) begin
        if (is_vbl && mouse_mode_q[MODE_INT_VBL]) begin
            // note that mouse_on state does not need to be set, only vbl
            mouse_state_d[3] = 1;
        end
        if (ab_read.sss_en) begin
            if (sss.slot_access &&
                ab_read.addr[15:12] == 4'hc && 
                ab_read.addr[11:8] == {1'h0, slot_assign} &&
                ab_read.rw) begin
                // slot access range, read access
                // port b [3:1] selects the 256-byte rom page from the 2k rom
                ab_write_d.wr_data = mouse_rom[{m6821_pb_out[3:1], ab_read.addr[7:0]}];
                ab_write_d.wr_data_en = 1;
            end else if (ab_read.addr[15:8] == 8'hc0 &&
                ab_read.addr[7] == 1 &&
                ab_read.addr[6:4] == slot_assign &&
                ab_read.rw) begin
                ab_write_d.wr_data_en = 1;
                //ab_write_d.wr_data = 0;
                ab_write_d.wr_data = m6821_dout;
                m6821_cs = 1;
            end else begin
                ab_write_d.wr_data = 0;
                ab_write_d.wr_data_en = 0;
            end
        end else if (ab_read.data_en) begin
            if (ab_read.addr[15:8] == 8'hc0 &&
                ab_read.addr[7] == 1 &&
                ab_read.addr[6:4] == slot_assign &&
                ab_read.rw == 0) begin
                // iosel address range, enable 6821 chip select to
                // snap the input value
                m6821_cs = 1;
            end
        end
        // IRQ gets asserted if any of the flags responsible are set, and cleared
        // when those flags are cleared (which happens when the interrupt gets serviced
        // or the driver gets reset)
        ab_write_d.assert_irq = mouse_state_q[1] | mouse_state_q[2] | mouse_state_q[3];
    end else begin
        // if this slot is disabled, never touch the bus
        ab_write_d = 0;
    end

    // update portb bits for next cycle (remember portb_q still has this cycle's values)
    portb_d[5:0] = m6821_pb_out[5:0];

    // if bit 5 changed, handling 6805 write state
    if (portb_q[5] != m6821_pb_out[5]) begin
        if (m6821_pb_out[5]) begin
            // asking permission to write, set bit granting permission
            portb_d[7] = 1;
        end else begin
            // announcing write is ready, set bit acking send
            portb_d[7] = 0;
            if (cmd_state_q == IDLE) begin
                cmd_d = m6821_pa_out;
                cmd_state_d = START_CMD;
            end
            if (cmd_state_q == CMD_BYTES) begin
                // shift byte onto cmd_shreg
                cmd_counter_d = cmd_counter_q - 1;
                cmd_shreg_d[31:8] = cmd_shreg_q[23:0];
                cmd_shreg_d[7:0] = m6821_pa_out;
                if (cmd_counter_q == 1) begin
                    cmd_state_d = PROCESS_CMD;
                end
            end
        end
    end

    // if bit 4 changed, handling 6805 read state
    if (portb_q[4] != m6821_pb_out[4]) begin
        if (m6821_pb_out[4]) begin
            // asking for permission to read, set bit granting permission
            portb_d[6] = 0;
        end else begin
            // announcing read is ready, set bit acking read
            portb_d[6] = 1;
            // shift the read byte off of rsp register
            rsp_shreg_d[55:0] = rsp_shreg_q[63:8];
            rsp_shreg_d[63:56] = 0;
        end
    end

    case (cmd_state_q)
    IDLE: begin
        // always normalize prev and new mouse values
        if (prevx_q[15] || prevx_q < minx_q) begin
            prevx_d = minx_q;
        end else if (prevx_q > maxx_q) begin
            prevx_d = maxx_q;
        end
        if (prevy_q[15] || prevy_q < miny_q) begin
            prevy_d = miny_q;
        end else if (prevy_q > maxy_q) begin
            prevy_d = maxy_q;
        end
        if (newx_q[15] || newx_q < minx_q) begin
            newx_d = minx_q;
        end else if (newx_q > maxx_q) begin
            newx_d = maxx_q;
        end
        if (newy_q[15] || newy_q < miny_q) begin
            newy_d = miny_q;
        end else if (newy_q > maxy_q) begin
            newy_d = maxy_q;
        end
    end
    START_CMD: begin
        case(cmd_q)
        4'h0: begin
            // MOUSE_SET
            // no data, just set the mode
            mouse_mode_d = cmd_q[3:0];
            cmd_state_d = IDLE;
        end
        4'h1: begin
            // MOUSE_READ
            cmd_state_d = IDLE;
            // load rsp_shreg with state
            rsp_shreg_d[15:0] = newx_q;
            rsp_shreg_d[31:16] = newy_q;
            rsp_shreg_d[39:32] = 0;
            rsp_shreg_d[32+STAT_PREV_BUTTON0] = prevb_q[0];
            rsp_shreg_d[32+STAT_CURR_BUTTON0] = newb_q[0];
            rsp_shreg_d[32+STAT_PREV_BUTTON1] = prevb_q[1];
            rsp_shreg_d[32+STAT_CURR_BUTTON1] = newb_q[1];
            rsp_shreg_d[32+STAT_MOVEMENT_SINCE_READMOUSE] = 
                mouse_state_q[STAT_MOVEMENT_SINCE_READMOUSE];
            mouse_state_d = 0;
            mouse_state_d[STAT_PREV_BUTTON0] = prevb_q[0];
            mouse_state_d[STAT_CURR_BUTTON0] = newb_q[0];
            mouse_state_d[STAT_PREV_BUTTON1] = prevb_q[1];
            mouse_state_d[STAT_CURR_BUTTON1] = newb_q[1];
            prevx_d = newx_q;
            prevy_d = newy_q;
            prevb_d = newb_q;
            ab_write_d.assert_irq = 0;
            cmd_state_d = IDLE;
        end
        4'h2: begin
            // MOUSE_SERV
            // 1 byte of data
            cmd_state_d = CMD_BYTES;
            rsp_shreg_d[7:0] = mouse_state_q;
            rsp_shreg_d[STAT_MOVEMENT_SINCE_READMOUSE] = 0;
            cmd_counter_d = 1;
        end
        4'h3: begin
            // MOUSE_CLEAR
            cmd_state_d = IDLE;
            mouse_state_d = 0;
            prevx_d = 0;
            prevy_d = 0;
            prevb_d = 0;
            newx_d = 0;
            newy_d = 0;
            newb_d = 0;
            ab_write_d.assert_irq = 0;
        end
        4'h4: begin
            // MOUSE_POS
            cmd_state_d = CMD_BYTES;
            cmd_counter_d = 4;
        end
        4'h5: begin
            // MOUSE_INIT
            cmd_state_d = CMD_BYTES;
            rsp_shreg_d[7:0] = 8'hff; // unknown why
            cmd_counter_d = 1;
        end
        4'h6: begin
            // MOUSE_CLAMP
            cmd_state_d = CMD_BYTES;
            cmd_counter_d = 4;
        end
        4'h7: begin
            // MOUSE_HOME
            cmd_state_d = IDLE;
            newx_d = 0;
            newy_d = 0;
        end
        4'h9: begin
            // MOUSE_TIME
            case(cmd_q[3:2])
            2'h0: begin
                // set hz, do nothing
                cmd_state_d = IDLE;
            end
            2'h1: begin
                // expect 2 bytes (0478, 04f8)
                cmd_state_d = CMD_BYTES;
                cmd_counter_d = 2;
            end
            2'h2: begin
                // expect 1 byte (0578)
                cmd_state_d = CMD_BYTES;
                cmd_counter_d = 1;
            end
            2'h3: begin
                // expect 3 bytes (0478, 04f8, 0578)
                cmd_state_d = CMD_BYTES;
                cmd_counter_d = 3;
            end
            endcase
        end
        4'ha: begin
            // unknown, has 1 byte of data
            cmd_state_d = CMD_BYTES;
            cmd_counter_d = 1;
        end
        default: begin
            cmd_state_d = IDLE;
            // do nothing
        end
        endcase
    end
    PROCESS_CMD: begin
        cmd_state_d = IDLE;
        case (cmd_q[7:4])
            4'h6: begin
                // MOUSE_CLAMP
                if (cmd_q[0]) begin
                    // set Y clamp
                    miny_d[15:8] = cmd_shreg_q[15:8];
                    miny_d[7:0] = cmd_shreg_q[31:24];
                    maxy_d[15:8] = cmd_shreg_q[7:0];
                    maxy_d = cmd_shreg_q[23:16];
                end else begin
                    // set X clamp
                    minx_d[15:8] = cmd_shreg_q[15:8];
                    minx_d[7:0] = cmd_shreg_q[31:24];
                    maxx_d[15:8] = cmd_shreg_q[7:0];
                    maxx_d = cmd_shreg_q[23:16];
                end
                cmd_state_d = CHECK_CLAMP;
            end
            4'h4: begin
                // MOUSE_POS
                prevx_d[15:8] = cmd_shreg_q[23:16];
                newx_d[15:8] = cmd_shreg_q[23:16];
                prevx_d[7:0] = cmd_shreg_q[31:24];
                newx_d[7:0] = cmd_shreg_q[31:24];
                prevy_d[15:8] = cmd_shreg_q[7:0];
                newy_d[15:8] = cmd_shreg_q[7:0];
                prevy_d[7:0] = cmd_shreg_q[15:8];
                newy_d[7:0] = cmd_shreg_q[15:8];
            end
            4'h5: begin
                // MOUSE_INIT
                // don't actually care about the byte received,
                // just execute the init when the cmd completes
                prevx_d = 0;
                prevy_d = 0;
                newx_d = 0;
                newy_d = 0;
                minx_d = 0;
                maxx_d = 16'h03ff;
                miny_d = 0;
                maxy_d = 16'h03ff;
            end
        endcase
    end
    CHECK_CLAMP: begin
        cmd_state_d = IDLE;
        if (minx_q > maxx_q) begin
            minx_d = 0;
            maxx_d = minx_q + maxx_q;
        end
        if (miny_q > maxy_q) begin
            miny_d = 0;
            maxy_d = miny_q + maxy_q;
        end
    end
    endcase

    if (reg_write.new_cmd) begin
        case (reg_write.address)
        ADDR_BASE: begin
            // not readable
            reg_read.rd_data = cmd_q;
            reg_read.rd_ready = 1;
            if (reg_write.is_write) begin
                newx_d = newx_q + reg_write.wr_data[15:0];
                newy_d = newy_q + reg_write.wr_data[31:0];
                if (mouse_mode_q[MODE_MOUSE_ON]) begin
                    if (newx_d != prevx_q && newy_d != prevy_q) begin
                        if (mouse_mode_q[MODE_INT_MOVEMENT]) begin
                            mouse_state_d[STAT_INT_MOVEMENT] = 1;
                        end
                        mouse_state_d[STAT_MOVEMENT_SINCE_READMOUSE] = 1;
                    end
                end                
            end
        end
        ADDR_BASE+4: begin
            // not readable
            reg_read.rd_data = 0;
            reg_read.rd_ready = 1;
            if (reg_write.is_write) begin
                newb_d[1:0] = reg_write.wr_data[1:0];
                if (mouse_mode_q[MODE_MOUSE_ON]) begin
                    if (newb_d != prevb_d) begin
                        if (mouse_mode_q[MODE_INT_BUTTON]) begin
                            mouse_state_d[STAT_INT_BUTTON] = 1;
                        end
                    end
                end
            end
        end
        endcase
    end
end

always @(posedge clk) begin
    if (rst || !ab_read.res) begin
        ab_write_q <= 0;
        prevx_q <= 0;
        prevy_q <= 0;
        prevb_q <= 0;
        newx_q <= 0;
        newy_q <= 0;
        newb_q <= 0;
        minx_q <= 0;
        maxx_q <= 16'h03ff;
        miny_q <= 0;
        maxy_q <= 16'h03ff;
        mouse_state_q <= 0;
        mouse_mode_q <= 0;
        portb_q <= 8'h40;
        rsp_shreg_q <= 0;
        cmd_state_q <= IDLE;
        cmd_shreg_q <= 0;
        cmd_q <= 0;
        cmd_counter_q <= 0;
    end else begin
        ab_write_q <= ab_write_d;
        prevx_q <= prevx_d;
        prevy_q <= prevy_d;
        prevb_q <= prevb_d;
        newx_q <= newx_d;
        newy_q <= newy_d;
        newb_q <= newb_d;
        minx_q <= minx_d;
        maxx_q <= maxx_d;
        miny_q <= miny_d;
        maxy_q <= maxy_d;
        mouse_state_q <= mouse_state_d;
        mouse_mode_q <= mouse_mode_q;
        portb_q <= portb_d;
        rsp_shreg_q <= rsp_shreg_d;
        cmd_state_q <= cmd_state_d;
        cmd_shreg_q <= cmd_shreg_d;
        cmd_q <= cmd_d;
        cmd_counter_q <= cmd_counter_d;
    end
end



endmodule
