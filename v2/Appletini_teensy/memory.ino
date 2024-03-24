#include "globals.h"
#include "memory.h"

uint32_t ss_mode = MF_BANK2 | MF_WRITERAM;
uint32_t last_ramwrite_flag = 0;

FASTRUN void reset_soft_switch_state() {
  ss_mode = MF_BANK2 | MF_WRITERAM;
  // force all state to get recalculated
  update_altzp_lc_paging();
  update_main_aux_paging();
  update_card_paging();
  brain_transplant_mode = false;
  bus_counter = 0;
  vbl_first_time = 1;
  prev_vbl = 0;
  vbl_done = 0;
  vbl_transition_count = 0;
}

FASTRUN void soft_switch_null_handler(bool data_phase) {
  return;
}

FASTRUN void ss_kbd_80storeoff(bool data_phase) {
  if (data_phase) {
    apple_main_memory[bus_address] = bus_data;
    return;
  }
  if (!bus_rw) {
    ss_mode &= ~MF_80STORE;
    update_main_aux_paging();
  }
}

FASTRUN void ss_80storeon(bool data_phase) {
  if (!bus_rw) {
    ss_mode |= MF_80STORE;
    update_main_aux_paging();
  }
}

FASTRUN void ss_ramrdoff(bool data_phase) {
  if (!bus_rw) {
    ss_mode &= ~MF_AUXREAD;
    update_main_aux_paging();
  }
}

FASTRUN void ss_ramrdon(bool data_phase) {
  if (!bus_rw) {
    ss_mode |= MF_AUXREAD;
    update_main_aux_paging();
  }
}

FASTRUN void ss_ramwrtoff(bool data_phase) {
  if (!bus_rw) {
    ss_mode &= ~MF_AUXWRITE;
    update_main_aux_paging();
  }
}

FASTRUN void ss_ramwrton(bool data_phase) {
  if (!bus_rw) {
    ss_mode |= MF_AUXWRITE;
    update_main_aux_paging();
  }
}

FASTRUN void ss_intcxromoff(bool data_phase) {
  if (!bus_rw) {
    ss_mode &= ~MF_INTCXROM;
    update_card_paging();
  }
}

FASTRUN void ss_intcxromon(bool data_phase) {
  if (!bus_rw) {
    ss_mode |= MF_INTCXROM;
    update_card_paging();
  }
}

FASTRUN void ss_altzpoff(bool data_phase) {
  if (!bus_rw) {
    ss_mode &= ~MF_ALTZP;
    update_altzp_lc_paging();
  }
}

FASTRUN void ss_altzpon(bool data_phase) {
  if (!bus_rw) {
    ss_mode |= MF_ALTZP;
    update_altzp_lc_paging();
  }
}

FASTRUN void ss_slotc3romoff(bool data_phase) {
  if (!bus_rw) {
    ss_mode &= ~MF_SLOTC3ROM;
    // don't need to directly update paging
  }
}

FASTRUN void ss_slotc3romon(bool data_phase) {
  if (!bus_rw) {
    ss_mode |= MF_SLOTC3ROM;
    // don't need to directly update paging
  }
}


FASTRUN void ss_kbdstrb(bool data_phase) {
  // clear strobe bit on key
  apple_main_memory[0xc000] &= 0x7f;
}

FASTRUN void ss_ramrd(bool data_phase) {
  if (data_phase && prev_bus_rw) {
    if (bus_data & 0x80) {
      ss_mode |= MF_AUXREAD;
    } else {
      ss_mode &= ~MF_AUXREAD;
    }
    update_main_aux_paging();
  }
}

FASTRUN void ss_ramwrt(bool data_phase) {
  if (data_phase && prev_bus_rw) {
    if (bus_data & 0x80) {
      ss_mode |= MF_AUXWRITE;
    } else {
      ss_mode &= ~MF_AUXWRITE;
    }
    update_main_aux_paging();
  }
}

FASTRUN void ss_intcxrom(bool data_phase) {
  if (data_phase && prev_bus_rw) {
    if (bus_data & 0x80) {
      ss_mode |= MF_INTCXROM;
    } else {
      ss_mode &= ~MF_INTCXROM;
    }
    update_card_paging();
  }
}

FASTRUN void ss_altzp(bool data_phase) {
  if (data_phase && prev_bus_rw) {
    if (bus_data & 0x80) {
      ss_mode |= MF_ALTZP;
    } else {
      ss_mode &= ~MF_ALTZP;
    }
    update_altzp_lc_paging();
  }
}

FASTRUN void ss_slotc3rom(bool data_phase) {
  if (data_phase && prev_bus_rw) {
    if (bus_data & 0x80) {
      ss_mode |= MF_SLOTC3ROM;
    } else {
      ss_mode &= ~MF_SLOTC3ROM;
    }
    // don't need to directly update paging
  }
}

FASTRUN void ss_80store(bool data_phase) {
  if (data_phase && prev_bus_rw) {
    if (bus_data & 0x80) {
      ss_mode |= MF_80STORE;
    } else {
      ss_mode &= MF_80STORE;
    }
    update_main_aux_paging();
  }
}

FASTRUN void ss_vbl(bool data_phase) {
  if (data_phase && prev_bus_rw) {
    uint8_t val = bus_data & 0x80;
    if (vbl_first_time) {
      //Serial.println("hit vbl");
      vbl_first_time = 0;
      prev_vbl = val;
      return;
    }
    if (vbl_done) {
      return;
    }
    if (val != prev_vbl) {
      vbl_transitions[vbl_transition_count++] = bus_counter;
      //Serial.println("vbl transition");
      if (vbl_transition_count == 26) {
        // for (int i = 1; i < 19; ++i) {
        //   Serial.println(vbl_transitions[i] - vbl_transitions[i-1]);
        // }
        vbl_done = 1;
      }
    }
    prev_vbl = val;
  }
}

FASTRUN void ss_page2(bool data_phase) {
  if (data_phase && prev_bus_rw) {
    if (bus_data & 0x80) {
      ss_mode |= MF_PAGE2;
    } else {
      ss_mode &= ~MF_PAGE2;
    }
    update_main_aux_paging();
  }
}

FASTRUN void ss_hires(bool data_phase) {
  if (data_phase && prev_bus_rw) {
    if (bus_data & 0x80) {
      ss_mode |= MF_HIRES;
    } else {
      ss_mode &= ~MF_HIRES;
    }
    update_main_aux_paging();
  }
}

// FASTRUN void ss_tape(bool data_phase) {
//   if (data_phase && prev_bus_rw) {
//     char buf[256];
//     if (!bus_data) {
//       return;
//     }
//     if (c020_hit_stage == 0) {
//       first_c020_hit = bus_counter;
//       //sprintf(buf, "first hit: %u",first_c020_hit);
//       //Serial.println(buf);
//       c020_hit_stage = 1;
//     } else if (c020_hit_stage == 1) {
//       second_c020_hit = bus_counter;
//       c020_hit_stage = 2; // don't worry about hits anymore
//       cycle_period = second_c020_hit - first_c020_hit;
//       sprintf(buf, "second hit: %u, approx period %u, data %u", second_c020_hit, cycle_period, bus_data);
//       Serial.println(buf);
//       // the exact amount between hits is imprecise, but if it's well larger than 17030,
//       // that means the real cycle period is 50Hz PAL, otherwise it's 60Hz NTSC
//       if (cycle_period > 18000) {
//         cycle_period = 20280;
//       } else {
//         cycle_period = 17030;
//       }
//       // the current data value -1 indicates the current cycle (relative to the start of screen)
//       current_cycle = bus_data - 1;
//     }
//   }
// }

FASTRUN void ss_page2off(bool data_phase) {
  if (data_phase) {
    return;
  }
  ss_mode &= ~MF_PAGE2;
  update_main_aux_paging();
}

FASTRUN void ss_page2on(bool data_phase) {
  if (data_phase) {
    return;
  }
  ss_mode |= MF_PAGE2;
  update_main_aux_paging();
}

FASTRUN void ss_hiresoff(bool data_phase) {
  if (data_phase) {
    return;
  }
  ss_mode &= ~MF_HIRES;
  update_main_aux_paging();
}

FASTRUN void ss_hireson(bool data_phase) {
  if (data_phase) {
    return;
  }
  ss_mode |= MF_HIRES;
  update_main_aux_paging();
}

FASTRUN void ss_languagecard(bool data_phase) {
  if (data_phase) {
    return;
  }
  if (!bus_rw) {
    return;
  }
  if (bus_address & 0x8) {
    ss_mode |= MF_BANK2;
  } else {
    ss_mode &= ~MF_BANK2;
  }
  if (((bus_address & 0x2) >> 1) == (bus_address & 0x1)) {
    ss_mode |= MF_HIGHRAM;
  } else {
    ss_mode &= ~MF_HIGHRAM;
  }
  if (bus_address & 0x1) {
    if (last_ramwrite_flag) {
      ss_mode |= MF_WRITERAM;
    }
  } else {
    ss_mode &= ~MF_WRITERAM;
  }
  last_ramwrite_flag = (bus_address & 0x1);
  update_altzp_lc_paging();
}

FASTRUN void low_rom_addr_func(uint16_t addr, bool rw) {
}

FASTRUN void low_rom_data_func(uint16_t addr, uint8_t data, bool rw) {
  // shadow data reads only
  if (rw) {
    apple_low_rom[addr - 0xc100] = data;
  }
}

FASTRUN void high_rom_addr_func(uint16_t addr, bool rw) {
  if (brain_transplant_mode) {
    inhibit_bus();
    if (rw) {
      emit_byte(apple_high_rom[addr - 0xd000]);
    }
    return;
  }

}

FASTRUN void high_rom_data_func(uint16_t addr, uint8_t data, bool rw) {
  if (rw) {
    uint16_t image_addr = addr - 0xd000;
    apple_high_rom[image_addr] = data;
  }
}

// inline functions used by the concrete functions which work from calculated
// offsets
inline void ram_addr_func(uint16_t addr, bool rw, int32_t offset) {
  if (!brain_transplant_mode) {
    return;
  }
  inhibit_bus();
  if (rw) {
    emit_byte(apple_main_memory[addr + offset]);
  }
}

inline void ram_data_func(uint16_t addr, uint8_t data, bool rw, int32_t offset) {
  // regardless of read or write, shadow to memory
  apple_main_memory[addr + offset] = data;
}

FASTRUN void ram_addr_main(uint16_t addr, bool rw) {
  ram_addr_func(addr, rw, 0);
}

FASTRUN void ram_addr_aux(uint16_t addr, bool rw) {
  ram_addr_func(addr, rw, 0x10000);
}

FASTRUN void ram_addr_main_bank1(uint16_t addr, bool rw) {
  ram_addr_func(addr, rw, -1024);
}

FASTRUN void ram_addr_aux_bank1(uint16_t addr, bool rw) {
  ram_addr_func(addr, rw, 0x10000 - 1024);
}

FASTRUN void ram_addr_main_bank2(uint16_t addr, bool rw) {
  ram_addr_func(addr, rw, 0);
}

FASTRUN void ram_addr_aux_bank2(uint16_t addr, bool rw) {
  ram_addr_func(addr, rw, 0x10000);
}

FASTRUN void ram_data_main(uint16_t addr, uint8_t data, bool rw) {
  ram_data_func(addr, data, rw, 0);
}

FASTRUN void ram_data_aux(uint16_t addr, uint8_t data, bool rw) {
  ram_data_func(addr, data, rw, 0x10000);
}

FASTRUN void ram_data_main_bank1(uint16_t addr, uint8_t data, bool rw) {
  if ((ss_mode & MF_WRITERAM) || rw) {
    ram_data_func(addr, data, rw, -1024);
  }
}

FASTRUN void ram_data_aux_bank1(uint16_t addr, uint8_t data, bool rw) {
  if ((ss_mode & MF_WRITERAM) || rw) {
    ram_data_func(addr, data, rw, 0x10000 - 1024);
  }
}

FASTRUN void ram_data_main_bank2(uint16_t addr, uint8_t data, bool rw) {
  if ((ss_mode & MF_WRITERAM) || rw) {
    ram_data_func(addr, data, rw, 0);
  }
}

FASTRUN void ram_data_aux_bank2(uint16_t addr, uint8_t data, bool rw) {
  if ((ss_mode & MF_WRITERAM) || rw) {
    ram_data_func(addr, data, rw, 0x10000);
  }
}


FASTRUN void c0_page_addr_func(uint16_t addr, bool rw) {
  if (addr < 0xc090) {
    uint32_t switch_index = addr - 0xc000;
    handle_soft_switch[switch_index](false);
    return;
  }
  uint32_t card_slot = ((addr & 0x00f0) >> 4) - 8;
  handle_card_io_addr[card_slot](addr, rw);
}

FASTRUN void c0_page_data_func(uint16_t addr, uint8_t data, bool rw) {
  if (addr < 0xc090) {
    uint32_t switch_index = addr - 0xc000;
    handle_soft_switch[switch_index](true);
    return;
  }
  uint32_t card_slot = ((addr & 0x00f0) >> 4) - 8;
  handle_card_io_data[card_slot](addr, data, rw);
}

FASTRUN void card_page_addr_func(uint16_t addr, bool rw) {
  uint32_t card_slot = (addr & 0x0f00) >> 8;
  // if we're not in SLOTC3ROM mode, an access to slot 3 gets redirected
  // to slot 0
  if (card_slot == 3) {
    if (ss_mode & MF_SLOTC3ROM) {
      // leave it slot 3 if SLOTC3ROM is on
    } else {
      // redirect to slot 0 if SLOTC3ROM is off
      card_slot = 0;
    }
  }
  card_shared_owner = card_slot;
  handle_card_page_addr[card_slot](addr, rw);
}

FASTRUN void card_page_data_func(uint16_t addr, uint8_t data, bool rw) {
  uint32_t card_slot = (addr & 0xf00) >> 8;
  // if we're not in SLOTC3ROM mode, an access to slot 3 gets redirected
  // to slot 0
  if (card_slot == 3) {
    if (ss_mode & MF_SLOTC3ROM) {
      // leave it slot 3 if SLOTC3ROM is on
    } else {
      // redirect to slot 0 if SLOTC3ROM is off
      card_slot = 0;
    }
  }
  card_shared_owner = card_slot;
  handle_card_page_data[card_slot](addr, data, rw);
}

FASTRUN void card_shared_addr_func(uint16_t addr, bool rw) {
  if (addr == 0xcfff) {
    card_shared_owner = -1;
  }
  if (card_shared_owner < 0) {
    return;
  }
  handle_card_shared_addr[card_shared_owner](addr, rw);
}

FASTRUN void card_shared_data_func(uint16_t addr, uint8_t data, bool rw) {
  if (addr == 0xcfff) {
    card_shared_owner = -1;
  }
  if (card_shared_owner < 0) {
    return;
  }
  handle_card_shared_data[card_shared_owner](addr, data, rw);
}

void empty_slot_addr(uint16_t addr, bool rw) {
  // do nothing
}

void empty_slot_data(uint16_t addr, uint8_t data, bool rw) {
  // do nothing
}

void tini_preboot_card_addr_func(uint16_t addr, bool rw) {
  if (!rw) {
    return;
  }
  uint32_t image_offset = addr & 0x00ff;
  emit_byte(preboot_card_image[image_offset]);
}

void tini_preboot_card_data_func(uint16_t addr, uint8_t data, bool rw) {
  // nothing to be done here
}

void tini_preboot_shared_addr_func(uint16_t addr, bool rw) {
  if (!rw) {
    return;
  }
  uint32_t image_offset = addr & 0x07ff;
  emit_byte(preboot_shared_image[image_offset]);
}

void tini_preboot_shared_data_func(uint16_t addr, uint8_t data, bool rw) {
  if (rw) {
    return;
  }
  if (addr == 0xc800) {
    // we write the machine type here during preboot:
    // 00: pre-IIe
    // 01: unenhanced IIe
    // 02: enhanced IIe
    // 03: GS
    preboot_shared_image[0x7ff] = data;
    if (data == 0x03) {
      // set to the value it will eventually get used as in event publish
      apple_iigs_mode = (1 << 31);
    } else {
      apple_iigs_mode = 0;
    }
    Serial.print("machine type:");
    Serial.print(data);
  }
}

void fake_vidhd_addr_func(uint16_t addr, bool rw) {
  if (!rw) {
    return;
  }
  uint32_t image_offset = addr & 0x00ff;
  emit_byte(fake_vidhd_image[image_offset]);
}

void fake_vidhd_data_func(uint16_t addr, uint8_t data, bool rw) {
  // nothing to be done here
}

void initialize_memory_page_handlers() {
  for (int i = 0x00; i < 0x02; ++i) {
    memory_page_addr_callbacks[i] = &zpstack_addr;
    memory_page_addr_callbacks[i + 0x100] = &zpstack_addr;
    memory_page_data_callbacks[i] = &zpstack_data;
    memory_page_data_callbacks[i + 0x100] = &zpstack_data;
  }
  for (int i = 0x02; i < 0x04; ++i) {
    memory_page_addr_callbacks[i] = &main_addr_read;
    memory_page_addr_callbacks[i + 0x100] = &main_addr_write;
    memory_page_data_callbacks[i] = &main_data_read;
    memory_page_data_callbacks[i + 0x100] = &main_data_write;
  }
  for (int i = 0x04; i < 0x08; ++i) {
    memory_page_addr_callbacks[i] = &text_addr_read;
    memory_page_addr_callbacks[i + 0x100] = &text_addr_write;
    memory_page_data_callbacks[i] = &text_data_read;
    memory_page_data_callbacks[i + 0x100] = &text_data_write;
  }
  for (int i = 0x08; i < 0x20; ++i) {
    memory_page_addr_callbacks[i] = &main_addr_read;
    memory_page_addr_callbacks[i + 0x100] = &main_addr_write;
    memory_page_data_callbacks[i] = &main_data_read;
    memory_page_data_callbacks[i + 0x100] = &main_data_write;
  }
  for (int i = 0x20; i < 0x40; ++i) {
    memory_page_addr_callbacks[i] = &hires_addr_read;
    memory_page_addr_callbacks[i + 0x100] = &hires_addr_write;
    memory_page_data_callbacks[i] = &hires_data_read;
    memory_page_data_callbacks[i + 0x100] = &hires_data_write;
  }
  for (int i = 0x40; i < 0xc0; ++i) {
    memory_page_addr_callbacks[i] = &main_addr_read;
    memory_page_addr_callbacks[i + 0x100] = &main_addr_write;
    memory_page_data_callbacks[i] = &main_data_read;
    memory_page_data_callbacks[i + 0x100] = &main_data_write;
  }
  memory_page_addr_callbacks[0xc0] = &c0_page_addr;
  memory_page_addr_callbacks[0xc0 + 0x100] = &c0_page_addr;
  memory_page_data_callbacks[0xc0] = &c0_page_data;
  memory_page_data_callbacks[0xc0 + 0x100] = &c0_page_data;
  for (int i = 0xc1; i < 0xc8; ++i) {
    memory_page_addr_callbacks[i] = &card_page_addr;
    memory_page_addr_callbacks[i + 0x100] = &card_page_addr;
    memory_page_data_callbacks[i] = &card_page_data;
    memory_page_data_callbacks[i + 0x100] = &card_page_data;
  }
  for (int i = 0xc8; i < 0xd0; ++i) {
    memory_page_addr_callbacks[i] = &card_shared_addr;
    memory_page_addr_callbacks[i + 0x100] = &card_shared_addr;
    memory_page_data_callbacks[i] = &card_shared_data;
    memory_page_data_callbacks[i + 0x100] = &card_shared_data;
  }
  for (int i = 0xd0; i < 0xe0; ++i) {
    memory_page_addr_callbacks[i] = &high_banked_addr;
    memory_page_addr_callbacks[i + 0x100] = &high_banked_addr;
    memory_page_data_callbacks[i] = &high_banked_data;
    memory_page_data_callbacks[i + 0x100] = &high_banked_data;
  }
  for (int i = 0xe0; i < 0x100; ++i) {
    memory_page_addr_callbacks[i] = &high_unbanked_addr;
    memory_page_addr_callbacks[i + 0x100] = &high_unbanked_addr;
    memory_page_data_callbacks[i] = &high_unbanked_data;
    memory_page_data_callbacks[i + 0x100] = &high_unbanked_data;
  }
  for (int i = 0; i < 8; ++i) {
    handle_card_io_addr[i] = empty_slot_addr;
    handle_card_io_data[i] = empty_slot_data;
    handle_card_page_addr[i] = empty_slot_addr;
    handle_card_page_data[i] = empty_slot_data;
    handle_card_shared_addr[i] = empty_slot_addr;
    handle_card_shared_data[i] = empty_slot_data;
  }

  // set the "card 0" callbacks to be the internal rom.
  // when INTCXROM == 0 and SLOTC3ROM == 0,
  // access to slot 3 is redirected to slot 0, which is
  // set to ROM.  Also, hitting the slot 3 page in this mode
  // sets the card shared area to internal rom as well, until
  // released by 0xcfff.
  handle_card_page_addr[0] = low_rom_addr_func;
  handle_card_page_data[0] = low_rom_data_func;
  handle_card_shared_addr[0] = low_rom_addr_func;
  handle_card_shared_data[0] = low_rom_data_func;

  // put our handlers on slot 7
  handle_card_page_addr[7] = tini_preboot_card_addr_func;
  handle_card_page_data[7] = tini_preboot_card_data_func;
  handle_card_shared_addr[7] = tini_preboot_shared_addr_func;
  handle_card_shared_data[7] = tini_preboot_shared_data_func;

  // fake a vidhd if configured
  #ifdef FAKE_VIDHD_SLOT
  handle_card_page_addr[FAKE_VIDHD_SLOT] = fake_vidhd_addr_func;
  handle_card_page_data[FAKE_VIDHD_SLOT] = fake_vidhd_data_func;
  #endif

  c0_page_addr = c0_page_addr_func;
  c0_page_data = c0_page_data_func;
  card_shared_addr = card_shared_addr_func;
  card_shared_data = card_shared_data_func;
  reset_soft_switch_state();
  for (int i = 0; i < 512; ++i) {
    // if (*memory_page_addr_callbacks[i] == 0) {
    //   Serial.println(i);
    // }
    // char buf[64];
    // sprintf(buf,"%d:%p",i,(*memory_page_addr_callbacks[i]));

    // Serial.println(buf);
  }
}

// call this function when ALTZP, HIGHRAM, WRITERAM, or BANK2 are touched.
void update_altzp_lc_paging() {
  if (ss_mode & MF_ALTZP) {
    zpstack_addr = ram_addr_aux;
    zpstack_data = ram_data_aux;
    if (ss_mode & MF_HIGHRAM) {
      high_banked_addr = (ss_mode & MF_BANK2) ? ram_addr_aux_bank2 : ram_addr_aux_bank1;
      high_unbanked_addr = ram_addr_aux_bank2;
      high_banked_data = (ss_mode & MF_BANK2) ? ram_data_aux_bank2 : ram_data_aux_bank1;
      high_unbanked_data = ram_data_aux_bank2;
    } else {
      high_banked_addr = high_rom_addr_func;
      high_banked_data = high_rom_data_func;
      high_unbanked_addr = high_rom_addr_func;
      high_unbanked_data = high_rom_data_func;
    }
  } else {
    zpstack_addr = ram_addr_main;
    zpstack_data = ram_data_main;
    if (ss_mode & MF_HIGHRAM) {
      high_banked_addr = (ss_mode & MF_BANK2) ? ram_addr_main_bank2 : ram_addr_main_bank1;
      high_unbanked_addr = ram_addr_main_bank2;
      high_banked_data = (ss_mode & MF_BANK2) ? ram_data_main_bank2 : ram_data_main_bank1;
      high_unbanked_data = ram_data_main_bank2;
    } else {
      high_banked_addr = high_rom_addr_func;
      high_banked_data = high_rom_data_func;
      high_unbanked_addr = high_rom_addr_func;
      high_unbanked_data = high_rom_data_func;
    }
  }
}

// call this function when AUXREAD, AUXWRITE, 80STORE, PAGE2, or HIRES are touched.
void update_main_aux_paging() {
  if (ss_mode & MF_AUXREAD) {
    main_addr_read = ram_addr_aux;
    main_data_read = ram_data_aux;
  } else {
    main_addr_read = ram_addr_main;
    main_data_read = ram_data_main;
  }
  if (ss_mode & MF_AUXWRITE) {
    main_addr_write = ram_addr_aux;
    main_data_write = ram_data_aux;
  } else {
    main_addr_write = ram_addr_main;
    main_data_write = ram_data_main;
  }
  if (ss_mode & MF_80STORE) {
    if (ss_mode & MF_PAGE2) {
      text_addr_read = ram_addr_aux;
      text_addr_write = ram_addr_aux;
      text_data_read = ram_data_aux;
      text_data_write = ram_data_aux;
    } else {
      text_addr_read = ram_addr_main;
      text_addr_write = ram_addr_main;
      text_data_read = ram_data_main;
      text_data_write = ram_data_main;
    }
    if (ss_mode & MF_HIRES) {
      hires_addr_read = text_addr_read;
      hires_addr_write = text_addr_write;
      hires_data_read = text_data_read;
      hires_data_write = text_data_write;
    } else {
      hires_addr_read = main_addr_read;
      hires_addr_write = main_addr_write;
      hires_data_read = main_data_read;
      hires_data_write = main_data_write;
    }
  } else {
    text_addr_read = main_addr_read;
    text_addr_write = main_addr_write;
    text_data_read = main_data_read;
    text_data_write = main_data_write;
    hires_addr_read = main_addr_read;
    hires_addr_write = main_addr_write;
    hires_data_read = main_data_read;
    hires_data_write = main_data_write;
  }
}

// call this function when INTCXROM is touched.
// SLOTC3ROM is related, but handled in the callbacks.
void update_card_paging() {
  if (ss_mode & MF_INTCXROM) {
    card_page_addr = low_rom_addr_func;
    card_page_data = low_rom_data_func;
  } else {
    card_page_addr = card_page_addr_func;
    card_page_data = card_page_data_func;
  }
}

void initialize_soft_switch_handlers() {

  for (int i = 0; i < 0x90; ++i) {
    handle_soft_switch[i] = &soft_switch_null_handler;
  }

  handle_soft_switch[0x00] = &ss_kbd_80storeoff;
  handle_soft_switch[0x01] = &ss_80storeon;
  handle_soft_switch[0x02] = &ss_ramrdoff;
  handle_soft_switch[0x03] = &ss_ramrdon;
  handle_soft_switch[0x04] = &ss_ramwrtoff;
  handle_soft_switch[0x05] = &ss_ramwrton;
  handle_soft_switch[0x06] = &ss_intcxromoff;
  handle_soft_switch[0x07] = &ss_intcxromon;
  handle_soft_switch[0x08] = &ss_altzpoff;
  handle_soft_switch[0x09] = &ss_altzpon;
  handle_soft_switch[0x0a] = &ss_slotc3romoff;
  handle_soft_switch[0x0b] = &ss_slotc3romon;
  handle_soft_switch[0x10] = &ss_kbdstrb;
  handle_soft_switch[0x13] = &ss_ramrd;
  handle_soft_switch[0x14] = &ss_ramwrt;
  handle_soft_switch[0x15] = &ss_intcxrom;
  handle_soft_switch[0x16] = &ss_altzp;
  handle_soft_switch[0x17] = &ss_slotc3rom;
  handle_soft_switch[0x18] = &ss_80store;
  handle_soft_switch[0x19] = &ss_vbl;
  handle_soft_switch[0x1c] = &ss_page2;
  handle_soft_switch[0x1d] = &ss_hires;
  //handle_soft_switch[0x20] = &ss_tape;
  handle_soft_switch[0x56] = &ss_hiresoff;
  handle_soft_switch[0x57] = &ss_hireson;
  handle_soft_switch[0x80] = &ss_languagecard;
  handle_soft_switch[0x81] = &ss_languagecard;
  handle_soft_switch[0x82] = &ss_languagecard;
  handle_soft_switch[0x83] = &ss_languagecard;
  handle_soft_switch[0x84] = &ss_languagecard;
  handle_soft_switch[0x85] = &ss_languagecard;
  handle_soft_switch[0x86] = &ss_languagecard;
  handle_soft_switch[0x87] = &ss_languagecard;
  handle_soft_switch[0x88] = &ss_languagecard;
  handle_soft_switch[0x89] = &ss_languagecard;
  handle_soft_switch[0x8a] = &ss_languagecard;
  handle_soft_switch[0x8b] = &ss_languagecard;
  handle_soft_switch[0x8c] = &ss_languagecard;
  handle_soft_switch[0x8d] = &ss_languagecard;
  handle_soft_switch[0x8e] = &ss_languagecard;
  handle_soft_switch[0x8f] = &ss_languagecard;
}
