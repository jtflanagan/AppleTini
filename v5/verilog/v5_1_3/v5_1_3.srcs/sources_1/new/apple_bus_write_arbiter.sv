`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/23/2025 08:53:50 PM
// Design Name: 
// Module Name: apple_bus_write_arbiter
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


module apple_bus_write_arbiter #(parameter NUM_CLIENTS = 1) (
    input globals::AppleBus_write [NUM_CLIENTS-1:0] client_writes,
    output globals::AppleBus_write ab_write
);

logic [NUM_CLIENTS-1:0] wr_data0;
logic [NUM_CLIENTS-1:0] wr_data1;
logic [NUM_CLIENTS-1:0] wr_data2;
logic [NUM_CLIENTS-1:0] wr_data3;
logic [NUM_CLIENTS-1:0] wr_data4;
logic [NUM_CLIENTS-1:0] wr_data5;
logic [NUM_CLIENTS-1:0] wr_data6;
logic [NUM_CLIENTS-1:0] wr_data7;
logic [NUM_CLIENTS-1:0] wr_data_en;
logic [NUM_CLIENTS-1:0] wr_addr0;
logic [NUM_CLIENTS-1:0] wr_addr1;
logic [NUM_CLIENTS-1:0] wr_addr2;
logic [NUM_CLIENTS-1:0] wr_addr3;
logic [NUM_CLIENTS-1:0] wr_addr4;
logic [NUM_CLIENTS-1:0] wr_addr5;
logic [NUM_CLIENTS-1:0] wr_addr6;
logic [NUM_CLIENTS-1:0] wr_addr7;
logic [NUM_CLIENTS-1:0] wr_addr8;
logic [NUM_CLIENTS-1:0] wr_addr9;
logic [NUM_CLIENTS-1:0] wr_addr10;
logic [NUM_CLIENTS-1:0] wr_addr11;
logic [NUM_CLIENTS-1:0] wr_addr12;
logic [NUM_CLIENTS-1:0] wr_addr13;
logic [NUM_CLIENTS-1:0] wr_addr14;
logic [NUM_CLIENTS-1:0] wr_addr15;
logic [NUM_CLIENTS-1:0] wr_rw;
logic [NUM_CLIENTS-1:0] wr_addr_rw_en;
logic [NUM_CLIENTS-1:0] assert_inh;
logic [NUM_CLIENTS-1:0] assert_res;
logic [NUM_CLIENTS-1:0] assert_irq;
logic [NUM_CLIENTS-1:0] assert_rdy;
logic [NUM_CLIENTS-1:0] assert_nmi;
logic [NUM_CLIENTS-1:0] assert_dma;

for (genvar i = 0; i < NUM_CLIENTS; i++) begin
    assign wr_data0[i] = client_writes[i].wr_data[0];
    assign wr_data1[i] = client_writes[i].wr_data[1];
    assign wr_data2[i] = client_writes[i].wr_data[2];
    assign wr_data3[i] = client_writes[i].wr_data[3];
    assign wr_data4[i] = client_writes[i].wr_data[4];
    assign wr_data5[i] = client_writes[i].wr_data[5];
    assign wr_data6[i] = client_writes[i].wr_data[6];
    assign wr_data7[i] = client_writes[i].wr_data[7];
    assign wr_data_en[i] = client_writes[i].wr_data_en;
    assign wr_addr0[i] = client_writes[i].wr_addr[0];
    assign wr_addr1[i] = client_writes[i].wr_addr[1];
    assign wr_addr2[i] = client_writes[i].wr_addr[2];
    assign wr_addr3[i] = client_writes[i].wr_addr[3];
    assign wr_addr4[i] = client_writes[i].wr_addr[4];
    assign wr_addr5[i] = client_writes[i].wr_addr[5];
    assign wr_addr6[i] = client_writes[i].wr_addr[6];
    assign wr_addr7[i] = client_writes[i].wr_addr[7];
    assign wr_addr8[i] = client_writes[i].wr_addr[8];
    assign wr_addr9[i] = client_writes[i].wr_addr[9];
    assign wr_addr10[i] = client_writes[i].wr_addr[10];
    assign wr_addr11[i] = client_writes[i].wr_addr[11];
    assign wr_addr12[i] = client_writes[i].wr_addr[12];
    assign wr_addr13[i] = client_writes[i].wr_addr[13];
    assign wr_addr14[i] = client_writes[i].wr_addr[14];
    assign wr_addr15[i] = client_writes[i].wr_addr[15];
    assign wr_rw[i] = client_writes[i].wr_rw;
    assign wr_addr_rw_en[i] = client_writes[i].wr_addr_rw_en;
    assign assert_inh[i] = client_writes[i].assert_inh;
    assign assert_res[i] = client_writes[i].assert_res;
    assign assert_irq[i] = client_writes[i].assert_irq;
    assign assert_rdy[i] = client_writes[i].assert_rdy;
    assign assert_nmi[i] = client_writes[i].assert_nmi;
    assign assert_dma[i] = client_writes[i].assert_dma; 
end

assign ab_write.wr_data[0] = |wr_data0;
assign ab_write.wr_data[1] = |wr_data1;
assign ab_write.wr_data[2] = |wr_data2;
assign ab_write.wr_data[3] = |wr_data3;
assign ab_write.wr_data[4] = |wr_data4;
assign ab_write.wr_data[5] = |wr_data5;
assign ab_write.wr_data[6] = |wr_data6;
assign ab_write.wr_data[7] = |wr_data7;
assign ab_write.wr_data_en = |wr_data_en;
assign ab_write.wr_addr[0] = |wr_addr0;
assign ab_write.wr_addr[1] = |wr_addr1;
assign ab_write.wr_addr[2] = |wr_addr2;
assign ab_write.wr_addr[3] = |wr_addr3;
assign ab_write.wr_addr[4] = |wr_addr4;
assign ab_write.wr_addr[5] = |wr_addr5;
assign ab_write.wr_addr[6] = |wr_addr6;
assign ab_write.wr_addr[7] = |wr_addr7;
assign ab_write.wr_addr[8] = |wr_addr8;
assign ab_write.wr_addr[9] = |wr_addr9;
assign ab_write.wr_addr[10] = |wr_addr10;
assign ab_write.wr_addr[11] = |wr_addr11;
assign ab_write.wr_addr[12] = |wr_addr12;
assign ab_write.wr_addr[13] = |wr_addr13;
assign ab_write.wr_addr[14] = |wr_addr14;
assign ab_write.wr_addr[15] = |wr_addr15;
assign ab_write.wr_rw = |wr_rw;
assign ab_write.wr_addr_rw_en = |wr_addr_rw_en;
assign ab_write.assert_inh = |assert_inh;
assign ab_write.assert_res = |assert_res;
assign ab_write.assert_irq = |assert_irq;
assign ab_write.assert_rdy = |assert_rdy;
assign ab_write.assert_nmi = |assert_nmi;
assign ab_write.assert_dma = |assert_dma;

endmodule
