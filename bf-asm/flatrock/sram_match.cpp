/* template specializations for flatrock -- #included directly in sram_match.cpp */

template<> void SRamMatchTable::write_attached_merge_regs(Target::Flatrock::mau_regs &regs,
            int bus, int word, int word_group) {
    error(lineno, "%s:%d: Flatrock sram match not implemented yet!", __FILE__, __LINE__);
}
template<> void SRamMatchTable::write_regs_vt(Target::Flatrock::mau_regs &regs) {
    LOG1("### SRam match table " << name() << " write_regs " << loc());
    MatchTable::write_regs(regs, 0, this);
    for (auto &ixb : input_xbar)
        ixb->write_xmu_regs(regs);

    for (auto &row : layout) {
        error(lineno, "%s:%d: Flatrock STM not implemented yet!", __FILE__, __LINE__);
    }

    if (actions) actions->write_regs(regs, this);
    if (gateway) gateway->write_regs(regs);
    if (idletime) idletime->write_regs(regs);
    for (auto &hd : hash_dist)
        hd.write_regs(regs, this);
}

