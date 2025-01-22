module blinker2 (
    input clk,  // clock
    input rst,  // reset
    input counted_event,
    output reg blink
  );
  
  reg [19:0] counter;

  /* Combinational Logic */
  always @* begin
    blink = counter[19];
  end
  
  /* Sequential Logic */
  always @(posedge clk) begin
    if (rst) begin
      counter[19:0] <= 20'h000;
    end else begin
      if (counted_event) begin
        counter <= counter + 1;
      end
    end
  end
  
endmodule
