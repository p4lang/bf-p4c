#ifndef BF_ASM_TOFINO_METER_H_
#define BF_ASM_TOFINO_METER_H_

#include <tables.h>

class Target::Tofino::MeterTable : public ::MeterTable {
    friend class ::MeterTable;
    MeterTable(int line, const char *n, gress_t gr, Stage *s, int lid) :
        ::MeterTable(line, n, gr, s, lid) { }
};

template<> void MeterTable::setup_teop_regs(Target::Tofino::mau_regs &, int) {
    BUG();  // no teop on tofino
}

template<> void MeterTable::write_alu_vpn_range(Target::Tofino::mau_regs &) {
    BUG();  // not available on tofino
}

#endif  /* BF_ASM_TOFINO_METER_H_ */
