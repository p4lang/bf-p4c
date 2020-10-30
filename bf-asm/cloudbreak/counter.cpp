template<> void CounterTable::setup_teop_regs(Target::Cloudbreak::mau_regs &regs,
                                              int stats_group_index) {
    setup_teop_regs_2(regs, stats_group_index);
}

template<> void CounterTable::write_alu_vpn_range(Target::Cloudbreak::mau_regs &regs) {
    write_alu_vpn_range_2(regs);
}
