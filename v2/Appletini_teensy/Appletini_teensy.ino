#include "globals.h"
#include "soft_switches.h"

FASTRUN void complete_main_rom_event(bool unused, uint32_t data) {
  main_rom[bus_address - 0xc100] = data;
}

FASTRUN void store_data_callback(bool data_phase, uint32_t data) {
  int32_t offset = 0;
  if (prev_bus_address < 0x0200) {
    // only switch that matters here is ALTZP=
    if (ss_mode & MF_ALTZP) {
      offset = 0x10000;
    }
  } else if (prev_bus_address < 0xc000) {
    if (prev_bus_rw) {
      if (ss_mode & MF_AUXREAD) {
        offset = 0x10000;
      } 
    } else {
      if (ss_mode & MF_AUXWRITE) {
        offset = 0x10000;
      }
    }
    // 80store overrides AUXREAD/AUXWRITE
    if (ss_mode & MF_80STORE) {
      if (prev_bus_address >= 0x0400 && prev_bus_address < 0x0800) {
        if (ss_mode & MF_PAGE2) {
          offset = 0x10000;
        } else {
          offset = 0;
        }
      }
      if (ss_mode & MF_HIRES) {
        if (prev_bus_address >= 0x2000 && prev_bus_address < 0x4000) {
          if (ss_mode & MF_PAGE2) {
            offset = 0x10000;
          } else {
            offset = 0;
          }
        }
      }
    }
  } else if (ss_mode & MF_HIGHRAM) {
    if (ss_mode & MF_ALTZP) {
      offset = 0x10000;
    }
    if (ss_mode & MF_BANK2) {
      // bank 2 is tucked back where 0xc000 would be
      offset -= 0x1000;
    }
    if (!prev_bus_rw) {
      if ( (ss_mode & MF_WRITERAM) == 0) {
        //ignoring writes to RAM
        return;
      }
    }
  } else {
    // addressing high rom
    if (!prev_bus_rw) {
      // ignore writes to ROM
      return;
    }
    // store the value in ROM space if it's a read, ignore if it's a write
    lc_rom[prev_bus_address - 0xc000] = (uint8_t)data;
    return;
  }
  apple_main_memory[prev_bus_address+offset] = (uint8_t)data;

}

inline void handle_main_rom_event() {
  if (!bus_rw) {
    return;
  }
  data_completion_callback = &complete_main_rom_event;
}

inline bool check_cxxx_range() {
  if ((bus_address & 0xff00) != 0xc000) {
    return false;
  }
  if (bus_address < 0xc090) {
    uint32_t switch_byte = (bus_address & 0x00ff);
    (*(handle_soft_switch[switch_byte]))(false, 0);
    return true;
  }
  if (bus_address < 0xc100) {
    uint32_t slot_number = (bus_address & 0x0070) >> 8;
    uint32_t slot_byte = (bus_address & 0x000f);
    (*(handle_card_io_event[slot_number]))(slot_byte);
    return true;
  }
  if (bus_address < 0xc800) {
    uint32_t slot_number = (bus_address & 0x0700) >> 16;
    uint32_t slot_byte = (bus_address & 0x00ff);
    bool is_slot_access = false;
    if (slot_number == 3) {
      if ((ss_mode & MF_SLOTC3ROM) == 0) {
        ss_mode |= MF_INTC8ROM;
      }
      if ( !(ss_mode & MF_INTC8ROM) && (ss_mode & MF_SLOTC3ROM)) {
        is_slot_access = true;
      }
    } else {
      is_slot_access = ss_mode & MF_INTC8ROM;
    }
    if (is_slot_access) {
      card_shared_owner = slot_number;
      (*(handle_card_page_event)[slot_number])(slot_byte);
    } else {
      handle_main_rom_event();
    }
    return true;
  }
  if (bus_address == 0xcfff) {
    card_shared_owner = 0;
    ss_mode &= ~MF_INTC8ROM;
  }
  uint32_t slot_byte = (bus_address & 0x07ff);
  if (ss_mode & MF_INTC8ROM) {
    handle_main_rom_event();
  } else {
    (*handle_card_shared_event[card_shared_owner])(slot_byte);
  }
  return true;
}

inline void determine_bus_cycle_action() {
  if (APPLEIIGS_MODE && bus_m2sel) {
    // not a valid IIgs bus cycle, ignore it
    return;
  }
  // if (!check_cxxx_range()) {
  //   data_completion_callback = &store_data_callback;
  // }

  // check for reset sequence
  // stolen from markadev/AppleII-VGA,
  // which was stolen from how the IIe IOU chip does reset detect
  if ((bus_address & 0xff00) == 0x0100) {
    if (reset_detect_state < 3) {
      ++reset_detect_state;
    } else if (reset_detect_state > 3) {
      reset_detect_state = 1;
    }
  } else if ((reset_detect_state == 3) && (bus_address == 0xfffc)) {
    reset_detect_state = 4;
  } else if ((reset_detect_state == 4) && (bus_address == 0xfffd)) {
    reset_happened = true;
    reset_detect_state = 0;
  } else {
    reset_detect_state = 0;
  }

}

FASTRUN void handle_reset() {
  reset_happened = false;
  tx_buf[0] = next_tx_seqno++;
  tx_buf[1] = 2;  // reset is message type 2
  Udp.send(host, localPort, (const uint8_t*)tx_buf, 8);
}


#define IMR_INDEX 5
#define ISR_INDEX 6

uint64_t bus_counter = 0;

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
  bus_rw = (addr_port6_pins & (1 << 13)) != 0;
  bus_m2sel = (addr_port6_pins & (1 << 2)) != 0;
  bus_m2b0 = (addr_port6_pins & (1 << 3)) != 0;

  // make whatever decision as to what to do on this bus cycle based on
  // the bus state
  if (data_completion_callback) {
    data_completion_callback(true, bus_data);
  }
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

  prev_addr_event = (bus_address << 8) | (bus_rw << 24) | (bus_m2sel << 25) | (bus_m2b0 << 26) | (APPLEIIGS_MODE << 31);

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
void card_null_handler(uint32_t addr_byte) {
  return;
}

void setup() {

  // initialize card handlers
  for (int i = 0; i < 8; ++i) {
    handle_card_io_event[i] = &card_null_handler;
    handle_card_page_event[i] = &card_null_handler;
    handle_card_shared_event[i] = &card_null_handler;
  }
  
  initialize_soft_switch_handlers();


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
  // pins to tell the TX latches to store the current values on their lines.
  // Always outputs, init high
  init_output_pin(PIN_ADDR_TX_LATCH, HIGH);
  init_output_pin(PIN_DATA_TX_LATCH, HIGH);

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

  // let the lib code in attachInterrupt do its config details
  attachInterrupt(digitalPinToInterrupt(PIN_TEENSY_IRQ), bus_handler, FALLING);

  // override the vector for GPIO directly to our handler to skip dispatching
  attachInterruptVector(IRQ_GPIO6789, &bus_handler);

  // start the Ethernet
  qn::Ethernet.begin(ipaddr, netmask, gw);

  // Serial.begin(9600);
  // while (!Serial) {
  //   // wait for connect
  // }
  // if (CrashReport) {
  //   Serial.print(CrashReport);
  //   delay(5000);
  // }

  // Serial.println("initializing");

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
  if (reset_happened) {
    // Serial.println("reset detected");
    handle_reset();
    // Serial.println("reset notification sent");
  }

  int packetSize = Udp.parsePacket();
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
