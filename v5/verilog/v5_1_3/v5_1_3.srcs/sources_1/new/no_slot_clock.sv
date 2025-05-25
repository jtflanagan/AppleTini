`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/25/2025 08:12:05 PM
// Design Name: 
// Module Name: no_slot_clock
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


module no_slot_clock(
    input clk,
    input rst,
    input enabled,
    input globals::NSC_time input_time,
    input input_time_en,
    input globals::AppleBus_read ab_read,
    input globals::SoftSwitchState sss,
    output globals::AppleBus_write ab_write
);

localparam logic [63:0] clock_access_pattern = 64'h5CA33AC55CA33AC5;
localparam logic [63:0] fake_time = 64'h2503300117510000;

typedef enum {IDLE, INC_CSEC, INC_SEC, 
              INC_MIN, INC_HOUR, INC_DAY, 
              INC_MONTH, INC_YEAR, UPDATE_PUB} carry_sm;

globals::AppleBus_write ab_write_d, ab_write_q = 0;

globals::NSC_time cur_time_d, cur_time_q = 0;
logic [63:0] pub_time_d, pub_time_q = 0;
carry_sm carry_state_d, carry_state_q = IDLE;


logic clock_reg_en_d, clock_reg_en_q = 0;
logic write_en_d, write_en_q = 0;
logic [7:0] clock_reg_cnt_d, clock_reg_cnt_q = 0;
logic [63:0] clock_reg_d, clock_reg_q = 0;
logic [63:0] cmp_reg_d, cmp_reg_q = clock_access_pattern;
logic [7:0] cmp_reg_cnt_d, cmp_reg_cnt_q = 0;

always_comb begin
    ab_write_d = ab_write_q;
    clock_reg_en_d = clock_reg_en_q;
    write_en_d = write_en_q;
    clock_reg_cnt_d = clock_reg_cnt_q;
    clock_reg_d = clock_reg_q;
    cmp_reg_d = cmp_reg_q;
    cmp_reg_cnt_d = cmp_reg_cnt_q;
    if (clock_reg_cnt_q == 64) begin
        // if clock reg cnt exhausted, disable the clock reg
        clock_reg_en_d = 0;
        clock_reg_cnt_d = 0;
    end
    if (cmp_reg_cnt_q == 0) begin
        // an empty reg cnt resets the clock access pattern
        cmp_reg_d = clock_access_pattern;
    end
    if (cmp_reg_cnt_q == 64) begin
        // we achieved full match, enable clock out
        clock_reg_en_d = 1;
        clock_reg_d = pub_time_q[63:0];
        clock_reg_cnt_d = 0;
        cmp_reg_cnt_d = 0;
    end
    // need to verify that this is a ROM access to the active range
    if (ab_read.sss_en) begin // sss ready
        if (sss.slot_access
            && ab_read.addr[15:8] == 8'hc2
        ) begin
            if (ab_read.addr[2]) begin
                // nsc read signal, possibly emit
                if (!clock_reg_en_q) begin
                    // read resets the compare register state and
                    // re-enables writes
                    cmp_reg_cnt_d = 0;
                    write_en_d = 1;
                end else begin
                    if (ab_read.rw) begin
                        // if the cycle is a read cycle, emit a bit
                        ab_write_d.wr_data = {7'h0, clock_reg_q[0]};
                        ab_write_d.wr_data_en = 1;
                        //ab_write_d.assert_inh = 1;
                        clock_reg_cnt_d = clock_reg_cnt_q + 1;
                        clock_reg_d[62:0] = clock_reg_q[63:1];
                        clock_reg_d[63] = 0;
                    end
                end
            end else begin
                // nsc write signal, possibly record
                if (write_en_q) begin
                    if (clock_reg_en_q) begin
                        // we never write to the clock register, just
                        // drop it and increment the clock reg count
                        clock_reg_cnt_d = clock_reg_cnt_q + 1;
                    end else begin
                        // address bit zero is the incoming data bit
                        if (ab_read.addr[0] != cmp_reg_q[0]) begin
                            // mismatch bit, disable writes
                            write_en_d = 0;
                        end else begin
                            // match bit, increment the match counter
                            // and shift the compare register
                            cmp_reg_d[62:0] = cmp_reg_q[63:1];
                            cmp_reg_d[63] = 0;
                            cmp_reg_cnt_d = cmp_reg_cnt_q + 1;
                        end
                    end
                end
            end
        end else begin
            // if not a rom access, we output nothing
            ab_write_d = 0;
        end
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        ab_write_q <= 0;
        clock_reg_en_q <= 0;
        write_en_q <= 0;
        clock_reg_cnt_q <= 0;
        clock_reg_q <= 0;
        cmp_reg_q <= 0;
        cmp_reg_cnt_q = 0;
    end else begin
        ab_write_q <= ab_write_d;
        clock_reg_en_q <= clock_reg_en_d;
        write_en_q <= write_en_d;
        clock_reg_cnt_q <= clock_reg_cnt_d;
        clock_reg_q <= clock_reg_d;
        cmp_reg_q <= cmp_reg_d;
        cmp_reg_cnt_q <= cmp_reg_cnt_d;
    end
end

assign ab_write = ab_write_q;

logic [7:0] month_byte;
logic [7:0] day_byte;

always_comb begin
    cur_time_d = cur_time_q;
    carry_state_d = carry_state_q;
    pub_time_d = pub_time_q;
    if (input_time_en) begin
        cur_time_d = input_time;
        pub_time_d = input_time[63:0];
        carry_state_d = IDLE;
    end else begin
        if (cur_time_q.centisecond_ticks == 999999) begin
            cur_time_d.centisecond_ticks = 0;
            carry_state_d = INC_CSEC;
        end else begin
            cur_time_d.centisecond_ticks = cur_time_q.centisecond_ticks + 1;
        end
        case (carry_state_q)
        IDLE: begin
            if (cur_time_q.day_of_week_lo == 0) begin
                cur_time_d.day_of_week_lo = 1;
            end
            if (cur_time_q.day_lo == 0 
                && cur_time_q.day_hi == 0) begin
                cur_time_d.day_lo = 1;
            end
        end
        INC_CSEC: begin
            if (cur_time_q.centisecond_lo == 9) begin
                cur_time_d.centisecond_lo = 0;
                if (cur_time_q.centisecond_hi == 9) begin
                    cur_time_d.centisecond_hi = 0;
                    carry_state_d = INC_SEC;
                end else begin
                    cur_time_d.centisecond_hi = cur_time_q.centisecond_hi + 1;
                    carry_state_d = UPDATE_PUB;
                end
            end else begin
                cur_time_d.centisecond_lo = cur_time_q.centisecond_lo + 1;
                carry_state_d = UPDATE_PUB;
            end
        end
        INC_SEC: begin
            if (cur_time_q.second_lo == 9) begin
                cur_time_d.second_lo = 0;
                if (cur_time_q.second_hi == 5) begin
                    cur_time_d.second_hi = 0;
                    carry_state_d = INC_MIN;
                end else begin
                    cur_time_d.second_hi = cur_time_q.second_hi + 1;
                    carry_state_d = UPDATE_PUB;
                end
            end else begin
                cur_time_d.second_lo = cur_time_q.second_lo + 1;
                carry_state_d = UPDATE_PUB;
            end
        end
        INC_MIN: begin
            if (cur_time_q.minute_lo == 9) begin
                cur_time_d.minute_lo = 0;
                if (cur_time_q.minute_hi == 5) begin
                    cur_time_d.minute_hi = 0;
                    carry_state_d = INC_HOUR;
                end else begin
                    cur_time_d.minute_hi = cur_time_q.minute_hi + 1;
                    carry_state_d = UPDATE_PUB;
                end
            end else begin
                cur_time_d.minute_lo = cur_time_q.minute_lo + 1;
                carry_state_d = UPDATE_PUB;
            end
        end
        INC_HOUR: begin
            if (cur_time_q.hour_lo == 9 || 
                (cur_time_q.hour_lo == 3 && cur_time_q.hour_hi == 2)) begin
                cur_time_d.hour_lo = 0;
                if (cur_time_q.hour_hi == 2) begin
                    cur_time_d.hour_hi = 0;
                    carry_state_d = INC_DAY;
                end else begin
                    cur_time_d.hour_hi = cur_time_q.hour_hi + 1;
                    carry_state_d = UPDATE_PUB;
                end
            end else begin
                cur_time_d.hour_lo = cur_time_q.hour_lo + 1;
                carry_state_d = UPDATE_PUB;
            end
        end
        INC_DAY: begin
            if (cur_time_q.day_of_week_lo == 7) begin
                cur_time_d.day_of_week_lo = 1;
            end else begin
                cur_time_d.day_of_week_lo = cur_time_q.day_of_week_lo + 1;
            end
            if (cur_time_q.day_lo == 9) begin
                cur_time_d.day_lo = 0;
                cur_time_d.day_hi = cur_time_q.day_hi + 1;
                carry_state_d = INC_MONTH;  // checks end of month too
            end else begin
                cur_time_d.day_lo = cur_time_q.day_lo + 1;
                carry_state_d = UPDATE_PUB;
            end
        end
        INC_MONTH: begin
            month_byte = {cur_time_q.month_hi, cur_time_q.month_lo};
            day_byte = {cur_time_q.day_hi, cur_time_q.day_lo};
            if (month_byte == 8'h01) begin
                if (day_byte == 8'h32) begin
                    cur_time_d.day_lo = 1;
                    cur_time_d.day_hi = 0;
                    cur_time_d.month_lo = 2;
                end
                carry_state_d = UPDATE_PUB;
            end
            if (month_byte == 8'h02) begin
                if (cur_time_q.year_lo[1:0] == 0) begin
                    if (day_byte == 8'h30) begin
                        cur_time_d.day_lo = 1;
                        cur_time_d.day_hi = 0;
                        cur_time_d.month_lo = 3;
                    end
                end else begin
                    if (day_byte == 8'h29) begin
                        cur_time_d.day_lo = 1;
                        cur_time_d.day_hi = 0;
                        cur_time_d.month_lo = 3;
                    end
                end
                carry_state_d = UPDATE_PUB;
            end
            if (month_byte == 8'h03) begin
                if (day_byte == 8'h32) begin
                    cur_time_d.day_lo = 1;
                    cur_time_d.day_hi = 0;
                    cur_time_d.month_lo = 4;
                end
                carry_state_d = UPDATE_PUB;
            end
            if (month_byte == 8'h04) begin
                if (day_byte == 8'h31) begin
                    cur_time_d.day_lo = 1;
                    cur_time_d.day_hi = 0;
                    cur_time_d.month_lo = 5;
                end
                carry_state_d = UPDATE_PUB;
            end
            if (month_byte == 8'h05) begin
                if (day_byte == 8'h32) begin
                    cur_time_d.day_lo = 1;
                    cur_time_d.day_hi = 0;
                    cur_time_d.month_lo = 6;
                end
                carry_state_d = UPDATE_PUB;
            end
            if (month_byte == 8'h06) begin
                if (day_byte == 8'h31) begin
                    cur_time_d.day_lo = 1;
                    cur_time_d.day_hi = 0;
                    cur_time_d.month_lo = 7;
                end
                carry_state_d = UPDATE_PUB;
            end
            if (month_byte == 8'h07) begin
                if (day_byte == 8'h32) begin
                    cur_time_d.day_lo = 1;
                    cur_time_d.day_hi = 0;
                    cur_time_d.month_lo = 8;
                end
                carry_state_d = UPDATE_PUB;
            end
            if (month_byte == 8'h08) begin
                if (day_byte == 8'h32) begin
                    cur_time_d.day_lo = 1;
                    cur_time_d.day_hi = 0;
                    cur_time_d.month_lo = 9;
                end
                carry_state_d = UPDATE_PUB;
            end
            if (month_byte == 8'h09) begin
                if (day_byte == 8'h31) begin
                    cur_time_d.day_lo = 1;
                    cur_time_d.day_hi = 0;
                    cur_time_d.month_lo = 0;
                    cur_time_d.month_hi = 1;
                end
                carry_state_d = UPDATE_PUB;
            end
            if (month_byte == 8'h10) begin
                if (day_byte == 8'h32) begin
                    cur_time_d.day_lo = 1;
                    cur_time_d.day_hi = 0;
                    cur_time_d.month_lo = 1;
                    cur_time_d.month_hi = 1;
                end
                carry_state_d = UPDATE_PUB;
            end
            if (month_byte == 8'h10) begin
                if (day_byte == 8'h32) begin
                    cur_time_d.day_lo = 1;
                    cur_time_d.day_hi = 0;
                    cur_time_d.month_lo = 1;
                    cur_time_d.month_hi = 1;
                end
                carry_state_d = UPDATE_PUB;
            end
            if (month_byte == 8'h11) begin
                if (day_byte == 8'h31) begin
                    cur_time_d.day_lo = 1;
                    cur_time_d.day_hi = 0;
                    cur_time_d.month_lo = 1;
                    cur_time_d.month_hi = 2;
                end
                carry_state_d = UPDATE_PUB;
            end
            if (month_byte == 8'h12) begin
                if (day_byte == 8'h32) begin
                    cur_time_d.day_lo = 1;
                    cur_time_d.day_hi = 0;
                    cur_time_d.month_lo = 1;
                    cur_time_d.month_hi = 0;
                    carry_state_d = INC_YEAR;
                end else begin
                    carry_state_d = UPDATE_PUB;
                end
            end
        end
        INC_YEAR: begin
            if (cur_time_q.year_lo == 9) begin
                cur_time_d.year_lo = 0;
                if (cur_time_q.year_hi == 9) begin
                    cur_time_d.year_hi = 0;
                    carry_state_d = UPDATE_PUB;
                end else begin
                    cur_time_d.year_hi = cur_time_q.year_hi + 1;
                    carry_state_d = UPDATE_PUB;
                end
            end else begin
                cur_time_d.year_lo = cur_time_q.year_lo + 1;
                carry_state_d = UPDATE_PUB;
            end
        end
        UPDATE_PUB: begin
            pub_time_d = cur_time_q[63:0];
        end
        default: begin 
            carry_state_d = IDLE;
        end
        endcase
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        cur_time_q <= fake_time;
        carry_state_q <= IDLE;
        pub_time_q <= 0;
    end else begin
        cur_time_q <= cur_time_d;
        carry_state_q <= carry_state_d;
        pub_time_q <= pub_time_d;
    end
end

endmodule
