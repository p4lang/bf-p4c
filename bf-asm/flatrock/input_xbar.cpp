#include "input_xbar.h"

template<> void InputXbar::write_regs(Target::Flatrock::mau_regs &regs) {
    LOG1("### Input xbar " << table->name() << " write_regs " << table->loc());
    for (auto &group : groups) {
        switch (group.first.type) {
        case Group::EXACT: {
            auto &em_key_cfg = regs.ppu_minput_rspec.minput_em_key_cfg[0];
            if (group.first.index) {
                for (auto &input : group.second)
                    em_key_cfg.key32[input.lo/32U] = input.what->reg.ixbar_id()/4U;
            } else {
                for (auto &input : group.second)
                    em_key_cfg.key8[input.lo/8U] = input.what->reg.ixbar_id();
            }
            break; }
        case Group::TERNARY: {
            auto &scm_key_cfg = regs.ppu_minput_rspec.minput_scm_key_cfg[0];
            int base = group.first.index * 5;  // first byte for the group
            for (auto &input : group.second)
                scm_key_cfg.sel[base + input.lo/8U] = input.what->reg.ixbar_id();
            break; }
        case Group::GATEWAY: {
            auto &gw_key_cfg = regs.ppu_minput_rspec.minput_gw_phv_cfg;
            for (auto &input : group.second)
                gw_key_cfg[input.lo/8U].sel = input.what->reg.ixbar_id();
            break; }
        case Group::XCMP:
            error(lineno, "%s:%d: Flatrock xcmp ixbar not implemented yet!", __FILE__, __LINE__);
            break;
        default:
            BUG("invalid InputXbar::Group::Type(%d)", group.first.type);
        }
    }
}

template void InputXbar::write_regs(Target::Flatrock::mau_regs &regs);
