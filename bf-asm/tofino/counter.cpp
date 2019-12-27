template<> void CounterTable::setup_teop_regs(Target::Tofino::mau_regs &, int) {
    BUG(); // no teop on tofino
}
