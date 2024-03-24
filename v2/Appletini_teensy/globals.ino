#include "globals.h"

namespace qn = qindesign::network;

//IPAddress ipaddr(192, 168, 155, 251);
//IPAddress netmask(255, 255, 255, 0);
//IPAddress gw(192, 168, 155, 1);
//IPAddress host(192, 168, 155, 250);

unsigned int localPort = 8080;  // local port to listen on

// buffers for receiving and sending data
uint32_t rx_buf[512];  // buffer to hold incoming packet
uint32_t tx_buf[512];  // buffer to hold outgoing (non-bus) packet

#define EVENT_BUF_SZ 256
uint32_t event_bufs[2][EVENT_BUF_SZ];
uint8_t apple_main_memory[128*1024];
uint8_t apple_low_rom[15*256];
uint8_t apple_high_rom[12*1024];
// preboot images could go to RAM2?  Rarely needed, not performant
uint8_t preboot_card_image[256] = PREBOOT_CARD_IMAGE;
uint8_t preboot_shared_image[2048] = PREBOOT_SHARED_IMAGE;
uint8_t fake_vidhd_image[256] = FAKE_VIDHD_IMAGE;
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
uint32_t discard_pins = 0;
uint32_t bus_address = 0;
uint32_t prev_bus_address = 0;
uint32_t bus_data = 0;
int32_t card_shared_owner = 0;
uint32_t apple_iigs_mode = 0;
uint32_t bus_rw = 0;
uint32_t prev_bus_rw = 0;
uint32_t brain_transplant_mode = 0;
uint32_t bus_inhibited = 0;
uint32_t emitting_byte = 0;
uint32_t bus_m2sel = 0;
uint32_t bus_m2b0 = 0;
volatile bool reset_happened = false;
uint32_t reset_detect_state = 0;
uint32_t bus_counter = 0;
uint32_t vbl_first_time = 1;
uint32_t prev_vbl = 0;
uint32_t vbl_done = 0;
uint32_t vbl_transition_count = 0;
uint32_t vbl_transitions[32];
void (*handle_soft_switch[144]) (bool data_phase);
AddrCallback handle_card_io_addr[8];
DataCallback handle_card_io_data[8];
AddrCallback handle_card_page_addr[8];
DataCallback handle_card_page_data[8];
AddrCallback handle_c3_card_page_addr[8];
DataCallback handle_c3_card_page_data[8];
AddrCallback handle_card_shared_addr[8];
DataCallback handle_card_shared_data[8];
AddrCallback* memory_page_addr_callbacks[512];
DataCallback* memory_page_data_callbacks[512];
AddrCallback zpstack_addr;
DataCallback zpstack_data;
AddrCallback main_addr_read;
AddrCallback main_addr_write;
DataCallback main_data_read;
DataCallback main_data_write;
AddrCallback text_addr_read;
AddrCallback text_addr_write;
DataCallback text_data_read;
DataCallback text_data_write;
AddrCallback hires_addr_read;
AddrCallback hires_addr_write;
DataCallback hires_data_read;
DataCallback hires_data_write;
AddrCallback c0_page_addr;
DataCallback c0_page_data;
AddrCallback card_page_addr;
DataCallback card_page_data;
AddrCallback card_shared_addr;
DataCallback card_shared_data;
AddrCallback high_banked_addr;
DataCallback high_banked_data;
AddrCallback high_unbanked_addr;
DataCallback high_unbanked_data;

