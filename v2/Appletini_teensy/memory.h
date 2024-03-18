#ifndef APPLETINI_SOFT_SWITCHES_H
#define APPLETINI_SOFT_SWITCHES_H

#include "globals.h"

#define  MF_80STORE    0x00000001
#define  MF_ALTZP      0x00000002
#define  MF_AUXREAD    0x00000004       // RAMRD
#define  MF_AUXWRITE   0x00000008       // RAMWRT
#define  MF_BANK2      0x00000010   // Language Card Bank 2 $D000..$DFFF
#define  MF_HIGHRAM    0x00000020   // Language Card RAM is active $D000..$DFFF
#define  MF_HIRES      0x00000040
#define  MF_PAGE2      0x00000080
#define  MF_SLOTC3ROM  0x00000100
#define  MF_INTCXROM   0x00000200
#define  MF_WRITERAM   0x00000400   // Language Card RAM is Write Enabled
#define  MF_INTC8ROM   0x00000800   // hidden INTC8ROM flag
#define  MF_LANGCARD_MASK       (MF_WRITERAM|MF_HIGHRAM|MF_BANK2)

extern uint32_t ss_mode;
extern uint32_t last_ramwrite_flag;

void initialize_memory_page_handlers();
void initialize_soft_switch_handlers();
void reset_soft_switch_state();
void update_altzp_lc_paging();
void update_main_aux_paging();
void update_card_paging();

#endif