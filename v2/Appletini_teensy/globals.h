#ifndef APPLETINI_GLOBALS_H
#define APPLETINI_GLOBALS_H

#include <QNEthernet.h>

namespace qn = qindesign::network;

// set this to 1 if generating IIGS-mode firmware
#define APPLEIIGS_MODE 0

// set this to the slot the Tini is advertising itself in
#define TINI_SLOT 2

//extern IPAddress ipaddr;
//extern IPAddress netmask;
//extern IPAddress gw;
//extern IPAddress host;

extern unsigned int localPort;  // local port to listen on

// buffers for receiving and sending data
extern uint32_t rx_buf[512];  // buffer to hold incoming packet
extern uint32_t tx_buf[512];  // buffer to hold outgoing (non-bus) packet

#define EVENT_BUF_SZ 256
extern uint32_t event_bufs[2][EVENT_BUF_SZ];
extern uint8_t apple_main_memory[128*1024];
extern uint8_t main_rom[15*256];
extern uint8_t lc_rom[12*1024];
extern EXTMEM uint8_t expanded_memory[16*1024*1024];
extern volatile uint32_t event_buf_index;
extern volatile uint32_t writing_buf;
// An EthernetUDP instance to let us send and receive packets over UDP
extern qindesign::network::EthernetUDP Udp;

extern uint32_t next_tx_seqno;
extern uint32_t prev_addr_event;
extern uint32_t addr_port6_pins;
extern uint32_t data_port6_pins;
extern uint32_t port7_pins;
extern uint32_t port9_pins;
extern uint32_t bus_address;
extern uint32_t prev_bus_address;
extern uint32_t bus_data;
extern int32_t card_shared_owner;
extern bool bus_rw;
extern bool bus_m2sel;
extern bool bus_m2b0;
extern bool prev_bus_rw;
extern bool brain_transplant_mode;
extern volatile bool reset_happened;
extern uint32_t reset_detect_state;
// function pointers for card_io bus events (0xc090-0xc0ff)
extern void (*handle_card_io_event[8]) (uint16_t addr, uint8_t bus_data, bool data_phase);
// function pointers for card page events (0xc100->0xc7ff)
extern void (*handle_card_page_event[8]) (uint16_t addr, uint8_t bus_data, bool data_phase);
// function pointers for card shared range events (0xc800->0xcfff)
extern void (*handle_card_shared_event[8]) (uint16_t addr, uint8_t bus_data, bool data_phase);
// function pointers for soft switches (0xc000-0xc08f)
extern void (*handle_soft_switch[144]) (bool data_phase);
extern void (*memory_page_callback[256]) (uint16_t addr, uint8_t bus_data, bool data_phase);


#define ADDR_RX_ENABLE_MASK (1 << 2)
#define DATA_RX_ENABLE_MASK (1 << 18)

// bus pins, these correspond, in order, to GPIO6.16 through GPIO6.31
#define PIN_B0 19
#define PIN_B1 18
#define PIN_B2 14
#define PIN_B3 15
#define PIN_B4 40
#define PIN_B5 41
#define PIN_B6 17
#define PIN_B7 16
#define PIN_B8 22
#define PIN_B9 23
#define PIN_B10 20
#define PIN_B11 21
#define PIN_B12 38
#define PIN_B13 39
#define PIN_B14 26
#define PIN_B15 27

// rw pin, GPIO6.13
#define PIN_RW 25

// M2SEL/uSYNC, GPIO6.3
#define PIN_M2SEL 0
// M2B0, GPIO6.2
#define PIN_M2B0 1

// TEENSY_IRQ, GPIO7.10
// this is the interrupt pin from the Pico to tell us to snap the address and data latches
#define PIN_TEENSY_IRQ 6

// ADDR_RX_ENABLE, GPIO7.2
// this is the output enable for the ADDR RX latches.
// this enables the latched address onto B0-B15,
// as well as enabling the latched values for RW, M2SEL, and M2B0.
#define PIN_ADDR_RX_ENABLE 11
// DATA_RX_ENABLE, GPIO7.18
// this is the output enable for the DATA RXlatch.
// this puts the latched data byte onto B0-B7.
#define PIN_DATA_RX_ENABLE 36

// ADDR_TX_LATCH, GPIO7.1
// this is the latch enable for the ADDR TX latches.
// when this line transitions High->Low, the ADDR TX latches store
// the current values of B0-B15 and RW
#define PIN_ADDR_TX_LATCH 12
// DATA_TX_LATCH, GPIO7.12
// this is the latch enable for the DATA TX latch.
// when this line transitions High->Low, the DATA TX latch stores
// the current values of B0-B7
#define PIN_DATA_TX_LATCH 32

// TEENSY_EMIT_DATA, GPIO7.19
// This line, active-low, is asserted when the Teensy is intending
// to emit the data byte for the current bus cycle.  The desired byte
// should be stored on the DATA TX latch, and this line asserted low.
// At the next interrupt, the line should be deasserted high.
#define PIN_TEENSY_EMIT_DATA 37

// TEENSY_REQ_DMAOUT, GPIO7.29
// This line, active low, should be asserted when the Teensy intends to
// start performing DMA.  This should be done one cycle in advance before
// actual DMA is requested, so that lower priority cards get advance notice
// that they need to get off the bus.
// this should be deasserted when the desired DMA is complete.
#define PIN_TEENSY_REQ_DMAOUT 34

// TEENSY_REQ_DMA, GPIO9.4
// This line, active high, should be asserted when the Teensy intends to
// start performing DMA.  This should be done the following cycle after asserting
// TEENSY_REQ_DMAOUT.  This does not imply that DMA will be permitted yet!
// The request will not be honored until DMAIN is high, meaning higher
// priority cards are no longer claiming DMA access.  If the DMA_CYCLE_ACTIVE
// line is asserted when the TEENSY_IRQ interrupt occurs, then the current cycle
// should perform the DMA request.
#define PIN_TEENSY_REQ_DMA 2

// DMA_CYCLE_ACTIVE, GPIO7.17
// this line, active high, is asserted when the current bus cycle is allowed
// to fulfill the current DMA request.  The Teensy should sample this line during
// the TEENSY_IRQ interrupt to know if it can do its desired DMA.
#define PIN_DMA_CYCLE_ACTIVE 7

// TEENSY_REQ_IRQ, GPIO7.28
// This line, active low, should be asserted when the teensy wants to request
// an IRQ on the Apple.  There are no particular timing requirements for this line,
// but neither are there requirements for when the Apple interrupt process gets
// around to calling the Teensy's specific handler (or handlers).  Once the request
// is serviced, the line should be deasserted.
#define PIN_TEENSY_REQ_IRQ 35

// INH, GPIO9.5
// This line, active low, should be asserted in the TEENSY_IRQ interrupt when
// the current address read should be inhibited from motherboard memory
// and served by the Teensy instead (by asserting TEENSY_EMIT_DATA as well).
// Otherwise the line should be set as INPUT and left high impedance.
#define PIN_INH 3

// DMA, GPIO9.6
// this line, active low, should NOT be asserted by the Teensy, but only
// used as an advisement that the current bus cycle is a DMA cycle-
// which could be the Teensy's own requested cycle, or another card's.
// Otherwise the line should be set as INPUT and left high impedance.
#define PIN_DMA 4

// RDY, GPIO9.8
// this line, active low, should be asserted in the TEENSY_IRQ interrupt when
// the current address read is intended to be stalled.  It should NOT be
// asserted when the RW line indicates that the current cycle is a write,
// because the 6502 does not respect the line on write cycles.
// Otherwise the line should be set as INPUT and left high impedance.
#define PIN_RDY 5

// RES, GPIO9.31
// this line, active low, should be asserted when the Teensy is invoking
// a reset on the Apple.
// Otherwise the line should be set as INPUT and left high impedance.
#define PIN_RES 29

#endif