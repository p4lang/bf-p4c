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
                    em_key_cfg.key32[input.lo/8U] = input.what->reg.ixbar_id();
            }
            break; }
        case Group::TERNARY: {
            auto &scm_key_cfg = regs.ppu_minput_rspec.minput_scm_key_cfg[0][group.first.index];
            for (auto &input : group.second)
                scm_key_cfg.sel[input.lo/8U] = input.what->reg.ixbar_id();
            break; }
        case Group::GATEWAY: {
            auto &gw_key_cfg = regs.ppu_minput_rspec.minput_gw_phv_cfg;
            for (auto &input : group.second)
                gw_key_cfg[input.lo/8U].sel = input.what->reg.ixbar_id();
            break; }
        case Group::TRIE:
            BUG("TBD");
            break;
        case Group::ACTION:
            BUG("TBD");
            break;
        default:
            BUG("invalid InputXbar::Group::Type(%d)", group.first.type);
        }
    }
}

