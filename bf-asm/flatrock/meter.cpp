#include "meter.h"

void Target::Flatrock::MeterTable::pass1() {
    ::MeterTable::pass1();
    if (match_tables.size() != 1)
        error(lineno, "Meter can only be used by a single match table on Flatrock");
    mark_dual_port_use();
    if (!physical_ids.empty())
        alloc_global_busses();
}

void Target::Flatrock::MeterTable::pass2() {
    ::MeterTable::pass2();
    if (physical_ids.empty()) {
        alloc_dual_port(0x5);
        if (!physical_ids.empty())
            alloc_global_busses(); }
    alloc_vpns();
}


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
    LOG1("### Meter " << name() << " write_regs " << loc());
    Synth2Port::write_regs(regs);

    BUG_CHECK(physical_ids.popcount() == 1, "not exactly one physical id in %s", name());
    int physid = *physical_ids.begin();
    BUG_CHECK(physid == 0 || physid == 2, "meter can only be on DPM 0 or 2");
    if (physid == 0) {
        regs.ppu_dpm.module.dpm_cfg.dpu0_sel = 2;
        regs.ppu_mrd.rf.mrd_cfg.au0_sel = 1; }
    if (physid == 2) {
        regs.ppu_dpm.module.dpm_cfg.dpu2_sel = 2;
        regs.ppu_mrd.rf.mrd_cfg.au2_sel = 1; }

    error(lineno, "%s:%d: Flatrock meter not fully implemented yet!", SRCFILE, __LINE__);
}
