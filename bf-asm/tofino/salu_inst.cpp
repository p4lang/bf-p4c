/* Tofino template specializations for instructions #included in salu_inst.cpp
 * WARNING -- this is included in an anonymous namespace, as these SaluInstruction
 * subclasses are all defined in that anonymous namespace */

template<>
void AluOP::write_regs(Target::Tofino::mau_regs &regs, Table *tbl_, Table::Actions::Action *act) {
    LOG2(this);
    auto tbl = dynamic_cast<StatefulTable *>(tbl_);
    int logical_home_row = tbl->layout[0].row;
    auto &meter_group = regs.rams.map_alu.meter_group[logical_home_row/4U];
    auto &salu = meter_group.stateful.salu_instr_state_alu[act->code][slot - ALU2LO];
    auto &salu_instr_common = meter_group.stateful.salu_instr_common[act->code];
    salu.salu_op = opc->opcode & 0xf;
    salu.salu_arith = opc->opcode >> 4;
    salu.salu_pred = predication_encode & Target::Tofino::STATEFUL_PRED_MASK;
    if (srca) {
        if (auto m = srca.to<operand::Memory>()) {
            salu.salu_asrc_memory = 1;
            salu.salu_asrc_memory_index = m->field->bit(0) > 0;
        } else if (auto k = srca.to<operand::Const>()) {
            salu.salu_asrc_memory = 0;
            if (k->value >= -8 && k->value < 8) {
                salu.salu_const_src = k->value;
                salu.salu_regfile_const = 0;
            } else {
                salu.salu_const_src = tbl->get_const(k->value);
                salu.salu_regfile_const = 1; }
        } else assert(0); }
    if (srcb) {
        if (auto f = srcb.to<operand::Phv>()) {
            salu.salu_bsrc_phv = 1;
            salu.salu_bsrc_phv_index = f->phv_index(tbl);
        } else if (auto m = srcb.to<operand::MathFn>()) {
            if(auto b = m->of.to<operand::Phv>()) {
                salu_instr_common.salu_alu2_lo_bsrc_math = 1;
                salu_instr_common.salu_alu2_lo_math_src = b->phv_index(tbl);
            } else assert(0);
        } else if (auto k = srcb.to<operand::Const>()) {
            salu.salu_bsrc_phv = 0;
            if (k->value >= -8 && k->value < 8) {
                salu.salu_const_src = k->value & 0xf;
                salu.salu_regfile_const = 0;
            } else {
                salu.salu_const_src = tbl->get_const(k->value);
                salu.salu_regfile_const = 1; }
        } else assert(0); }
}
void AluOP::write_regs(Target::Tofino::mau_regs &regs, Table *tbl, Table::Actions::Action *act) {
    write_regs<Target::Tofino::mau_regs>(regs, tbl, act); }

template<>
void BitOP::write_regs(Target::Tofino::mau_regs &regs, Table *tbl, Table::Actions::Action *act) {
    LOG2(this);
    int logical_home_row = tbl->layout[0].row;
    auto &meter_group = regs.rams.map_alu.meter_group[logical_home_row/4U];
    auto &salu = meter_group.stateful.salu_instr_state_alu[act->code][slot-ALU2LO];
    salu.salu_op = opc->opcode & 0xf;
    salu.salu_pred = predication_encode & Target::Tofino::STATEFUL_PRED_MASK;
    //1b instructions are from mem-lo to alu1-lo
    salu.salu_asrc_memory = 1;
    salu.salu_asrc_memory_index = 0;
}
void BitOP::write_regs(Target::Tofino::mau_regs &regs, Table *tbl, Table::Actions::Action *act) {
    write_regs<Target::Tofino::mau_regs>(regs, tbl, act); }

template<>
void CmpOP::write_regs(Target::Tofino::mau_regs &regs, Table *tbl_, Table::Actions::Action *act) {
    LOG2(this);
    auto tbl = dynamic_cast<StatefulTable *>(tbl_);
    int logical_home_row = tbl->layout[0].row;
    auto &meter_group = regs.rams.map_alu.meter_group[logical_home_row/4U];
    auto &salu = meter_group.stateful.salu_instr_cmp_alu[act->code][slot];
    if (srca) {
        salu.salu_cmp_asrc_input = srca->field->bit(0) > 0;
        salu.salu_cmp_asrc_sign = srca_neg;
        salu.salu_cmp_asrc_enable = 1; }
    if (srcb) {
        salu.salu_cmp_bsrc_input = srcb->phv_index(tbl);
        salu.salu_cmp_bsrc_sign = srcb_neg;
        salu.salu_cmp_bsrc_enable = 1; }
    if (srcc) {
        if (srcc->value >= -8 && srcc->value < 8) {
            salu.salu_cmp_const_src = srcc->value & 0xf;
            salu.salu_cmp_regfile_const = 0;
        } else {
            salu.salu_cmp_const_src = tbl->get_const(srcc->value);
            salu.salu_cmp_regfile_const = 1; } }
    salu.salu_cmp_opcode = opc->opcode | (type << 2);
}
void CmpOP::write_regs(Target::Tofino::mau_regs &regs, Table *tbl, Table::Actions::Action *act) {
    write_regs<Target::Tofino::mau_regs>(regs, tbl, act); }

#if HAVE_JBAY
void TMatchOP::write_regs(Target::Tofino::mau_regs &regs, Table *tbl, Table::Actions::Action *act) {
    assert(0);  // should never be called
}
#endif

void OutOP::decode_output_mux(Target::Tofino, value_t &op) {
    static const std::map<std::string, int> ops_mux_lookup = {
        { "mem_hi", 0 }, { "mem_lo", 1 },
        { "memory_hi", 0 }, { "memory_lo", 1 },
        { "phv_hi", 2 }, { "phv_lo", 3 },
        { "alu_hi", 4 }, { "alu_lo", 5 },
        { "alu_hi_out", 4 }, { "alu_lo_out", 5 },
        { "predicate", 6 } };
    if (op.type == tSTR && ops_mux_lookup.count(op.s))
        output_mux = ops_mux_lookup.at(op.s);
    else
        output_mux = -1;
}

template<>
void OutOP::write_regs(Target::Tofino::mau_regs &regs, Table *tbl, Table::Actions::Action *act) {
    LOG2(this);
    int logical_home_row = tbl->layout[0].row;
    auto &meter_group = regs.rams.map_alu.meter_group[logical_home_row/4U];
    auto &salu = meter_group.stateful.salu_instr_output_alu[act->code];
    if (predication_encode) {
        salu.salu_output_cmpfn = predication_encode & Target::Tofino::STATEFUL_PRED_MASK;
    } else {
        salu.salu_output_cmpfn = STATEFUL_PREDICATION_ENCODE_UNCOND; }
    salu.salu_output_asrc = output_mux;
}
void OutOP::write_regs(Target::Tofino::mau_regs &regs, Table *tbl, Table::Actions::Action *act) {
    write_regs<Target::Tofino::mau_regs>(regs, tbl, act); }

