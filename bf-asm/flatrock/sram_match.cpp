/* template specializations for flatrock -- #included directly in sram_match.cpp */

template<> void SRamMatchTable::write_attached_merge_regs(Target::Flatrock::mau_regs &regs,
            int bus, int word, int word_group) {
    BUG("TBD");
}
template<> void SRamMatchTable::write_regs_vt(Target::Flatrock::mau_regs &regs) {
    LOG1("### SRam match table " << name() << " write_regs " << loc());
    MatchTable::write_regs(regs, 0, this);

    for (auto &row : layout) {
        BUG("TDB -- STM setup");
    }
    if (actions) actions->write_regs(regs, this);
    if (gateway) gateway->write_regs(regs);
    if (idletime) idletime->write_regs(regs);
}

