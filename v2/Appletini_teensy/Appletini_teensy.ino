#include "globals.h"
#include "memory.h"

IPAddress host;
bool host_found = false;
uint32_t last_host_check = 0;

FASTRUN void emit_byte(uint8_t emitted_byte) {
  if (!bus_rw) {
    return;
  }
  // bring ADDR_RX_ENABLE high to shut it off (is is default bus owner)
  // also set TEENSY_EMIT_DATA low to signal we are emitting this cycle
  // also set DATA_TX_LATCH high to accept data
  GPIO7_DR_SET = ADDR_RX_ENABLE_MASK | DATA_TX_LATCH_MASK;
  GPIO7_DR_CLEAR = TEENSY_EMIT_DATA_MASK;
  // set bus0-7 to output
  GPIO6_GDIR |= BUS_DATA_MASK;
  // put byte onto bus- clear all 8 bits and then set the ones which
  // are set in the emitted byte
  GPIO6_DR_CLEAR = BUS_DATA_MASK;
  GPIO6_DR_SET = BUS_DATA_MASK & (emitted_byte << 16);
  // figure out how long to wait for stability, try discarding a GPIO read or two
  discard_pins = GPIO9_PSR;
  discard_pins = GPIO9_PSR;
  // bring DATA_TX_LATCH low to latch the emitted byte
  GPIO7_DR_CLEAR = DATA_TX_LATCH_MASK;
  // set bus0-7 to input
  GPIO6_GDIR &= ~(BUS_DATA_MASK);
  // return ADDR_RX_ENABLE low for it to be ready for the next address cycle
  GPIO7_DR_CLEAR = ADDR_RX_ENABLE_MASK;
  emitting_byte = true;
}

FASTRUN void inhibit_bus() {
  // set INH output, assert low
  GPIO9_GDIR |= INH_MASK;
  GPIO9_DR_CLEAR |= INH_MASK;
  bus_inhibited = true;
}

inline void determine_bus_cycle_action() {
  if (apple_iigs_mode && bus_m2sel) {
    // not a valid IIgs bus cycle, ignore it
    return;
  }

  if (bus_reset && !prev_bus_reset) {
    reset_soft_switch_state();
  }
  prev_bus_reset = bus_reset;

  uint32_t pre_memory_page = ((uint32_t)bus_rw << 8) + ((bus_address & 0xff00) >> 8);
  AddrCallback addr_cb = *(memory_page_addr_callbacks[pre_memory_page]);
  addr_cb(bus_address, bus_rw);



  if (bus_inhibited) {
    bus_inhibited = false;
  } else {
    // if the bus is not inhibited this cycle, deassert INH in case
    // it had been previously asserted
    GPIO9_GDIR &= ~(INH_MASK);
  }

  if (emitting_byte) {
    emitting_byte = false;
  } else {
    // since we're not emitting here, disable TEENSY_EMIT_DATA in case
    // it had been set the prior phase
    GPIO7_DR_SET = TEENSY_EMIT_DATA_MASK;
  }



  uint32_t post_memory_page = (prev_bus_rw << 8) + ((prev_bus_address & 0xff00) >> 8);
  DataCallback data_cb = *(memory_page_data_callbacks[post_memory_page]);
  data_cb(prev_bus_address, bus_data, prev_bus_rw);
}

// FASTRUN void handle_reset() {
//   reset_happened = false;
//   tx_buf[0] = next_tx_seqno++;
//   tx_buf[1] = 2;  // reset is message type 2
//   Udp.send(host, localPort, (const uint8_t*)tx_buf, 8);
// }


#define IMR_INDEX 5
#define ISR_INDEX 6

FASTRUN void bus_handler() {
  ++bus_counter;

  // clear interrupts.  Since we know that we are the only GPIO
  // interrupt running, and we know it's on GPIO7.10, we can
  // clear just that interrupt register.
  volatile uint32_t* drp = &GPIO7_DR;
  uint32_t interrupt_status = drp[ISR_INDEX] & drp[IMR_INDEX];
  drp[ISR_INDEX] = interrupt_status;

  // snap the inputs.  Each port read takes 8 cycles, writes take only 1.
  // A certain amount of stabilization time is needed after we toggle the
  // RX_ENABLE lines, before we can read GPIO6_PSR a second time to get the
  // latched data byte.  We can spend the delay time by snapping port7 and
  // port9, consuming 16 cycles, which should be sufficient for the bus lines
  // to become stable again.
  // TODO: make sure the optimizer doesn't bone us by reordering the code

  // snap address (ADDR_RX_ENABLE is asserted by default)
  addr_port6_pins = GPIO6_PSR;
  // toggle to DATA_RX_ENABLE
  GPIO7_DR_TOGGLE = ADDR_RX_ENABLE_MASK | DATA_RX_ENABLE_MASK;
  // snap port7 and port9 pins in the middle to allow the bus pins to stabilize
  port7_pins = GPIO7_PSR;
  port9_pins = GPIO9_PSR;
  // snap data
  data_port6_pins = GPIO6_PSR;
  // toggle back to ADDR_RX_ENABLE
  GPIO7_DR_TOGGLE = ADDR_RX_ENABLE_MASK | DATA_RX_ENABLE_MASK;

  bus_data = (data_port6_pins & 0x00ff0000) >> 16;
  bus_address = (addr_port6_pins & 0xffff0000) >> 16;
  // these are set to the offsets they will eventually get used as
  // for event publish, and used in boolean context otherwise
  bus_rw = (addr_port6_pins & (1 << 13)) ? (1 << 24) : 0;
  bus_m2sel = (addr_port6_pins & (1 << 2)) ? (1 << 25) : 0;
  bus_m2b0 = (addr_port6_pins & (1 << 3)) ? (1 << 26) : 0;
  bus_reset = (port9_pins & (1 << 31)) ? (1 << 27) : 0;

  // make whatever decision as to what to do on this bus cycle based on
  // the bus state
  // if (data_completion_callback) {
  //   data_completion_callback(true, bus_data);
  // }
  determine_bus_cycle_action();

  // since it's not time critical, write the event out to the buffer
  // at the end, and format prev_addr_event with this event for the
  // next cycle.
  uint32_t& event = event_bufs[writing_buf][event_buf_index];
  ++event_buf_index;
  if (event_buf_index == EVENT_BUF_SZ) {
    event_buf_index = EVENT_BUF_SZ - 1;
  }
  event = prev_addr_event | bus_data;
  prev_bus_address = bus_address;
  prev_bus_rw = bus_rw;

  prev_addr_event = (bus_address << 8) | bus_rw | bus_m2sel | bus_m2b0 | bus_reset | apple_iigs_mode;
}

// initializing a pin to OUTPUT to a desired initial value
// requires a little setup to avoid glitching the other way.
inline void init_output_pin(uint8_t pin, uint8_t level) {
  if (level == HIGH) {
    pinMode(pin, INPUT_PULLUP);
    pinMode(pin, OUTPUT);
    digitalWrite(pin, HIGH);
  } else {
    pinMode(pin, INPUT);
    pinMode(pin, OUTPUT);
    digitalWrite(pin, LOW);
  }
}

// handler for card memory slots where we are not configured to respond
void card_null_handler(uint16_t addr, uint8_t data, bool data_phase) {
  return;
}

void tini_io_event(uint16_t addr, uint8_t data, bool data_phase) {}

void tini_page_event(uint16_t addr, uint8_t data, bool data_phase) {}

void tini_shared_event(uint16_t addr, uint8_t data, bool data_phase) {}

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
  // We have ADDR_RX_ENABLE asserted normally, so that
  // the bus interrupt can snap the address lines immediately.
  // other bus actions will deassert ADDR_RX_ENABLE but we return
  // to a default state of ADDR_RX_ENABLE afterward.
  init_output_pin(PIN_ADDR_RX_ENABLE, LOW);
  init_output_pin(PIN_DATA_RX_ENABLE, HIGH);

  // ADDR_TX_LATCH
  // DATA_TX_LATCH
  // pins to tell the TX latches to retain their latched values.
  // Always outputs, init low
  init_output_pin(PIN_ADDR_TX_LATCH, LOW);
  init_output_pin(PIN_DATA_TX_LATCH, LOW);

  // TEENSY_EMIT_DATA
  // pin to tell Pico that the current bus cycle should emit the latched data byte.
  // always outputs, init high
  init_output_pin(PIN_TEENSY_EMIT_DATA, HIGH);

  // TEENSY_REQ_DMAOUT
  // pin to pre-request DMA.  This should be asserted the cycle before beginning DMA request.
  // always outputs, init high
  init_output_pin(PIN_TEENSY_REQ_DMAOUT, HIGH);

  // DMA_CYCLE_ACTIVE
  // pin indicating whether the current bus cycle is a DMA cycle under Teensy control.
  // always input
  pinMode(PIN_DMA_CYCLE_ACTIVE, INPUT);

  // TEENSY_REQ_IRQ
  // pin to request apple IRQ assert.
  // always output, init high
  init_output_pin(PIN_TEENSY_REQ_IRQ, HIGH);

  // INH
  // pin to instruct Apple that the current cycle is inhibiting the motherboard memory.
  // defaults to input (pin floating high-impedance), and is asserted by setting the pin to output low
  pinMode(PIN_INH, INPUT);

  // DMA
  // never actively controlled by the Teensy, but allows the Teensy to see when DMA is occurring
  // other than when it is doing the DMA itself.
  // set to input (pin floating high-impedance).
  pinMode(PIN_DMA, INPUT);

  // RDY
  // pin to instruct Apple to stall this cycle's bus read event.
  // defaults to input (pin floating high-impedance), and is asserted by setting the pin to output low
  pinMode(PIN_RDY, INPUT);

  // RES
  // pin to force an Apple reboot.
  // defaults to input (pin floating high-impedance), and is asserted by setting the pin to output low
  pinMode(PIN_RES, INPUT);

  // TEENSY_IRQ, the pin we get address-phase interrupts from the Pico.  Always an input.
  pinMode(PIN_TEENSY_IRQ, INPUT);





  // start the Ethernet
  qn::Ethernet.begin();

  // Serial.begin(9600);
  // while (!Serial) {
  //   // wait for connect
  // }
  // if (CrashReport) {
  //   Serial.print(CrashReport);
  //   delay(5000);
  // }

  // Serial.println("initializing");
  
  initialize_memory_page_handlers();
  initialize_soft_switch_handlers();

  cli();
  // let the lib code in attachInterrupt do its config details
  attachInterrupt(digitalPinToInterrupt(PIN_TEENSY_IRQ), bus_handler, FALLING);

  // override the vector for GPIO directly to our handler to skip dispatching
  attachInterruptVector(IRQ_GPIO6789, &bus_handler);
  sei();

  // demote any top-priority interrupts and set the GPIO interrupt
  // to top priority, so that the bus handler preempts everything else.
  // This minimizes jitter to just the periods when interrupts are disabled.
  for (int i = 0; i < NVIC_NUM_INTERRUPTS; ++i) {
    uint32_t prio = NVIC_GET_PRIORITY(i);
    if (prio < 16) {
      NVIC_SET_PRIORITY(i, 16);
    }
  }
  NVIC_SET_PRIORITY(IRQ_GPIO6789, 0);
}

void loop() {
  auto now = millis();
  if (!host_found && (now > last_host_check + 5000)) {
    // Serial.println("looking up host");
    host_found = qn::Ethernet.hostByName("raspberrypi.local", host);
    // if (host_found) {
    //   Serial.println("host found");
    // } else {
    //   Serial.println("host not found");
    // }
  }
  if (!host_found) {
    return;
  }

  // if (reset_happened) {
  //   // Serial.println("reset detected");
  //   handle_reset();
  //   // Serial.println("reset notification sent");
  // }

  //int packetSize = Udp.parsePacket();
  Udp.parsePacket();
  // ignore them for now

  // swap buffers and get buffer length
  cli();
  uint8_t send_index = event_buf_index;
  uint8_t send_buf;
  if (send_index > 200) {
    send_buf = writing_buf;
    writing_buf = !writing_buf;
    event_buf_index = 2;
  } else {
    send_index = 0;
  }
  sei();
  // if ((bus_counter % 1024) == 0) {
  //   Serial.println(bus_counter);
  // }

  if (send_index) {
    uint32_t* event_buf = event_bufs[send_buf];
    event_buf[0] = next_tx_seqno++;
    event_buf[1] = 0;
    Udp.send(host, localPort, (const uint8_t*)event_buf, send_index * 4);
  }
}
