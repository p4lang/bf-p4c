template<> void MeterTable::setup_teop_regs(Target::Tofino::mau_regs &, int) {
    BUG();  // no teop on tofino
}

template<> void MeterTable::write_alu_vpn_range(Target::Tofino::mau_regs &) {
    BUG();  // not available on tofino
}
