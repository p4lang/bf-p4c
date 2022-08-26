#include "gateway.h"
#include "input_xbar.h"  // FIXME needed only in unified build to ensure proper specialization

int Target::Flatrock::GatewayTable::find_next_lut_entry(Table *tbl, const Match &match) {
    int rv = 0;
    for (auto &e : tbl->hit_next) {
        if (e == match.next &&
            (!inhibit_idx_action.count(rv) || inhibit_idx_action.at(rv) == match.action)) {
            inhibit_idx_action[rv] = match.action;
            return rv; }
        ++rv; }
    for (auto &e : tbl->extra_next_lut) {
        if (e == match.next &&
            (!inhibit_idx_action.count(rv) || inhibit_idx_action.at(rv) == match.action)) {
            inhibit_idx_action[rv] = match.action;
            return rv; }
        ++rv; }
    tbl->extra_next_lut.push_back(match.next);
    inhibit_idx_action[rv] = match.action;
    if (rv == Target::NEXT_TABLE_SUCCESSOR_TABLE_DEPTH())
        error(tbl->lineno, "Too many next table map entries in table %s", tbl->name());
    return rv;
}

/* this is mostly the same as what happens in GatewayTable::pass2, except it is unconditional
 * (as flatrock will always need to use the map table) and correlates the action run with
 * the inhibit index.  Maybe could be factored better with less duplication? */
void Target::Flatrock::GatewayTable::setup_map_indexing(Table *tbl) {
    BUG_CHECK(match_table ? tbl == match_table : tbl == this,
              "unexpected table in setup_map_indexing");
    for (auto &e : table)
        if (!e.run_table)
            e.next_map_lut = find_next_lut_entry(tbl, e);
    if (!miss.run_table && miss.next_map_lut < 0)
        miss.next_map_lut = find_next_lut_entry(tbl, miss);

    if (tbl->actions) {
        for (auto &inhibit_idx : inhibit_idx_action) {
            if (auto *act = tbl->actions->action(inhibit_idx.second)) {
                if (act->next_table_encode < 0)
                    act->next_table_encode = inhibit_idx.first;
            }
        }
    }
}

void Target::Flatrock::GatewayTable::pass1() {
    ::GatewayTable::pass1();
    if (layout.size() != 1 || layout[0].row < 0) {
        error(lineno, "No row specified in gateway");
    } else if (layout[0].bus >= 0) {
        // should be error?
        warning(lineno, "No search bus needed for gateway on %s", Target::name()); }
}

void Target::Flatrock::GatewayTable::pass2() {
    ::GatewayTable::pass2();
    bitvec match_bits, xor_bits;
    int lineno = this->lineno;
    for (auto &key : match) {
        match_bits.setrange(key.offset, key.val.size());
        for (auto &ixb : input_xbar) {
            int offset = ixb->find_gateway_offset(&key.val);
            if (offset != key.offset)
                error(key.val.lineno, "%s in match does not line up with ixbar",
                      key.val.desc().c_str()); } }
    for (auto &xkey : xor_match) {
        lineno = xkey.val.lineno;
        xor_bits.setrange(xkey.offset, xkey.val.size());
        for (auto &ixb : input_xbar) {
            int offset = ixb->find_gateway_offset(&xkey.val);
            if (offset != xkey.offset + 32)
                error(xkey.val.lineno, "%s in xor does not line up with ixbar",
                      xkey.val.desc().c_str()); } }
    while (xor_bits) {
        if (xor_bits.getrange(0, 8) && match_bits.getrange(0, 8) != xor_bits.getrange(0, 8)) {
            error(lineno, "Can't mix xor and non-xor match with a byte");
            break; }
        xor_bits >>= 8;
        match_bits >>= 8; }
}

#if 0
void Target::Flatrock::GatewayTable::pass3() {
    ::GatewayTable::pass2();
}
#endif

void Target::Flatrock::GatewayTable::write_next_table_regs(Target::Flatrock::mau_regs &regs) {
    if (match_table && inhibit_idx_action.size() > 1) {
        // In this case we definitely need to use the inhibit_index to select, but
        // otherwise will use the payload
        auto &mrd = regs.ppu_mrd;
        bitvec dconfig(1);  // FIXME could select different bits based on dconfig, but for
        // now just using set 0
        for (int d : dconfig) {
            mrd.rf.mrd_nt_ext[match_table->physical_id].ext_start[d] = 62;
            mrd.rf.mrd_nt_ext[match_table->physical_id].ext_size[d] = 2;
            mrd.rf.mrd_pred_pld[match_table->physical_id].map_en_gw_inh[d] = 1;
        }

        // FIXME -- maybe this belongs elsewhere?  In MatchTable::write_regs?  Or that should
        // call some gateway method?  Needs access to the Flatrock::GatewayTable object
        auto &imem_map = mrd.mrd_imem_map_erf.mrd_imem_map[match_table->physical_id];
        for (auto &act : inhibit_idx_action) {
            auto *action = match_table->actions->action(act.second);
            BUG_CHECK(action || act.second == "", "Can't find action %s in table %s",
                      act.second.c_str(), match_table->name());
            // FIXME -- this assumes addr 0 is always a noop.
            imem_map[act.first].data = action ? action->addr : 0;
        }
        for (int d : dconfig)
            mrd.rf.mrd_imem_pld[match_table->physical_id].map_en_gw_inh[d] = 1;
    }
}

template<> void GatewayTable::write_regs_vt(Target::Flatrock::mau_regs &regs) {
    LOG1("### Gateway table " << name() << " write_regs " << loc());
    for (auto &ixb : input_xbar)
        ixb->write_regs(regs);
    auto &minput = regs.ppu_minput.rf;
    auto &mrd = regs.ppu_mrd.rf;
    auto &first_row = layout.at(0);
    int row = first_row.row;
    for (auto &line : table) {
        // FIXME -- there are 104 bits of match to specify here, but each of the 24 rows
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
            minput.minput_gw_comp.inhibit_idx[row] = line.next_map_lut;
        } else if (!match_table || match_table->table_type() == HASH_ACTION) {
            BUG("Flatrock can't run_table on hash_action"); }
        ++row; }
    --row;  // last row of the table (inclusive)
    minput.minput_gw_comp.grp_start |= 1 << row;
    if (!miss.run_table) {
        minput.minput_gw_comp.grp_inhibit |= 1 << first_row.row;
        minput.minput_gw_comp.grp_inh_idx[first_row.row] = miss.next_map_lut;
    } else if (!match_table || match_table->table_type() == HASH_ACTION) {
        BUG("Flatrock can't run_table on hash_action"); }

    for (auto &xkey : xor_match)
        for (auto byte = xkey.offset/8U; byte <= (xkey.offset + xkey.val->size() - 1)/8U; ++byte)
            minput.minput_gw_vtst.xor_en[byte] = 1;

    minput.minput_gw_comp_vect[match_table->physical_id].comp_idx = first_row.row;
    mrd.mrd_inhibit_ix.en[match_table->physical_id] = 1;

    // FIXME -- model needs these non-zero to avoid error message, but what should they be?
    mrd.mrd_pld_delay[match_table->physical_id].delay = 1;
    mrd.mrd_gwres_delay[match_table->physical_id].delay = 1;

    if (have_payload) {
        mrd.mrd_inhibit_pld[match_table->physical_id].pld0 = payload & 0xffffffff;
        mrd.mrd_inhibit_pld[match_table->physical_id].pld1 = payload >> 32; }
    // FIXME -- when to enable inserting the inhibit index?  For now do it unconditionally
    // as it just uses the upper two bits of payload which are otherwise useless.
    mrd.mrd_inhibit_ix.en[match_table->physical_id] = 1;
    write_next_table_regs(regs);
}
template void GatewayTable::write_regs_vt(Target::Flatrock::mau_regs &regs);
