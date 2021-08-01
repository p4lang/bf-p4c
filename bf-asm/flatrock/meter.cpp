

template<> void MeterTable::write_merge_regs_vt(Target::Flatrock::mau_regs &regs,
            MatchTable *match, int type, int bus, const std::vector<Call::Arg> &args) {
    BUG("TBD");
}

template<> void MeterTable::write_color_regs(Target::Flatrock::mau_regs &regs,
                                             MatchTable *match, int type, int bus,
                                             const std::vector<Call::Arg> &args) {
    BUG("TBD");
}

template<> void MeterTable::setup_exact_shift(Target::Flatrock::mau_regs &regs,
                                              int bus, int group, int word, int word_group,
                                              Call &meter_call, Call &color_call) {
    BUG("TBD");
}

template<> void MeterTable::setup_tcam_shift(Target::Flatrock::mau_regs &regs,
                                              int bus, int tcam_shift,
                                              Call &meter_call, Call &color_call) {
    BUG("TBD");
}

template<> void MeterTable::write_regs_vt(Target::Flatrock::mau_regs &regs) {
    BUG("TBD");
}
