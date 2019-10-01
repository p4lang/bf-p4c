/* Tofino overloads for instructions #included in instruction.cpp
 * WARNING -- this is included in an anonymous namespace, as VLIWInstruction is 
 * in that anonymous namespace */

void VLIWInstruction::write_regs(Target::Tofino::mau_regs &regs,
        Table *tbl, Table::Actions::Action *act) {
    if (act != tbl->stage->imem_addr_use[tbl->gress][act->addr]) {
        LOG3("skipping " << tbl->name() << '.' << act->name << " as its imem is used by " <<
             tbl->stage->imem_addr_use[tbl->gress][act->addr]->name);
        return; }
    LOG2(this);
    auto &imem = regs.dp.imem;
    int iaddr = act->addr/ACTION_IMEM_COLORS;
    int color = act->addr%ACTION_IMEM_COLORS;
    unsigned bits = encode();
    BUG_CHECK(slot >= 0);
    switch (Phv::reg(slot)->size) {
    case 8:
        imem.imem_subword8[slot-64][iaddr].imem_subword8_instr = bits;
        imem.imem_subword8[slot-64][iaddr].imem_subword8_color = color;
        imem.imem_subword8[slot-64][iaddr].imem_subword8_parity =
            parity(bits) ^ color;
        break;
    case 16:
        imem.imem_subword16[slot-128][iaddr].imem_subword16_instr = bits;
        imem.imem_subword16[slot-128][iaddr].imem_subword16_color = color;
        imem.imem_subword16[slot-128][iaddr].imem_subword16_parity =
            parity(bits) ^ color;
        break;
    case 32:
        imem.imem_subword32[slot][iaddr].imem_subword32_instr = bits;
        imem.imem_subword32[slot][iaddr].imem_subword32_color = color;
        imem.imem_subword32[slot][iaddr].imem_subword32_parity =
            parity(bits) ^ color;
        break;
    default:
        BUG(); }
    auto &power_ctl = regs.dp.actionmux_din_power_ctl;
    phvRead([&](const Phv::Slice &sl) {
        set_power_ctl_reg(power_ctl, sl.reg.mau_id()); });
}
