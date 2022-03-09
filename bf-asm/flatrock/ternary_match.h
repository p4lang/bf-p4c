#ifndef BF_ASM_FLATROCK_TERNARY_MATCH_H_
#define BF_ASM_FLATROCK_TERNARY_MATCH_H_

#include <tables.h>

#if HAVE_FLATROCK
template<> void TernaryMatchTable::write_regs_vt(Target::Flatrock::mau_regs &regs);
template<> void TernaryIndirectTable::write_regs_vt(Target::Flatrock::mau_regs &regs);
#endif /* HAVE_FLATROCK */

#endif /* BF_ASM_FLATROCK_TERNARY_MATCH_H_ */
