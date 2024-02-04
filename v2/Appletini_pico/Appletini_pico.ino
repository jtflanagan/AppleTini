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
  TEENSY_IRQ_GEN_SM = 0,
  ADDR_LOOP_SM = 1,
  DATA_LOOP_SM = 2,
};

#define BUS_PIO pio0
#define BUS_PIN_PHI0 7
#define BUS_PIN_IRQ_GEN_BASE 4
#define BUS_PIN_ADDR_BASE 2
#define BUS_PIN_DATA_BASE 1
#define BUS_PIN_DMA_CYCLE_ACTIVE 0
#define BUS_PIN_TEENSY_EMIT_DATA 8
#define BUS_PIN_LEVEL_ENABLE 9

static void teensy_irq_gen_setup(PIO pio, uint sm) {
  uint program_offset = pio_add_program(pio, &teensy_irq_gen_program);
  pio_sm_claim(pio, sm);
  pio_sm_config c = teensy_irq_gen_program_get_default_config(program_offset);
  // no jump pin
  // map the SET pin group to the control signals
  sm_config_set_set_pins(&c, BUS_PIN_IRQ_GEN_BASE, 3);
  pio_sm_init(pio, sm, program_offset, &c);
  // set outbound pins (TEENSY_IRQ, ADDR_RX_LATCH, DATA_RX_LATCH) initially high
  pio_sm_set_pins_with_mask(pio, sm,
    ((uint32_t)0x7 << BUS_PIN_IRQ_GEN_BASE),
    ((uint32_t)0x7 << BUS_PIN_IRQ_GEN_BASE));
  // set outbound pins pointing outbound, leaving PHI0 pointing inbound
  pio_sm_set_pindirs_with_mask(pio, sm, 
    ((uint32_t)0x7 << BUS_PIN_IRQ_GEN_BASE),
    ((uint32_t)0x1 << BUS_PIN_PHI0) | ((uint32_t)0x7 << BUS_PIN_IRQ_GEN_BASE));
  // configure PHI0
  pio_gpio_init(pio, BUS_PIN_PHI0);
  // disable internal pulls on PHI0
  gpio_set_pulls(BUS_PIN_PHI0, false, false);
  // configure and disable internal pulls on control pins as well (they have external pulls where needed)
  for (int i = 0; i < 3; ++i) {
    pio_gpio_init(pio, BUS_PIN_IRQ_GEN_BASE + i);
    gpio_set_pulls(BUS_PIN_IRQ_GEN_BASE + i, false, false);
  }
}

static void addr_loop_setup(PIO pio, uint sm) {
  uint program_offset = pio_add_program(pio, &addr_loop_program);
  pio_sm_claim(pio, sm);
  pio_sm_config c = addr_loop_program_get_default_config(program_offset);
  // jump pin is DMA_CYCLE_ACTIVE
  sm_config_set_jmp_pin(&c, BUS_PIN_DMA_CYCLE_ACTIVE);
  // map the SET pin group to the addr control group
  sm_config_set_set_pins(&c, BUS_PIN_ADDR_BASE, 2);
  pio_sm_init(pio, sm, program_offset, &c);
  // set outbound values for pins.  ADDR_TX_ENABLE is initially high,
  // DMA is initially low
  pio_sm_set_pins_with_mask(pio, sm,
    ((uint32_t)0x1 << BUS_PIN_ADDR_BASE),
    ((uint32_t)0x3 << BUS_PIN_ADDR_BASE));
  // set pindir to INPUT for DMA and OUTPUT for ADDR_TX_ENABLE, and inputs for PHI0 and DMA_CYCLE_ACTIVE
  pio_sm_set_pindirs_with_mask(pio, sm,
    ((uint32_t)0x1 << BUS_PIN_ADDR_BASE),
    ((uint32_t)0x3 << BUS_PIN_ADDR_BASE) | ((uint32_t)0x1 << BUS_PIN_PHI0) | ((uint32_t)0x1 << BUS_PIN_DMA_CYCLE_ACTIVE));
  // PHI0 already configured in first state machine, don't reconfigure
  // configure DMA_CYCLE_ACTIVE
  pio_gpio_init(pio, BUS_PIN_DMA_CYCLE_ACTIVE);
  // disable internal pulls on DMA_CYCLE_ACTIVE
  gpio_set_pulls(BUS_PIN_DMA_CYCLE_ACTIVE, false, false);
  // configure and disable internal pulls on control pins as well (they have external pulls where needed)
  for (int i = 0; i < 2; ++i) {
    pio_gpio_init(pio, BUS_PIN_ADDR_BASE + i);
    gpio_set_pulls(BUS_PIN_ADDR_BASE + i, false, false);
  }
}

static void data_loop_setup(PIO pio, uint sm) {
  uint program_offset = pio_add_program(pio, &data_loop_program);
  pio_sm_claim(pio, sm);
  pio_sm_config c = data_loop_program_get_default_config(program_offset);
  // jump pin is TEENSY_EMIT_DATA
  sm_config_set_jmp_pin(&c, BUS_PIN_TEENSY_EMIT_DATA);
  // map the SET pin group to the data control group
  sm_config_set_set_pins(&c, BUS_PIN_DATA_BASE, 1);
  pio_sm_init(pio, sm, program_offset, &c);
  // set outbound values for pins.  Only one pin really,
  // DATA_TX_ENABLE is initially high
  pio_sm_set_pins_with_mask(pio, sm,
    ((uint32_t)0x01 << BUS_PIN_DATA_BASE),
    ((uint32_t)0x01 << BUS_PIN_DATA_BASE));
  // set pindir to OUTPUT for ADDR_TX_ENABLE, and inputs for PHI0 and TEENSY_EMIT_DATA
  pio_sm_set_pindirs_with_mask(pio, sm,
    ((uint32_t)0x1 << BUS_PIN_DATA_BASE),
    ((uint32_t)0x1 << BUS_PIN_DATA_BASE) | ((uint32_t)0x1 << BUS_PIN_PHI0) | ((uint32_t)0x1 << BUS_PIN_TEENSY_EMIT_DATA));
  // PHI0 already configured in first state machine, don't reconfigure
  // configure BUS_PIN_TEENSY_EMIT_DATA
  pio_gpio_init(pio, BUS_PIN_TEENSY_EMIT_DATA);
  // disable internal pulls on TEENSY_EMIT_DATA, it has its own external pull
  gpio_set_pulls(BUS_PIN_TEENSY_EMIT_DATA, false, false);
  // configure and disable internal pulls on control pins as well (they have external pulls where needed)
  // yes, there's only one for this SM, but I'm trying to treat them uniformly in the code so it gets a loop
  for (int i = 0; i < 1; ++i) {
    pio_gpio_init(pio, BUS_PIN_DATA_BASE + i);
    gpio_set_pulls(BUS_PIN_ADDR_BASE + i, false, false);
  }
}

void setup() {
  // put your setup code here, to run once:
  set_sys_clock_khz(126 * 1000, true);
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);

  teensy_irq_gen_setup(BUS_PIO, TEENSY_IRQ_GEN_SM);
  addr_loop_setup(BUS_PIO, ADDR_LOOP_SM);
  data_loop_setup(BUS_PIO, DATA_LOOP_SM);

  // properly we should have a line in from the Teensy which we check in loop()
  // and disable the pios and LEVEL_ENABLE if it is not asserted, but I forgot
  // in the design.  Just turn stuff on for now and we'll deal with
  // it later.
  pio_enable_sm_mask_in_sync(BUS_PIO,
    (1 << TEENSY_IRQ_GEN_SM) | (1 << ADDR_LOOP_SM)
                               | (1 << DATA_LOOP_SM));

  pinMode(BUS_PIN_LEVEL_ENABLE, OUTPUT);
  digitalWrite(BUS_PIN_LEVEL_ENABLE, HIGH);
}

uint64_t last_bus_us = 0;
uint32_t bus_event_count = 0;
int bus_toggle = 0;
int led_state = 1;

void loop() {
  // put your main code here, to run repeatedly:
  uint64_t now = time_us_64();

  // turn LED on and leave it on if we go a second without
  // seeing any bus events
  if (now > last_bus_us + 1000000) {
    last_bus_us = now;
    digitalWrite(LED_BUILTIN, HIGH);
    led_state = 1;
  }

  // check for a bus cycle event from the irq_gen state machine.
  // the contents don't matter, we throw it away.  We just count
  // events as we get them and toggle the LED every 500k, so it flashes
  // approximately once a second.
  if (pio_sm_get_rx_fifo_level(BUS_PIO, TEENSY_IRQ_GEN_SM)) {
    pio_sm_get_blocking(BUS_PIO, TEENSY_IRQ_GEN_SM);
    ++bus_event_count;
    last_bus_us = now;
  }

  if (bus_event_count > 500000) {
    led_state = !led_state;
    digitalWrite(LED_BUILTIN, led_state);
    bus_event_count = 0;
  }

}
