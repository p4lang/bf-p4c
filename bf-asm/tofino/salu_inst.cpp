/* Tofino template specializations for instructions #included in salu_inst.cpp
 * WARNING -- this is included in an anonymous namespace, as these SaluInstruction
 * subclasses are all defined in that anonymous namespace */

template<>
void AluOP::write_regs(Target::Tofino::mau_regs &regs, Table *tbl_, Table::Actions::Action *act) {
    auto tbl = dynamic_cast<StatefulTable *>(tbl_);
    int logical_home_row = tbl->layout[0].row;
    auto &meter_group = regs.rams.map_alu.meter_group[logical_home_row/4U];
    auto &salu = meter_group.stateful.salu_instr_state_alu[act->code][slot - 2];
    auto &salu_instr_common = meter_group.stateful.salu_instr_common[act->code];
    auto &salu_instr_output_alu = meter_group.stateful.salu_instr_output_alu[act->code];
    salu.salu_op = opc->opcode & 0xf;
    salu.salu_arith = opc->opcode >> 4;
    salu.salu_pred = predication_encode;
    if (tbl->is_dual_mode()) {
        salu_instr_common.salu_datasize = tbl->format->log2size - 1;
        salu_instr_common.salu_op_dual = 1; }
    else {
        salu_instr_common.salu_datasize = tbl->format->log2size; }
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
    int logical_home_row = tbl->layout[0].row;
    auto &meter_group = regs.rams.map_alu.meter_group[logical_home_row/4U];
    auto &salu = meter_group.stateful.salu_instr_state_alu[act->code][slot-2];
    salu.salu_op = opc->opcode & 0xf;
    salu.salu_pred = predication_encode;
    //1b instructions are from mem-lo to alu1-lo
    salu.salu_asrc_memory = 1;
    salu.salu_asrc_memory_index = 0;
}
void BitOP::write_regs(Target::Tofino::mau_regs &regs, Table *tbl, Table::Actions::Action *act) {
    write_regs<Target::Tofino::mau_regs>(regs, tbl, act); }

template<>
void CmpOP::write_regs(Target::Tofino::mau_regs &regs, Table *tbl_, Table::Actions::Action *act) {
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

template<>
void OutOP::write_regs(Target::Tofino::mau_regs &regs, Table *tbl, Table::Actions::Action *act) {
    int logical_home_row = tbl->layout[0].row;
    auto &meter_group = regs.rams.map_alu.meter_group[logical_home_row/4U];
    auto &action_ctl = regs.rams.map_alu.meter_alu_group_action_ctl[logical_home_row/4U];
    auto &switch_ctl = regs.rams.array.switchbox.row[logical_home_row/2U].ctl;
    auto &action_hv_xbar = regs.rams.array.row[logical_home_row/2U].action_hv_xbar;
    auto &salu = meter_group.stateful.salu_instr_output_alu[act->code];
    if (predication_encode) {
        salu.salu_output_cmpfn = predication_encode;
        // Not clear if this is the best place for the rest of these -- should perhaps
        // be in stateful?  Only needed if the salu wants to output to the VLIW action data bus
        // Output onto rhs action data bus w 4 cycle delay iff selectors anywhere in this stage
        action_ctl.right_alu_action_enable = 1;
        action_ctl.right_alu_action_delay =
            tbl->stage->group_table_use[tbl->gress] & Stage::USE_SELECTOR ? 4 : 0;
        switch_ctl.r_action_o_mux_select.r_action_o_sel_action_rd_r_i = 1;
        // disable action data address huffman decoding, on the assumtion we're not trying
        // to combine this with an action data table on the same home row.  Otherwise, the
        // huffman decoding will think this is an 8-bit value and replicate it.
        action_hv_xbar.action_hv_xbar_disable_ram_adr.action_hv_xbar_disable_ram_adr_right = 1; 
    } else {
        salu.salu_output_cmpfn = STATEFUL_PREDICATION_ENCODE_UNCOND; }
    salu.salu_output_asrc = output_mux;
}
void OutOP::write_regs(Target::Tofino::mau_regs &regs, Table *tbl, Table::Actions::Action *act) {
    write_regs<Target::Tofino::mau_regs>(regs, tbl, act); }

