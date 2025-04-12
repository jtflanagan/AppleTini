`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/12/2025 01:51:19 PM
// Design Name: 
// Module Name: ft601_tx_only
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


module ft601_tx_only (
        input wire clk,
        input wire rst,
        input wire ft_clk,
        input wire ft_rxf,
        input wire ft_txe,
        inout wire [31:0] ft_data,
        inout wire [3:0] ft_be,
        output reg ft_rd,
        output reg ft_wr,
        output reg ft_oe,
        input wire [31:0] ui_din,
        input wire [3:0] ui_din_be,
        input wire ui_din_valid,
        output reg ui_din_full,
        output reg [31:0] ui_dout,
        output reg [3:0] ui_dout_be,
        output reg ui_dout_empty,
        input wire ui_dout_get
    );

    logic [35:0] write_fifo_din;
    logic write_fifo_wr_en;
    logic write_fifo_rd_en;
    logic [35:0] write_fifo_dout;
    logic write_fifo_full;
    logic write_fifo_empty;

    fifo_generator_0 write_fifo(
        .rst(rst),
        .wr_clk(clk),
        .rd_clk(ft_clk),
        .din(write_fifo_din),
        .wr_en(write_fifo_wr_en),
        .rd_en(write_fifo_rd_en),
        .dout(write_fifo_dout),
        .full(write_fifo_full),
        .empty(write_fifo_empty),
        .wr_rst_busy(),
        .rd_rst_busy()
    );

typedef enum {IDLE, TX, PRE_IDLE} ft601sm;
ft601sm ft_state_d, ft_state_q = IDLE; 
logic tx_empty_d, tx_empty_q = 0;
//logic [7:0] packet_counter_d, packet_counter_q = 0;
logic [31:0] tx_data_out = 0;
logic [3:0] tx_be_out = 0;

always_comb begin
    ft_state_d = ft_state_q;
    tx_empty_d = ft_txe;
    ft_oe = 1;
    ft_rd = 1;
    ft_wr = 1;
    tx_data_out = 0;
    tx_be_out = 4'hf;
    write_fifo_rd_en = 0;

    case (ft_state_q)
    IDLE:
        if (!write_fifo_empty && !tx_empty_q) begin
            ft_state_d = TX;
        end
    TX:
        if (tx_empty_q == 1 || write_fifo_empty) begin
            ft_state_d = PRE_IDLE;
        end else begin
            tx_data_out = write_fifo_dout[31:0];
            tx_be_out = write_fifo_dout[35:32];
            write_fifo_rd_en = 1;
            ft_wr = 0;
        end
    PRE_IDLE:
        ft_state_d = IDLE;
    endcase
end

assign write_fifo_din[31:0] = ui_din;
assign write_fifo_din[35:32] = ui_din_be;
assign write_fifo_wr_en = ui_din_valid;
assign ui_din_full = write_fifo_full;
assign ft_data = ft_wr ? 16'hzzzz : tx_data_out;
assign ft_be = ft_wr ? 4'hz : tx_be_out;
assign ui_dout = 0;
assign ui_dout_be = 0;
assign ui_dout_empty = 0;

always_ff @(posedge ft_clk) begin
    if (rst) begin
        ft_state_q <= IDLE;
        tx_empty_q <= 1;
    end else begin
        ft_state_q <= ft_state_d;
        tx_empty_q <= tx_empty_d;
    end
end

endmodule
