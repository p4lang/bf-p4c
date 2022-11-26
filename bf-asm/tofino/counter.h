#ifndef BF_ASM_TOFINO_COUNTER_H_
#define BF_ASM_TOFINO_COUNTER_H_

template<> void CounterTable::setup_teop_regs(Target::Tofino::mau_regs &, int) {
    BUG();  // no teop on tofino
}

template<> void CounterTable::write_alu_vpn_range(Target::Tofino::mau_regs &) {
    BUG();  // not available on tofino
}

#endif  /* BF_ASM_TOFINO_COUNTER_H_ */
