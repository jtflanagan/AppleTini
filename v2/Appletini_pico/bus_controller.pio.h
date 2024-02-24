// -------------------------------------------------- //
// This file is autogenerated by pioasm; do not edit! //
// -------------------------------------------------- //

#pragma once

#if !PICO_NO_HARDWARE
#include "hardware/pio.h"
#endif

#define PHI0_GPIO 7

// -------------- //
// teensy_irq_gen //
// -------------- //

#define teensy_irq_gen_wrap_target 0
#define teensy_irq_gen_wrap 7

static const uint16_t teensy_irq_gen_program_instructions[] = {
            //     .wrap_target
    0x8000, //  0: push   noblock                    
    0x3307, //  1: wait   0 gpio, 7              [19]
    0xe106, //  2: set    pins, 6                [1] 
    0xe300, //  3: set    pins, 0                [3] 
    0xe004, //  4: set    pins, 4                    
    0x3f87, //  5: wait   1 gpio, 7              [31]
    0xed05, //  6: set    pins, 5                [13]
    0xe004, //  7: set    pins, 4                    
            //     .wrap
};

#if !PICO_NO_HARDWARE
static const struct pio_program teensy_irq_gen_program = {
    .instructions = teensy_irq_gen_program_instructions,
    .length = 8,
    .origin = -1,
};

static inline pio_sm_config teensy_irq_gen_program_get_default_config(uint offset) {
    pio_sm_config c = pio_get_default_sm_config();
    sm_config_set_wrap(&c, offset + teensy_irq_gen_wrap_target, offset + teensy_irq_gen_wrap);
    return c;
}
#endif

// --------- //
// addr_loop //
// --------- //

#define addr_loop_wrap_target 0
#define addr_loop_wrap 12

static const uint16_t addr_loop_program_instructions[] = {
            //     .wrap_target
    0x2007, //  0: wait   0 gpio, 7                  
    0x00c9, //  1: jmp    pin, 9                     
    0xeb03, //  2: set    pins, 3                [11]
    0xe081, //  3: set    pindirs, 1                 
    0xe001, //  4: set    pins, 1                    
    0x3f87, //  5: wait   1 gpio, 7              [31]
    0xa642, //  6: nop                           [6] 
    0xc000, //  7: irq    nowait 0                   
    0x0000, //  8: jmp    0                          
    0xe583, //  9: set    pindirs, 3             [5] 
    0xe000, // 10: set    pins, 0                    
    0x2f87, // 11: wait   1 gpio, 7              [15]
    0xc000, // 12: irq    nowait 0                   
            //     .wrap
};

#if !PICO_NO_HARDWARE
static const struct pio_program addr_loop_program = {
    .instructions = addr_loop_program_instructions,
    .length = 13,
    .origin = -1,
};

static inline pio_sm_config addr_loop_program_get_default_config(uint offset) {
    pio_sm_config c = pio_get_default_sm_config();
    sm_config_set_wrap(&c, offset + addr_loop_wrap_target, offset + addr_loop_wrap);
    return c;
}
#endif

// --------- //
// data_loop //
// --------- //

#define data_loop_wrap_target 0
#define data_loop_wrap 4

static const uint16_t data_loop_program_instructions[] = {
            //     .wrap_target
    0x2007, //  0: wait   0 gpio, 7                  
    0xe001, //  1: set    pins, 1                    
    0x20c0, //  2: wait   1 irq, 0                   
    0x00c0, //  3: jmp    pin, 0                     
    0xe000, //  4: set    pins, 0                    
            //     .wrap
};

#if !PICO_NO_HARDWARE
static const struct pio_program data_loop_program = {
    .instructions = data_loop_program_instructions,
    .length = 5,
    .origin = -1,
};

static inline pio_sm_config data_loop_program_get_default_config(uint offset) {
    pio_sm_config c = pio_get_default_sm_config();
    sm_config_set_wrap(&c, offset + data_loop_wrap_target, offset + data_loop_wrap);
    return c;
}
#endif
