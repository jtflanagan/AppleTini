`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/18/2025 08:46:16 PM
// Design Name: 
// Module Name: bus_event_manager_tb
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


module bus_event_manager_tb(
    );

  logic clk;
  logic rst;
globals::AppleBus_read abus;
ft600_msg msg();

bus_event_manager mgr(
    .clk(clk),
    .rst(rst),
    .ab_read(abus),
    .ft600_send(msg)
);

parameter CLK_PERIOD = 5;

initial begin
    $display($time, "Start sim");
    clk = 0;
    rst = 1;
    abus.data = 8'h00;
    abus.addr = 16'h0000;
    abus.rw = 0;
    abus.phi0 = 0;
    abus.m2sel = 0;
    abus.q3 = 0;
    abus.m7m = 0;
    abus.m2b0 = 0;
    abus.inh = 1;
    abus.res = 1;
    abus.irq = 1;
    abus.rdy = 1;
    abus.nmi = 1;
    abus.dma = 1;
    abus.data_en = 0;
    abus.addr_en = 0;
    msg.msg_rd_en = 0;
    #40 rst = 0;
end

always #CLK_PERIOD clk=~clk;

initial begin
    #100;
    for (integer i = 0; i < 512; ++i) begin
        abus.data = i[7:0];
        abus.addr[8:0] = i[8:0];
        abus.data_en = 1;
        #10 abus.data_en = 0;
        #20;
    end
end

initial begin
    #8000;
    for (integer i = 0; i < 256; ++i) begin
        msg.msg_rd_en = 1;
        #10;
        // msg.msg_rd_en = 0;
        // #10;
    end
    msg.msg_rd_en = 0;
    #16000;
    for (integer i = 0; i < 256; ++i) begin
        msg.msg_rd_en = 1;
        #10;
        // msg.msg_rd_en = 0;
        // #10;
    end
    msg.msg_rd_en = 0;
end

endmodule
