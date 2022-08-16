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
        // FIXME -- there 104 bits of match to specify here, but each of the 24 rows
        // FIXME -- only has 48 bits -- the vector key is only 1 bit per byte with a
        // FIXME -- separate 8-row tmatch (1 row per byte) that is shared by all the
        // FIXME -- gateway rows.  So we really need to check that every gateway row
        // FIXME -- uses the byte match compatibly.  There's also the extra not and
        // FIXME -- comb2/comb4 optional and/or -- not clear how to best use those
        // FIXME -- or expose them in the .bfa
        for (int i = 0; i < 20; ++i)
            minput.minput_gw_btst_key[row].dir[i] = line.val.dirtcam(2, 64 + i*2);
        for (int i = 0; i < 8; ++i) {
            int word0 = line.val.word0.getrange(8*i, 8);
            int word1 = line.val.word1.getrange(8*i, 8);
            if (word0 == word1) {
                // don't care on whole byte
                minput.minput_gw_vtst_key[row].trit[i] = 3;
            } else {
                minput.minput_gw_vtst_key[row].trit[i] = 1;
                for (int j = 0; j < 4; ++j) {
                    minput.minput_gw_vtst_vgd_key[i].dir[j] =
                        line.val.dirtcam(2, 8*i + 2*j); } } }
        if (!line.run_table) {
            minput.minput_gw_comp.inhibit |= 1 << row;
        } else if (!match_table || match_table->table_type() == HASH_ACTION) {
            // FIXME -- can't really do hash_action on flatrack (no match miss doesn't
            // work, so we can't actually run the table to do nothing here, as it won't
            // run next table properly.  So we hack it.  How?
            minput.minput_gw_comp.inhibit |= 1 << row;
        }
        ++row; }
    --row;  // last row of the table (inclusive)
    minput.minput_gw_comp.grp_start |= 1 << row;
    if (!miss.run_table) {
        minput.minput_gw_comp.grp_inhibit |= 1 << first_row.row;
    } else if (!match_table || match_table->table_type() == HASH_ACTION) {
        // FIXME -- can't really do hash_action on flatrack (no match miss doesn't
        // work, so we can't actually run the table to do nothing here, as it won't
        // run next table properly.  So we hack it.  How?
        minput.minput_gw_comp.grp_inhibit |= 1 << first_row.row;
    }

    minput.minput_gw_comp_vect[match_table->physical_id].comp_idx = first_row.row;
    mrd.mrd_inhibit_ix.en[match_table->physical_id] = 1;

    // FIXME -- model needs these non-zero to avoid error message, but what should they be?
    mrd.mrd_pld_delay[match_table->physical_id].delay = 1;
    mrd.mrd_gwres_delay[match_table->physical_id].delay = 1;

    if (have_payload) {
        mrd.mrd_inhibit_pld[match_table->physical_id].pld0 = payload & 0xffffffff;
        mrd.mrd_inhibit_pld[match_table->physical_id].pld1 = payload >> 32;
        // FIXME -- when to enable inserting the inhibit index?
        mrd.mrd_inhibit_ix.en[match_table->physical_id] = 0; }
}
template void GatewayTable::write_regs_vt(Target::Flatrock::mau_regs &regs);
