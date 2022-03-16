#include "input_xbar.h"
#include "tables.h"

int Flatrock::InputXbar::group_max_index(Group::type_t t) const {
    switch (t) {
    case Group::EXACT:   return 2;
    case Group::TERNARY: return 16;
    case Group::GATEWAY: return 1;
    case Group::XCMP:    return 4;
    default:
       BUG("invalid group type for %s: %s", Target::name(), group_type(t)); }
    return 0;
}

InputXbar::Group Flatrock::InputXbar::group_name(bool tern, const value_t &key) const {
    if (key.type == tSTR) {
        if (key == "gateway") return Group(Group::GATEWAY, 0);
    } else if (key.type == tCMD && key.vec.size == 2) {
        if (key[0] == "exact") {
            if (key[1] == "byte") return Group(Group::EXACT, 0);
            if (key[1] == "word") return Group(Group::EXACT, 1);
        } else if (key[0] == "xcmp") {
            if (key[1] == "byte") return Group(Group::XCMP, 0);
            if (key[1] == "word") return Group(Group::XCMP, 1);
        } else if (key[0] == "ternary" && CHECKTYPE(key[1], tINT)) {
            return Group(Group::TERNARY, key[1].i); } }
    return Group(Group::INVALID, 0);
}

int Flatrock::InputXbar::group_size(Group::type_t t) const {
    switch (t) {
    case Group::EXACT:   return 20*8;
    case Group::TERNARY: return 5*8;
    case Group::GATEWAY: return 8*8;
    case Group::XCMP:    return 16*8;
    default:
        BUG("invalid group type for %s: %s", Target::name(), group_type(t)); }
    return 0;
}

void Flatrock::InputXbar::check_input(Group group, Input &input, TcamUseCache &tcam_use) {
    if (group.type == Group::TERNARY) {
        // all ternary are byte organized, but concatenated in groups of 5 bytes
        unsigned align = input.what->reg.size == 8 ? 8 : 16;
        unsigned bit = input.lo + 40 * group.index;
        if (bit % align != input.what->lo % align)
            error(input.what.lineno, "%s misaligned on input_xbar", input.what.name());
    } else if (group.index == 0) {
        // a byte organized group -- 8 bit alignment for 8 bit PHEs, 16 bit for 16/32 PHEs
        unsigned align = input.what->reg.size == 8 ? 8 : 16;
        if (input.lo % align != input.what->lo % align)
            error(input.what.lineno, "%s misaligned on input_xbar", input.what.name());
    } else if (group.index == 1) {
        // a word group -- needs 32-bit alignment
        unsigned bit = input.what->reg.index * input.what->reg.size + input.what->lo;
        if (input.lo % 32U != bit % 32U)
            error(input.what.lineno, "%s misaligned on input_xbar", input.what.name());
    } else {
        BUG("unexpected group %s %d for %s", group_type(group.type), group.index, Target::name());
    }
}

template<> void InputXbar::write_regs(Target::Flatrock::mau_regs &regs) {
    LOG1("### Input xbar " << table->name() << " write_regs " << table->loc());
    for (auto &group : groups) {
        switch (group.first.type) {
        case Group::EXACT: {
            auto &em_key_cfg = regs.ppu_minput_rspec.rf.minput_em_xb_key[0];
            if (group.first.index) {
                for (auto &input : group.second)
                    em_key_cfg.key32[input.lo/32U] = input.what->reg.ixbar_id()/4U;
            } else {
                for (auto &input : group.second)
                    em_key_cfg.key8[input.lo/8U] = input.what->reg.ixbar_id();
            }
            break; }
        case Group::TERNARY: {
            auto &scm_key_cfg = regs.ppu_minput_rspec.rf.minput_scm_xb_key[0];
            int base = group.first.index * 5;  // first byte for the group
            for (auto &input : group.second)
                scm_key_cfg.key8[base + input.lo/8U] = input.what->reg.ixbar_id();
            break; }
        case Group::GATEWAY: {
            auto &gw_key_cfg = regs.ppu_minput_rspec.rf.minput_gw_xb_vdg;
            for (auto &input : group.second)
                gw_key_cfg.vgd[input.lo/8U] = input.what->reg.ixbar_id();
            break; }
        case Group::XCMP: {
            auto &xcmp_key_cfg = regs.ppu_minput_rspec.rf.minput_xcmp_xb_key[0];
            if (group.first.index) {
                for (auto &input : group.second)
                    xcmp_key_cfg.key32[input.lo/32U] = input.what->reg.ixbar_id()/4U;
            } else {
                for (auto &input : group.second)
                    xcmp_key_cfg.key8[input.lo/8U] = input.what->reg.ixbar_id();
            }
            break; }
        default:
            BUG("invalid InputXbar::Group::Type(%d)", group.first.type);
        }
    }
}

template void InputXbar::write_regs(Target::Flatrock::mau_regs &regs);
