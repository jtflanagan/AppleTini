/*
 AppleTini:
 This installs an ISR which watches for two control pins: AddressReady and
 DataReady, waiting for a negative edge transition on each.

 When AddressReady signals, the ISR reads the 16 bits of Apple bus address,
 and the RW bit, and saves them for the DataReady phase.  In addition, if
 the RW flag indicates a read, it examines the address and decides whether
 to emit the byte read, or not.  It sets the active-low OUT_D_REQ pin
 appropriately, and puts the emitted byte onto the 8 data-out pins.

 When DataReady signals, the ISR reads the 8 bits of Apple bus data (which
 if we emitted a byte on the previous AddressReady phase, will be the same
 byte we wrote out), and pushes the entire 25 bit bus event (16 address, RW,
 8 data) to a ring buffer for the main loop to pick up and write out over
 UDP.

 */

#include <QNEthernet.h>


// Enter a MAC address and IP address for your controller below.
// The IP address will be dependent on your local network:
// byte mac[] = {
//   0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED
// };
IPAddress ipaddr(192, 168, 155, 251);
IPAddress netmask(255, 255, 255, 0);
IPAddress gw(192, 168, 155, 1);
IPAddress host(192, 168, 155, 250);

namespace qn = qindesign::network;

unsigned int localPort = 8080;  // local port to listen on

// buffers for receiving and sending data
uint8_t packetBuffer[1500];  // buffer to hold incoming packet,
//char ReplyBuffer[] = "acknowledged";        // a string to send back

// An EthernetUDP instance to let us send and receive packets over UDP
qn::EthernetUDP Udp;

uint32_t last_micros = 0;
uint8_t tx_buf[2048];
uint8_t* p = tx_buf;
uint16_t prev_tx_address = 0;
uint32_t next_tx_seqno = 0;
uint16_t bus_address = 0;
uint8_t bus_user1 = true;
uint8_t bus_rw = true;
uint8_t bus_m2b0 = true;
uint8_t bus_usync = true;
bool io_strobe = false;
uint8_t iosel_memory[256];
uint8_t rom_strobe_memory[2048];
uint32_t event_ring[256];
uint8_t event_ring_begin = 0;
volatile uint8_t event_ring_end = 0;
uint8_t slotc3rom = 0;
uint8_t intcxrom = 0;
uint8_t appletini_dev_enabled = 0;
volatile bool reset_occurred = false;
bool reset_pin = true;
uint8_t result_buf[256];
uint8_t result_len = 0;
uint8_t* result_ptr = result_buf;

struct time_struct {
  int32_t epoch_sec;
  int32_t millis;
} last_timestamp;

uint32_t last_timestamp_reference = 0;

#define APPLETINI_SLOT 2

#define DEVSEL_RANGE (0xc080 + (APPLETINI_SLOT << 4))
#define DEVSEL_MASK 0xfff0
#define IOSEL_RANGE (0xc000 + (APPLETINI_SLOT << 8))
#define IOSEL_MASK 0xff00
#define STROBE_RANGE 0xc800
#define STROBE_MASK 0xf800

#define CLRINTCXROM 0xc006
#define SETINTCXROM 0xc007
#define CLRSLOTC3ROM 0xc00a
#define SETSLOTC3ROM 0xc00b
#define RDCXROM 0xc015
#define RDC3ROM 0xc017

// data bits are scattered on GPIO7 register.
// the two clumps of 4 at 0-3 and 16-19 are the
// low and high half of the data byte.
#define DATA_OUT_MASK 0x000f000f
// OUT_D_REQ is on GPIO8, bit 22
#define OUT_D_REQ_MASK 0x00400000
// RDY_REQ is on GPIO7, bit 28
#define RDY_REQ_MASK 0x10000000
// INH_REQ is on GPIO7, bit 29
#define INH_REQ_MASK 0x20000000
// IRQ is on GPIO6, bit 02
#define IRQ_MASK 0x00000004
// INTOUT is on GPIO6, bit 03
#define INTOUT_MASK 0x00000008

FASTRUN static inline void check_soft_switches(uint8_t data) {
  if ((bus_address & 0xf000) == 0xc000) {
    if (bus_rw) {
      // read switches of interest
      if (appletini_dev_enabled && (bus_address & IOSEL_MASK) == IOSEL_RANGE) {
        io_strobe = true;
      } else if (bus_address == 0xcfff) {
        io_strobe = false;
      } else if (bus_address == RDCXROM) {
        intcxrom = (data & 0x80) != 0;
#if APPLETINI_SLOT == 3
      } else if (bus_address == RDC3ROM) {
        slotc3rom = (data & 0x80) != 0;
        appletini_dev_enabled = !slotc3rom || !intcxrom;
#else
        appletini_dev_enabled = !intcxrom;
#endif
      }
    } else {
      if ((bus_address & DEVSEL_MASK) == DEVSEL_RANGE) {
        handle_devsel_address_write(bus_address, data);
      }
      if (bus_address == CLRINTCXROM) {
        //Serial.println("CLRINTCXROM");
        intcxrom = false;
      }
      if (bus_address == SETINTCXROM) {
        //Serial.println("SETINTCXROM");
        intcxrom = true;
      }
#if APPLETINI_SLOT == 3
      if (bus_address == CLRSLOTC3ROM) {
        //Serial.println("CLRSLOTC3ROM");
        slotc3rom = false;
      }
      if (bus_address == SETSLOTC3ROM) {
        //Serial.println("SETSLOTC3ROM");
        slotc3rom = true;
      }
      appletini_dev_enabled = !slotc3rom || !intcxrom;
#else
      appletini_dev_enabled = !intcxrom;
#endif
      //Serial.print("appletini_dev_enabled:");
      //Serial.println(appletini_dev_enabled);
    }
  }
}

FASTRUN static inline void handle_reset() {
  // Serial.println("Reset occurred");
  intcxrom = false;
  slotc3rom = false;
  if (p != tx_buf) {
    // write out the current packet in progress immediately
    Udp.beginPacket(host, localPort);
    Udp.write(tx_buf, p - tx_buf);
    Udp.endPacket();
    p = tx_buf;
  }
  *p++ = next_tx_seqno & 0xff;
  *p++ = (next_tx_seqno >> 8) & 0xff;
  *p++ = (next_tx_seqno >> 16) & 0xff;
  *p++ = (next_tx_seqno >> 24) & 0xff;
  *p++ = 2;  // reset is message type 2
  Udp.beginPacket(host, localPort);
  Udp.write(tx_buf, p - tx_buf);
  Udp.endPacket();
  p = tx_buf;
}

FASTRUN static inline uint8_t handle_devsel_address_read(uint16_t address) {
  //Serial.print("handledevsel:");
  //Serial.println(address);
  uint8_t val = address & 0x0f;
  switch (val) {
    // currently only handle result address read in byte 3
    case 3: break;
    default: return val;
  }
  if (result_ptr == result_buf + result_len) {
    return 0;
  }
  val = *result_ptr++;
  return val;
}

FASTRUN static inline void handle_card_command(uint8_t val) {
  //Serial.print("card command:");
  //Serial.print(val);
  switch (val) {
    case 0:
      {
        //Serial.println("sending time");
        uint32_t now = millis();
        int32_t adj = now - last_timestamp_reference;
        last_timestamp_reference = now;
        int32_t adj_millis = last_timestamp.millis + adj;
        // compiler might be smart enough to optimize this
        // automatically but being explicit using div()
        ldiv_t ret = ldiv(adj_millis, (int32_t)1000);
        last_timestamp.epoch_sec += ret.quot;
        last_timestamp.millis = ret.rem;
        result_ptr = result_buf;
        result_len = 7;
        result_buf[0] = result_len;
        result_buf[1] = last_timestamp.epoch_sec & 0xff;
        result_buf[2] = (last_timestamp.epoch_sec >> 8) & 0xff;
        result_buf[3] = (last_timestamp.epoch_sec >> 16) & 0xff;
        result_buf[4] = (last_timestamp.epoch_sec >> 24) & 0xff;
        result_buf[5] = last_timestamp.millis & 0xff;
        result_buf[6] = (last_timestamp.millis >> 8) & 0xff;
      }
      break;
    default: break;
  }
}

FASTRUN static inline void handle_devsel_address_write(uint16_t address, uint8_t val) {
  uint8_t addr_val = address & 0x0f;
  switch (addr_val) {
    // currently only handle writes to card command address in byte 2
    case 2: handle_card_command(val); break;
    default: break;
  }
}

FASTRUN static inline void do_address_phase(uint32_t gpio6_pins, uint32_t gpio9_pins) {
  // first disable OUT_D_REQ pin (set high, as it is active-low)
  GPIO8_DR_SET = OUT_D_REQ_MASK;

  // we arranged for the address pins to be the contiguous set of bits 16-31
  bus_address = (gpio6_pins >> 16) & 0xffff;
  // toggle io_strobe if needed
  bus_rw = (gpio9_pins >> 8) & 0x01;
  bus_m2b0 = (gpio6_pins >> 12) & 0x01;
  bus_usync = (gpio6_pins >> 13) & 0x01;
  // // forward INTIN to INTOUT
  // // TODO- if we ever do our own interrupt, we would need to flag it
  // // Thinking more about this, we should be doing this in hardware, auto
  // // forwarding instantly by default and only pulling it down if we decide
  // // it's safe because INTIN is high, and we want to do an interrupt
  // uint32_t intin = (gpio9_pins >> 4) & 0x01;
  // if (intin) {
  //   GPIO6_DR_SET = INTOUT_MASK;
  // } else {
  //   GPIO6_DR_CLEAR = INTOUT_MASK;
  // }
  // check if this is a read that we will service
  if (bus_rw && ((bus_address & DEVSEL_MASK) == DEVSEL_RANGE)) {
    uint8_t data_byte = handle_devsel_address_read(bus_address);
    //Serial.print("emit:");
    //Serial.print(bus_address);
    //Serial.print(":");
    //Serial.println(data_byte);
    uint32_t data_register = ((uint32_t)data_byte & 0xf0) << 12;
    data_register |= data_byte & 0x0f;
    GPIO7_DR_CLEAR = DATA_OUT_MASK;
    GPIO7_DR_SET = data_register;
  } else if (appletini_dev_enabled && bus_rw) {
    uint8_t data_byte;
    bool emit = true;
    if ((bus_address & IOSEL_MASK) == IOSEL_RANGE) {
      data_byte = iosel_memory[bus_address & 0x00ff];
    } else if (io_strobe && ((bus_address & STROBE_MASK) == STROBE_RANGE)) {
      data_byte = rom_strobe_memory[bus_address & 0x7ff];
    } else {
      emit = false;
    }
    if (emit) {
      //Serial.print("emit:");
      //Serial.print(bus_address);
      //Serial.print(":");
      //Serial.println(data_byte);
      uint32_t data_register = ((uint32_t)data_byte & 0xf0) << 12;
      data_register |= data_byte & 0x0f;
      GPIO7_DR_CLEAR = DATA_OUT_MASK;
      GPIO7_DR_SET = data_register;
      // clear OUT_D_REQ (active low, to indicate byte write) 
      GPIO8_DR_CLEAR = OUT_D_REQ_MASK;
    }
  }
}


FASTRUN static inline void do_data_phase(uint32_t port6_pins, uint32_t port9_pins) {
  // reset pin on GPIO9 06, and handling reset not time critical so do in data phase
  bool new_reset_pin = (port9_pins >> 6) & 0x01;
  if (new_reset_pin != reset_pin) {
    reset_pin = new_reset_pin;
    if (reset_pin == 0) {
      reset_occurred = true;
    }
  }
  uint8_t data = (port6_pins >> 16) & 0xff;
  check_soft_switches(data);

  uint32_t event = data;
  event |= (uint32_t)bus_address << 8;
  if (bus_rw) {
    event |= 1 << 24;
  }
  event_ring[event_ring_end++] = event;
}

#define IMR_INDEX 5
#define ISR_INDEX 6

FASTRUN void bus_handler() {
  // snap the pins immediately
  uint32_t port6_pins = GPIO6_PSR;  // address/data, and M2B0/uSYNC
  uint32_t port7_pins = GPIO7_PSR;  // PHI0 is on GPIO7 12
  uint32_t port9_pins = GPIO9_PSR;
  // clear interrupts.  We are doing it slightly faster than the
  // stock interrupt code, because we know we are the only gpio
  // interrupt running, and we are only on GPIO8 23 (TEENSY_IRQ).
  volatile uint32_t* drp = &GPIO8_DR;
  uint32_t interrupt_status = drp[ISR_INDEX] & drp[IMR_INDEX];
  drp[ISR_INDEX] = interrupt_status;  // this clears the interrupt

  // PHI0 (pin 32, GPIO7 bit 12)
  if (port7_pins & CORE_PIN32_BITMASK) {
    //Serial.println("data");
    do_data_phase(port6_pins, port9_pins);
  } else {
    //Serial.println("addr");
    do_address_phase(port6_pins, port9_pins);
  }
  asm("dsb");  // memory barrier to flush everything
}


void setup() {
  // You can use Ethernet.init(pin) to configure the CS pin
  //Ethernet.init(10);  // Most Arduino shields
  //Ethernet.init(5);   // MKR ETH shield
  //Ethernet.init(0);   // Teensy 2.0
  //Ethernet.init(20);  // Teensy++ 2.0
  //Ethernet.init(15);  // ESP8266 with Adafruit Featherwing Ethernet
  //Ethernet.init(33);  // ESP32 with Adafruit Featherwing Ethernet

  // set pin directions
  // disable all pins
  for (int i = 0; i < 42; ++i) {
    pinMode(i, INPUT_DISABLE);
  }

  // addr0-16, numbers are wacky because the pin->register bit
  // mapping is totally wacky
  // these are GPIO6 16-31
  pinMode(19, INPUT);
  pinMode(18, INPUT);
  pinMode(14, INPUT);
  pinMode(15, INPUT);
  pinMode(40, INPUT);
  pinMode(41, INPUT);
  pinMode(17, INPUT);
  pinMode(16, INPUT);
  pinMode(22, INPUT);
  pinMode(23, INPUT);
  pinMode(20, INPUT);
  pinMode(21, INPUT);
  pinMode(38, INPUT);
  pinMode(39, INPUT);
  pinMode(26, INPUT);
  pinMode(27, INPUT);

  // misc inputs
  // INTIN
  pinMode(2, INPUT); // GPIO9 04
  // DMA
  pinMode(3, INPUT); // GPIO9 05
  // RES
  pinMode(4, INPUT); // GPIO9 06
  // RW
  pinMode(5, INPUT); // GPIO9 08 (yes, it skips 07)
  // M2B0
  pinMode(24, INPUT); // GPIO6 12
  // uSYNC
  pinMode(25, INPUT); // GPIO6 13
  // TEENSY_IRQ
  pinMode(30, INPUT); // GPIO8 23
  // PHI0
  pinMode(32, INPUT); // GPIO7 12
  
  // misc outputs
  // INTOUT
  // default INTOUT high, but ultimately it will be set to (INTIN & IRQ)
  pinMode(0, INPUT);  // disabled
  //pinMode(0, OUTPUT); // GPIO6 03
  //digitalWrite(0, HIGH);
  // IRQ
  // default IRQ high, we can pull it low to request bus interrupt
  pinMode(1, INPUT); // disabled
  //pinMode(1, OUTPUT); // GPIO6 02
  //digitalWrite(1, HIGH);
  // OUT_D_REQ
  // default high, we pull low when we want to put a byte on the bus
  pinMode(31, INPUT); // disabled
  //pinMode(31, OUTPUT); // GPIO8 22
  //digitalWrite(31, HIGH);
  // INH_REQ
  // default high, we pull low when we want to inhibit (and serve) memory
  pinMode(32, INPUT); // disabled
  //pinMode(34, OUTPUT); // GPIO7 29
  //digitalWrite(34, HIGH);
  // RDY_REQ
  // default high, we pull low when we want to stall the bus
  pinMode(35, INPUT); // disabled
  //pinMode(35, OUTPUT); // GPIO7 28
  //digitalWrite(35, HIGH);

  // data_out0-8
  pinMode(10, OUTPUT); // GPIO7 00
  pinMode(12, OUTPUT); // GPIO7 01
  pinMode(11, OUTPUT); // GPIO7 02
  pinMode(13, OUTPUT); // GPIO7 03
  pinMode(8, OUTPUT);  // GPIO7 16
  pinMode(7, OUTPUT);  // GPIO7 17
  pinMode(36, OUTPUT); // GPIO7 18
  pinMode(37, OUTPUT); // GPIO7 19

  // let the lib code in attachInterrupt do its config details
  attachInterrupt(digitalPinToInterrupt(30), bus_handler, FALLING);

  // override the vector for gpio directly to our handler to
  // skip dispatching
  attachInterruptVector(IRQ_GPIO6789, &bus_handler);

  // start the Ethernet
  qn::Ethernet.begin(ipaddr, netmask, gw);

  // Open serial communications and wait for port to open:
  //Serial.begin(9600);
  //while (!Serial) {
  //  ;  // wait for serial port to connect. Needed for native USB port only
  //}

  //Serial.println("starting udp");
  // // start UDP
  //Udp.begin(localPort);
  //Serial.println("started udp");

  // set GPIO priority to highest priority, as
  // handling the bus is hard-realtime
  for (int i = 0; i < NVIC_NUM_INTERRUPTS; ++i) {
    uint32_t prio = NVIC_GET_PRIORITY(i);
    if (prio < 16) {
      // Serial.print("interrupt prio 0:");
      // Serial.println(i);
      NVIC_SET_PRIORITY(i, 16);
    }
    NVIC_SET_PRIORITY(IRQ_GPIO6789, 0);
  }
}

void handle_echo(uint8_t* buf, int size) {
  memcpy(p, buf, size);
  p += size;
}

void handle_timestamp(uint8_t* buf, int size) {
  last_timestamp_reference = millis();
  memcpy((void*)&last_timestamp, (void*)buf, sizeof(last_timestamp));
  // Serial.print(last_timestamp.epoch_sec);
  // Serial.print(".");
  // Serial.println(last_timestamp.millis);
}

void handle_rx_packet(uint8_t* buf, int size) {
  if (p != tx_buf) {
    // write out the current packet in progress immediately
    Udp.beginPacket(host, localPort);
    Udp.write(tx_buf, p - tx_buf);
    Udp.endPacket();
    p = tx_buf;
  }
  ++next_tx_seqno;
  *p++ = next_tx_seqno & 0xff;
  *p++ = (next_tx_seqno >> 8) & 0xff;
  *p++ = (next_tx_seqno >> 16) & 0xff;
  *p++ = (next_tx_seqno >> 24) & 0xff;
  // get the msg type and echo back the rx seqno
  uint8_t msg_type = buf[4];
  *p++ = msg_type;
  *p++ = buf[0];
  *p++ = buf[1];
  *p++ = buf[2];
  *p++ = buf[3];
  buf += 5;
  switch (msg_type) {
    case 1:
      handle_echo(buf, size - 5);
      break;
    case 2:
      // reset message, should never be getting it
      break;
    case 3:
      // timestamp message
      handle_timestamp(buf, size - 5);
    default:
      break;
  }
  Udp.beginPacket(host, localPort);
  Udp.write(tx_buf, p - tx_buf);
  Udp.endPacket();
  p = tx_buf;
}

void loop() {
  // if a reset occurred, process it
  if (reset_occurred) {
    reset_occurred = false;
    handle_reset();
  }
  // if there's data available, read a packet
  int packetSize = Udp.parsePacket();
  if (packetSize >= 0) {
    // read the packet into packetBufffer
    Udp.read(packetBuffer, packetSize);
    handle_rx_packet(packetBuffer, packetSize);
  }
  // make safe nonvolatile copy of event_ring_end for processing
  //cli();
  uint32_t ring_end = event_ring_end;
  //sei();
  uint32_t buffered_events;
  if (ring_end < event_ring_begin) {
    buffered_events = 256 + ring_end - event_ring_begin;
  } else {
    buffered_events = ring_end - event_ring_begin;
  }
  //Serial.println(buffered_events);
  while (buffered_events >= 8) {
    buffered_events -= 8;
    if (p == tx_buf) {
      ++next_tx_seqno;
      *p++ = next_tx_seqno & 0xff;
      *p++ = (next_tx_seqno >> 8) & 0xff;
      *p++ = (next_tx_seqno >> 16) & 0xff;
      *p++ = (next_tx_seqno >> 24) & 0xff;
      *p++ = 0;
    }
    uint8_t* rw_flags = p++;
    uint8_t* seq_flags = p++;
    uint8_t* data_p = p;
    *rw_flags = 0;
    *seq_flags = 0;
    p += 8;
    for (int i = 0; i < 8; ++i) {
      uint32_t event = event_ring[event_ring_begin++];
      //Serial.println(event, HEX);
      if (event & (1 << 24)) {
        *rw_flags |= 1 << i;
      }
      uint8_t data = event & 0xff;
      data_p[i] = data;
      uint16_t address = (event >> 8) & 0xffff;
      if (address != prev_tx_address + 1) {
        *seq_flags |= 1 << i;
        uint8_t addrlo = address & 0xff;
        *p++ = addrlo;
        uint8_t addrhi = (address >> 8) & 0xff;
        *p++ = addrhi;
      }
      prev_tx_address = address;
    }
    if (p - tx_buf >= 256) {
      Udp.beginPacket(host, localPort);
      Udp.write(tx_buf, p - tx_buf);
      Udp.endPacket();
      p = tx_buf;
    }
  }
}
