#include "gateway.h"
#include "input_xbar.h"  // FIXME needed only in unified build to ensure proper specialization
#include "stage.h"

bool Target::Flatrock::GatewayTable::check_match_key(MatchKey &key,
        const std::vector<MatchKey> &vec, bool is_xor) {
    if (!::GatewayTable::check_match_key(key, vec, is_xor)) return false;
    if ((key.offset & 7) != (key.val->lo & 7))
        error(key.val.lineno, "Gateway %s key %s misaligned within byte",
              is_xor ? "xor" : "match", key.val.name());
    if (key.offset + key.val->size() > (is_xor ? 32 : 104)) {
        error(key.val.lineno, "Gateway %s key too big", is_xor ? "xor" : "match");
        return false; }
    return true;
}

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
    } else if (!layout[0].bus.empty()) {
        // should be error?
        warning(lineno, "No search bus needed for gateway on %s", Target::name()); }
}

void Target::Flatrock::GatewayTable::pass2() {
    ::GatewayTable::pass2();
    bitvec match_bits, xor_bits;
    int lineno = this->lineno;
    for (auto &key : match) {
        match_bits.setrange(key.offset, key.val.size());
        if (key.offset >= 64) {
            int byte = (key.offset - 64)/8U;
            if (key.val->reg.ixbar_id() != byte)
                error(key.val.lineno, "Gateway match bits %d..%d can only match B%d",
                      byte*8 + 64, byte*8 + 64 + 7, byte);
            else if (key.offset % 8U != key.val->lo)
                error(key.val.lineno, "%s in match not aligned",
                      key.val.desc().c_str());
        } else {
            for (auto &ixb : input_xbar) {
                int offset = ixb->find_gateway_offset(&key.val);
                if (offset != key.offset)
                    error(key.val.lineno, "%s in match does not line up with ixbar",
                          key.val.desc().c_str()); } } }
    for (auto &xkey : xor_match) {
        lineno = xkey.val.lineno;
        xor_bits.setrange(xkey.offset, xkey.val.size());
        for (auto &ixb : input_xbar) {
            int offset = ixb->find_gateway_offset(&xkey.val);
            if (offset != xkey.offset + 32)
                error(xkey.val.lineno, "%s in xor does not line up with ixbar",
                      xkey.val.desc().c_str()); } }
    unsigned byte = 1;
    while ((xor_bits || match_bits) && byte < (1U << GATEWAY_VECTOR_BYTES)) {
        if (xor_bits.getrange(0, 8)) {
            byte_use |= byte;
            byte_xor_value |= byte; }
        if (match_bits.getrange(0, 8))
            byte_use |= byte;
        if (xor_bits.getrange(0, 8) && match_bits.getrange(0, 8) != xor_bits.getrange(0, 8)) {
            error(lineno, "Can't mix xor and non-xor match within a byte");
            break; }
        xor_bits >>= 8;
        match_bits >>= 8;
        byte <<= 1; }
    if (xor_bits)
        error(lineno, "Can't xor in fixed part of gateway match");

    for (auto &line : table) {
        for (int i = 0; i < 8; ++i) {
            uint8_t word0 = line.val.word0.getrange(8*i, 8);
            uint8_t word1 = line.val.word1.getrange(8*i, 8);
            if (word0 == word1) {
                // don't care on whole byte
            } else if (byte_matches.count(i)) {
                if (byte_matches.at(i).word0 != word0 || byte_matches.at(i).word1 != word1) {
                    error(byte_matches.at(i).lineno, "Different matching in byte %d of "
                          "vector match in %s", i, name());
                    error(line.lineno, "and here"); }
            } else {
                byte_matches.emplace(i, byte_match_t{ line.lineno, word0, word1 }); } } }

    for (auto *tbl : stage->tables) {
        if (auto *gw = dynamic_cast<const GatewayTable *>(tbl->get_gateway())) {
            auto overlap = byte_use & gw->byte_use;
            if ((byte_xor_value & overlap) != (gw->byte_xor_value & overlap)) {
                error(lineno, "%s xor use conflict with %s", name(), gw->name());
                error(gw->lineno, "%s defined here", gw->name()); }
            for (auto &bm : byte_matches) {
                if (gw->byte_matches.count(bm.first)) {
                    auto &prev = gw->byte_matches.at(bm.first);
                    if (bm.second.word0 != prev.word0 || bm.second.word1 != prev.word1) {
                        error(bm.second.lineno, "Conflict in gateway vector byte %d between %s",
                              bm.first, name());
                        error(prev.lineno, "and %s", gw->name()); } } }
        } else {
            BUG_CHECK(!tbl->get_gateway(), "gateway is not a flatrock gateway?"); } }
}

#if 0
void Target::Flatrock::GatewayTable::pass3() {
    ::GatewayTable::pass2();
}
#endif

void Target::Flatrock::GatewayTable::write_next_table_regs(Target::Flatrock::mau_regs &regs) {
    auto &mrd = regs.ppu_mrd;
    bitvec dconfig(1);  // FIXME could select different bits based on dconfig, but for
                        // now just using set 0

    if (!match_table) {
        // FIXME -- duplicates MatchTable::write_next_table_regs, as that is needed for
        // standalone gateways
        auto &mrd = regs.ppu_mrd;
        auto &pred_map = mrd.mrd_pred_map_erf.mrd_pred_map;
        if (!hit_next.empty() || !extra_next_lut.empty()) {
            int i = 0;
            for (auto &n : hit_next) {
                pred_map[logical_id][i].gl_pred_vec = n.next_in_stage(stage->stageno + 1);
                pred_map[logical_id][i].long_branch |= n.long_branch_tags();
                pred_map[logical_id][i].next_table = n.next_table_id();
                pred_map[logical_id][i].pred_vec = n.next_in_stage(stage->stageno) >> 1;
                ++i; }
            for (auto &n : extra_next_lut) {
                pred_map[logical_id][i].gl_pred_vec = n.next_in_stage(stage->stageno + 1);
                pred_map[logical_id][i].long_branch |= n.long_branch_tags();
                pred_map[logical_id][i].next_table = n.next_table_id();
                pred_map[logical_id][i].pred_vec = n.next_in_stage(stage->stageno) >> 1;
                ++i; }
            // is this needed?  The model complains if we leave the unused slots as 0
            while (i < Target::NEXT_TABLE_SUCCESSOR_TABLE_DEPTH())
                pred_map[logical_id][i++].next_table = Target::Flatrock::END_OF_PIPE; }
        pred_map[logical_id][16].gl_pred_vec = miss_next.next_in_stage(stage->stageno + 1);
        pred_map[logical_id][16].long_branch |= miss_next.long_branch_tags();
        pred_map[logical_id][16].next_table = miss_next.next_table_id();
        pred_map[logical_id][16].pred_vec = miss_next.next_in_stage(stage->stageno) >> 1;

        // FIXME -- need to set delay regs correctly -- this just avoids model errors
        mrd.rf.mrd_ntt_delay[logical_id].pre_delay = 1;
        mrd.rf.mrd_ntt_delay[logical_id].post_delay = 1;
    }

    if (!match_table || inhibit_idx_action.size() > 1) {
        // In this case we definitely need to use the inhibit_index to select, but
        // otherwise will use the payload
        for (int d : dconfig) {
            mrd.rf.mrd_nt_ext[physical_id].ext_start[d] = 62;
            mrd.rf.mrd_nt_ext[physical_id].ext_size[d] = 2;
            mrd.rf.mrd_pred_pld[logical_id].map_en_gw_inh[d] = 1;
        }
    }

    Actions *actions = match_table ? match_table->actions.get() : this->actions.get();
    if (actions && inhibit_idx_action.size() > (match_table ? 1 : 0)) {
        // FIXME -- maybe this belongs elsewhere?  In MatchTable::write_regs?  Or that should
        // call some gateway method?  Needs access to the Flatrock::GatewayTable object
        auto &imem_map = mrd.mrd_imem_map_erf.mrd_imem_map[physical_id];
        for (auto &act : inhibit_idx_action) {
            auto *action = actions->action(act.second);
            BUG_CHECK(action || act.second == "", "Can't find action %s in table %s",
                      act.second.c_str(), match_table->name());
            // FIXME -- this assumes addr 0 is always a noop.
            imem_map[act.first].data = action ? action->addr : 0;
        }
        for (int d : dconfig)
            mrd.rf.mrd_imem_pld[physical_id].map_en_gw_inh[d] = 1;
    }
}

void Target::Flatrock::GatewayTable::write_regs(Target::Flatrock::mau_regs &regs) {
    LOG1("### Gateway table " << name() << " write_regs " << loc());
    auto &minput = regs.ppu_minput.rf;
    auto &mrd = regs.ppu_mrd.rf;
    if (!match_table) {
        // FIXME -- mostly just duplicates what is in MatchTable::write_regs, as we need
        // all that basic logical/physical setup for standalone gateways too.
        if (gress == GHOST) {
            mrd.mrd_pred_cfg.gst_tables |= 1 << logical_id;
            minput.minput_mpr.gst_tables |= 1 << logical_id;
        } else {
            mrd.mrd_pred_cfg.main_tables |= 1 << logical_id;
            minput.minput_mpr.main_tables |= 1 << logical_id; }
        if (always_run || pred.empty()) {
            minput.minput_mpr.always_run = 1 << logical_id;
            minput.minput_mpr_act[logical_id].activate |= 1 << physical_id;
        } else {
            for (auto tbl : Keys(find_pred_in_stage(stage->stageno)))
                minput.minput_mpr_act[tbl->logical_id].activate |= 1 << physical_id;
        }
        if (long_branch_input >= 0) {
            minput.minput_mpr_act[logical_id].long_branch_en = 1;
            minput.minput_mpr_act[logical_id].long_branch_sel = long_branch_input; }


        // these xbars are "backwards" (because they are oxbars?) -- l2p maps physical to logical
        // and p2l maps logical to physical
        mrd.mrd_l2p_xbar[physical_id].en = 1;
        mrd.mrd_l2p_xbar[physical_id].logical_table = logical_id;
        mrd.mrd_p2l_xbar[logical_id].en = 1;
        mrd.mrd_p2l_xbar[logical_id].phy_table = physical_id;
        if (get_actions()) {
            mrd.mrd_imem_cfg.active_en |= 1 << physical_id;
            mrd.mrd_imem_delay[physical_id].delay = 1; }   // FIXME -- what is the delay?
        minput.minput_mpr_act[logical_id].activate |= 1 << physical_id;

        // FIXME -- need action/imem setup from MatchTable::write_regs if the gateway has actions?
    }

    for (auto &ixb : input_xbar)
        ixb->write_regs(regs);
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

    for (auto byte : bitvec(byte_use)) {
        if (byte < minput.minput_gw_vtst.xor_en.size())
            minput.minput_gw_vtst.xor_en[byte] = (byte_xor_value >> byte) & 1;
        else
            BUG_CHECK(((byte_xor_value >> byte) & 1) == 0, "invalid byte xor value"); }

    minput.minput_gw_comp_vect[physical_id].comp_idx = first_row.row;
    mrd.mrd_inhibit_ix.en[physical_id] = 1;

    // FIXME -- model needs these non-zero to avoid error message, but what should they be?
    mrd.mrd_pld_delay[physical_id].delay = 1;
    mrd.mrd_gwres_delay[physical_id].delay = 1;

    if (have_payload) {
        mrd.mrd_inhibit_pld[physical_id].pld0 = payload & 0xffffffff;
        mrd.mrd_inhibit_pld[physical_id].pld1 = payload >> 32; }
    // FIXME -- when to enable inserting the inhibit index?  For now do it unconditionally
    // as it just uses the upper two bits of payload which are otherwise useless.
    mrd.mrd_inhibit_ix.en[physical_id] = 1;
    write_next_table_regs(regs);
}

// never called as we override write_regs, but needs to be defined to satisfy the linker
template<> void GatewayTable::write_regs_vt(Target::Flatrock::mau_regs &regs) { BUG(); }
template void GatewayTable::write_regs_vt(Target::Flatrock::mau_regs &regs);
