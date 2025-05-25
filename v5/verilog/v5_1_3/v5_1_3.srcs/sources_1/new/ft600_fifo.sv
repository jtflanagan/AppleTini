`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/23/2025 09:09:58 PM
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
    // General
    input clk,
    input ft_clk,
    input rst,

    // ftdi lines
    inout logic [15:0] ftdi_data,
    inout logic [1:0] ftdi_be,
    input ftdi_rxf_n,
    input ftdi_txe_n,
    output logic ftdi_wr_n,
    output logic ftdi_rd_n,
    output logic ftdi_oe_n,

    // tx interface
    input tx_data_en,
    input [31:0] tx_data,
    output logic tx_data_full,

    // rx interface
    input rx_data_en,
    output logic [31:0] rx_data,
    output logic rx_data_empty
);

logic tx_fifo_rd_en;
logic [31:0] tx_fifo_dout;
logic tx_fifo_empty;

fifo_async_36x512 tx_fifo(
  .rst(rst),
  .wr_clk(clk),
  .rd_clk(ft_clk),
  .din(tx_data),
  .wr_en(tx_data_en),
  .rd_en(tx_fifo_rd_en),
  .dout(tx_fifo_dout),
  .full(tx_data_full),
  .empty(tx_fifo_empty),
  .wr_rst_busy(),
  .rd_rst_busy()
);

logic [31:0] rx_fifo_din;
logic rx_fifo_wr_en;
logic rx_fifo_rd_en;
logic rx_data_full;

fifo_async_36x512 rx_fifo(
  .rst(rst),
  .wr_clk(ft_clk),
  .rd_clk(clk),
  .din(rx_fifo_din),
  .wr_en(rx_fifo_wr_en),
  .rd_en(rx_data_en),
  .dout(rx_data),
  .full(rx_data_full),
  .empty(rx_data_empty),
  .wr_rst_busy(),
  .rd_rst_busy()
);

typedef enum {DRAIN, IDLE, TX_LOW_START, TX_HIGH_START, TX_LOW, TX_HIGH, RX_LOW, RX_HIGH, PRE_IDLE, PRE_IDLE2 } ft600sm;

ft600sm ft_state_d, ft_state_q = DRAIN;
logic [15:0] data_out;
logic [15:0] rx_data_lo_d, rx_data_lo_q = 0;
logic txe_d, txe_q = 0;
logic rxf_d, rxf_q = 0;

always_comb begin
    ft_state_d = ft_state_q;
    rx_data_lo_d = rx_data_lo_q;
    //rx_fifo_din = {16'hffff, rx_data_lo_q};
    rx_fifo_din = {ftdi_data, rx_data_lo_q};
    rx_fifo_wr_en = 0;
    txe_d = ftdi_txe_n;
    rxf_d = ftdi_rxf_n;

    ftdi_oe_n = 1;
    ftdi_rd_n = 1;
    ftdi_wr_n = 1;
    tx_fifo_rd_en = 0;
    data_out = 16'h0000;

    case (ft_state_q)
    DRAIN: begin
        if (!ftdi_rxf_n) begin
            // drain anything which might be queued from the host
            ftdi_oe_n = 0;
            ftdi_rd_n = 0;
        end
        if (!tx_fifo_empty) begin
            // drain any message data which might be buffered
            tx_fifo_rd_en = 1;
        end
        // once fully drained in both directions, we can go to IDLE
        if (ftdi_rxf_n && rx_data_empty) begin
            ft_state_d = IDLE;
        end
    end
    PRE_IDLE: begin
        ft_state_d = PRE_IDLE2;
    end
    PRE_IDLE2: begin
        ft_state_d = IDLE;
    end
    IDLE: begin
        if (!tx_fifo_empty && !txe_q) begin
            // default to tx, if tx enabled and tx data ready
            ft_state_d = TX_HIGH;
            data_out = tx_fifo_dout[15:0];
            ftdi_wr_n = 0;
        end else begin
            if (!rxf_q) begin
            //if (!ftdi_rxf_n) begin
                // assert oen the cycle before beginning rx
                // to turn the bus around
                ftdi_oe_n = 0;
                ft_state_d = RX_LOW;
            end
        end
    end
    TX_LOW: begin
        if (tx_fifo_empty || ftdi_txe_n) begin
            // can't send data (either none left or tx full)
            ft_state_d = PRE_IDLE;
        end else begin
            ft_state_d = TX_HIGH;
            data_out = tx_fifo_dout[15:0];
            ftdi_wr_n = 0;
        end
    end
    TX_HIGH: begin
        // send the high half and pop the event from the fifo
        ft_state_d = TX_LOW;
        ftdi_wr_n = 0;
        data_out = tx_fifo_dout[31:16];
        tx_fifo_rd_en = 1;
    end
    RX_LOW: begin
        // keep oen low while receiving
        if (rxf_q) begin
        //if (ftdi_rxf_n) begin
            // rx ended
            ft_state_d = PRE_IDLE;
        end else begin
            ftdi_oe_n = 0;
            ftdi_rd_n = 0;
            rx_data_lo_d = ftdi_data;
            ft_state_d = RX_HIGH;
        end
    end
    RX_HIGH: begin
        if (rxf_q) begin
        //if (ftdi_rxf_n) begin
            ft_state_d = PRE_IDLE;
        end else begin
            ftdi_oe_n = 0;
            ftdi_rd_n = 0;
            rx_fifo_wr_en = 1;
            ft_state_d = RX_LOW;
        end
    end
    default: begin
        // move to INIT state on bad state
        ft_state_d = DRAIN;
    end
    endcase
end

assign ftdi_data = ftdi_wr_n ? 16'hzzzz : data_out;
assign ftdi_be = ftdi_wr_n ? 2'bzz : 2'b11;

// flip flop transitions
always @(posedge ft_clk) begin
    if (rst) begin
        ft_state_q <= DRAIN;
        rx_data_lo_q <= 0;
        txe_q <= 0;
        rxf_q <= 0;
    end else begin
        ft_state_q <= ft_state_d;
        rx_data_lo_q <= rx_data_lo_d;
        txe_q <= txe_d;
        rxf_q <= rxf_d;
    end
end

endmodule
