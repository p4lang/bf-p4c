#ifndef BF_ASM_TOFINO_COUNTER_H_
#define BF_ASM_TOFINO_COUNTER_H_

#include "tables.h"

class Target::Tofino::CounterTable : public ::CounterTable {
    friend class ::CounterTable;
    CounterTable(int line, const char *n, gress_t gr, Stage *s, int lid) :
        ::CounterTable(line, n, gr, s, lid) { }
};

template<> void CounterTable::setup_teop_regs(Target::Tofino::mau_regs &, int) {
    BUG();  // no teop on tofino
}

template<> void CounterTable::write_alu_vpn_range(Target::Tofino::mau_regs &) {
    BUG();  // not available on tofino
}

#endif  /* BF_ASM_TOFINO_COUNTER_H_ */
