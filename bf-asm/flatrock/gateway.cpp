#include "gateway.h"
#include "input_xbar.h"  // FIXME needed only in unified build to ensure proper specialization

void Target::Flatrock::GatewayTable::pass1() {
    ::GatewayTable::pass1();
    if (layout.size() != 1 || layout[0].row < 0) {
        error(lineno, "No row specified in gateway");
    } else if (layout[0].bus >= 0) {
        // should be error?
        warning(lineno, "No search bus needed for gateway on %s", Target::name()); }
}

#if 0
void Target::Flatrock::GatewayTable::pass2() {
    ::GatewayTable::pass2();
}

void Target::Flatrock::GatewayTable::pass3() {
    ::GatewayTable::pass2();
}
#endif

template<> void GatewayTable::write_regs_vt(Target::Flatrock::mau_regs &regs) {
    LOG1("### Gateway table " << name() << " write_regs " << loc());
    for (auto &ixb : input_xbar)
        ixb->write_regs(regs);
    auto &minput = regs.ppu_minput.rf;
    auto &mrd = regs.ppu_mrd.rf;
    auto &first_row = layout.at(0);
    int row = first_row.row;
    for (auto &line : table) {
        // FIXME -- there 104 bits of match to (maybe) specify here, but we
        // FIXME -- only store 64 bits in line.  The vector/byte match is also
        // FIXME -- weirdly shared between rows (single match for each byte,
        // FIXME -- then each row gets to match on those 8 bits
        // for now, just map as 40+8 bits
        for (int i = 0; i < 20; ++i)
            minput.minput_gw_btst_key[row].dir[i] = line.val.dirtcam(2, i*2);
        for (int i = 0; i < 8; ++i)
            minput.minput_gw_vtst_key[row].trit[i] = line.val.dirtcam(1, 40 + i);
        if (!line.run_table)
            minput.minput_gw_comp.inhibit |= 1 << row;
        ++row; }
    --row;  // last row of the table (inclusive)
    minput.minput_gw_comp.grp_start |= 1 << row;
    if (!miss.run_table)
        minput.minput_gw_comp.grp_inhibit |= 1 << first_row.row;
    minput.minput_gw_comp_vect[match_table->physical_id].comp_idx = first_row.row;
    mrd.mrd_inhibit_ix.en[match_table->physical_id] = 1;

    // FIXME -- model needs these non-zero to avoid error message, but what should they be?
    mrd.mrd_pld_delay[match_table->physical_id].delay = 1;
    mrd.mrd_gwres_delay[match_table->physical_id].delay = 1;

    // FIXME -- write payload?
    // mrd.mrd_aram_pld[physical action ram].dconfig_sel_lo = 0;
    // mrd.mrd_aram_pld[physical action ram].dconfig_sel_hi = 0;
    // mrd.mrd_au_pld[physical action unit].dconfig_sel_lo = 0;
    // mrd.mrd_au_pld[physical action unit].dconfig_sel_hi = 0;
    mrd.mrd_iad_pld[match_table->physical_id].dconfig_sel_lo = 0;
    mrd.mrd_iad_pld[match_table->physical_id].dconfig_sel_hi = 0;
    mrd.mrd_iad_pld[match_table->physical_id].base[0] = 0;
    mrd.mrd_iad_pld[match_table->physical_id].base_gw_inh[0] = 0;
    mrd.mrd_iad_pld[match_table->physical_id].map_en[0] = 0;
    mrd.mrd_iad_pld[match_table->physical_id].map_en_gw_inh[0] = 0;
    mrd.mrd_imem_pld[match_table->physical_id].dconfig_sel_lo = 0;
    mrd.mrd_imem_pld[match_table->physical_id].dconfig_sel_hi = 0;
    mrd.mrd_imem_pld[match_table->physical_id].base[0] = 0;
    mrd.mrd_imem_pld[match_table->physical_id].base_gw_inh[0] = 0;
    mrd.mrd_imem_pld[match_table->physical_id].map_en[0] = 0;
    mrd.mrd_imem_pld[match_table->physical_id].map_en_gw_inh[0] = 0;
    mrd.mrd_inhibit_pld[match_table->physical_id].pld0 = 0;
    mrd.mrd_inhibit_pld[match_table->physical_id].pld1 = 0;
    mrd.mrd_pred_pld[match_table->physical_id].dconfig_sel_lo = 0;
    mrd.mrd_pred_pld[match_table->physical_id].dconfig_sel_hi = 0;
    mrd.mrd_pred_pld[match_table->physical_id].base[0] = 0;
    mrd.mrd_pred_pld[match_table->physical_id].base_gw_inh[0] = 0;
    mrd.mrd_pred_pld[match_table->physical_id].map_en[0] = 0;
    mrd.mrd_pred_pld[match_table->physical_id].map_en_gw_inh[0] = 0;

    // error(lineno, "%s:%d: Flatrock gateway not implemented yet!", SRCFILE, __LINE__);
}
template void GatewayTable::write_regs_vt(Target::Flatrock::mau_regs &regs);
