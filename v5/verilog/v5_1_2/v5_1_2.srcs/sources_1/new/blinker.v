`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/24/2025 06:45:28 PM
// Design Name: 
// Module Name: blinker
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


module blinker (
    input clk,
    input rst,
    input counted_event,
    output reg blink
  );

  reg [18:0] M_counter_d, M_counter_q = 0;
  
  always @* begin
    if (counted_event) begin
      M_counter_d = M_counter_q + 1;
    end
    else begin
      M_counter_d = M_counter_q;
    end
  end
  
  always @(posedge clk) begin
    if (rst) begin
      M_counter_q <= 0;
      blink <= 0;
    end
    else
    begin
      M_counter_q <= M_counter_d;
      blink <= M_counter_q[18];
    end
  end

endmodule

