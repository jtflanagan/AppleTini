module synchronizer #(parameter SYNC_STAGES = 2, WIDTH = 1)(
  input clk,
  input rst,
  input [WIDTH-1:0] in,
  output reg [WIDTH-1:0] out
);

  (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] sync_regs [SYNC_STAGES-1:0];

  integer i;

  always @(posedge clk) begin
    if (rst) begin
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin
            sync_regs[i] = {WIDTH{1'b0}};
        end
    end
    else begin
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin
            sync_regs[i] <= sync_regs[i-1];
        end
        sync_regs[0] <= in;
        out <= {sync_regs[SYNC_STAGES-1]};
    end
  end
endmodule