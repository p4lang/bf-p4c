

template<> void MeterTable::write_merge_regs_vt(Target::Flatrock::mau_regs &regs,
            MatchTable *match, int type, int bus, const std::vector<Call::Arg> &args) {
    error(lineno, "%s:%d: Flatrock meter not implemented yet!", SRCFILE, __LINE__);
}

template<> void MeterTable::write_color_regs(Target::Flatrock::mau_regs &regs,
                                             MatchTable *match, int type, int bus,
                                             const std::vector<Call::Arg> &args) {
    error(lineno, "%s:%d: Flatrock meter not implemented yet!", SRCFILE, __LINE__);
}

template<> void MeterTable::setup_exact_shift(Target::Flatrock::mau_regs &regs,
                                              int bus, int group, int word, int word_group,
                                              Call &meter_call, Call &color_call) {
    error(lineno, "%s:%d: Flatrock meter not implemented yet!", SRCFILE, __LINE__);
}

template<> void MeterTable::setup_tcam_shift(Target::Flatrock::mau_regs &regs,
                                              int bus, int tcam_shift,
                                              Call &meter_call, Call &color_call) {
    error(lineno, "%s:%d: Flatrock meter not implemented yet!", SRCFILE, __LINE__);
}

template<> void MeterTable::write_regs_vt(Target::Flatrock::mau_regs &regs) {
    error(lineno, "%s:%d: Flatrock meter not implemented yet!", SRCFILE, __LINE__);
}
