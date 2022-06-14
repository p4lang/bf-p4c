#ifndef BF_ASM_FLATROCK_HASH_ACTION_H_
#define BF_ASM_FLATROCK_HASH_ACTION_H_

#include <tables.h>

#if HAVE_FLATROCK
template<> void HashActionTable::write_regs_vt(Target::Flatrock::mau_regs &regs);
#endif /* HAVE_FLATROCK */

#endif /* BF_ASM_FLATROCK_HASH_ACTION_H_ */
