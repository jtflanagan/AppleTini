`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/01/2025 05:45:45 PM
// Design Name: 
// Module Name: ft600_fifo
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


module ft600_fifo(
    // Inputs
     input           clk_i
    ,input           ft_clk_i
    ,input           rst_i
    ,input           ftdi_rxf_i
    ,input           ftdi_txe_i
    ,input  [ 15:0]  ftdi_data_in_i
    ,input  [  1:0]  ftdi_be_in_i
    ,input           inport_wr_en_i
    ,input  [ 35:0]  inport_data_i
    ,input           outport_rd_en_i

    // Outputs
    ,output reg         ftdi_wrn_o
    ,output reg         ftdi_rdn_o
    ,output reg         ftdi_oen_o
    ,output reg [ 15:0]  ftdi_data_out_o
    ,output reg [  1:0]  ftdi_be_out_o
    ,output reg         inport_full_o
    ,output reg         outport_empty_o
    ,output reg [ 35:0]  outport_data_o
);

reg inport_rd_en_r;
wire [35:0] inport_dout_w;
wire inport_empty_w;
wire inport_full_w;

fifo_async_36x512 tx_fifo(
  .rst(rst_i),
  .wr_clk(clk_i),
  .rd_clk(ft_clk_i),
  .din(inport_data_i),
  .wr_en(inport_wr_en_i),
  .rd_en(inport_rd_en_r),
  .dout(inport_dout_w),
  .full(inport_full_w),
  .empty(inport_empty_w),
  .wr_rst_busy(),
  .rd_rst_busy()
);

// the state machine starts in INIT.  While in INIT state, it will
// check whether ft_rxf is asserted low.  If so, it will assert oe
// low and transition to DRAIN state to clear out anything in RX
// lingering from pre-reset.
//
// from DRAIN, it will read and discard data until ft_rxf is
// no longer asserted, and then transit to IDLE.  The point of
// draining all RX data on restart, is to achive packet-boundary
// sync on RX.  It is only possible to be sure of a packet boundary
// on a transition from ft_rxf unasserted to asserted, so pulling
// and discarding data until ft_rxf deasserts ensures that the next
// assertion of ft_rxf is the beginning of a packet.
//
// from IDLE, TX data has priority.  So if there is data in the TX 
// fifo and the FT600 is ready to send, it will transition to
// TX_LOW_START.
//
// From TX_LOW_START, it will write the low half of the entry,
// and then transition to TX_HIGH.
//
// From TX_HIGH, it will write the top half of the entry, hit 
// rd_en on the FIFO to pop the entry, and then transition to
// TX_LOW.
//
// From TX_LOW, it will check if the fifo is empty, or if the 
// sideband bits are 0001 (indicating the start of a new message).
// If either of those are the case, it will transit to IDLE.
// Otherwise, it will write the low half of the entry and transition
// to TX_HIGH.
//
// If, while IDLE, and there either is no TX data, or the FT600
// is not ready for TX, then it will check if the FT600 has data
// to receive.  If there is data to receive, and room in the 
// RX fifo, it will assert oe low (to begin the FT data bus
// turnaround), and transition to RX_LOW_START.
//
// From RX_LOW_START, it will assert ft_rd low, read the low
// half of the first entry (which is also the entry count),
// and transition to RX_HIGH_START.  It stores the entry count
// (which counts the number of subsequent entries) to be decremented
// in RX_HIGH state until zero, which will flag the end of the packet.
//
// From RX_HIGH_START, it reads the top half of the first entry,
// and pushes the first entry onto the RX fifo with sideband bits
// of 0001 (to indicate start of message), and transits to RX_LOW.
//
// From RX_LOW, it checks that ft_rxf is still asserted low.  If not.
// it transitions to IDLE.  If there is still RX to consume, and 
// space in the RX fifo, it will read the low half of the next entry,
// decrements the event count, and transitions to RX_HIGH.
//
// from RX_HIGH, it reads the top half of the next entry, pushes
// the entry onto the RX fifo with sideband bits of 0000 (to indicate
// continuing message data).  If the event count is zero, it
// transitions to IDLE.  Otherwise it transitions to RX_LOW. 

localparam INIT = 4'h0;
localparam DRAIN = 4'h1;
localparam IDLE = 4'h2;
localparam TX_LOW_START = 4'h3;
localparam TX_LOW = 4'h4;
localparam TX_HIGH = 4'h5;
localparam RX_LOW_START = 4'h6;
localparam RX_HIGH_START = 4'h7;
localparam RX_LOW = 4'h8;
localparam RX_HIGH = 4'h9;
localparam PRE_IDLE = 4'ha;
localparam PRE_IDLE2 = 4'hb;

reg [3:0] ft_state_d, ft_state_q = INIT;
reg tx_empty_d, tx_empty_q = 1'h0;
reg rx_full_d, rx_full_q = 1'h0;

always @* begin
    ft_state_d = ft_state_q;
    tx_empty_d = ftdi_txe_i;
    rx_full_d = ftdi_rxf_i;
    inport_full_o = inport_full_w;

    ftdi_oen_o = 1;
    ftdi_rdn_o = 1;
    ftdi_wrn_o = 1;
    ftdi_data_out_o = 16'h0000;
    ftdi_be_out_o = 2'b11;
    inport_rd_en_r = 0;

    case (ft_state_q)
    INIT: begin
        if (rx_full_q) begin
            ft_state_d = IDLE;
        end else begin
            ft_state_d = DRAIN;
            ftdi_oen_o = 0;
        end
    end
    DRAIN: begin
        if (rx_full_q) begin
            // done draining
            ft_state_d = IDLE;
        end else begin
            //discard data, keep draining
            ftdi_oen_o = 0;
            ftdi_rdn_o = 0;
        end
    end
    PRE_IDLE: begin
        ft_state_d = PRE_IDLE2;
    end
    PRE_IDLE2: begin
        ft_state_d = IDLE;
    end
    IDLE: begin
        if (!inport_empty_w && !tx_empty_q) begin
            // default to tx, if tx enabled and tx data ready
            ft_state_d = TX_LOW_START;
        end else begin
            // handle rx when we're ready, currently stay IDLE
        end
    end
    TX_LOW_START: begin
        ft_state_d = TX_HIGH;
        ftdi_data_out_o = inport_dout_w[15:0];
        ftdi_wrn_o = 0;
    end
    TX_LOW: begin
        if (inport_empty_w || inport_dout_w[35:32] != 4'h0) begin
            // new message beginning, enforce IDLE gap
            ft_state_d = PRE_IDLE;
        end else begin
            ft_state_d = TX_HIGH;
            ftdi_data_out_o = inport_dout_w[15:0];
            ftdi_wrn_o = 0;
        end
    end
    TX_HIGH: begin
        ft_state_d = TX_LOW;
        ftdi_wrn_o = 0;
        ftdi_data_out_o = inport_dout_w[31:16];
        inport_rd_en_r = 1;
    end
    RX_LOW_START:
        ft_state_d = IDLE; // TODO
    RX_HIGH_START:
        ft_state_d = IDLE; // TODO
    RX_LOW:
        ft_state_d = IDLE; // TODO
    RX_HIGH:
        ft_state_d = IDLE; // TODO
    default: begin
        // move to INIT state on bad state
        ft_state_d = INIT;
    end
    endcase
end

// flip flop transitions
always @(posedge ft_clk_i) begin
    if (rst_i) begin
        ft_state_q <= INIT;
        tx_empty_q <= 1;
        rx_full_q <= 1;
    end else begin
        ft_state_q <= ft_state_d;
        tx_empty_q <= tx_empty_d;
        rx_full_q <= rx_full_d;
    end
end

endmodule

