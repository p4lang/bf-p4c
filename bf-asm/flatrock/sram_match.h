#ifndef BF_ASM_FLATROCK_SRAM_MATCH_H_
#define BF_ASM_FLATROCK_SRAM_MATCH_H_

#include <tables.h>

#if HAVE_FLATROCK
template<> void SRamMatchTable::write_attached_merge_regs(Target::Flatrock::mau_regs &regs,
                                                          int bus, int word, int word_group);
template<> void SRamMatchTable::write_regs_vt(Target::Flatrock::mau_regs &regs);
#endif /* HAVE_FLATROCK */

#endif /* BF_ASM_FLATROCK_SRAM_MATCH_H_ */
