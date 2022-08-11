#ifndef BF_ASM_FLATROCK_ACTION_TABLE_H_
#define BF_ASM_FLATROCK_ACTION_TABLE_H_

#include "tables.h"

#if HAVE_FLATROCK

template<> void ActionTable::write_regs_vt(Target::Flatrock::mau_regs &regs);

class Target::Flatrock::ActionTable : public ::ActionTable {
 public:
    ActionTable(int line, const char *n, gress_t gr, Stage *s, int lid) :
        ::ActionTable(line, n, gr, s, lid) { }
};

#endif

#endif  /* BF_ASM_FLATROCK_ACTION_TABLE_H_ */
