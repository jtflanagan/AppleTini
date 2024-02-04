#include <hardware/pio.h>
#include "bus_controller.pio.h"

#include "hardware/pll.h"
#include "hardware/clocks.h"

void set_sys_clock_pll(uint32_t vco_freq, uint post_div1, uint post_div2) {
  if (!running_on_fpga()) {
    clock_configure(clk_sys,
                    CLOCKS_CLK_SYS_CTRL_SRC_VALUE_CLKSRC_CLK_SYS_AUX,
                    CLOCKS_CLK_SYS_CTRL_AUXSRC_VALUE_CLKSRC_PLL_USB,
                    48 * MHZ,
                    48 * MHZ);

    pll_init(pll_sys, 1, vco_freq, post_div1, post_div2);
    uint32_t freq = vco_freq / (post_div1 * post_div2);

    // Configure clocks
    // CLK_REF = XOSC (12MHz) / 1 = 12MHz
    clock_configure(clk_ref,
                    CLOCKS_CLK_REF_CTRL_SRC_VALUE_XOSC_CLKSRC,
                    0,  // No aux mux
                    12 * MHZ,
                    12 * MHZ);

    // CLK SYS = PLL SYS (125MHz) / 1 = 125MHz
    clock_configure(clk_sys,
                    CLOCKS_CLK_SYS_CTRL_SRC_VALUE_CLKSRC_CLK_SYS_AUX,
                    CLOCKS_CLK_SYS_CTRL_AUXSRC_VALUE_CLKSRC_PLL_SYS,
                    freq, freq);

    clock_configure(clk_peri,
                    0,  // Only AUX mux on ADC
                    CLOCKS_CLK_PERI_CTRL_AUXSRC_VALUE_CLKSRC_PLL_USB,
                    48 * MHZ,
                    48 * MHZ);
  }
}
bool check_sys_clock_khz(uint32_t freq_khz, uint *vco_out, uint *postdiv1_out, uint *postdiv_out) {
  uint crystal_freq_khz = clock_get_hz(clk_ref) / 1000;
  for (uint fbdiv = 320; fbdiv >= 16; fbdiv--) {
    uint vco = fbdiv * crystal_freq_khz;
    if (vco < 400000 || vco > 1600000) continue;
    for (uint postdiv1 = 7; postdiv1 >= 1; postdiv1--) {
      for (uint postdiv2 = postdiv1; postdiv2 >= 1; postdiv2--) {
        uint out = vco / (postdiv1 * postdiv2);
        if (out == freq_khz && !(vco % (postdiv1 * postdiv2))) {
          *vco_out = vco * 1000;
          *postdiv1_out = postdiv1;
          *postdiv_out = postdiv2;
          return true;
        }
      }
    }
  }
  return false;
}
static inline bool set_sys_clock_khz(uint32_t freq_khz, bool required) {
  uint vco, postdiv1, postdiv2;
  if (check_sys_clock_khz(freq_khz, &vco, &postdiv1, &postdiv2)) {
    set_sys_clock_pll(vco, postdiv1, postdiv2);
    return true;
  } else if (required) {
    panic("System clock of %u kHz cannot be exactly achieved", freq_khz);
  }
  return false;
}

enum {
  PHI0_CONTROL_SM = 0,
  PHI0_SIGNAL_SM = 1,
  BUS_RDY_TX_SM = 2,
  BUS_INH_TX_SM = 3,
};

#define BUS_PIO pio0
#define BUS_PIN_PHI0 0
#define BUS_PIN_CONTROL_BASE 16  // 4 transceiver control pins, 16-19
#define BUS_PIN_INH 20           // pin to control bus INH
#define BUS_PIN_RDY 21           // pin to control bus RDY
#define BUS_PIN_INH_REQ 22       // pin from teensy to request INH pull
#define BUS_PIN_RDY_REQ 26       // pin from teensy to request RDY pull|
#define BUS_PIN_TEENSY_IRQ 27    // teensy interrupt pin
#define BUS_PIN_OUT_D_REQ 28     // pin from teensy to request bus data emit

static void phi0_control_setup(PIO pio, uint sm) {
  uint program_offset = pio_add_program(pio, &phi0_control_program);
  pio_sm_claim(pio, sm);
  pio_sm_config c = phi0_control_program_get_default_config(program_offset);
  // set OUT_D_REQ pin as jump pin for control sm
  sm_config_set_jmp_pin(&c, BUS_PIN_OUT_D_REQ);
  // map the SET pin group to the transceiver control signals
  sm_config_set_set_pins(&c, BUS_PIN_CONTROL_BASE, 4);
  pio_sm_init(pio, sm, program_offset, &c);
  pio_sm_set_pins_with_mask(pio, sm,
                            (uint32_t)0xe << BUS_PIN_CONTROL_BASE,
                            (uint32_t)0xf << BUS_PIN_CONTROL_BASE);
  pio_sm_set_pindirs_with_mask(pio, sm,
                               ((uint32_t)0xf << BUS_PIN_CONTROL_BASE),
                               ((uint32_t)0x1 << BUS_PIN_PHI0) | ((uint32_t)0x1 << BUS_PIN_OUT_D_REQ) | ((uint32_t)0xf << BUS_PIN_CONTROL_BASE));
  pio_gpio_init(pio, BUS_PIN_PHI0);
  // no pulls on PHI0 to maximize responsiveness
  gpio_set_pulls(BUS_PIN_PHI0, false, false);
  pio_gpio_init(pio, BUS_PIN_OUT_D_REQ);
  // pullup on OUT_D_REQ to hold it high if teensy is not driving it
  gpio_set_pulls(BUS_PIN_OUT_D_REQ, true, false);
  for (int i = 0; i < 4; ++i) {
    pio_gpio_init(pio, BUS_PIN_CONTROL_BASE + i);
  }
}

static void phi0_signal_setup(PIO pio, uint sm) {
  uint program_offset = pio_add_program(pio, &phi0_signal_program);
  pio_sm_claim(pio, sm);
  pio_sm_config c = phi0_signal_program_get_default_config(program_offset);
  // note, no call to set_jmp_pin, we don't jump
  // note, no call to set_out_pins as we do not have any
  // map the SET pin group to the teensy interrupt
  sm_config_set_set_pins(&c, BUS_PIN_TEENSY_IRQ, 2);
  pio_sm_init(pio, sm, program_offset, &c);
  pio_sm_set_pins_with_mask(pio, sm,
                            (uint32_t)0x1 << BUS_PIN_TEENSY_IRQ,
                            (uint32_t)0x1 << BUS_PIN_TEENSY_IRQ);
  pio_sm_set_pindirs_with_mask(pio, sm,
                               ((uint32_t)0x1 << BUS_PIN_TEENSY_IRQ),
                               (((uint32_t)1 << BUS_PIN_PHI0) | ((uint32_t)0x3 << BUS_PIN_TEENSY_IRQ)));
  // PHI0 pin already configured in other machine, don't reconfigure
  // only configure TEENSY_IRQ
  pio_gpio_init(pio, BUS_PIN_TEENSY_IRQ);
}

static void rdy_tx_setup(PIO pio, uint sm) {
  uint program_offset = pio_add_program(pio, &rdy_tx_program);
  pio_sm_claim(pio, sm);
  pio_sm_config c = rdy_tx_program_get_default_config(program_offset);
  // set BUS_PIN_RDY_REQ as jump pin
  sm_config_set_jmp_pin(&c, BUS_PIN_RDY_REQ);
  // note, no call to set_out_pins as we do not have any
  // map the SET pin group to the BUS_PIN_RDY pin
  sm_config_set_set_pins(&c, BUS_PIN_RDY, 1);
  pio_sm_init(pio, sm, program_offset, &c);
  pio_sm_set_pins_with_mask(pio, sm,
                            (uint32_t)0x1 << BUS_PIN_RDY,
                            (uint32_t)0x1 << BUS_PIN_RDY);
  pio_sm_set_pindirs_with_mask(pio, sm,
                               ((uint32_t)0x1 << BUS_PIN_RDY),
                               ((uint32_t)0x1 << BUS_PIN_PHI0) | ((uint32_t)0x1 << BUS_PIN_RDY) | ((uint32_t)0x1 << BUS_PIN_RDY_REQ));
  pio_gpio_init(pio, BUS_PIN_RDY_REQ);
  // pullup on RDY_REQ to hold it high if teensy is not driving it
  gpio_set_pulls(BUS_PIN_RDY_REQ, true, false);
  pio_gpio_init(pio, BUS_PIN_RDY);
}

static void inh_tx_setup(PIO pio, uint sm) {
  uint program_offset = pio_add_program(pio, &inh_tx_program);
  pio_sm_claim(pio, sm);
  pio_sm_config c = inh_tx_program_get_default_config(program_offset);
  // set BUS_PIN_INH_REQ as jump pin
  sm_config_set_jmp_pin(&c, BUS_PIN_INH_REQ);
  // note, no call to set_out_pins as we do not have any
  // map the SET pin group to the BUS_PIN_INH pin
  sm_config_set_set_pins(&c, BUS_PIN_INH, 1);
  pio_sm_init(pio, sm, program_offset, &c);
  pio_sm_set_pins_with_mask(pio, sm,
                            (uint32_t)0x1 << BUS_PIN_INH,
                            (uint32_t)0x1 << BUS_PIN_INH);
  pio_sm_set_pindirs_with_mask(pio, sm,
                               ((uint32_t)0x1 << BUS_PIN_INH),
                               ((uint32_t)0x1 << BUS_PIN_PHI0) | ((uint32_t)0x1 << BUS_PIN_INH) | ((uint32_t)0x1 << BUS_PIN_INH_REQ));
  pio_gpio_init(pio, BUS_PIN_INH_REQ);
  // pullup on INH_REQ to hold it high if teensy is not driving it
  gpio_set_pulls(BUS_PIN_INH_REQ, true, false);
  pio_gpio_init(pio, BUS_PIN_INH);
}

uint64_t last_bus_us = 0;
uint32_t bus_event_count = 0;
int bus_toggle = 0;
int led_state = 1;

void setup() {
  // put your setup code here, to run once:
  set_sys_clock_khz(126 * 1000, true);
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);

  phi0_control_setup(BUS_PIO, PHI0_CONTROL_SM);
  phi0_signal_setup(BUS_PIO, PHI0_SIGNAL_SM);
  rdy_tx_setup(BUS_PIO, BUS_RDY_TX_SM);
  inh_tx_setup(BUS_PIO, BUS_INH_TX_SM);

  pio_enable_sm_mask_in_sync(BUS_PIO,
                             (1 << PHI0_CONTROL_SM) | (1 << PHI0_SIGNAL_SM)
                               | (1 << BUS_RDY_TX_SM) | (1 << BUS_INH_TX_SM));
}

void loop() {
  uint64_t now = time_us_64();
  //printf("now: %llu\n",now);
  // turn LED on if we haven't received a bus event in over a second
  if (now > last_bus_us + 1000000) {
    last_bus_us = now;
    digitalWrite(LED_BUILTIN, HIGH);
    led_state = 1;
  }
  // check for a rx event from each state machine (the contents
  // don't matter, we throw them away).  Getting events
  // from both state machines indicates that both are
  // detecting bus cycles and the bus is running.
  if (pio_sm_get_rx_fifo_level(BUS_PIO, PHI0_CONTROL_SM)) {
    pio_sm_get_blocking(BUS_PIO, PHI0_CONTROL_SM);
    if (bus_toggle == 0) {
      bus_toggle = 1;
      ++bus_event_count;
      last_bus_us = now;
    }
  }
  if (pio_sm_get_rx_fifo_level(BUS_PIO, PHI0_SIGNAL_SM)) {
    pio_sm_get_blocking(BUS_PIO, PHI0_SIGNAL_SM);
    if (bus_toggle == 1) {
      bus_toggle = 0;
      ++bus_event_count;
      last_bus_us = now;
    }
  }
  if (bus_event_count > 1000000) {
    // because we flip the bus toggle twice per bus cycle,
    // we get about 2 million events every second.  Toggling
    // the LED every million events thus gets it flashing once
    // a second.
    led_state = !led_state;
    digitalWrite(LED_BUILTIN, led_state);
    bus_event_count = 0;
  }
}
