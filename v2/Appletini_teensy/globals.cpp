#include "globals.h"

namespace qn = qindesign::network;

// set this to 1 if generating IIGS-mode firmware
#define APPLEIIGS_MODE 0

IPAddress ipaddr(192, 168, 155, 251);
IPAddress netmask(255, 255, 255, 0);
IPAddress gw(192, 168, 155, 1);
IPAddress host(192, 168, 155, 250);

unsigned int localPort = 8080;  // local port to listen on

// buffers for receiving and sending data
uint32_t rx_buf[512];  // buffer to hold incoming packet
uint32_t tx_buf[512];  // buffer to hold outgoing (non-bus) packet

#define EVENT_BUF_SZ 256
uint32_t event_bufs[2][EVENT_BUF_SZ];
uint8_t apple_main_memory[128*1024];
uint8_t main_rom[15*256];
uint8_t lc_rom[12*1024];
EXTMEM uint8_t expanded_memory[16*1024*1024];
volatile uint32_t event_buf_index = 2;
volatile uint32_t writing_buf = 0;
// An EthernetUDP instance to let us send and receive packets over UDP
qn::EthernetUDP Udp;

uint32_t next_tx_seqno = 0;
uint32_t prev_addr_event = 0;
uint32_t addr_port6_pins = 0;
uint32_t data_port6_pins = 0;
uint32_t port7_pins = 0;
uint32_t port9_pins = 0;
uint32_t bus_address = 0;
uint32_t prev_bus_address = 0;
uint32_t bus_data = 0;
uint32_t card_shared_owner = 0;
bool bus_rw = false;
bool prev_bus_rw = false;
bool bus_m2sel = false;
bool bus_m2b0 = false;
volatile bool reset_happened = false;
uint32_t reset_detect_state = 0;
// function pointers for card_io bus events (0xc090-0xc0ff)
void (*handle_card_io_event[8]) (uint32_t addr_byte);
// function pointers for card page events (0xc100->0xc7ff)
void (*handle_card_page_event[8]) (uint32_t addr_byte);
// function pointers for card shared range events (0xc800->0xcfff)
void (*handle_card_shared_event[8]) (uint32_t addr_byte);
// function pointers for soft switches (0xc000-0xc08f)
void (*handle_soft_switch[144]) (bool data_phase, uint32_t data);
void (*data_completion_callback) (bool data_phase, uint32_t data);