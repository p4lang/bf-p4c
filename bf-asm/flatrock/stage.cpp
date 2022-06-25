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
        regs.rf.ppu_cfg.bypass = 1;
    }
    regs.rf.ppu_phvfifo_cfg.delay = 8;  // FIXME -- needs to be 8-31
    regs.rf.ppu_pktdly_cfg.delay = 2;   // FIXME -- needs to be 2-31
}

void AlwaysRunTable::write_regs(Target::Flatrock::mau_regs &regs) {
    error(lineno, "%s:%d: Flatrock always run not implemented yet!", __FILE__, __LINE__);
}
