`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/28/2025 07:12:28 PM
// Design Name: 
// Module Name: vbl_manager
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


module vbl_manager(
    input clk,
    input rst,
    input globals::AppleBus_read ab_read,
    output logic [15:0] vbl_cycle,
    output logic vbl_is_60hz,
    output logic is_vbl // updates on ab_read.sss_en
    );

logic [15:0] vbl_cycle_d, vbl_cycle_q = 0;
logic [4:0] prev_probe_d, prev_probe_q = 0;
logic vbl_is_60hz_d, vbl_is_60hz_q = 0;
logic seen_vbl_d, seen_vbl_q = 0;
logic prev_vbl_d, prev_vbl_q = 0;

assign vbl_cycle = vbl_cycle_q;

always_comb begin
    vbl_cycle_d = vbl_cycle_q;
    prev_probe_d = prev_probe_q;
    vbl_is_60hz_d = vbl_is_60hz_q;
    seen_vbl_d = seen_vbl_q;
    prev_vbl_d = prev_vbl_q;
    is_vbl = (vbl_cycle_d == 0);

    if (ab_read.addr_en) begin
        vbl_cycle_d = vbl_cycle_q + 1;
        if (vbl_is_60hz_q) begin
            if (vbl_cycle_q == 17029) begin
                vbl_cycle_d = 0;
            end
        end else begin
            if (vbl_cycle_q == 20279) begin
                vbl_cycle_d = 0;
            end
        end
    end
    if (ab_read.data_en) begin
        if (prev_probe_q != 5'h1f) begin
            prev_probe_d = prev_probe_q + 1;
        end
        if (ab_read.addr[15:0] == 16'hc019) begin
            prev_probe_d = 0;
            if (prev_probe_q != 5'h1f) begin
                prev_vbl_d = ab_read.data[7];
                if (prev_vbl_q == 1 && ab_read.data[7] == 0) begin
                    if (!seen_vbl_q) begin
                        seen_vbl_d = 1;
                        vbl_cycle_d = 0;
                    end else begin
                        if (vbl_cycle_q <= 17029) begin
                            vbl_cycle_d = 0;
                            vbl_is_60hz_d = 1;
                        end else begin
                            if (vbl_cycle_q <= 20279) begin
                                vbl_cycle_d = 0;
                                vbl_is_60hz_d = 0;
                            end
                        end
                    end
                end
            end
        end
    end
end

always @(posedge clk) begin
    if (rst || (ab_read.res == 0) ) begin
        vbl_cycle_q <= 0;
        prev_probe_q <= 0;
        vbl_is_60hz_q <= 0;
        seen_vbl_q <= 0;
        prev_vbl_q <= 0;
    end else begin
        vbl_cycle_q <= vbl_cycle_d;
        prev_probe_q <= prev_probe_d;
        vbl_is_60hz_q <= vbl_is_60hz_d;
        seen_vbl_q <= seen_vbl_d;
        prev_vbl_q <= prev_vbl_d;
    end
end

endmodule
