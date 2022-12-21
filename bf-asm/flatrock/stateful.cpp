#include "stateful.h"
#include "jbay/stateful.h"

void Target::Flatrock::StatefulTable::pass1() {
    ::StatefulTable::pass1();
    if (match_tables.size() != 1)
        error(lineno, "Stateful can only be used by a single match table on Flatrock");
    mark_dual_port_use();
    if (!physical_ids.empty())
        alloc_global_busses();
}

void Target::Flatrock::StatefulTable::pass2() {
    ::StatefulTable::pass2();
    if (physical_ids.empty()) {
        alloc_dual_port(0xf);
        if (!physical_ids.empty())
            alloc_global_busses(); }
    alloc_vpns();
}

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
    // TODO: Handle stack and fifo
    BUG_CHECK(physical_ids.popcount() == 1, "not exactly one physical id for %s", name());
    auto &sful = regs.ppu_sful[*physical_ids.begin()];
    auto &salu = sful.ppu_sful_alu;
    auto &sfulregs = sful.ppu_sful_reg;

    auto &ctl = sfulregs.sful_counter_ctl;
    if (stateful_counter_mode && (stateful_counter_mode & FUNCTION_MASK) != FUNCTION_FAST_CLEAR) {
        // FTR uses 4 for single-width 8-bit instructions and 0 for
        // single-width 128-bit/double-width 64-bit instructions.
        sfulregs.sful_counter_cfg.fifo_ctr_subw_w = 4 - (format->log2size - 3);
        if (watermark_level) {
            ctl.log_watermark_en = 1;
            ctl.log_watermark_th = watermark_level;
        }
        if (underflow_action.set()) {
            auto act = actions->action(underflow_action.name);
            BUG_CHECK(act);
            ctl.underflow_instr = act->code;
            ctl.underflow_enable = 1;
        }
        if (overflow_action.set()) {
            auto act = actions->action(overflow_action.name);
            BUG_CHECK(act);
            ctl.overflow_instr = act->code;
            ctl.overflow_enable = 1;
        }
    } else {
        sfulregs.sful_counter_cfg.fifo_ctr_subw_w = 0;  // 128 bits
        if (busy_value) {
            salu.sful_clr_action_outp.action_outp = busy_value;
        }
        if (clear_value) {
            set_ftr_raw_instr_bits(salu.sful_instr_state_alu[3], clear_value);
            salu.sful_ctl.clear_value_ctl = 1;
        }
        // TODO: Handle sweep
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

template<> void StatefulTable::write_action_regs_vt(Target::Flatrock::mau_regs &regs,
            const Actions::Action *act) {
    BUG_CHECK(physical_ids.popcount() == 1, "not exactly one physical id for %s", name());
    auto &salu = regs.ppu_sful[*physical_ids.begin()].ppu_sful_alu;
    auto &salu_instr_common = salu.sful_instr_common[act->code];
    if (act->minmax_use) {
        salu_instr_common.datasize = 7;
        salu_instr_common.op_dual = is_dual_mode();
    } else if (is_dual_mode()) {
        salu_instr_common.datasize = format->log2size - 1;
        salu_instr_common.op_dual = 1;
    } else {
        salu_instr_common.datasize = format->log2size;
    }
}

template<> void StatefulTable::write_merge_regs_vt(Target::Flatrock::mau_regs &regs,
            MatchTable *match, int type, int bus, const std::vector<Call::Arg> &args) {
    error(lineno, "%s:%d: Flatrock stateful not implemented yet!", SRCFILE, __LINE__);
}

template<> void StatefulTable::write_regs_vt(Target::Flatrock::mau_regs &regs) {
    LOG1("### Stateful table " << name() << " write_regs " << loc());
    Synth2Port::write_regs(regs);

    BUG_CHECK(physical_ids.popcount() == 1, "not exactly one physical id for %s", name());
    int physid = *physical_ids.begin();
    switch (physid) {
    case 0:
        regs.ppu_dpm.module.dpm_cfg.dpu0_sel = 1;
        regs.ppu_mrd.rf.mrd_cfg.au0_sel = 0;
        break;
    case 1:
        regs.ppu_dpm.module.dpm_cfg.dpu1_sel = 1;
        regs.ppu_mrd.rf.mrd_cfg.au1_sel = 0;
        break;
    case 2:
        regs.ppu_dpm.module.dpm_cfg.dpu2_sel = 1;
        regs.ppu_mrd.rf.mrd_cfg.au2_sel = 0;
        break;
    case 3:
        regs.ppu_dpm.module.dpm_cfg.dpu3_sel = 1;
        regs.ppu_mrd.rf.mrd_cfg.au3_sel = 0;
        break;
    default:
        BUG("invalid physical id %d for stateful", physid); }

    auto &salu = regs.ppu_sful[*physical_ids.begin()].ppu_sful_alu;
    salu.sful_ctl.enable_ = 1;
    salu.sful_ctl.outp_pred_shift = pred_shift / 4;
    salu.sful_ctl.out_prd_cmb_shft = pred_comb_shift;

    this->write_logging_regs(regs);

    for (auto &inst : salu.sful_instr_cmp_alu) {
        for (auto &alu : inst) {
            if (!alu.cmp_opcode.modified()) {
                alu.cmp_opcode = 2;
            }
        }
    }

    if (math_table) {
        for (size_t i = 0; i < math_table.data.size(); ++i) {
            salu.sful_mathtable[i/4U].mathtable.set_subfield(math_table.data[i], 8*(i%4U), 8);
        }
        salu.sful_mathunit_ctl.output_scale = math_table.scale & 0x3fU;
        salu.sful_mathunit_ctl.exponent_invert = math_table.invert;
        switch (math_table.shift) {
        case -1: salu.sful_mathunit_ctl.exponent_shift = 2; break;
        case  0: salu.sful_mathunit_ctl.exponent_shift = 0; break;
        case  1: salu.sful_mathunit_ctl.exponent_shift = 1; break;
        }
    }
}
