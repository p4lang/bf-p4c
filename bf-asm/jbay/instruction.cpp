/* JBay template specializations for instructions #included in instruction.cpp
 * WARNING -- this is included in an anonymous namespace, as VLIWInstruction is 
 * in that anonymous namespace */

template<> void VLIWInstruction::write_regs(Target::JBay::mau_regs &regs,
        Table *tbl, Table::Actions::Action *act)
{
#if 0
    // FIXME -- JBay instruction incoding is quite different from Tofino, due
    // to dark and mocha phvs.
    if (act != tbl->stage->imem_addr_use[tbl->gress][act->addr]) {
        LOG3("skipping " << tbl->name() << '.' << act->name << " as its imem is used by " <<
             tbl->stage->imem_addr_use[tbl->gress][act->addr]->name);
        return; }
    auto &imem = regs.dp.imem;
    int iaddr = act->addr/ACTION_IMEM_COLORS;
    int color = act->addr%ACTION_IMEM_COLORS;
    unsigned bits = encode();
    assert(slot >= 0);
    LOG2(this);
    switch (Phv::reg(slot).size) {
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
        assert(0); }
    auto &power_ctl = regs.dp.actionmux_din_power_ctl;
    phvRead([&](const Phv::Slice &sl) {
        set_power_ctl_reg(power_ctl, sl.reg.index); });
#endif
}

void VLIWInstruction::write_regs(Target::JBay::mau_regs &regs,
        Table *tbl, Table::Actions::Action *act) {
    write_regs<Target::JBay::mau_regs>(regs, tbl, act);
}
