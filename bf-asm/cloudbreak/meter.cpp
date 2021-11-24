template<> void MeterTable::setup_teop_regs(Target::Cloudbreak::mau_regs &regs,
                                            int meter_group_index) {
    setup_teop_regs_2(regs, meter_group_index);
}

template<> void MeterTable::write_alu_vpn_range(Target::Cloudbreak::mau_regs &regs) {
    write_alu_vpn_range_2(regs);
}
