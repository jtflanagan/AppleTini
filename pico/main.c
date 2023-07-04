#include <pico/stdlib.h>
#include <stdio.h>
#include "pico/cyw43_arch.h"
#include "bus_controller.pio.h"

enum {
  PHI0_CONTROL_SM = 0,
  PHI0_SIGNAL_SM = 1,
};

#define BUS_PIO pio0
#define BUS_PIN_PHI0 0
#define BUS_PIN_RW 1
#define BUS_PIN_CONTROL_BASE 2 // 4 pins, 2-5
#define BUS_PIN_SIGNAL_BASE 26 // 2 pins, 26-27
#define BUS_PIN_DATA_OUT 28

static void phi0_control_setup(PIO pio, uint sm) {
  uint program_offset = pio_add_program(pio, &phi0_control_program);
  pio_sm_claim(pio, sm);
  pio_sm_config c = phi0_control_program_get_default_config(program_offset);
  // set RW pin as jump pin for control sm
  sm_config_set_jmp_pin(&c, BUS_PIN_RW);
  // note, no call to set_out_pins as we do not have any
  // map the SET pin group to the transceiver control signals
  sm_config_set_set_pins(&c, BUS_PIN_CONTROL_BASE, 4);
  pio_sm_init(pio, sm, program_offset, &c);
  pio_sm_set_pins_with_mask(pio, sm,
			    (uint32_t)0xe << BUS_PIN_CONTROL_BASE,
			    (uint32_t)0xf << BUS_PIN_CONTROL_BASE);
  pio_sm_set_pindirs_with_mask(pio, sm,
			       (0xf << BUS_PIN_CONTROL_BASE),
			       ((1 << BUS_PIN_PHI0) | (1 << BUS_PIN_RW) |
				(0xf << BUS_PIN_CONTROL_BASE)));
  pio_gpio_init(pio, BUS_PIN_PHI0);
  gpio_set_pulls(BUS_PIN_PHI0, false, false);
  pio_gpio_init(pio, BUS_PIN_RW);
  gpio_set_pulls(BUS_PIN_RW, false, false);
  for (int i = 0; i < 4; ++i) {
    pio_gpio_init(pio, BUS_PIN_CONTROL_BASE + i);
    gpio_set_pulls(BUS_PIN_CONTROL_BASE + i, true, false);
  }
}

static void phi0_signal_setup(PIO pio, uint sm) {
  uint program_offset = pio_add_program(pio, &phi0_signal_program);
  pio_sm_claim(pio, sm);
  pio_sm_config c = phi0_signal_program_get_default_config(program_offset);
  // set DATA_OUT pin as jump pin for signal sm
  sm_config_set_jmp_pin(&c, BUS_PIN_DATA_OUT);
  // note, no call to set_out_pins as we do not have any
  // map the SET pin group to the teensy control signals
  sm_config_set_set_pins(&c, BUS_PIN_SIGNAL_BASE, 2);
  pio_sm_init(pio, sm, program_offset, &c);
  pio_sm_set_pins_with_mask(pio, sm,
			    (uint32_t)0x3 << BUS_PIN_SIGNAL_BASE,
			    (uint32_t)0x3 << BUS_PIN_SIGNAL_BASE);
  pio_sm_set_pindirs_with_mask(pio, sm,
			       (0x3 << BUS_PIN_SIGNAL_BASE),
			       ((1 << BUS_PIN_PHI0) | (1 << BUS_PIN_DATA_OUT) |
				(0x3 << BUS_PIN_SIGNAL_BASE)));
  // PHI0 pin already configured in other machine
  //pio_gpio_init(pio, BUS_PIN_PHI0);
  //gpio_set_pulls(BUS_PIN_PHI0, false, false);
  pio_gpio_init(pio, BUS_PIN_DATA_OUT);
  gpio_set_pulls(BUS_PIN_DATA_OUT, false, false);
  for (int i = 0; i < 2; ++i) {
    pio_gpio_init(pio, BUS_PIN_SIGNAL_BASE + i);
    gpio_set_pulls(BUS_PIN_SIGNAL_BASE + i, true, false);  
}


int main() {
  uint64_t last_bus_us = 0;
  set_sys_clock_khz(126 * 1000);


  if (cyw43_arch_init()) {
    while (1) {}
  }
  
  // do pio init
  phi0_control_setup(BUS_PIO, PHI0_CONTROL_SM);
  phi0_signal_setup(BUS_PIO, PHI0_SIGNAL_SM);

  pio_enable_sm_mask_in_sync(BUS_PIO, 
			     (1 << PHI0_CONTROL_SM) | (1 << PHIO_SIGNAL_SM));

  // loop forever, pulling sm events and blinking the LED every
  // million bus events, approximately once a second
  int bus_toggle = 0;
  int led_state = 1;
  while (1) {
    uint64_t now = time_us_64();
    // turn LED on if we haven't received a bus event in over a second
    if (now > last_bus_us + 1000000) {
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
