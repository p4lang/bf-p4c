#ifndef BF_ASM_TOFINO_STATEFUL_H_
#define BF_ASM_TOFINO_STATEFUL_H_

#include <tables.h>
#include <target.h>

class Target::Tofino::StatefulTable : public ::StatefulTable {
    friend class ::StatefulTable;
    StatefulTable(int line, const char *n, gress_t gr, Stage *s, int lid) :
        ::StatefulTable(line, n, gr, s, lid) { }
};

template<> void StatefulTable::write_logging_regs(Target::Tofino::mau_regs &regs);

#endif  /* BF_ASM_TOFINO_STATEFUL_H_ */
