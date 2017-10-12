/* JBay template specializations for instructions #included in instruction.cpp
 * WARNING -- this is included in an anonymous namespace, as VLIWInstruction is 
 * in that anonymous namespace */

template<> void VLIWInstruction::write_regs(Target::JBay::mau_regs &regs,
        Table *tbl, Table::Actions::Action *act)
{
    if (act != tbl->stage->imem_addr_use[tbl->gress][act->addr]) {
        LOG3("skipping " << tbl->name() << '.' << act->name << " as its imem is used by " <<
             tbl->stage->imem_addr_use[tbl->gress][act->addr]->name);
        return; }
    auto &imem = regs.dp.imem;
    int iaddr = act->addr/ACTION_IMEM_COLORS;
    int color = act->addr%ACTION_IMEM_COLORS;
    unsigned bits = encode();
    assert(slot >= 0);
    unsigned group = slot / Phv::mau_groupsize();
    unsigned off = slot % Phv::mau_groupsize();
    LOG2(this);
    switch (Phv::reg(slot)->type) {
    case Phv::Register::NORMAL:
        switch (Phv::reg(slot)->size) {
        case 8:
            imem.imem_subword8[group-4][off][iaddr].imem_subword8_instr = bits;
            imem.imem_subword8[group-4][off][iaddr].imem_subword8_color = color;
            imem.imem_subword8[group-4][off][iaddr].imem_subword8_parity = parity(bits) ^ color;
            break;
        case 16:
            imem.imem_subword16[group-8][off][iaddr].imem_subword16_instr = bits;
            imem.imem_subword16[group-8][off][iaddr].imem_subword16_color = color;
            imem.imem_subword16[group-8][off][iaddr].imem_subword16_parity = parity(bits) ^ color;
            break;
        case 32:
            imem.imem_subword32[group][off][iaddr].imem_subword32_instr = bits;
            imem.imem_subword32[group][off][iaddr].imem_subword32_color = color;
            imem.imem_subword32[group][off][iaddr].imem_subword32_parity = parity(bits) ^ color;
            break;
        default:
            assert(0); }
        break;
    case Phv::Register::MOCHA:
        switch (Phv::reg(slot)->size) {
        case 8:
            imem.imem_mocha_subword8[group-4][off-12][iaddr].imem_mocha_subword_instr = bits;
            imem.imem_mocha_subword8[group-4][off-12][iaddr].imem_mocha_subword_color = color;
            imem.imem_mocha_subword8[group-4][off-12][iaddr].imem_mocha_subword_parity =
                    parity(bits) ^ color;
            break;
        case 16:
            imem.imem_mocha_subword16[group-8][off-12][iaddr].imem_mocha_subword_instr = bits;
            imem.imem_mocha_subword16[group-8][off-12][iaddr].imem_mocha_subword_color = color;
            imem.imem_mocha_subword16[group-8][off-12][iaddr].imem_mocha_subword_parity =
                    parity(bits) ^ color;
            break;
        case 32:
            imem.imem_mocha_subword32[group][off-12][iaddr].imem_mocha_subword_instr = bits;
            imem.imem_mocha_subword32[group][off-12][iaddr].imem_mocha_subword_color = color;
            imem.imem_mocha_subword32[group][off-12][iaddr].imem_mocha_subword_parity =
                    parity(bits) ^ color;
            break;
        default:
            assert(0); }
        break;
    case Phv::Register::DARK:
        switch (Phv::reg(slot)->size) {
        case 8:
            imem.imem_dark_subword8[group-4][off-16][iaddr].imem_dark_subword_instr = bits;
            imem.imem_dark_subword8[group-4][off-16][iaddr].imem_dark_subword_color = color;
            imem.imem_dark_subword8[group-4][off-16][iaddr].imem_dark_subword_parity =
                    parity(bits) ^ color;
            break;
        case 16:
            imem.imem_dark_subword16[group-8][off-16][iaddr].imem_dark_subword_instr = bits;
            imem.imem_dark_subword16[group-8][off-16][iaddr].imem_dark_subword_color = color;
            imem.imem_dark_subword16[group-8][off-16][iaddr].imem_dark_subword_parity =
                    parity(bits) ^ color;
            break;
        case 32:
            imem.imem_dark_subword32[group][off-16][iaddr].imem_dark_subword_instr = bits;
            imem.imem_dark_subword32[group][off-16][iaddr].imem_dark_subword_color = color;
            imem.imem_dark_subword32[group][off-16][iaddr].imem_dark_subword_parity =
                    parity(bits) ^ color;
            break;
        default:
            assert(0); }
        break;
    default:
        assert(0); }

    auto &power_ctl = regs.dp.actionmux_din_power_ctl;
    phvRead([&](const Phv::Slice &sl) {
        set_power_ctl_reg(power_ctl, sl.reg.mau_id()); });
}

void VLIWInstruction::write_regs(Target::JBay::mau_regs &regs,
        Table *tbl, Table::Actions::Action *act) {
    write_regs<Target::JBay::mau_regs>(regs, tbl, act);
}
