`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/27/2025 03:49:46 PM
// Design Name: 
// Module Name: tini_bus_arbiter
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


module tini_bus_arbiter #(parameter NUM_REG_CLIENTS = 1, NUM_TX_CLIENTS = 1) (
    input clk,
    input rst,
    output globals::RegOpWrite reg_write,
    input globals::RegOpRead reg_read_clients[NUM_REG_CLIENTS],
    TxRequest.master tx_clients[NUM_TX_CLIENTS],

    // tx interface
    output logic ft600_tx_data_en,
    output logic [31:0] ft600_tx_data,
    input ft600_tx_data_full,

    // rx interface
    output logic ft600_rx_data_en,
    input [31:0] ft600_rx_data,
    input ft600_rx_data_empty
    );

    logic [32:0][NUM_REG_CLIENTS-1:0] reg_read_state;
    logic [31:0] reg_read_data;
    logic reg_read_ready;

    // logical OR-together all the reg_read clients, which should
    // always be all 0's for every client except the one which is currently active,
    // so OR-ing them all together gets that client's data.
    for (genvar i = 0; i < NUM_REG_CLIENTS; i++) begin
        for (genvar j = 0; j < 32; j++) begin
            assign reg_read_state[j][i] = reg_read_clients[i].rd_data[j];
        end
        assign reg_read_state[32][i] = reg_read_clients[i].rd_ready;
    end

    for (genvar i = 0; i < 32; i++) begin
        assign reg_read_data[i] = |reg_read_state[i]; 
    end
    assign reg_read_ready = |reg_read_state[32];

    logic [NUM_TX_CLIENTS-1:0] current_tx_client_d, current_tx_client_q = 0;
    logic [NUM_TX_CLIENTS-1:0] tx_client_requests;
    logic [40:0][NUM_TX_CLIENTS-1:0] tx_client_cmds;
    logic [40:0] tx_client_cmd;
    
    logic [40:0] tx_cmd_fifo_din;
    logic tx_cmd_fifo_wr_en;
    logic tx_cmd_fifo_rd_en;
    logic [40:0] tx_cmd_fifo_dout;
    logic tx_cmd_fifo_full;
    logic tx_cmd_fifo_empty;

    tx_request_fifo tx_cmd_fifo(
        .rst(rst),
        .clk(clk),
        .din(tx_cmd_fifo_din),
        .wr_en(tx_cmd_fifo_wr_en),
        .rd_en(tx_cmd_fifo_rd_en),
        .dout(tx_cmd_fifo_dout),
        .full(tx_cmd_fifo_full),
        .empty(tx_cmd_fifo_empty)
    );

    for (genvar i = 0; i < NUM_TX_CLIENTS; i++) begin
        assign tx_client_requests[i] = tx_clients[i].tx_request;
        assign tx_clients[i].tx_ack = current_tx_client_q[i] && !tx_cmd_fifo_full;
    end

    // logical OR-together all the tx client commands, which should
    // always be all 0's for every client except the one which is currently acked,
    // so OR-ing them all together gets that client's command.
    for (genvar i = 0; i < NUM_TX_CLIENTS; i++) begin
        for (genvar j = 0; j < 32; j++) begin
            assign tx_client_cmds[j][i] = tx_clients[i].address[j];
        end
        for (genvar j = 0; j < 8; j++) begin
            assign tx_client_cmds[j+32][i] = tx_clients[i].length[j]; 
        end
        assign tx_client_cmds[40][i] = tx_clients[i].addr_incr;
    end

    for (genvar i = 0; i < 41; i++) begin
        assign tx_client_cmd[i] = |tx_client_cmds[i]; 
    end

    always_comb begin
        tx_cmd_fifo_din = tx_client_cmd;
        tx_cmd_fifo_wr_en = 0;
        current_tx_client_d = current_tx_client_q;
        for (int i = 0; i < NUM_TX_CLIENTS; i++) begin
            if (!current_tx_client_q) begin
                if (tx_client_requests[i]) begin
                    current_tx_client_d = 1 << i;
                end
            end else begin
                if (current_tx_client_q[i]) begin
                    if (!tx_cmd_fifo_full) begin
                        tx_cmd_fifo_wr_en = 1;
                        current_tx_client_d = 0;
                    end
                end
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            current_tx_client_q <= 0;
        end else begin
            current_tx_client_q <= current_tx_client_d;
        end
    end

    typedef enum {IDLE, TX_HEADER, TX_ADDR, TX_DATA_FETCH, TX_DATA_WAIT, TX_DATA_WRITE, RX_HEADER, RX_ADDR, RX_DATA} tini_bus_sm;

    tini_bus_sm tini_bus_state_d, tini_bus_state_q = IDLE;

    logic [31:0] current_address_d, current_address_q = 0;
    logic [7:0] current_count_d, current_count_q = 0;
    logic current_incr_d, current_incr_q = 0;
    logic [31:0] tx_data_d, tx_data_q = 0;

    always_comb begin
        tini_bus_state_d = tini_bus_state_q;
        current_address_d = current_address_q;
        current_count_d = current_count_q;
        current_incr_d = current_incr_q;
        tx_data_d = tx_data_q;
        tx_cmd_fifo_rd_en = 0;
        ft600_tx_data_en = 0;
        ft600_tx_data = reg_read_data;
        ft600_rx_data_en = 0;
        reg_write.address = 32'hxxxxxxxx;
        reg_write.wr_data = 32'hxxxxxxxx;
        reg_write.is_write = 0;
        reg_write.new_cmd = 0;
        case (tini_bus_state_q)
        IDLE: begin
            if (!tx_cmd_fifo_empty) begin
                tini_bus_state_d = TX_HEADER;
            end else begin
                if (!ft600_rx_data_empty) begin
                    tini_bus_state_d = RX_HEADER;
                end
            end
        end
        TX_HEADER: begin
            if (!ft600_tx_data_full) begin
                current_incr_d = tx_cmd_fifo_dout[40];
                current_count_d = tx_cmd_fifo_dout[39:32];
                ft600_tx_data = {tx_cmd_fifo_dout[40], 23'h0, tx_cmd_fifo_dout[39:32]};
                ft600_tx_data_en = 1;
                tini_bus_state_d = TX_ADDR;
            end
        end
        TX_ADDR: begin
            if (!ft600_tx_data_full) begin
                current_address_d = tx_cmd_fifo_dout[31:0];
                ft600_tx_data = tx_cmd_fifo_dout[31:0];
                ft600_tx_data_en = 1;
                tx_cmd_fifo_rd_en = 1;
                tini_bus_state_d = TX_DATA_FETCH;
            end
        end
        TX_DATA_FETCH: begin
            if (!current_count_q) begin
                tini_bus_state_d = IDLE;
            end else begin
                reg_write.address = current_address_q;
                reg_write.new_cmd = 1;
                tx_data_d = reg_read_data;
                if (reg_read_ready) begin
                    // read achieved same-cycle
                    if (current_incr_q) begin
                        current_address_d = current_address_q + 4;
                    end
                    current_count_d = current_count_q - 1;
                    if (!ft600_tx_data_full) begin
                        ft600_tx_data_en = 1;
                    end else begin
                        // stuck waiting for fifo space
                        tini_bus_state_d = TX_DATA_WRITE;
                    end
                end else begin
                    // waiting for read complete
                    tini_bus_state_d = TX_DATA_WAIT;
                end
            end
        end
        TX_DATA_WAIT: begin
            if (reg_read_ready) begin
                if (current_incr_q) begin
                    current_address_d = current_address_q + 4;
                end
                current_count_d = current_count_q - 1;
                if (!ft600_tx_data_full) begin
                    // fifo has room, can complete immediately
                    ft600_tx_data = tx_data_q;
                    ft600_tx_data_en = 1;
                    tini_bus_state_d = TX_DATA_FETCH;
                end else begin
                    // have to wait for fifo space
                    tini_bus_state_d = TX_DATA_WRITE; 
                end
            end
        end
        TX_DATA_WRITE: begin
            if (!ft600_tx_data_full) begin
                // fifo has room, can complete now
                ft600_tx_data = tx_data_q;
                ft600_tx_data_en = 1;
                tini_bus_state_d = TX_DATA_FETCH;
            end
        end
        RX_HEADER: begin
            current_incr_d = ft600_rx_data[31];
            current_count_d = ft600_rx_data[7:0];
            ft600_rx_data_en = 1;
            tini_bus_state_d = RX_ADDR;
        end
        RX_ADDR: begin
            if (!ft600_rx_data_empty) begin
               current_address_d = ft600_rx_data;
               //current_address_d = 32'hffffffff;
               ft600_rx_data_en = 1;
               tini_bus_state_d = RX_DATA;
            end
        end
        RX_DATA: begin
            if (!current_count_d) begin
                tini_bus_state_d = IDLE;
            end else if (!ft600_rx_data_empty) begin
                reg_write.address = current_address_q;
                //reg_write.address = 32'hffffffff;
                reg_write.is_write = 1;
                reg_write.new_cmd = 1;
                reg_write.wr_data = ft600_rx_data;
                ft600_rx_data_en = 1;
                if (current_incr_q) begin
                    current_address_d = current_address_q + 4;
                end
                current_count_d = current_count_q - 1;
            end 
        end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            tini_bus_state_q <= IDLE;
            current_address_q <= 0;
            current_count_q <= 0;
            current_incr_q <= 0;
            tx_data_q <= 0;
        end else begin
            tini_bus_state_q <= tini_bus_state_d;
            current_address_q <= current_address_d;
            current_count_q <= current_count_d;
            current_incr_q <= current_incr_d;
            tx_data_q <= tx_data_d;
        end
    end

endmodule
