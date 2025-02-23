module bus_timing (
    input clk,
    input rst,
    input phi0_clean,
    output reg addr_phase_begin,
    output reg addr_phase_snap_bus,
    output reg data_phase_emit,
    output reg data_phase_snap_bus
  );
  
  
  
  reg M_prev_phi0_d, M_prev_phi0_q = 1'h0;
  
  reg [19:0] M_addr_pipe_d, M_addr_pipe_q = 1'h0;
  
  reg [45:0] M_data_pipe_d, M_data_pipe_q = 1'h0;
  
  //reg [16:0] M_addr_pipe_d, M_addr_pipe_q = 1'h0;
  
  //reg [36:0] M_data_pipe_d, M_data_pipe_q = 1'h0;
  
  reg addr_edge;
  
  reg data_edge;
  
  always @* begin
    M_addr_pipe_d = M_addr_pipe_q;
    M_data_pipe_d = M_data_pipe_q;
    M_prev_phi0_d = M_prev_phi0_q;
    
    M_addr_pipe_d[0] = 1'h0;
    // M_addr_pipe_d[1+15-:16] = M_addr_pipe_q[0+15-:16];
    M_addr_pipe_d[19:1] = M_addr_pipe_q[18:0];
    M_data_pipe_d[0] = 1'h0;
    // M_data_pipe_d[1+35-:36] = M_data_pipe_q[0+35-:36];
    M_data_pipe_d[45:1] = M_data_pipe_q[44:0];
    addr_edge = 1'h0;
    data_edge = 1'h0;
    if (phi0_clean == 1'h1 && M_prev_phi0_q == 1'h0) begin
      data_edge = 1'h1;
      M_prev_phi0_d = 1'h1;
    end else begin
      if (phi0_clean == 1'h0 && M_prev_phi0_q == 1'h1) begin
        addr_edge = 1'h1;
        M_prev_phi0_d = 1'h0;
      end
    end
    M_addr_pipe_d[0] = addr_edge;
    M_data_pipe_d[0] = data_edge;
    addr_phase_begin = addr_edge;
    // addr_phase_snap_bus = M_addr_pipe_q[16+0-:1];
    // data_phase_emit = M_data_pipe_q[27+0-:1];
    // data_phase_snap_bus = M_data_pipe_q[36+0-:1];
    addr_phase_snap_bus = M_addr_pipe_q[19];
    data_phase_emit = M_data_pipe_q[34];
    data_phase_snap_bus = M_data_pipe_q[44];
  end
  
  always @(posedge clk) begin
    if (rst == 1'b1) begin
      M_addr_pipe_q <= 1'h0;
    end else begin
      M_addr_pipe_q <= M_addr_pipe_d;
    end
  end
  
  
  always @(posedge clk) begin
    if (rst == 1'b1) begin
      M_prev_phi0_q <= 1'h0;
    end else begin
      M_prev_phi0_q <= M_prev_phi0_d;
    end
  end
  
  
  always @(posedge clk) begin
    if (rst == 1'b1) begin
      M_data_pipe_q <= 1'h0;
    end else begin
      M_data_pipe_q <= M_data_pipe_d;
    end
  end
  
endmodule
