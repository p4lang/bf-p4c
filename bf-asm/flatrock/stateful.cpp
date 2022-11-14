/* mau table template specializations for flatrock -- #included directly in stateful.cpp */

int StatefulTable::parse_counter_mode(Target::Flatrock target, const value_t &v) {
    return parse_jbay_counter_mode(v);
}

void StatefulTable::set_counter_mode(Target::Flatrock target, int mode) {
    error(lineno, "%s:%d: Flatrock stateful not implemented yet!", SRCFILE, __LINE__);
}

void StatefulTable::gen_tbl_cfg(Target::Flatrock, json::map&, json::map&) const {
    error(lineno, "%s:%d: Flatrock stateful not implemented yet!", SRCFILE, __LINE__);
}

// DANGER -- nasty hack to set the raw bits of an SALU state alu instruction
// really need to make the csr2cpp codegen handle this automatically
void set_ftr_raw_instr_bits(checked_array<4,
    Flatrock::regs_match_action_stage_::_ppu_sful::_ppu_sful_alu::_sful_instr_state_alu> &reg,
    bitvec v) {
    for (int i = 0; i < 4; ++i) {
        reg[i].const_src = v.getrange(i*32, 4);
        reg[i].regfile_const = v.getrange(i*32 + 4, 1);
        reg[i].bsrc_input = v.getrange(i*32 + 5, 3);
        reg[i].asrc_input = v.getrange(i*32 + 8, 3);
        reg[i].op = v.getrange(i*32 + 11, 4);
        reg[i].arith = v.getrange(i*32 + 15, 1);
        reg[i].pred = v.getrange(i*32 + 16, 16);
    }
}

template<> void StatefulTable::write_logging_regs(Target::Flatrock::mau_regs &regs) {
    BUG_CHECK(physical_ids.popcount() == 1, "not exactly one physical id for %s", name());
    auto &sful = regs.ppu_sful[*physical_ids.begin()];
    auto &salu = sful.ppu_sful_alu;

    if (stateful_counter_mode && (stateful_counter_mode & FUNCTION_MASK) != FUNCTION_FAST_CLEAR) {
        // TODO:
    } else {
        if (busy_value) {
            salu.sful_clr_action_outp.action_outp = busy_value;
        }
        if (clear_value) {
            set_ftr_raw_instr_bits(salu.sful_instr_state_alu[3], clear_value);
            salu.sful_ctl.clear_value_ctl = 1;
        }
    }

    for (size_t i = 0; i < const_vals.size(); ++i) {
        if (const_vals[i].value > (INT64_C(1) << 33) || const_vals[i].value <= -(INT64_C(1) << 33))
            error(const_vals[i].lineno, "constant value %" PRId64 " too large for stateful alu",
                  const_vals[i].value);
        salu.sful_const_regfile[i].const_regfile = const_vals[i].value & 0xffffffffU;
        salu.sful_const_regfile_m[i].regfile_msbs = (const_vals[i].value >> 32) & 0x3;
    }

    if (stage_alu_id >= 0) {
        salu.sful_ctl.stage_id = stage_alu_id;
        salu.sful_ctl.stage_id_enable = 1;
    }
}
