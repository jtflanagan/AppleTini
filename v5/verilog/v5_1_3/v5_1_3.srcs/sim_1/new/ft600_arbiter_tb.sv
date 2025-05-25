`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/22/2025 01:43:31 PM
// Design Name: 
// Module Name: ft600_arbiter_tb
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

    // input clk,
    // input rst,
    // ft600_msg.recv client_inputs[NUM_CLIENTS],
    // input inport_full,
    // output logic [35:0] inport_data,
    // output logic inport_wr_en


module test_message #(parameter NUM_WORDS = 1) (
    input clk,
    input rst,
    input [31:0] message_word,
    input message_word_wr_en,
    ft600_msg.send ft600_send
);

logic [NUM_WORDS-1:0][31:0] msg_storage;
logic [8:0] word_counter_d, word_counter_q = 0;
logic [8:0] send_counter_d, send_counter_q = 0;

always_comb begin
    word_counter_d = word_counter_q;
    send_counter_d = send_counter_q;
    ft600_send.msg_ready = 0;
    if (message_word_wr_en) begin
        msg_storage[word_counter_q] = message_word;
        word_counter_d = word_counter_q + 1;
    end
    if (word_counter_q == NUM_WORDS) begin
        // message is fully loaded and ready to send
        if (send_counter_q != NUM_WORDS) begin
            // if the message isn't completely sent yet,
            // show ready
            ft600_send.msg_ready = 1;
            ft600_send.msg = msg_storage[send_counter_q];
        end
        if (ft600_send.msg_rd_en && send_counter_q != NUM_WORDS) begin
            // if a word sent, increment
            send_counter_d = send_counter_q + 1;
        end
    end
end

always @(posedge clk) begin
    if (rst) begin
        word_counter_q <= 0;
        send_counter_q = 0;
    end else begin
        word_counter_q <= word_counter_d;
        send_counter_q <= send_counter_d;
    end
end

endmodule

module ft600_arbiter_tb(

    );

logic clk;
logic rst;
ft600_msg msg1();
ft600_msg msg2();
logic inport_full;
logic [31:0] inport_data;
logic inport_wr_en;

ft600_arbiter #(.NUM_CLIENTS(2))
ft600_arb(
    .clk(clk),
    .rst(rst),
    .client_inputs({msg1, msg2}),
    .inport_full(inport_full),
    .inport_data(inport_data),
    .inport_wr_en(inport_wr_en)
);

logic [31:0] tm1_word;
logic tm1_wr_en;
test_message #(.NUM_WORDS(1))
tm1(
    .clk(clk),
    .rst(rst),
    .message_word(tm1_word),
    .message_word_wr_en(tm1_wr_en),
    .ft600_send(msg1)
);
logic [31:0] tm2_word;
logic tm2_wr_en;
test_message #(.NUM_WORDS(2))
tm2(
    .clk(clk),
    .rst(rst),
    .message_word(tm2_word),
    .message_word_wr_en(tm2_wr_en),
    .ft600_send(msg2)
);

initial begin
    $display($time, "Start sim");
    clk = 0;
    rst = 1;
    inport_full = 0;
    #40 rst = 0;
end

parameter CLK_PERIOD = 5;

always #CLK_PERIOD clk=~clk;

initial begin
    #100;
    tm1_word = 32'h11111111;
    tm1_wr_en = 1;
    tm2_word = 32'h22222222;
    tm2_wr_en = 1;
    #10;
    tm1_wr_en = 0;
    tm2_word = 32'h33333333;
    tm2_wr_en = 1;
    #10;
    tm2_wr_en = 0;
end

endmodule
