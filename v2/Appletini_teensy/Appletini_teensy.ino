#include <QNEthernet.h>

IPAddress ipaddr(192, 168, 155, 251);
IPAddress netmask(255, 255, 255, 0);
IPAddress gw(192, 168, 155, 1);
IPAddress host(192, 168, 155, 250);

namespace qn = qindesign::network;

unsigned int localPort = 8080;  // local port to listen on

// buffers for receiving and sending data
uint32_t rx_buf[512];  // buffer to hold incoming packet
uint32_t tx_buf[512];  // buffer to hold outgoing (non-bus) packet

// An EthernetUDP instance to let us send and receive packets over UDP
qn::EthernetUDP Udp;


// bus pins, these correspond, in order, to GPIO6.16 through GPIO6.31
#define PIN_B0  19
#define PIN_B1  18
#define PIN_B2  14
#define PIN_B3  15
#define PIN_B4  40
#define PIN_B5  41
#define PIN_B6  17
#define PIN_B7  16
#define PIN_B8  22
#define PIN_B9  23
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

// TEENSY_IRQ, GPIO7.16
// this is the interrupt pin from the Pico to tell us to snap the address and data latches
#define PIN_TEENSY_IRQ 8

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

void setup() {
  for (int i = 0; i < 42; ++i) {
    pinMode(i, INPUT_DISABLE);
  }

  // bus0-15. Defined initially as inputs, but will be set to outputs briefly when loading the TX addr and data latches
  pinMode(PIN_B0, INPUT);
  pinMode(PIN_B1, INPUT);
  pinMode(PIN_B2, INPUT);
  pinMode(PIN_B3, INPUT);
  pinMode(PIN_B4, INPUT);
  pinMode(PIN_B5, INPUT);
  pinMode(PIN_B6, INPUT);
  pinMode(PIN_B7, INPUT);
  pinMode(PIN_B8, INPUT);
  pinMode(PIN_B9, INPUT);
  pinMode(PIN_B10, INPUT);
  pinMode(PIN_B11, INPUT);
  pinMode(PIN_B12, INPUT);
  pinMode(PIN_B13, INPUT);
  pinMode(PIN_B14, INPUT);
  pinMode(PIN_B15, INPUT);

  // RW, also initially input, but set to output briefly when loading the TX addr latches
  pinMode(PIN_RW, INPUT);

  // M2SEL on IIgs, uSYNC on IIe.  Always an input.
  pinMode(PIN_M2SEL, INPUT);
  // M2B0 on IIgs, not used on IIe. Always an input.
  pinMode(PIN_M2B0, INPUT);

  // ADDR_RX_ENABLE
  // DATA_RX_ENABLE
  // pins to enable latched address and data onto the bus.
  // Always outputs, init high
  pinMode(PIN_ADDR_RX_ENABLE, INPUT_PULLUP);
  pinMode(PIN_ADDR_RX_ENABLE, OUTPUT);
  digitalWrite(PIN_ADDR_RX_ENABLE, HIGH);
  pinMode(PIN_DATA_RX_ENABLE, INPUT_PULLUP);
  pinMode(PIN_DATA_RX_ENABLE, OUTPUT);
  digitalWrite(PIN_DATA_RX_ENABLE, HIGH);

  // ADDR_TX_LATCH
  // DATA_TX_LATCH
  // pins to tell the TX latches to store the current values on their lines.
  // Always outputs, init high
  pinMode(PIN_ADDR_TX_LATCH, INPUT_PULLUP);
  pinMode(PIN_ADDR_TX_LATCH, OUTPUT);
  digitalWrite(PIN_ADDR_TX_LATCH, HIGH);
  pinMode(PIN_DATA_TX_LATCH, INPUT_PULLUP);
  pinMode(PIN_DATA_TX_LATCH, OUTPUT);
  digitalWrite(PIN_DATA_TX_LATCH, HIGH);





  // TEENSY_IRQ, the pin we get address-phase interrupts from the Pico.  Always an input.
  pinMode(PIN_TEENSY_IRQ, INPUT);

  // let the lib code in attachInterrupt do its config details
  attachInterrupt(digitalPinToInterrupt(30), bus_handler, FALLING);
}

void loop() {
  if (reset_happened) {
    handle_reset();
  }

  // swap buffers and get buffer length
  cli();
  uint8_t send_index = event_buf_index;
  uint8_t send_buf;
  if (send_index > 64) {
    send_buf = writing_buf;
    writing_buf = !writing_buf;
    event_buf_index = 2;
  } else {
    send_index = 0;
  }
  sei();

  if (send_index) {
    uint32_t* event_buf = event_bufs[send_buf];
    event_buf[0] = next_tx_seqno++;
    event_buf[1] = 0;
    Udp.send(host, localPort, (const uint8_t*)event_buf, send_index * 4);
  }
}
