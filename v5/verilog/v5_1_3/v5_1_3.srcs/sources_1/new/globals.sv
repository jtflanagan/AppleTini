`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/23/2025 03:08:08 PM
// Design Name: 
// Module Name: globals
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

package globals;

    typedef struct packed {
        logic [27:0] addr;
        logic [2:0] cmd;
        logic enable;
        logic [127:0] wr_data;
        logic wr_enable;
        logic [15:0] wr_mask;
    } Memory_in;

    typedef struct packed {
        logic [127:0] rd_data;
        logic rd_valid;
        logic rdy;
        logic wr_rdy;
    } Memory_out;

    typedef struct packed {
        logic [7:0] data;
        logic [15:0] addr;
        logic rw;
        logic phi0;
        logic m2sel;
        logic q3;
        logic m7m;
        logic m2b0;
        logic inh;
        logic res;
        logic irq;
        logic rdy;
        logic nmi;
        logic dma;
        logic data_en; // 1 in the phase that data field update
        logic addr_en; // 1 in the phase that addr/rw field updates
        logic sss_en; // 1 in the phase that soft switches update
    } AppleBus_read;

    typedef struct packed {
        logic [7:0] wr_data;
        logic wr_data_en;
        logic [15:0] wr_addr;
        logic wr_rw;
        logic wr_addr_rw_en;
        logic assert_inh;
        logic assert_res;
        logic assert_irq;
        logic assert_rdy;
        logic assert_nmi;
        logic assert_dma;
    } AppleBus_write;

    typedef struct packed {
        logic [2:0] c8_select;
        logic slot_access;
        logic [16:0] addr_decode;
        logic addr_decode_en;
    } SoftSwitchState;

    typedef struct packed {
        logic [19:0] centisecond_ticks;
        logic [3:0] year_hi;
        logic [3:0] year_lo;
        logic [3:0] month_hi;
        logic [3:0] month_lo;
        logic [3:0] day_hi;
        logic [3:0] day_lo;
        logic [3:0] day_of_week_hi;
        logic [3:0] day_of_week_lo;
        logic [3:0] hour_hi;
        logic [3:0] hour_lo;
        logic [3:0] minute_hi;
        logic [3:0] minute_lo;
        logic [3:0] second_hi;
        logic [3:0] second_lo;
        logic [3:0] centisecond_hi;
        logic [3:0] centisecond_lo;
    } NSC_time;

    typedef struct packed {
        logic [31:0] address;
        logic [31:0] wr_data;
        logic is_write;
        logic new_cmd;
    } RegOpWrite;

    typedef struct packed {
        logic [31:0] rd_data;
        logic rd_ready;
    } RegOpRead;

endpackage

// a TxRequest client keeps 0's on address, length, and addr_incr at all times until
// its request has been acked.  When it wants to enqueue a tx request, it raises tx_request
// and waits for tx_ack to be raised in response.  Then it asserts its desired address,
// length, and addr_incr for one cycle, which completes the request.
interface TxRequest;
    logic [31:0] address;
    logic [7:0] length;
    logic addr_incr;
    logic tx_request;
    logic tx_ack;
    modport client(output address, length, addr_incr, tx_request, input tx_ack);
    modport master(input address, length, addr_incr, tx_request, output tx_ack);
endinterface : TxRequest
