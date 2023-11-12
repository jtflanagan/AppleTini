#include <pico/stdlib.h>
#include <stdio.h>
#include <pico/cyw43_arch.h>
#include "bus_controller.pio.h"

enum {
  PHI0_CONTROL_SM = 0,
  PHI0_SIGNAL_SM = 1,
  BUS_RDY_TX_SM = 2,
  BUS_INH_TX_SM = 3,
};

#define BUS_PIO pio0
#define BUS_PIN_PHI0 0
#define BUS_PIN_CONTROL_BASE 16 // 4 transceiver control pins, 16-19
#define BUS_PIN_INH 20 // pin to control bus INH
#define BUS_PIN_RDY 21 // pin to control bus RDY
#define BUS_PIN_INH_REQ 22 // pin from teensy to request INH pull
#define BUS_PIN_RDY_REQ 26 // pin from teensy to request RDY pull
#define BUS_PIN_TEENSY_IRQ 27 // teensy interrupt pin
#define BUS_PIN_OUT_D_REQ 28 // pin from teensy to request bus data emit

static void phi0_control_setup(PIO pio, uint sm) {
  uint program_offset = pio_add_program(pio, &phi0_control_program);
  pio_sm_claim(pio, sm);
  pio_sm_config c = phi0_control_program_get_default_config(program_offset);
  // set DATA_OUT pin as jump pin for control sm
  sm_config_set_jmp_pin(&c, BUS_PIN_DATA_OUT);
  // note, no call to set_out_pins as we do not have any
  // map the SET pin group to the transceiver control signals
  sm_config_set_set_pins(&c, BUS_PIN_CONTROL_BASE, 4);
  pio_sm_init(pio, sm, program_offset, &c);
  pio_sm_set_pins_with_mask(pio, sm,
			    (uint32_t)0xe << BUS_PIN_CONTROL_BASE,
			    (uint32_t)0xf << BUS_PIN_CONTROL_BASE);
  pio_sm_set_pindirs_with_mask(pio, sm,
			       ((uint32_t)0xf << BUS_PIN_CONTROL_BASE),
			       ((uint32_t)0x1 << BUS_PIN_PHI0) | 
			       ((uint32_t)0x1 << BUS_PIN_OUT_D_REQ) |
			       ((uint32_t)0xf << BUS_PIN_CONTROL_BASE));
  pio_gpio_init(pio, BUS_PIN_PHI0);
  // no pulls on PHI0 to maximize responsiveness
  gpio_set_pulls(BUS_PIN_PHI0, false, false);
  pio_gpio_init(pio, BUS_PIN_OUT_D_REQ);
  // pullup on OUT_D_REQ to hold it high if teensy is not driving it
  gpio_set_pulls(BUS_PIN_PIN_OUT_D_REQ, true, false);
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
			       (((uint32_t)1 << BUS_PIN_PHI0) |
				((uint32_t)0x3 << BUS_PIN_TEENSY_IRQ)));
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
                            (uint32_t)0x1 << BUS_PIN_RDY),
                            (uint32_t)0x1 << BUS_PIN_RDY));
  pio_sm_set_pindirs_withm_mask(pio, sm,
                                ((uint32_t)0x1 << BUS_PIN_RDY),
                                ((uint32_t)0x1 << BUS_PIN_PHI0) |
                                ((uint32_t)0x1 << BUS_PIN_RDY) |
                                ((uint32_t)0x1 << BUS_PIN_RDY_REQ));
  pio_gpio_init(pio, BUS_PIN_RDY_REQ);
  // pullup on RDY_REQ to hold it high if teensy is not driving it
  gpio_set_pulls(pio, BUS_PIN_RDY_REQ, true, false);
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
                            (uint32_t)0x1 << BUS_PIN_INH),
                            (uint32_t)0x1 << BUS_PIN_INH));
  pio_sm_set_pindirs_withm_mask(pio, sm,
                                ((uint32_t)0x1 << BUS_PIN_INH),
                                ((uint32_t)0x1 << BUS_PIN_PHI0) |
                                ((uint32_t)0x1 << BUS_PIN_INH) |
                                ((uint32_t)0x1 << BUS_PIN_INH_REQ));
  pio_gpio_init(pio, BUS_PIN_INH_REQ);
  // pullup on INH_REQ to hold it high if teensy is not driving it
  gpio_set_pulls(pio, BUS_PIN_INH_REQ, true, false);
  pio_gpio_init(pio, BUS_PIN_INH);
}

int main() {
  uint64_t last_bus_us = 0;
  uint32_t bus_event_count = 0;
  set_sys_clock_khz(126 * 1000, true);

  stdio_init_all();

  sleep_ms(2000);

  if (cyw43_arch_init()) {
    while (1) {}
  }

  printf("setting up pio\n");
  // do pio init
  phi0_control_setup(BUS_PIO, PHI0_CONTROL_SM);
  phi0_signal_setup(BUS_PIO, PHI0_SIGNAL_SM);
  rdy_tx_setup(BUS_PIO, RDY_TX_SM);
  inh_tx_setup(BUS_PIO, INH_TX_SM);

  pio_enable_sm_mask_in_sync(BUS_PIO, 
			     (1 << PHI0_CONTROL_SM) | (1 << PHI0_SIGNAL_SM)
                             | (1 << RDY_TX_SM) | (1 << INH_TX_SM));

  // loop forever, pulling sm events and blinking the LED every
  // million bus events, approximately once a second
  int bus_toggle = 0;
  int led_state = 1;
  while (1) {
    uint64_t now = time_us_64();
    //printf("now: %llu\n",now);
    // turn LED on if we haven't received a bus event in over a second
    if (now > last_bus_us + 1000000) {
      last_bus_us = now;
      cyw43_arch_gpio_put(CYW43_WL_GPIO_LED_PIN, 1);
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
      cyw43_arch_gpio_put(CYW43_WL_GPIO_LED_PIN, led_state);
      bus_event_count = 0;
    }

  }
}
