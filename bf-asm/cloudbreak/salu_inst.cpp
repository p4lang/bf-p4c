/* Cloudbreak template specializations for instructions #included in salu_inst.cpp
 * WARNING -- this is included in an anonymous namespace, as these SaluInstruction
 * subclasses are all defined in that anonymous namespace */

// FIXME -- factor better with identical JBay code

// setz op, so can OR with alu1hi to get that result
DivMod::Decode cb_opDIVMOD("divmod", CLOUDBREAK, 0x00);

void DivMod::write_regs(Target::Cloudbreak::mau_regs &regs, Table *tbl,
                        Table::Actions::Action *act) {
    AluOP::write_regs(regs, tbl, act);
    int logical_home_row = tbl->layout[0].row;
    auto &meter_group = regs.rams.map_alu.meter_group[logical_home_row/4U];
    auto &salu_instr_common = meter_group.stateful.salu_instr_common[act->code];
    salu_instr_common.salu_divide_enable |= 1;
}

MinMax::Decode cb_opMIN8("min8", CLOUDBREAK, 0), cb_opMAX8("max8", CLOUDBREAK, 1),
               cb_opMIN16("min16", CLOUDBREAK, 2), cb_opMAX16("max16", CLOUDBREAK, 3);

/*
 * TODO(Chris) I would like to look into reducing the redundancy in all the write_regs code
 * between JBay and Cloudbreak here -- lots of stuff you had to do twice, which is painful
 * and error-prone.
 */
void MinMax::write_regs(Target::Cloudbreak::mau_regs &regs, Table *tbl_,
        Table::Actions::Action *act) {
    auto tbl = dynamic_cast<StatefulTable *>(tbl_);
    int logical_home_row = tbl->layout[0].row;
    auto &meter_group = regs.rams.map_alu.meter_group[logical_home_row/4U];
    auto &salu_instr_common = meter_group.stateful.salu_instr_common[act->code];
    if (auto k = mask.to<operand::Const>()) {
        salu_instr_common.salu_minmax_mask_ctl = 1;
    } else {
        salu_instr_common.salu_minmax_mask_ctl = 0; }
    salu_instr_common.salu_minmax_ctl = opc->opcode;
    salu_instr_common.salu_minmax_enable = 1;
    if (postmod) {
        if (auto k = postmod.to<operand::Const>()) {
            salu_instr_common.salu_minmax_postmod_value_ctl = 0;
        } else {
            salu_instr_common.salu_minmax_postmod_value_ctl = 1; }
        if (postmod.neg)
            salu_instr_common.salu_minmax_postdec_enable = 1;
        else
            salu_instr_common.salu_minmax_postinc_enable = 1; }
    if (constval) {
        auto &salu_instr_cmp = meter_group.stateful.salu_instr_cmp_alu[act->code][3];
        salu_instr_cmp.salu_cmp_regfile_adr = tbl->get_const(lineno, *constval);
    }
    // salu_instr_common.salu_minmax_src_sel = phv;  -- FIXME -- specify PHV source?
    for (auto &salu : meter_group.stateful.salu_instr_state_alu[act->code]) {
        salu.salu_op = 0xd;
        salu.salu_arith = 1;
        salu.salu_pred = 0xffff; }
}

template<>
void AluOP::write_regs(Target::Cloudbreak::mau_regs &regs, Table *tbl_,
        Table::Actions::Action *act) {
    LOG2(this);
    auto tbl = dynamic_cast<StatefulTable *>(tbl_);
    int logical_home_row = tbl->layout[0].row;
    auto &meter_group = regs.rams.map_alu.meter_group[logical_home_row/4U];
    auto &salu = meter_group.stateful.salu_instr_state_alu[act->code][slot - ALU2LO];
    auto &salu_ext = meter_group.stateful.salu_instr2_state_alu[act->code][slot - ALU2LO];
    auto &salu_instr_common = meter_group.stateful.salu_instr_common[act->code];
    auto &salu_instr_output_alu = meter_group.stateful.salu_instr_output_alu[act->code];
    salu.salu_op = opc->opcode & 0xf;
    salu.salu_arith = opc->opcode >> 4;
    salu.salu_pred = predication_encode;
    bool need_flyover = (tbl->format->size >> tbl->is_dual_mode()) > 32;
    const int alu_const_min = Target::STATEFUL_ALU_CONST_MIN();
    const int alu_const_max = Target::STATEFUL_ALU_CONST_MAX();
    if (srca) {
        if (auto m = srca.to<operand::Memory>()) {
            salu.salu_asrc_input = m->field->bit(0) > 0 ? 1 : 0;
            if (need_flyover) {
                salu_ext.salu_flyover_src_sel = 1;
                need_flyover = false; }
        } else if (auto f = srca.to<operand::Phv>()) {
            salu.salu_asrc_input = f->phv_index(tbl) ? 3 : 2;
            if (need_flyover) {
                salu_ext.salu_flyover_src_sel = 1;
                need_flyover = false; }
        } else if (auto k = srca.to<operand::Const>()) {
            salu.salu_asrc_input = 4;
            if (k->value >= alu_const_min && k->value <= alu_const_max) {
                salu.salu_const_src = k->value & Target::STATEFUL_ALU_CONST_MASK();
                salu.salu_regfile_const = 0;
            } else {
                salu.salu_const_src = tbl->get_const(k->lineno, k->value);
                salu.salu_regfile_const = 1;
            }
        } else if (auto r = srca.to<operand::Regfile>()) {
            salu.salu_asrc_input = 4;
            salu.salu_const_src = r->index;
            salu.salu_regfile_const = 1;
        } else {
            BUG();
        }
    }
    if (srcb) {
        if (auto m = srcb.to<operand::Memory>()) {
            salu.salu_bsrc_input = m->field->bit(0) > 0 ? 3 : 2;
            if (need_flyover) {
                salu_ext.salu_flyover_src_sel = 0;
                need_flyover = false; }
        } else if (auto f = srcb.to<operand::Phv>()) {
            salu.salu_bsrc_input = f->phv_index(tbl) ? 1 : 0;
            if (need_flyover) {
                salu_ext.salu_flyover_src_sel = 0;
                need_flyover = false; }
        } else if (auto m = srcb.to<operand::MathFn>()) {
            salu_instr_common.salu_alu2_lo_bsrc_math = 1;
            if (auto b = m->of.to<operand::Phv>()) {
                salu_instr_common.salu_alu2_lo_math_src = b->phv_index(tbl);
            } else if (auto b = m->of.to<operand::Memory>()) {
                salu_instr_common.salu_alu2_lo_math_src = b->field->bit(0) > 0 ? 3 : 2;
            } else {
                BUG();
            }
        } else if (auto k = srcb.to<operand::Const>()) {
            salu.salu_bsrc_input = 4;
            if (k->value >= alu_const_min && k->value <= alu_const_max) {
                salu.salu_const_src = k->value & Target::STATEFUL_ALU_CONST_MASK();
                salu.salu_regfile_const = 0;
            } else {
                salu.salu_const_src = tbl->get_const(k->lineno, k->value);
                salu.salu_regfile_const = 1;
            }
        } else if (auto r = srcb.to<operand::Regfile>()) {
            salu.salu_bsrc_input = 4;
            salu.salu_const_src = r->index;
            salu.salu_regfile_const = 1;
        } else {
            BUG();
        }
    }
}
void AluOP::write_regs(Target::Cloudbreak::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    write_regs<Target::Cloudbreak::mau_regs>(regs, tbl, act); }

template<>
void BitOP::write_regs(Target::Cloudbreak::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    LOG2(this);
    int logical_home_row = tbl->layout[0].row;
    auto &meter_group = regs.rams.map_alu.meter_group[logical_home_row/4U];
    auto &salu = meter_group.stateful.salu_instr_state_alu[act->code][slot-ALU2LO];
    salu.salu_op = opc->opcode & 0xf;
    salu.salu_pred = predication_encode;
    // 1b instructions are from mem-lo to alu1-lo
    salu.salu_asrc_input = 0;
}
void BitOP::write_regs(Target::Cloudbreak::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    write_regs<Target::Cloudbreak::mau_regs>(regs, tbl, act); }

template<>
void CmpOP::write_regs(Target::Cloudbreak::mau_regs &regs, Table *tbl_,
        Table::Actions::Action *act) {
    LOG2(this);
    auto tbl = dynamic_cast<StatefulTable *>(tbl_);
    int logical_home_row = tbl->layout[0].row;
    auto &meter_group = regs.rams.map_alu.meter_group[logical_home_row/4U];
    auto &salu = meter_group.stateful.salu_instr_cmp_alu[act->code][slot];
    auto &salu_instr_common = meter_group.stateful.salu_instr_common[act->code];
    if (srca) {
        salu.salu_cmp_asrc_input = srca->field->bit(0) > 0;
        salu.salu_cmp_asrc_sign = srca_neg;
        salu.salu_cmp_asrc_enable = 1;
        if (maska != uint32_t(-1)) {
            salu.salu_cmp_asrc_mask_enable = 1;
            auto cval = 0;
            if (auto k = dynamic_cast<const operand::Const *>(srcc))
                cval = k->value;
            else if (auto r = dynamic_cast<const operand::Regfile *>(srcc))
                cval = tbl->get_const_val(r->index);
            auto min = Target::STATEFUL_CMP_CONST_MIN();
            auto max = Target::STATEFUL_CMP_CONST_MAX();
            bool maska_outside = (maska < uint32_t(min) && maska > max);
            bool maska_equal_inside = (uint32_t(cval) != maska && cval >= min && cval <= max);
            if (!maska_outside && !maska_equal_inside) {
                salu.salu_cmp_const_src = maska & Target::STATEFUL_CMP_CONST_MASK();
                salu.salu_cmp_mask_input = 0;
            } else {
                salu.salu_cmp_regfile_adr = tbl->get_const(srca->lineno, maska);
                salu.salu_cmp_mask_input = 1;
            }
        }
    }
    if (srcb) {
        salu.salu_cmp_bsrc_input = srcb->phv_index(tbl);
        salu.salu_cmp_bsrc_sign = srcb_neg;
        salu.salu_cmp_bsrc_enable = 1;
        if (maskb != uint32_t(-1)) {
            salu.salu_cmp_regfile_adr = tbl->get_const(srcb->lineno, maskb);
            salu.salu_cmp_bsrc_mask_enable = 1;
        }
    }
    if (srcc) {
        if (auto k = dynamic_cast<const operand::Const *>(srcc)) {
            const int cmp_const_min = Target::STATEFUL_CMP_CONST_MIN();
            const int cmp_const_max = Target::STATEFUL_CMP_CONST_MAX();
            if (k->value >= cmp_const_min && k->value <= cmp_const_max) {
                salu.salu_cmp_const_src = k->value & Target::STATEFUL_CMP_CONST_MASK();
                salu.salu_cmp_regfile_const = 0;
            } else {
                salu.salu_cmp_regfile_adr = tbl->get_const(srcc->lineno, k->value);
                salu.salu_cmp_regfile_const = 1;
            }
        } else if (auto r = dynamic_cast<const operand::Regfile *>(srcc)) {
            salu.salu_cmp_regfile_adr = r->index;
            salu.salu_cmp_regfile_const = 1;
        }
    } else {
        salu.salu_cmp_const_src = 0;
        salu.salu_cmp_regfile_const = 0;
    }
    salu.salu_cmp_opcode = opc->opcode | (type << 2);
    auto lmask = sbus_mask(logical_home_row/4U, tbl->sbus_learn);
    auto mmask = sbus_mask(logical_home_row/4U, tbl->sbus_match);
    salu_instr_common.salu_lmatch_sbus_listen = lmask;
    salu_instr_common.salu_match_sbus_listen = mmask;
    salu_instr_common.salu_sbus_in_comb = tbl->sbus_comb;
    if (lmask || mmask) {
        // if lmask and mmask are both zero, these registers don't matter, but the model
        // will assert if they are non-zero)
        salu.salu_cmp_sbus_or = 0;
        salu.salu_cmp_sbus_and = learn ? 1 : 0;
        salu.salu_cmp_sbus_invert = learn_not ? 1 : 0; }
}
void CmpOP::write_regs(Target::Cloudbreak::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    write_regs<Target::Cloudbreak::mau_regs>(regs, tbl, act); }

template<>
void TMatchOP::write_regs(Target::Cloudbreak::mau_regs &regs, Table *tbl_,
        Table::Actions::Action *act) {
    LOG2(this);
    auto tbl = dynamic_cast<StatefulTable *>(tbl_);
    int logical_home_row = tbl->layout[0].row;
    auto &meter_group = regs.rams.map_alu.meter_group[logical_home_row/4U];
    auto &salu = meter_group.stateful.salu_instr_cmp_alu[act->code][slot];
    auto &salu_tmatch = meter_group.stateful.salu_instr_tmatch_alu[act->code][slot];
    auto &salu_instr_common = meter_group.stateful.salu_instr_common[act->code];
    salu.salu_cmp_tmatch_enable = 1;
    salu.salu_cmp_asrc_enable = 1;
    salu.salu_cmp_bsrc_enable = 1;
    meter_group.stateful.tmatch_mask[slot][0] = ~mask & 0xffffffffU;
    meter_group.stateful.tmatch_mask[slot][1] = ~mask >> 32;
    salu.salu_cmp_opcode = 2;
    salu.salu_cmp_asrc_input = srca->field->bit(0) > 0;
    salu.salu_cmp_bsrc_input = srcb->phv_index(tbl);
    if (auto lmask = sbus_mask(logical_home_row/4U, tbl->sbus_learn))
        salu_instr_common.salu_lmatch_sbus_listen = lmask;
    if (auto mmask = sbus_mask(logical_home_row/4U, tbl->sbus_match))
        salu_instr_common.salu_match_sbus_listen = mmask;
    salu.salu_cmp_sbus_or = 0;
    salu.salu_cmp_sbus_and = learn ? 1 : 0;
    salu.salu_cmp_sbus_invert = learn_not ? 1 : 0;
    // we set the learn output unconditionally if there's a tmatch -- should it be controllable?
    salu_tmatch.salu_tmatch_vld_ctl = 1;
    // salu_tmatch.salu_tmatch_invert = 0;  -- when can this be useful?
}

void TMatchOP::write_regs(Target::Cloudbreak::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    write_regs<Target::Cloudbreak::mau_regs>(regs, tbl, act); }

void OutOP::decode_output_mux(Target::Cloudbreak, value_t &op) {
    static const std::map<std::string, int> ops_mux_lookup = {
        { "mem_hi", 1 }, { "mem_lo", 0 },
        { "memory_hi", 1 }, { "memory_lo", 0 },
        { "phv_hi", 3 }, { "phv_lo", 2 },
        { "alu_hi", 5 }, { "alu_lo", 4 },
        { "minmax_index", 5 }, { "minmax_post", 4 },
        { "predicate", 6 }, { "address", 7 },
        { "div", 8 }, { "mod", 9 }, { "minmax", 10 } };
    if (op.type == tCMD && ops_mux_lookup.count(op[0].s))
        output_mux = ops_mux_lookup.at(op[0].s);
    else if (op.type == tSTR && ops_mux_lookup.count(op.s))
        output_mux = ops_mux_lookup.at(op.s);
    else
        output_mux = -1;
}
int OutOP::decode_output_option(Target::Cloudbreak, value_t &op) {
    if (op == "lmatch") {
        lmatch = true;
        if (op.type == tCMD)
            lmatch_pred = decode_predicate(op[1]);
        else
            lmatch_pred = STATEFUL_PREDICATION_ENCODE_UNCOND;
    } else {
        return -1;
    }
    return 0;
}

template<>
void OutOP::write_regs(Target::Cloudbreak::mau_regs &regs, Table *tbl_,
        Table::Actions::Action *act) {
    LOG2(this);
    auto tbl = dynamic_cast<StatefulTable *>(tbl_);
    int logical_home_row = tbl->layout[0].row;
    auto &meter_group = regs.rams.map_alu.meter_group[logical_home_row/4U];
    auto &salu = meter_group.stateful.salu_instr_output_alu[act->code][slot - ALUOUT0];
    if (predication_encode) {
        salu.salu_output_cmpfn = predication_encode;
    } else {
        salu.salu_output_cmpfn = STATEFUL_PREDICATION_ENCODE_UNCOND; }
    salu.salu_output_asrc = output_operand ? 2 + output_operand->phv_index(tbl) : output_mux;
    if ((salu.salu_lmatch_adr_bit_enable = lmatch))
        meter_group.stateful.salu_mathtable[0] = lmatch_pred;
    if (output_mux == STATEFUL_PREDICATION_OUTPUT)
        meter_group.stateful.stateful_ctl.salu_output_pred_sel = slot - ALUOUT0;
}
void OutOP::write_regs(Target::Cloudbreak::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    write_regs<Target::Cloudbreak::mau_regs>(regs, tbl, act); }

