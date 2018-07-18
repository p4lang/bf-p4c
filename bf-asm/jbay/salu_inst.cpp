/* JBay template specializations for instructions #included in salu_inst.cpp
 * WARNING -- this is included in an anonymous namespace, as these SaluInstruction
 * subclasses are all defined in that anonymous namespace */

template<>
void AluOP::write_regs(Target::JBay::mau_regs &regs, Table *tbl_, Table::Actions::Action *act) {
    LOG2(this);
    auto tbl = dynamic_cast<StatefulTable *>(tbl_);
    int logical_home_row = tbl->layout[0].row;
    auto &meter_group = regs.rams.map_alu.meter_group[logical_home_row/4U];
    auto &salu = meter_group.stateful.salu_instr_state_alu[act->code][slot - ALU2LO];
    auto &salu_instr_common = meter_group.stateful.salu_instr_common[act->code];
    auto &salu_instr_output_alu = meter_group.stateful.salu_instr_output_alu[act->code];
    salu.salu_op = opc->opcode & 0xf;
    salu.salu_arith = opc->opcode >> 4;
    salu.salu_pred = predication_encode;
    if (srca) {
        if (auto m = srca.to<operand::Memory>()) {
            salu.salu_asrc_input = m->field->bit(0) > 0 ? 1 : 0;
        } else if (auto f = srca.to<operand::Phv>()) {
            salu.salu_asrc_input = f->phv_index(tbl) ? 3 : 2;
        } else if (auto k = srca.to<operand::Const>()) {
            salu.salu_asrc_input = 4;
            if (k->value >= -8 && k->value < 8) {
                salu.salu_const_src = k->value;
                salu.salu_regfile_const = 0;
            } else {
                salu.salu_const_src = tbl->get_const(k->value);
                salu.salu_regfile_const = 1; }
        } else assert(0); }
    if (srcb) {
        if (auto m = srcb.to<operand::Memory>()) {
            salu.salu_bsrc_input = m->field->bit(0) > 0 ? 3 : 2;
        } else if (auto f = srcb.to<operand::Phv>()) {
            salu.salu_bsrc_input = f->phv_index(tbl) ? 1 : 0;
        } else if (auto m = srcb.to<operand::MathFn>()) {
            if(auto b = m->of.to<operand::Phv>()) {
                salu_instr_common.salu_alu2_lo_bsrc_math = 1;
                salu_instr_common.salu_alu2_lo_math_src = b->phv_index(tbl);
            } else assert(0);
        } else if (auto k = srcb.to<operand::Const>()) {
            salu.salu_bsrc_input = 4;
            if (k->value >= -8 && k->value < 8) {
                salu.salu_const_src = k->value;
                salu.salu_regfile_const = 0;
            } else {
                salu.salu_const_src = tbl->get_const(k->value);
                salu.salu_regfile_const = 1; }
        } else assert(0); }
}
void AluOP::write_regs(Target::JBay::mau_regs &regs, Table *tbl, Table::Actions::Action *act) {
    write_regs<Target::JBay::mau_regs>(regs, tbl, act); }

template<>
void BitOP::write_regs(Target::JBay::mau_regs &regs, Table *tbl, Table::Actions::Action *act) {
    LOG2(this);
    int logical_home_row = tbl->layout[0].row;
    auto &meter_group = regs.rams.map_alu.meter_group[logical_home_row/4U];
    auto &salu = meter_group.stateful.salu_instr_state_alu[act->code][slot-ALU2LO];
    salu.salu_op = opc->opcode & 0xf;
    salu.salu_pred = predication_encode;
    //1b instructions are from mem-lo to alu1-lo
    salu.salu_asrc_input = 0;
}
void BitOP::write_regs(Target::JBay::mau_regs &regs, Table *tbl, Table::Actions::Action *act) {
    write_regs<Target::JBay::mau_regs>(regs, tbl, act); }

static int sbus_mask(int alu, const std::vector<Table::Ref> &tbls) {
    int rv = 0;
    for (auto &tbl : tbls) {
        int bit = tbl->layout[0].row/4U;
        if (bit > alu) --bit;
        rv |= 1 << bit; }
    return rv;
}

template<>
void CmpOP::write_regs(Target::JBay::mau_regs &regs, Table *tbl_, Table::Actions::Action *act) {
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
            auto cval = srcc ? srcc->value : 0;
            if ((maska >= uint32_t(-32) || maska < 32) && 
                (uint32_t(cval) == maska || cval < -32 || cval >= 32)) {
                salu.salu_cmp_const_src = maska & 0x2f;
                salu.salu_cmp_mask_input = 0;
            } else {
                salu.salu_cmp_mask_input = 1;
                salu.salu_cmp_regfile_adr = tbl->get_const(maska); } } }
    if (srcb) {
        salu.salu_cmp_bsrc_input = srcb->phv_index(tbl);
        salu.salu_cmp_bsrc_sign = srcb_neg;
        salu.salu_cmp_bsrc_enable = 1;
        if (maskb != uint32_t(-1)) {
            salu.salu_cmp_bsrc_mask_enable = 1;
            salu.salu_cmp_regfile_adr = tbl->get_const(maskb); } }
    if (srcc && (srcc->value < -32 || srcc->value >= 32)) {
        salu.salu_cmp_regfile_adr = tbl->get_const(srcc->value);
        salu.salu_cmp_regfile_const = 1;
    } else {
        salu.salu_cmp_const_src = srcc ? srcc->value & 0x2f : 0;
        salu.salu_cmp_regfile_const = 0; }
    salu.salu_cmp_opcode = opc->opcode | (type << 2);
    if (auto lmask = sbus_mask(logical_home_row/4U, tbl->sbus_learn))
        salu_instr_common.salu_lmatch_sbus_listen = lmask;
    if (auto mmask = sbus_mask(logical_home_row/4U, tbl->sbus_match))
        salu_instr_common.salu_match_sbus_listen = mmask;
    salu.salu_cmp_sbus_or = 0;
    salu.salu_cmp_sbus_and = learn ? 1 : 0;
    salu.salu_cmp_sbus_invert = learn_not ? 1 : 0;
}
void CmpOP::write_regs(Target::JBay::mau_regs &regs, Table *tbl, Table::Actions::Action *act) {
    write_regs<Target::JBay::mau_regs>(regs, tbl, act); }

template<>
void TMatchOP::write_regs(Target::JBay::mau_regs &regs, Table *tbl_, Table::Actions::Action *act) {
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

void TMatchOP::write_regs(Target::JBay::mau_regs &regs, Table *tbl, Table::Actions::Action *act) {
    write_regs<Target::JBay::mau_regs>(regs, tbl, act); }

void OutOP::decode_output_mux(Target::JBay, value_t &op) {
    static const std::map<std::string, int> ops_mux_lookup = {
        { "mem_hi", 1 }, { "mem_lo", 0 },
        { "memory_hi", 1 }, { "memory_lo", 0 },
        { "phv_hi", 3 }, { "phv_lo", 2 },
        { "alu_hi", 5 }, { "alu_lo", 4 },
        { "alu_hi_out", 5 }, { "alu_lo_out", 4 },
        { "predicate", 6 }, { "address", 7 },
        { "div", 8 }, { "mod", 9 } };
    if (op.type == tCMD && ops_mux_lookup.count(op[0].s))
        output_mux = ops_mux_lookup.at(op[0].s);
    else if (op.type == tSTR && ops_mux_lookup.count(op.s))
        output_mux = ops_mux_lookup.at(op.s);
    else
        output_mux = -1;
}

template<>
void OutOP::write_regs(Target::JBay::mau_regs &regs, Table *tbl, Table::Actions::Action *act) {
    LOG2(this);
    int logical_home_row = tbl->layout[0].row;
    auto &meter_group = regs.rams.map_alu.meter_group[logical_home_row/4U];
    auto &salu = meter_group.stateful.salu_instr_output_alu[act->code][slot - ALUOUT0];
    if (predication_encode) {
        salu.salu_output_cmpfn = predication_encode;
    } else {
        salu.salu_output_cmpfn = STATEFUL_PREDICATION_ENCODE_UNCOND; }
    salu.salu_output_asrc = output_mux;
}
void OutOP::write_regs(Target::JBay::mau_regs &regs, Table *tbl, Table::Actions::Action *act) {
    write_regs<Target::JBay::mau_regs>(regs, tbl, act); }

