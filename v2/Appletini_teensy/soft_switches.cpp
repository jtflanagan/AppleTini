#include "globals.h"
#include "soft_switches.h"

uint32_t ss_mode = 0;
uint32_t last_ramwrite_flag = 0;

FASTRUN void soft_switch_null_handler(bool data_phase, uint32_t data) {
  return;
}

FASTRUN void ss_kbd_80storeoff(bool data_phase, uint32_t data) {
  if (data_phase) {
    apple_main_memory[bus_address] = data;
    return;
  }
  if (bus_rw) {
    data_completion_callback = &ss_kbd_80storeoff;
  } else {
    ss_mode &= ~MF_80STORE;
  }
}

FASTRUN void ss_80storeon(bool data_phase, uint32_t data) {
  if (bus_rw) {
    return;
  }
  ss_mode |= MF_80STORE;
}

FASTRUN void ss_ramrdoff(bool data_phase, uint32_t data) {
  if (bus_rw) {
    return;
  }
  ss_mode &= ~MF_AUXREAD;
}

FASTRUN void ss_ramrdon(bool data_phase, uint32_t data) {
  if (bus_rw) {
    return;
  }
  ss_mode |= MF_AUXREAD;
}

FASTRUN void ss_ramwrtoff(bool data_phase, uint32_t data) {
  if (bus_rw) {
    return;
  }
  ss_mode &= ~MF_AUXWRITE;
}

FASTRUN void ss_ramwrton(bool data_phase, uint32_t data) {
  if (bus_rw) {
    return;
  }
  ss_mode |= MF_AUXWRITE;
}

FASTRUN void ss_intcxromoff(bool data_phase, uint32_t data) {
  if (bus_rw) {
    return;
  }
  ss_mode &= ~MF_INTCXROM;
}

FASTRUN void ss_intcxromon(bool data_phase, uint32_t data) {
  if (bus_rw) {
    return;
  }
  ss_mode |= MF_INTCXROM;
}

FASTRUN void ss_altzpoff(bool data_phase, uint32_t data) {
  if (bus_rw) {
    return;
  }
  ss_mode &= ~MF_ALTZP;
}

FASTRUN void ss_altzpon(bool data_phase, uint32_t data) {
  if (bus_rw) {
    return;
  }
  ss_mode |= MF_ALTZP;
}

FASTRUN void ss_slotc3romoff(bool data_phase, uint32_t data) {
  if (bus_rw) {
    return;
  }
  ss_mode &= ~MF_SLOTC3ROM;
}

FASTRUN void ss_slotc3romon(bool data_phase, uint32_t data) {
  if (bus_rw) {
    return;
  }
  ss_mode |= MF_SLOTC3ROM;
}

FASTRUN void ss_80coloff(bool data_phase, uint32_t data) {}

FASTRUN void ss_80colon(bool data_phase, uint32_t data) {}

FASTRUN void ss_altcharsetoff(bool data_phase, uint32_t data) {}

FASTRUN void ss_altcharseton(bool data_phase, uint32_t data) {}

FASTRUN void ss_kbdstrb(bool data_phase, uint32_t data) {
  // clear strobe bit on key
  apple_main_memory[0xc000] &= 0x7f;
}

FASTRUN void ss_bsrbank2(bool data_phase, uint32_t data) {}

FASTRUN void ss_bsrreadram(bool data_phase, uint32_t data) {}

FASTRUN void ss_ramrd(bool data_phase, uint32_t data) {
  if (data_phase) {
    if (data & 0x80) {
      ss_mode |= MF_AUXREAD;
    } else {
      ss_mode &= ~MF_AUXREAD;
    }
  }
  if (bus_rw) {
    data_completion_callback = &ss_ramrd;
  }
}

FASTRUN void ss_ramwrt(bool data_phase, uint32_t data) {
  if (data_phase) {
    if (data & 0x80) {
      ss_mode |= MF_AUXWRITE;
    } else {
      ss_mode &= ~MF_AUXWRITE;
    }
  }
  if (bus_rw) {
    data_completion_callback = &ss_ramwrt;
  }
}

FASTRUN void ss_intcxrom(bool data_phase, uint32_t data) {
  if (data_phase) {
    if (data & 0x80) {
      ss_mode |= MF_INTCXROM;
    } else {
      ss_mode &= ~MF_INTCXROM;
    }
  }
  if (bus_rw) {
    data_completion_callback = &ss_intcxrom;
  }
}

FASTRUN void ss_altzp(bool data_phase, uint32_t data) {
  if (data_phase) {
    if (data & 0x80) {
      ss_mode |= MF_ALTZP;
    } else {
      ss_mode &= ~MF_ALTZP;
    }
  }
  if (bus_rw) {
    data_completion_callback = &ss_altzp;
  }
}

FASTRUN void ss_slotc3rom(bool data_phase, uint32_t data) {
  if (data_phase) {
    if (data & 0x80) {
      ss_mode |= MF_SLOTC3ROM;
    } else {
      ss_mode &= ~MF_SLOTC3ROM;
    }
  }
  if (bus_rw) {
    data_completion_callback = &ss_slotc3rom;
  }
}

FASTRUN void ss_80store(bool data_phase, uint32_t data) {
  if (data_phase) {
    if (data & 0x80) {
      ss_mode |= MF_80STORE;
    } else {
      ss_mode &= MF_80STORE;
    }
  }
  if (bus_rw) {
    data_completion_callback = &ss_80store;
  }
}

FASTRUN void ss_vertblank(bool data_phase, uint32_t data) {}
FASTRUN void ss_text(bool data_phase, uint32_t data) {}
FASTRUN void ss_mixed(bool data_phase, uint32_t data) {}

FASTRUN void ss_page2(bool data_phase, uint32_t data) {
  if (data_phase) {
    if (data & 0x80) {
      ss_mode |= MF_PAGE2;
    } else {
      ss_mode &= ~MF_PAGE2;
    }
  }
  if (bus_rw) {
    data_completion_callback = &ss_page2;
  }
}

FASTRUN void ss_hires(bool data_phase, uint32_t data) {
  if (data_phase) {
    if (data & 0x80) {
      ss_mode |= MF_HIRES;
    } else {
      ss_mode &= ~MF_HIRES;
    }
  }
  if (bus_rw) {
    data_completion_callback = &ss_hires;
  }
}

FASTRUN void ss_altcharset(bool data_phase, uint32_t data) {}
FASTRUN void ss_80col(bool data_phase, uint32_t data) {}
FASTRUN void ss_tapeout(bool data_phase, uint32_t data) {}
FASTRUN void ss_monocolor(bool data_phase, uint32_t data) {}
FASTRUN void ss_tbcolor(bool data_phase, uint32_t data) {}
FASTRUN void ss_vgcint(bool data_phase, uint32_t data) {}
FASTRUN void ss_mousedata(bool data_phase, uint32_t data) {}
FASTRUN void ss_keymodreg(bool data_phase, uint32_t data) {}
FASTRUN void ss_datareg(bool data_phase, uint32_t data) {}
FASTRUN void ss_kmstatus(bool data_phase, uint32_t data) {}
FASTRUN void ss_rombank(bool data_phase, uint32_t data) {}
FASTRUN void ss_newvideo(bool data_phase, uint32_t data) {}
FASTRUN void ss_langsel(bool data_phase, uint32_t data) {}
FASTRUN void ss_charrom(bool data_phase, uint32_t data) {}
FASTRUN void ss_sltromsel(bool data_phase, uint32_t data) {}
FASTRUN void ss_vertcnt(bool data_phase, uint32_t data) {}
FASTRUN void ss_horizcnt(bool data_phase, uint32_t data) {}
FASTRUN void ss_spkr(bool data_phase, uint32_t data) {}
FASTRUN void ss_diskreg(bool data_phase, uint32_t data) {}
FASTRUN void ss_scanint(bool data_phase, uint32_t data) {}
FASTRUN void ss_clockdata(bool data_phase, uint32_t data) {}
FASTRUN void ss_clockctl(bool data_phase, uint32_t data) {}
FASTRUN void ss_shadow(bool data_phase, uint32_t data) {}
FASTRUN void ss_cyareg(bool data_phase, uint32_t data) {}
FASTRUN void ss_bmareg(bool data_phase, uint32_t data) {}
FASTRUN void ss_sccbreg(bool data_phase, uint32_t data) {}
FASTRUN void ss_sccareg(bool data_phase, uint32_t data) {}
FASTRUN void ss_sccbdata(bool data_phase, uint32_t data) {}
FASTRUN void ss_sccadata(bool data_phase, uint32_t data) {}
FASTRUN void ss_soundctl(bool data_phase, uint32_t data) {}
FASTRUN void ss_sounddata(bool data_phase, uint32_t data) {}
FASTRUN void ss_soundadrl(bool data_phase, uint32_t data) {}
FASTRUN void ss_soundadrh(bool data_phase, uint32_t data) {}
FASTRUN void ss_strobe(bool data_phase, uint32_t data) {}
FASTRUN void ss_rdvblmsk(bool data_phase, uint32_t data) {}
FASTRUN void ss_rdx0edge(bool data_phase, uint32_t data) {}
FASTRUN void ss_rdy0edge(bool data_phase, uint32_t data) {}
FASTRUN void ss_mmdeltax(bool data_phase, uint32_t data) {}
FASTRUN void ss_mmdeltay(bool data_phase, uint32_t data) {}
FASTRUN void ss_diagtype_intflag(bool data_phase, uint32_t data) {}
FASTRUN void ss_clrvblint(bool data_phase, uint32_t data) {}
FASTRUN void ss_clrxyint(bool data_phase, uint32_t data) {}
FASTRUN void ss_emubyte(bool data_phase, uint32_t data) {}
FASTRUN void ss_textoff(bool data_phase, uint32_t data) {}
FASTRUN void ss_texton(bool data_phase, uint32_t data) {}
FASTRUN void ss_mixedoff(bool data_phase, uint32_t data) {}
FASTRUN void ss_mixedon(bool data_phase, uint32_t data) {}

FASTRUN void ss_page2off(bool data_phase, uint32_t data) {
  ss_mode &= ~MF_PAGE2;
}

FASTRUN void ss_page2on(bool data_phase, uint32_t data) {
  ss_mode |= MF_PAGE2;
}

FASTRUN void ss_hiresoff(bool data_phase, uint32_t data) {
  ss_mode &= ~MF_HIRES;
}

FASTRUN void ss_hireson(bool data_phase, uint32_t data) {
  ss_mode |= MF_HIRES;
}

FASTRUN void ss_clran0(bool data_phase, uint32_t data) {}
FASTRUN void ss_setan0(bool data_phase, uint32_t data) {}
FASTRUN void ss_clran1(bool data_phase, uint32_t data) {}
FASTRUN void ss_setan1(bool data_phase, uint32_t data) {}
FASTRUN void ss_clran2(bool data_phase, uint32_t data) {}
FASTRUN void ss_setan2(bool data_phase, uint32_t data) {}
FASTRUN void ss_dhireson(bool data_phase, uint32_t data) {}
FASTRUN void ss_dhiresoff(bool data_phase, uint32_t data) {}
FASTRUN void ss_tapein_butn3(bool data_phase, uint32_t data) {}
FASTRUN void ss_rdbtn0(bool data_phase, uint32_t data) {}
FASTRUN void ss_butn1(bool data_phase, uint32_t data) {}
FASTRUN void ss_rd63(bool data_phase, uint32_t data) {}
FASTRUN void ss_paddl0(bool data_phase, uint32_t data) {}
FASTRUN void ss_paddl1(bool data_phase, uint32_t data) {}
FASTRUN void ss_paddl2(bool data_phase, uint32_t data) {}
FASTRUN void ss_paddl3(bool data_phase, uint32_t data) {}
FASTRUN void ss_statereg(bool data_phase, uint32_t data) {}
FASTRUN void ss_testreg(bool data_phase, uint32_t data) {}
FASTRUN void ss_clrtm(bool data_phase, uint32_t data) {}
FASTRUN void ss_banksel(bool data_phase, uint32_t data) {}
FASTRUN void ss_blossom(bool data_phase, uint32_t data) {}
FASTRUN void ss_ioudison(bool data_phase, uint32_t data) {}
FASTRUN void ss_ioudisoff(bool data_phase, uint32_t data) {}
FASTRUN void ss_languagecard(bool data_phase, uint32_t data) {
  if (!bus_rw) {
    return;
  }
  if (bus_address & 0x8) {
    ss_mode |= MF_BANK2;
  } else {
    ss_mode &= ~MF_BANK2;
  }
  if ( ((bus_address & 0x2) >> 1) == (bus_address & 0x1)) {
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
}



FASTRUN void initialize_soft_switch_handlers() {

  data_completion_callback = &soft_switch_null_handler;

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
  handle_soft_switch[0x0c] = &ss_80coloff;
  handle_soft_switch[0x0d] = &ss_80colon;
  handle_soft_switch[0x0e] = &ss_altcharsetoff;
  handle_soft_switch[0x0f] = &ss_altcharseton;
  handle_soft_switch[0x10] = &ss_kbdstrb;
  handle_soft_switch[0x11] = &ss_bsrbank2;
  handle_soft_switch[0x12] = &ss_bsrreadram;
  handle_soft_switch[0x13] = &ss_ramrd;
  handle_soft_switch[0x14] = &ss_ramwrt;
  handle_soft_switch[0x15] = &ss_intcxrom;
  handle_soft_switch[0x16] = &ss_altzp;
  handle_soft_switch[0x17] = &ss_slotc3rom;
  handle_soft_switch[0x18] = &ss_80store;
  handle_soft_switch[0x19] = &ss_vertblank;
  handle_soft_switch[0x1a] = &ss_text;
  handle_soft_switch[0x1b] = &ss_mixed;
  handle_soft_switch[0x1c] = &ss_page2;
  handle_soft_switch[0x1d] = &ss_hires;
  handle_soft_switch[0x1f] = &ss_80col;
  handle_soft_switch[0x20] = &ss_tapeout;
  handle_soft_switch[0x21] = &ss_monocolor;
  handle_soft_switch[0x22] = &ss_tbcolor;
  handle_soft_switch[0x23] = &ss_vgcint;
  handle_soft_switch[0x24] = &ss_mousedata;
  handle_soft_switch[0x25] = &ss_keymodreg;
  handle_soft_switch[0x26] = &ss_datareg;
  handle_soft_switch[0x27] = &ss_kmstatus;
  handle_soft_switch[0x28] = &ss_rombank;
  handle_soft_switch[0x29] = &ss_newvideo;
  handle_soft_switch[0x2a] = &soft_switch_null_handler;
  handle_soft_switch[0x2b] = &ss_langsel;
  handle_soft_switch[0x2c] = &ss_charrom;
  handle_soft_switch[0x2d] = &ss_sltromsel;
  handle_soft_switch[0x2e] = &ss_vertcnt;
  handle_soft_switch[0x2f] = &ss_horizcnt;
  handle_soft_switch[0x30] = &ss_spkr;
  handle_soft_switch[0x31] = &ss_diskreg;
  handle_soft_switch[0x32] = &ss_scanint;
  handle_soft_switch[0x33] = &ss_clockdata;
  handle_soft_switch[0x34] = &ss_clockctl;
  handle_soft_switch[0x35] = &ss_shadow;
  handle_soft_switch[0x36] = &ss_cyareg;
  handle_soft_switch[0x37] = &ss_bmareg;
  handle_soft_switch[0x38] = &ss_sccbreg;
  handle_soft_switch[0x39] = &ss_sccareg;
  handle_soft_switch[0x3a] = &ss_sccbdata;
  handle_soft_switch[0x3b] = &ss_sccadata;
  handle_soft_switch[0x3c] = &ss_soundctl;
  handle_soft_switch[0x3d] = &ss_sounddata;
  handle_soft_switch[0x3e] = &ss_soundadrl;
  handle_soft_switch[0x3f] = &ss_soundadrh;
  handle_soft_switch[0x40] = &ss_strobe;
  handle_soft_switch[0x41] = &ss_rdvblmsk;
  handle_soft_switch[0x42] = &ss_rdx0edge;
  handle_soft_switch[0x43] = &ss_rdy0edge;
  handle_soft_switch[0x44] = &ss_mmdeltax;
  handle_soft_switch[0x45] = &ss_mmdeltay;
  handle_soft_switch[0x46] = &ss_diagtype_intflag;
  handle_soft_switch[0x47] = &ss_clrvblint;
  handle_soft_switch[0x48] = &ss_clrxyint;
  handle_soft_switch[0x49] = &soft_switch_null_handler;
  handle_soft_switch[0x4a] = &soft_switch_null_handler;
  handle_soft_switch[0x4b] = &soft_switch_null_handler;
  handle_soft_switch[0x4c] = &soft_switch_null_handler;
  handle_soft_switch[0x4d] = &soft_switch_null_handler;
  handle_soft_switch[0x4e] = &soft_switch_null_handler;
  handle_soft_switch[0x4f] = &ss_emubyte;
  handle_soft_switch[0x50] = &ss_textoff;
  handle_soft_switch[0x51] = &ss_texton;
  handle_soft_switch[0x52] = &ss_mixedoff;
  handle_soft_switch[0x53] = &ss_mixedon;
  handle_soft_switch[0x54] = &ss_page2off;
  handle_soft_switch[0x55] = &ss_page2on;
  handle_soft_switch[0x56] = &ss_hiresoff;
  handle_soft_switch[0x57] = &ss_hireson;
  handle_soft_switch[0x58] = &ss_clran0;
  handle_soft_switch[0x59] = &ss_setan0;
  handle_soft_switch[0x5a] = &ss_clran1;
  handle_soft_switch[0x5b] = &ss_setan1;
  handle_soft_switch[0x5c] = &ss_clran2;
  handle_soft_switch[0x5d] = &ss_setan2;
  handle_soft_switch[0x5e] = &ss_dhireson;
  handle_soft_switch[0x5f] = &ss_dhiresoff;
  handle_soft_switch[0x60] = &ss_tapein_butn3;
  handle_soft_switch[0x61] = &ss_rdbtn0;
  handle_soft_switch[0x62] = &ss_butn1;
  handle_soft_switch[0x63] = &ss_rd63;
  handle_soft_switch[0x64] = &ss_paddl0;
  handle_soft_switch[0x65] = &ss_paddl1;
  handle_soft_switch[0x66] = &ss_paddl2;
  handle_soft_switch[0x67] = &ss_paddl3;
  handle_soft_switch[0x68] = &ss_statereg;
  handle_soft_switch[0x69] = &ss_testreg;
  handle_soft_switch[0x70] = &ss_clrtm;
  handle_soft_switch[0x71] = &soft_switch_null_handler;
  handle_soft_switch[0x72] = &soft_switch_null_handler;
  handle_soft_switch[0x73] = &ss_banksel;
  handle_soft_switch[0x74] = &ss_blossom;
  handle_soft_switch[0x78] = &soft_switch_null_handler;
  handle_soft_switch[0x79] = &soft_switch_null_handler;
  handle_soft_switch[0x7a] = &soft_switch_null_handler;
  handle_soft_switch[0x7b] = &soft_switch_null_handler;
  handle_soft_switch[0x7c] = &soft_switch_null_handler;
  handle_soft_switch[0x7d] = &soft_switch_null_handler;
  handle_soft_switch[0x7e] = &ss_ioudison;
  handle_soft_switch[0x7f] = &ss_ioudisoff;
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
