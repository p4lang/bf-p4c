#include "counter.h"
#include "stage.h"
#include "top_level.h"

void Target::Flatrock::CounterTable::pass1() {
    ::CounterTable::pass1();
    if (match_tables.size() != 1)
        error(lineno, "Counter can only be used by a single match table on Flatrock");
    mark_dual_port_use();
    if (!physical_ids.empty())
        alloc_global_busses();
}

void Target::Flatrock::CounterTable::pass2() {
    ::CounterTable::pass2();
    if (physical_ids.empty()) {
        alloc_dual_port(0xa);
        if (!physical_ids.empty())
            alloc_global_busses(); }
    alloc_vpns();
}

template<> void CounterTable::write_merge_regs_vt(Target::Flatrock::mau_regs &, MatchTable *,
                int, int, const std::vector<Call::Arg> &) {
    BUG("write_merge_regs not used on Flatrock");
}

template<> void CounterTable::write_regs_vt(Target::Flatrock::mau_regs &regs) {
    LOG1("### Counter " << name() << " write_regs " << loc());
    Synth2Port::write_regs(regs);

    BUG_CHECK(physical_ids.popcount() == 1, "not exactly one physical id in %s", name());
    int physid = *physical_ids.begin();
    BUG_CHECK(physid == 1 || physid == 3, "counter can only be on DPM 1 or 3");
    if (physid == 1) {
        regs.ppu_dpm.module.dpm_cfg.dpu1_sel = 2;
        regs.ppu_mrd.rf.mrd_cfg.au1_sel = 1; }
    if (physid == 3) {
        regs.ppu_dpm.module.dpm_cfg.dpu3_sel = 2;
        regs.ppu_mrd.rf.mrd_cfg.au3_sel = 1; }

    auto &stats_alu = regs.ppu_stats[physid/2].ppu_stats_alu;
    auto &stats_cfg = regs.ppu_stats[physid/2].rf.stats_cfg;
    stats_cfg.eop_en = 1;  // always runs at eop
    stats_alu.stats_alu_cfg.byte_en = (type == BYTES || type == BOTH);
    stats_alu.stats_alu_cfg.packet_en = (type == PACKETS || type == BOTH);
    stats_alu.stats_alu_cfg.bytecount_adjust = bytecount_adjust;
    stats_alu.stats_alu_cfg.entries_per_word = format->groups() * (4 >> (format->log2size - 5));
    stats_alu.stats_alu_cfg.lrt_en = lrt.size() > 0;
    int idx = 0;
    for (auto &l : lrt) {
        stats_alu.stats_interval_cfg[idx].interval = l.interval;
        stats_alu.stats_threshold_cfg[idx].threshold = l.threshold;
        ++idx; }
}
