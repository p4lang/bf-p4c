/* mau stage template specializations for jbay -- #included directly in top-level stage.cpp */

#include "input_xbar.h"

template<> void Stage::fixup_regs(Target::Flatrock::mau_regs &) {
}
template<> void Stage::gen_configuration_cache(Target::Flatrock::mau_regs &, json::vector &) {
}
template<> void Stage::gen_gfm_json_info(Target::Flatrock::mau_regs &, std::ostream &) {
}
template<> void Stage::gen_mau_stage_characteristics(Target::Flatrock::mau_regs &, json::vector &) {
}
template<> void Stage::gen_mau_stage_extension(Target::Flatrock::mau_regs &, json::map &) {
}
template<> void Stage::write_regs(Target::Flatrock::mau_regs &regs, bool egress_only) {
    if (egress_only) {
        Flatrock::InputXbar::write_global_regs(regs, EGRESS);
    } else {
        Flatrock::InputXbar::write_global_regs(regs, INGRESS);
        Flatrock::InputXbar::write_global_regs(regs, GHOST);
    }
    if (tables.empty()) {
        /* no tables in this stage, so bypass */
        regs.ppu_top.rf.ppu_cfg.bypass = 1;
    } else {
        // FIXME -- needs to be 1-16
        auto &nt_delay = regs.ppu_mrd.rf.mrd_nt_delay;
        nt_delay.pinfo_in_delay = 1;
        nt_delay.pinfo_out_delay = 1;
        nt_delay.pred_vec_delay = 1;
    }
    regs.ppu_top.rf.ppu_phvfifo_cfg.delay = 8;  // FIXME -- needs to be 8-31
    regs.ppu_top.rf.ppu_pktdly_cfg.delay = 2;   // FIXME -- needs to be 2-31
    for (auto &delay : regs.ppu_mrd.rf.mrd_iad_delay)
        delay.delay = 1;   // FIXME -- needs to be set even for non-enabled tables?

    // FIXME -- this should be based on the number of logical tables in the stage or
    // perhaps less if there are multiple that have the same control deps, but for
    // now we hardcode to 16 to match jbay/cloudbreak
    regs.ppu_mrd.rf.mrd_pred_cfg.pv_shr = 16;
}

void AlwaysRunTable::write_regs(Target::Flatrock::mau_regs &regs) {
    error(lineno, "%s:%d: Flatrock always run not implemented yet!", SRCFILE, __LINE__);
}
