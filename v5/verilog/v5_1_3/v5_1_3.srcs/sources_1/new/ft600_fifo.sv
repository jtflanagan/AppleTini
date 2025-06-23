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
    inout logic [31:0] ftdi_data,
    inout logic [3:0] ftdi_be,
    input ftdi_rxf_n,
    input ftdi_txe_n,
    output logic ftdi_wr_n,
    output logic ftdi_rd_n,
    output logic ftdi_oe_n,
    output logic ftdi_wakeup,
    output logic ftdi_reset,

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
(* MARK_DEBUG = "TRUE" *) logic wr_rst_busy;
(* MARK_DEBUG = "TRUE" *) logic rd_rst_busy;

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
  .wr_rst_busy(wr_rst_busy),
  .rd_rst_busy(rd_rst_busy)
);

typedef enum {DRAIN, IDLE, TX, RX, PRE_IDLE, PRE_IDLE2 } ft600sm;

ft600sm ft_state_d, ft_state_q = DRAIN;
logic [31:0] data_out;
logic txe_d, txe_q = 0;
logic rxf_d, rxf_q = 0;

always_comb begin
    ftdi_wakeup = 1;
    ftdi_reset = 1;
    ft_state_d = ft_state_q;
    rx_fifo_din = 0;
    rx_fifo_wr_en = 0;
    txe_d = ftdi_txe_n;
    rxf_d = ftdi_rxf_n;

    ftdi_oe_n = 1;
    ftdi_rd_n = 1;
    ftdi_wr_n = 1;
    tx_fifo_rd_en = 0;
    data_out = tx_fifo_dout;

    case (ft_state_q)
    DRAIN: begin
        ft_state_d = IDLE;
        // if (!ftdi_rxf_n) begin
        //     // drain anything which might be queued from the host
        //     ftdi_oe_n = 0;
        //     ftdi_rd_n = 0;
        // end
        // if (!tx_fifo_empty) begin
        //     // drain any message data which might be buffered
        //     tx_fifo_rd_en = 1;
        // end
        // // once fully drained in both directions, we can go to IDLE
        // if (ftdi_rxf_n && rx_data_empty) begin
        //     ft_state_d = IDLE;
        // end
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
            ft_state_d = TX;
            //ftdi_wr_n = 0;
            //tx_fifo_rd_en = 1;
        end else begin
            if (!rxf_q) begin
            //if (!ftdi_rxf_n) begin
                // assert oen the cycle before beginning rx
                // to turn the bus around
                ftdi_oe_n = 0;
                ft_state_d = RX;
            end
        end
    end
    TX: begin
        if (tx_fifo_empty || ftdi_txe_n) begin
            // can't send data (either none left or tx full)
            ft_state_d = PRE_IDLE;
        end else begin
            ftdi_wr_n = 0;
            tx_fifo_rd_en = 1;
        end
    end
    RX: begin
        // keep oen low while receiving
        if (ftdi_rxf_n) begin
        //if (ftdi_rxf_n) begin
            // rx ended
            ft_state_d = PRE_IDLE;
        end else begin
            ftdi_oe_n = 0;
            ftdi_rd_n = 0;
            rx_fifo_din = ftdi_data;
            rx_fifo_wr_en = 1;
        end
    end
    default: begin
        // move to INIT state on bad state
        ft_state_d = DRAIN;
    end
    endcase
end

assign ftdi_data = ftdi_wr_n ? 32'hzzzzzzzz : data_out;
assign ftdi_be = ftdi_wr_n ? 4'hz : 4'hf;

// flip flop transitions
always @(posedge ft_clk) begin
    if (rst) begin
        ft_state_q <= DRAIN;
        txe_q <= 0;
        rxf_q <= 0;
    end else begin
        ft_state_q <= ft_state_d;
        txe_q <= txe_d;
        rxf_q <= rxf_d;
    end
end

endmodule
