`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
//
// Engineer:    Thomas Skibo
//
// Create Date: Sep 24, 2011
//
// Module Name: via6522
//
// Description:
//
//      A simple implementation of the 6522 Versatile Interface Adapter (VIA).
//      Tri-state lines aren't used.  Instead,  All PIA I/O signals have
//      seperate "in" and "out" signals.  Wire or ignore appropriately.
//
//      A seperate "slow clock" (a synchronous pulse) runs the timers.
//      Typically, it's 1Mhz.
//
/////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2011, Thomas Skibo.  All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// * Redistributions of source code must retain the above copyright
//   notice, this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright
//   notice, this list of conditions and the following disclaimer in the
//   documentation and/or other materials provided with the distribution.
// * The names of contributors may not be used to endorse or promote products
//   derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL Thomas Skibo OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
// OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
// SUCH DAMAGE.
//
//////////////////////////////////////////////////////////////////////////////

module via6522(output reg [7:0] data_out,       // cpu interface
               input [7:0]      data_in,
               input [3:0]      addr,
               input            strobe,
               input            we,

               output reg       irq,

               output reg [7:0] porta_out,
               input [7:0]      porta_in,
               output reg [7:0] portb_out,
               input [7:0]      portb_in,

               input            ca1_in,
               output reg       ca2_out,
               input            ca2_in,
               output reg       cb1_out,
               input            cb1_in,
               output reg       cb2_out,
               input            cb2_in,

               input            slow_clock,

               input            clk,
               input            reset
       );

    // Register address offsets
    localparam [3:0]
        ADDR_PORTB =            4'h0,
        ADDR_PORTA =            4'h1,
        ADDR_DDRB =             4'h2,
        ADDR_DDRA =             4'h3,
        ADDR_TIMER1_LO =        4'h4,
        ADDR_TIMER1_HI =        4'h5,
        ADDR_TIMER1_LATCH_LO =  4'h6,
        ADDR_TIMER1_LATCH_HI =  4'h7,
        ADDR_TIMER2_LO =        4'h8,
        ADDR_TIMER2_HI =        4'h9,
        ADDR_SR =               4'ha,
        ADDR_ACR =              4'hb,
        ADDR_PCR =              4'hc,
        ADDR_IFR =              4'hd,
        ADDR_IER =              4'he,
        ADDR_PORTA_NH =         4'hf;

    wire        wr_strobe = strobe && we;
    wire        rd_strobe = strobe && !we;

    ///////////////////////////////////////////////////
    // IER - Interrupt Enable Register
    reg [6:0]   ier;

    always @(posedge clk)
        if (reset)
            ier <= 7'd0;
        else if (wr_strobe && addr == ADDR_IER)
            ier <= data_in[7] ? (ier | data_in[6:0]) : (ier & ~data_in[6:0]);

    ////////////////////////////////////////////////////
    // PCR - Peripheral Control Register
    reg [7:0]   pcr;

    always @(posedge clk)
        if (reset)
            pcr <= 8'h00;
        else if (wr_strobe && addr == ADDR_PCR)
            pcr <= data_in;

    //////////////////////////////////////////////////////
    // ACR - Auxiliary Control Register
    reg [7:0]   acr;

    always @(posedge clk)
        if (reset)
            acr <= 8'h00;
        else if (wr_strobe && addr == ADDR_ACR)
            acr <= data_in;

    /////////////////////////////////////////////////////
    // PORTs and DDRs
    reg [7:0]   ddra;
    reg [7:0]   ddrb;
    reg         pb7_nxt; // generated by timer1 logic, used when acr7 is set

    // Implement PORTA (out)
    always @(posedge clk)
        if (reset)
            porta_out <= 8'h00;
        else if (wr_strobe && (addr == ADDR_PORTA || addr == ADDR_PORTA_NH))
            porta_out <= data_in;

    // Implement DDRA
    always @(posedge clk)
        if (reset)
            ddra <= 8'h00;
        else if (wr_strobe && addr == ADDR_DDRA)
            ddra <= data_in;

    // Implement PORTB (out).
    always @(posedge clk)
        if (reset)
            portb_out[6:0] <= 7'h00;
        else if (wr_strobe && addr == ADDR_PORTB)
            portb_out[6:0] <= data_in[6:0];
    always @(posedge clk)
        if (reset)
            portb_out[7] <= 1'b0;
        else if (acr[7])
            portb_out[7] <= pb7_nxt;
        else if (wr_strobe && addr == ADDR_PORTB)
            portb_out[7] <= data_in[7];

    // Implement DDRB
    always @(posedge clk)
        if (reset)
            ddrb <= 8'h00;
        else if (wr_strobe && addr == ADDR_DDRB)
            ddrb <= data_in;

    ////////////////////////////////////////////////////////
    // CA interrupt logic
    reg         irq_ca1;
    reg         irq_ca2;

    // CA1 and CA2 transition logic.
    reg         ca1_in_1;
    reg         ca2_in_1;
    always @(posedge clk) begin
        ca1_in_1 <= ca1_in;
        ca2_in_1 <= ca2_in;
    end

    // detect "active" transitions.
    wire        ca1_act_trans = ((ca1_in && !ca1_in_1 && pcr[0]) ||
                                 (!ca1_in && ca1_in_1 && !pcr[0]));
    wire        ca2_act_trans = ((ca2_in && !ca2_in_1 && pcr[2]) ||
                                 (!ca2_in && ca2_in_1 && !pcr[2])) && !pcr[3];

    // logic for clearing CA1 and CA2 interrupt bits.
    wire        irq_ca1_clr = ((strobe && addr == ADDR_PORTA) ||
                               (wr_strobe && addr == ADDR_IFR && data_in[1]));
    wire        irq_ca2_clr = ((strobe && addr == ADDR_PORTA && !pcr[1]) ||
                               (wr_strobe && addr == ADDR_IFR && data_in[0]));

    always @(posedge clk)
        if (reset || (irq_ca1_clr && !ca1_act_trans))
            irq_ca1 <= 1'b0;
        else if (ca1_act_trans)
            irq_ca1 <= 1'b1;

    always @(posedge clk)
        if (reset || (irq_ca2_clr && !ca2_act_trans))
            irq_ca2 <= 1'b0;
        else if (ca2_act_trans)
            irq_ca2 <= 1'b1;


    ////////////////////////////////////////////////////////
    // CB logic
    reg         irq_cb1;
    reg         irq_cb2;

    // transition logic
    reg         cb1_in_1;
    reg         cb2_in_1;
    always @(posedge clk) begin
        cb1_in_1 <= cb1_in;
        cb2_in_1 <= cb2_in;
    end

    // detect "active" transitions.
    wire        cb1_act_trans = ((cb1_in && !cb1_in_1 && pcr[4]) ||
                                 (!cb1_in && cb1_in_1 && !pcr[4]));
    wire        cb2_act_trans = ((cb2_in && !cb2_in_1 && pcr[6]) ||
                                 (!cb2_in && cb2_in_1 && !pcr[6])) && !pcr[7];

    // logic for clearing CB1 and CB2 interrupt bits.
    wire        irq_cb1_clr = ((strobe && addr == ADDR_PORTB) ||
                               (wr_strobe && addr == ADDR_IFR && data_in[4]));
    wire        irq_cb2_clr = ((strobe && addr == ADDR_PORTB && !pcr[5]) ||
                               (wr_strobe && addr == ADDR_IFR && data_in[3]));

    always @(posedge clk)
        if (reset || (irq_cb1_clr && !cb1_act_trans))
            irq_cb1 <= 1'b0;
        else if (cb1_act_trans)
            irq_cb1 <= 1'b1;

    always @(posedge clk)
        if (reset || (irq_cb2_clr && !cb2_act_trans))
            irq_cb2 <= 1'b0;
        else if (cb2_act_trans)
            irq_cb2 <= 1'b1;

    ///////////////////////////////////////////////////
    // CA2/CB2 output modes
    always @(posedge clk)
        case (pcr[3:1])
            3'b100:     ca2_out <= irq_ca1;
            3'b101:     ca2_out <= !ca1_act_trans;
            3'b110:     ca2_out <= 1'b0;
            default:    ca2_out <= 1'b1;
        endcase

    reg cb2_out_r;
    wire portb_wr_strobe = wr_strobe && addr == ADDR_PORTB;
    wire cb2_sr_out;

    always @(posedge clk)
        if (reset || (portb_wr_strobe && !cb1_act_trans))
            cb2_out_r <= 1'b0;
        else if (cb1_act_trans)
            cb2_out_r <= 1'b1;

    always @(posedge clk) begin
        if (acr[4])
            cb2_out <= cb2_sr_out;
        else
            case (pcr[7:5])
                3'b100: cb2_out <= cb2_out_r;
                3'b101: cb2_out <= !portb_wr_strobe;
                3'b110: cb2_out <= 1'b0;
                default: cb2_out <= 1'b1;
            endcase
    end

    //////////////////////////////////////////////////////////
    // Implement PORTA (in) latch
    reg [7:0] porta_in_r;
    always @(posedge clk)
        if (!acr[0] || !irq_ca1)
            porta_in_r <= porta_in;

    // Implement PORTB (in) latch
    reg [7:0] portb_in_r;
    always @(posedge clk)
        if (!acr[1] || !irq_cb1)
            portb_in_r <= portb_in;

    ///////////////////////////////////////////////////
    // Timers
    reg [15:0] timer1;
    reg [7:0]  timer1_latch_lo;
    reg [7:0]  timer1_latch_hi;
    reg        timer1_undf;

    reg [15:0] timer2;
    reg [7:0]  timer2_latch_lo;
    reg        timer2l_reload;
    reg        timer2_undf;

    reg        irq_t1_one_shot;
    reg        irq_t1;
    reg        irq_t2_one_shot;
    reg        irq_t2;

    // TIMER1
    always @(posedge clk)
        if (reset) begin
            timer1 <= 16'hffff;
            timer1_undf <= 0;
        end
        else if (wr_strobe && addr == ADDR_TIMER1_HI) begin
            timer1 <= {data_in, timer1_latch_lo};
            timer1_undf <= 0;
        end
        else if (timer1_undf && slow_clock) begin
            timer1 <= {timer1_latch_hi, timer1_latch_lo};
            timer1_undf <= 0;
        end
        else if (slow_clock) begin
            if (timer1 == 16'h0000)
                timer1_undf <= 1;
            timer1 <= timer1 - 1'b1;
        end

    // T1 latch lo
    always @(posedge clk)
        if (reset)
            timer1_latch_lo <= 8'hff;
        else if (wr_strobe && (addr == ADDR_TIMER1_LO ||
                               addr == ADDR_TIMER1_LATCH_LO))
            timer1_latch_lo <= data_in;

    // T1 latch hi
    always @(posedge clk)
        if (reset)
            timer1_latch_hi <= 8'hff;
        else if (wr_strobe && (addr == ADDR_TIMER1_HI ||
                               addr == ADDR_TIMER1_LATCH_HI))
            timer1_latch_hi <= data_in;

    // "one-shot" logic so we only get an interrupt on first counter roll-over
    always @(posedge clk)
        if (reset)
            irq_t1_one_shot <= 1'b0;
        else if (wr_strobe && addr == ADDR_TIMER1_HI)
            irq_t1_one_shot <= 1'b1;
        else if (timer1_undf && slow_clock && !acr[6])
            irq_t1_one_shot <= 1'b0;

    // T1 interrupt set and clear logic
    wire        irq_t1_set = (timer1_undf && slow_clock &&
                              (irq_t1_one_shot || acr[6]));
    wire        irq_t1_clr = ((wr_strobe && addr == ADDR_TIMER1_HI) ||
                              (wr_strobe && addr == ADDR_TIMER1_LATCH_HI) ||
                              (rd_strobe && addr == ADDR_TIMER1_LO) ||
                              (wr_strobe && addr == ADDR_IFR && data_in[6]));

    // T1 IRQ
    always @(posedge clk)
        if (reset || irq_t1_clr)
            irq_t1 <= 1'b0;
        else if (irq_t1_set)
            irq_t1 <= 1'b1;

    // Generate PB7 for T1 output modes (acr[7]=1)
    always @(posedge clk)
        if (reset)
            pb7_nxt <= 1'b1;
        else if (wr_strobe && addr == ADDR_TIMER1_HI)
            pb7_nxt <= 1'b0;
        else if (timer1_undf && slow_clock)
            pb7_nxt <= !pb7_nxt;

    // Find portb[6] transitions.
    reg         pb6_in;
    wire        pb6_trans = !portb_in[6] && pb6_in;
    always @(posedge clk)
        if (slow_clock)
            pb6_in <= portb_in[6];

    // TIMER2
    always @(posedge clk)
        if (reset) begin
            timer2 <= 16'hffff;
            timer2_undf <= 0;
            timer2l_reload <= 0;
        end
        else if (wr_strobe && addr == ADDR_TIMER2_HI) begin
            timer2 <= {data_in, timer2_latch_lo};
            timer2_undf <= 0;
        end
        else if (timer2l_reload && slow_clock) begin
            timer2[7:0] <= timer2_latch_lo;
            timer2l_reload <= 0;
        end
        else if ((!acr[5] || pb6_trans) && slow_clock) begin
            // Reload T2L on next cycle?
            if (timer2[7:0] == 8'h00 && (acr[4] || acr[2]))
                timer2l_reload <= 1;
            timer2_undf <= timer2 == 16'h0000;
            timer2 <= timer2 - 1'b1;
        end

    // T2 latch lo (i.e. writes to T2L)
    always @(posedge clk)
        if (reset)
            timer2_latch_lo <= 8'hff;
        else if (wr_strobe && addr == ADDR_TIMER2_LO)
            timer2_latch_lo <= data_in;

    // T2 IRQ "one-shot" logic
    always @(posedge clk)
        if (reset)
            irq_t2_one_shot <= 1'b0;
        else if (wr_strobe && addr == ADDR_TIMER2_HI)
            irq_t2_one_shot <= 1'b1;
        else if (timer2_undf && slow_clock)
            irq_t2_one_shot <= 1'b0;

    // T2 IRQ set and clear logic
    wire        irq_t2_set = (timer2_undf && slow_clock &&
                              irq_t2_one_shot);
    wire        irq_t2_clr = ((wr_strobe && addr == ADDR_TIMER2_HI) ||
                              (rd_strobe && addr == ADDR_TIMER2_LO) ||
                              (wr_strobe && addr == ADDR_IFR && data_in[5]));

    // T2 IRQ
    always @(posedge clk)
        if (reset || irq_t2_clr)
            irq_t2 <= 1'b0;
        else if (irq_t2_set)
            irq_t2 <= 1'b1;


    ////////////////////////////////////////////////////////
    // SR - shift register
    reg [7:0]   sr;
    reg [2:0]   sr_cntr;
    reg         sr_go;
    reg         irq_sr;
    reg         do_shift;

    always @(posedge clk)
        if (reset)
            sr <= 8'h00;
        else if (wr_strobe && addr == ADDR_SR)
            sr <= data_in;
        else if (do_shift && cb1_out)
            sr <= {sr[6:0], (acr[4] ? sr[7] : cb2_in)};

    assign cb2_sr_out = sr[0];

    always @(posedge clk)
        if (reset || (strobe && addr == ADDR_SR))
            sr_cntr <= 3'd7;
        else if (do_shift && acr[4:2] != 3'b100 &&
                 (!cb1_out || acr[3:2] == 2'b11))
            sr_cntr <= sr_cntr - 1'b1;

    // SR IRQ set and clr logic
    wire        irq_sr_set = do_shift && sr_cntr == 3'b000 &&
                              (!cb1_out || acr[3:2] == 2'b11);
    wire        irq_sr_clr = ((strobe && addr == ADDR_SR) ||
                              (wr_strobe && addr == ADDR_IFR && data_in[2]));

    // SR IRQ
    always @(posedge clk)
        if (reset || (irq_sr_clr && !irq_sr_set))
            irq_sr <= 1'b0;
        else if (irq_sr_set)
            irq_sr <= 1'b1;

    always @(posedge clk)
        if (reset)
            sr_go <= 1'b0;
        else if (strobe && addr == ADDR_SR)
            sr_go <= 1'b1;
        else if (irq_sr_set)
            sr_go <= 1'b0;

    // cominatorial logic for do_shift signal.
    always @(*)
        if (sr_go)
            case (acr[4:2])
                3'b000:
                    do_shift = 1'b0;
                3'b001, 3'b100, 3'b101:
                    do_shift = slow_clock && timer2l_reload;
                3'b010, 3'b110:
                    do_shift = slow_clock;
                3'b011:
                    do_shift = cb1_in && !cb1_in_1;
                3'b111:
                    do_shift = !cb1_in && cb1_in_1;
            endcase
        else
            do_shift = 1'b0;

    always @(posedge clk)
        if (reset)
            cb1_out <= 1'b1;
        else if (do_shift && acr[3:2] != 2'b11)
            cb1_out <= !cb1_out;

    ////////////////////////////////////////////////////////
    // IRQ and enable logic.
    //

    // IFR register (not including bit 7)
    wire [6:0]  ifr = {irq_t1, irq_t2, irq_cb1,
                        irq_cb2, irq_sr, irq_ca1, irq_ca2};

    // IRQ combinatorial logic
    wire        irq_p = |{(ifr & ier)};

    // IRQ output
    always @(posedge clk)
        if (reset)
            irq <= 1'b0;
        else
            irq <= irq_p;

   ///////////////////////////////////////////////////
   // Read data mux
    wire [7:0]  porta = (porta_out & ddra) | (porta_in_r & ~ddra);
    wire [7:0]  portb = (portb_out & ddrb) | (portb_in_r & ~ddrb);

    always @(*)
        case (addr)
            ADDR_PORTB:                 data_out = portb;
            ADDR_PORTA:                 data_out = porta;
            ADDR_DDRB:                  data_out = ddrb;
            ADDR_DDRA:                  data_out = ddra;
            ADDR_TIMER1_LO:             data_out = timer1[7:0];
            ADDR_TIMER1_HI:             data_out = timer1[15:8];
            ADDR_TIMER1_LATCH_LO:       data_out = timer1_latch_lo;
            ADDR_TIMER1_LATCH_HI:       data_out = timer1_latch_hi;
            ADDR_TIMER2_LO:             data_out = timer2[7:0];
            ADDR_TIMER2_HI:             data_out = timer2[15:8];
            ADDR_IER:                   data_out = {1'b1, ier};
            ADDR_PCR:                   data_out = pcr;
            ADDR_ACR:                   data_out = acr;
            ADDR_IFR:                   data_out = {irq_p, ifr};
            ADDR_SR:                    data_out = sr;
            ADDR_PORTA_NH:              data_out = porta;
        endcase

endmodule // via6522