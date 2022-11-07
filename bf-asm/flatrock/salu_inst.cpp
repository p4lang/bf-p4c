/* Flatrock template specializations for instructions #included in salu_inst.cpp
 * WARNING -- this is included in an anonymous namespace, as these SaluInstruction
 * subclasses are all defined in that anonymous namespace */

// FIXME -- this should be compatible with jbay/cloudbreak (as the SALU is essentially
// the same) but the register space may be completely different

void DivMod::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
                        Table::Actions::Action *act) {
    // FTR uses multiplication and not div mod
    BUG("Flatrock does not support DivMod instructions");
}

void MinMax::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl_,
        Table::Actions::Action *act) {
    auto tbl = dynamic_cast<StatefulTable *>(tbl_);
    auto &salu = regs.ppu_sful[tbl->physical_id].ppu_sful_alu;
    auto &sful_instr_common = salu.sful_instr_common[act->code];

    if (auto k = mask.to<operand::Const>()) {
        sful_instr_common.minmax_mask_ctl = 1;
    } else {
        sful_instr_common.minmax_mask_ctl = 0;
    }
    sful_instr_common.minmax_ctl = opc->opcode;
    sful_instr_common.minmax_enable = 1;
    if (postmod) {
        if (auto k = postmod.to<operand::Const>()) {
            sful_instr_common.mnmx_pstmod_v_ct = 0;
        } else {
            sful_instr_common.mnmx_pstmod_v_ct = 1;
        }
        if (postmod.neg)
            sful_instr_common.minmax_pstdec_en = 1;
        else
            sful_instr_common.minmax_pstinc_en = 1;
    }

    if (constval) {
        auto &salu_instr_cmp = salu.sful_instr_cmp_alu[act->code][3];
        salu_instr_cmp.cmp_regfile_adr = tbl->get_const(lineno, *constval);
    }
    // sful_instr_common.minmax_src_sel = phv;  -- FIXME -- specify PHV source?
    for (auto &salu : salu.sful_instr_state_alu[act->code]) {
        salu.op = 0xd;
        salu.arith = 1;
        salu.pred = 0xffff;
    }
}

template<>
void AluOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl_,
        Table::Actions::Action *act) {
    LOG2(this);
    auto tbl = dynamic_cast<StatefulTable *>(tbl_);
    auto &salu = regs.ppu_sful[tbl->physical_id].ppu_sful_alu;
    auto &sful_inst_st = salu.sful_instr_state_alu[act->code][slot - ALU2LO];
    auto &sful_i2st = salu.sful_instr2_st_alu[act->code][slot - ALU2LO];
    auto &sful_instr_common = salu.sful_instr_common[act->code];

    sful_inst_st.op = opc->opcode & 0xf;
    sful_inst_st.arith = opc->opcode >> 4;
    sful_inst_st.pred = predication_encode;
    bool need_flyover = (tbl->format->size >> tbl->is_dual_mode()) > 32;
    const int alu_const_min = Target::STATEFUL_ALU_CONST_MIN();
    const int alu_const_max = Target::STATEFUL_ALU_CONST_MAX();
    if (srca) {
        if (auto m = srca.to<operand::Memory>()) {
            sful_inst_st.asrc_input = m->field->bit(0) > 0 ? 1 : 0;
            if (need_flyover) {
                sful_i2st.flyover_src_sel = 1;
                need_flyover = false;
            }
        } else if (auto f = srca.to<operand::Phv>()) {
            sful_inst_st.asrc_input = f->phv_index(tbl) ? 3 : 2;
            if (need_flyover) {
                sful_i2st.flyover_src_sel = 1;
                need_flyover = false;
            }
        } else if (auto k = srca.to<operand::Const>()) {
            sful_inst_st.asrc_input = 4;
            if (k->value >= alu_const_min && k->value <= alu_const_max) {
                sful_inst_st.const_src = k->value & Target::STATEFUL_ALU_CONST_MASK();
                sful_inst_st.regfile_const = 0;
            } else {
                sful_inst_st.const_src = tbl->get_const(k->lineno, k->value);
                sful_inst_st.regfile_const = 1;
            }
        } else if (auto r = srca.to<operand::Regfile>()) {
            sful_inst_st.asrc_input = 4;
            sful_inst_st.const_src = r->index;
            sful_inst_st.regfile_const = 1;
        } else {
            BUG();
        }
    }
    if (srcb) {
        if (auto m = srcb.to<operand::Memory>()) {
            sful_inst_st.bsrc_input = m->field->bit(0) > 0 ? 3 : 2;
            if (need_flyover) {
                sful_i2st.flyover_src_sel = 0;
                need_flyover = false; }
        } else if (auto f = srcb.to<operand::Phv>()) {
            sful_inst_st.bsrc_input = f->phv_index(tbl) ? 1 : 0;
            if (need_flyover) {
                sful_i2st.flyover_src_sel = 0;
                need_flyover = false; }
        } else if (auto m = srcb.to<operand::MathFn>()) {
            sful_instr_common.alu2_lo_b_math = 1;
            if (auto b = m->of.to<operand::Phv>()) {
                sful_instr_common.alu2_lo_math_src = b->phv_index(tbl);
            } else if (auto b = m->of.to<operand::Memory>()) {
                sful_instr_common.alu2_lo_math_src = b->field->bit(0) > 0 ? 3 : 2;
            } else {
                BUG();
            }
        } else if (auto k = srcb.to<operand::Const>()) {
            sful_inst_st.bsrc_input = 4;
            if (k->value >= alu_const_min && k->value <= alu_const_max) {
                sful_inst_st.const_src = k->value & Target::STATEFUL_ALU_CONST_MASK();
                sful_inst_st.regfile_const = 0;
            } else {
                sful_inst_st.const_src = tbl->get_const(k->lineno, k->value);
                sful_inst_st.regfile_const = 1;
            }
        } else if (auto r = srcb.to<operand::Regfile>()) {
            sful_inst_st.bsrc_input = 4;
            sful_inst_st.const_src = r->index;
            sful_inst_st.regfile_const = 1;
        } else {
            BUG();
        }
    }
}
void AluOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    write_regs<Target::Flatrock::mau_regs>(regs, tbl, act); }

template<>
void BitOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    LOG2(this);
    auto &salu = regs.ppu_sful[tbl->physical_id].ppu_sful_alu;
    auto &sful_inst_st = salu.sful_instr_state_alu[act->code][slot - ALU2LO];

    sful_inst_st.op = opc->opcode & 0xf;
    sful_inst_st.pred = predication_encode;
    // 1b instructions are from mem-lo to alu1-lo
    sful_inst_st.asrc_input = 0;
}
void BitOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    write_regs<Target::Flatrock::mau_regs>(regs, tbl, act); }

template<>
void CmpOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl_,
        Table::Actions::Action *act) {
    LOG2(this);
    auto tbl = dynamic_cast<StatefulTable *>(tbl_);
    auto &salu = regs.ppu_sful[tbl->physical_id].ppu_sful_alu;
    auto &salu_cmp_alu = salu.sful_instr_cmp_alu[act->code][slot];
    auto &salu_inst_com = salu.sful_instr_common[act->code];

    if (srca) {
        salu_cmp_alu.cmp_asrc_input = srca->field->bit(0) > 0;
        salu_cmp_alu.cmp_asrc_sign = srca_neg;
        salu_cmp_alu.cmp_asrc_en = 1;
        if (maska != uint32_t(-1)) {
            salu_cmp_alu.cmp_asrc_mask_en = 1;
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
                salu_cmp_alu.cmp_const_src = maska & Target::STATEFUL_CMP_CONST_MASK();
                salu_cmp_alu.cmp_mask_input = 0;
            } else {
                salu_cmp_alu.cmp_regfile_adr = tbl->get_const(srca->lineno, maska);
                salu_cmp_alu.cmp_mask_input = 1;
            }
        }
    }
    if (srcb) {
        salu_cmp_alu.cmp_bsrc_input = srcb->phv_index(tbl);
        salu_cmp_alu.cmp_bsrc_sign = srcb_neg;
        salu_cmp_alu.cmp_bsrc_en = 1;
        if (maskb != uint32_t(-1)) {
            // uarch 6.2.12.6.1, masks for operand a/b are sourced from the
            // same regfile slot.
            if (salu_cmp_alu.cmp_asrc_mask_en && salu_cmp_alu.cmp_mask_input && maskb != maska)
                error(lineno, "inconsistent operand mask %d and %d in salu compare operation",
                        maska, maskb);
            salu_cmp_alu.cmp_regfile_adr = tbl->get_const(srcb->lineno, maskb);
            salu_cmp_alu.cmp_bsrc_mask_en = 1;
        }
    }
    if (srcc) {
        if (auto k = dynamic_cast<const operand::Const *>(srcc)) {
            const int cmp_const_min = Target::STATEFUL_CMP_CONST_MIN();
            const int cmp_const_max = Target::STATEFUL_CMP_CONST_MAX();
            if (k->value >= cmp_const_min && k->value <= cmp_const_max) {
                salu_cmp_alu.cmp_const_src = k->value & Target::STATEFUL_CMP_CONST_MASK();
                salu_cmp_alu.cmp_rfile_const = 0;
            } else {
                // uarch 6.2.12.6.1, masks for operand a/b are sourced from the
                // same regfile slot as operand c if c is a constant.
                if (salu_cmp_alu.cmp_asrc_mask_en && salu_cmp_alu.cmp_mask_input &&
                    maska != uint32_t(k->value))
                    error(lineno, "inconsistent operand mask %d and %d in salu compare operation",
                            maska, uint32_t(k->value));
                if (salu_cmp_alu.cmp_bsrc_mask_en && salu_cmp_alu.cmp_mask_input &&
                    maskb != uint32_t(k->value))
                    error(lineno, "inconsistent operand mask %d and %d in salu compare operation",
                            maskb, uint32_t(k->value));
                salu_cmp_alu.cmp_regfile_adr = tbl->get_const(srcc->lineno, k->value);
                salu_cmp_alu.cmp_rfile_const = 1;
            }
        } else if (auto r = dynamic_cast<const operand::Regfile *>(srcc)) {
            salu_cmp_alu.cmp_regfile_adr = r->index;
            salu_cmp_alu.cmp_rfile_const = 1;
        }
    } else {
        salu_cmp_alu.cmp_const_src = 0;
        salu_cmp_alu.cmp_rfile_const = 0;
    }

    salu_cmp_alu.cmp_opcode = opc->opcode | (type << 2);
    auto lmask = sbus_mask(tbl->physical_id, tbl->sbus_learn);
    auto mmask = sbus_mask(tbl->physical_id, tbl->sbus_match);

    salu_inst_com.lmatch_sb_listen = lmask;
    salu_inst_com.match_sb_listen = mmask;
    salu_inst_com.sbus_in_comb = tbl->sbus_comb;

    if (lmask || mmask) {
        // if lmask and mmask are both zero, these registers don't matter, but the model
        // will assert if they are non-zero)
        salu_cmp_alu.cmp_sbus_or = 0;
        salu_cmp_alu.cmp_sbus_and = learn ? 1 : 0;
        salu_cmp_alu.cmp_sbus_invert = learn_not ? 1 : 0;
    }
}
void CmpOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    write_regs<Target::Flatrock::mau_regs>(regs, tbl, act); }

template<>
void TMatchOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl_,
        Table::Actions::Action *act) {
    auto tbl = dynamic_cast<StatefulTable *>(tbl_);
    auto &salu = regs.ppu_sful[tbl->physical_id].ppu_sful_alu;
    auto &salu_cmp_alu = salu.sful_instr_cmp_alu[act->code][slot];
    auto &salu_tmatch = salu.sful_instr_tmtch_alu[act->code][slot];
    auto &salu_inst_com = salu.sful_instr_common[act->code];
    salu_cmp_alu.cmp_tmatch_en = 1;
    salu_cmp_alu.cmp_asrc_en = 1;
    salu_cmp_alu.cmp_bsrc_en = 1;
    salu.sful_tmatch_mask[slot][0].tmatch_mask = ~mask & 0xffffffffU;
    salu.sful_tmatch_mask[slot][1].tmatch_mask = ~mask >> 32;
    salu_cmp_alu.cmp_opcode = 2;
    salu_cmp_alu.cmp_asrc_input = srca->field->bit(0) > 0;
    salu_cmp_alu.cmp_bsrc_input = srcb->phv_index(tbl);
    if (auto lmask = sbus_mask(tbl->physical_id, tbl->sbus_learn))
        salu_inst_com.lmatch_sb_listen = lmask;
    if (auto mmask = sbus_mask(tbl->physical_id, tbl->sbus_match))
        salu_inst_com.match_sb_listen = mmask;
    salu_cmp_alu.cmp_sbus_or = 0;
    salu_cmp_alu.cmp_sbus_and = learn ? 1 : 0;
    salu_cmp_alu.cmp_sbus_invert = learn_not ? 1 : 0;
    // we set the learn output unconditionally if there's a tmatch -- should it be controllable?
    salu_tmatch.tmatch_vld_ctl = 1;
}
void TMatchOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    write_regs<Target::Flatrock::mau_regs>(regs, tbl, act); }

template<>
void OutOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl_,
        Table::Actions::Action *act) {
    auto tbl = dynamic_cast<StatefulTable *>(tbl_);
    auto &salu = regs.ppu_sful[tbl->physical_id].ppu_sful_alu;
    auto &sful_ioa = salu.sful_instr_outp_alu[act->code][slot - ALUOUT0];
    if (predication_encode) {
        sful_ioa.output_cmpfn = predication_encode;
    } else {
        sful_ioa.output_cmpfn = STATEFUL_PREDICATION_ENCODE_UNCOND;
    }
    sful_ioa.output_asrc = output_mux;
    if ((sful_ioa.lmatch_adrbit_en = lmatch))
        salu.sful_mathtable[0].mathtable = lmatch_pred;
    if (output_mux == STATEFUL_PREDICATION_OUTPUT)
        salu.sful_ctl.output_pred_sel = slot - ALUOUT0;
}
void OutOP::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl,
        Table::Actions::Action *act) {
    write_regs<Target::Flatrock::mau_regs>(regs, tbl, act); }

void OutOP::decode_output_mux(Target::Flatrock, Table *tbl, value_t &op) {
    error(lineno, "%s:%d: Flatrock SALU not implemented yet!", SRCFILE, __LINE__);
}

int OutOP::decode_output_option(Target::Flatrock, value_t &op) {
    error(lineno, "%s:%d: Flatrock SALU not implemented yet!", SRCFILE, __LINE__);
    return 0;
}
