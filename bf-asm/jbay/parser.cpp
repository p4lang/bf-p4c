/* parser template specializations for jbay -- #included directly in top-level parser.cpp */

template <> void Parser::CounterInit::write_config(Target::JBay::parser_regs &regs,
                                                   gress_t gress, int idx) {
    auto &ctr_init_ram = regs.memory[gress].ml_ctr_init_ram[idx];
    ctr_init_ram.add = add;
    ctr_init_ram.mask_8 = mask;
    ctr_init_ram.rotate = rot;
    ctr_init_ram.max = max;
    ctr_init_ram.src = src;
}

template<> void Parser::State::Match::write_lookup_config(Target::JBay::parser_regs &regs,
                                                          State *state, int r) const {
    auto &row = regs.memory[state->gress].ml_tcam_row[r];
    match_t lookup = { 0, 0 };
    for (int i = 0; i < 4; i++) {
        lookup.word0 <<= 8;
        lookup.word1 <<= 8;
        if (state->key.data[i].bit >= 0) {
            lookup.word0 |= ((match.word0 >> state->key.data[i].bit) & 0xff);
            lookup.word1 |= ((match.word1 >> state->key.data[i].bit) & 0xff); } }
    unsigned dont_care = ~(lookup.word0 | lookup.word1);
    lookup.word0 |= dont_care;
    lookup.word1 |= dont_care;
    for (int i = 3; i >= 0; i--) {
        row.w0_lookup_8[i] = lookup.word0 & 0xff;
        row.w1_lookup_8[i] = lookup.word1 & 0xff;
        lookup.word0 >>= 8;
        lookup.word1 >>= 8; }
    row.w0_curr_state = state->stateno.word0;
    row.w1_curr_state = state->stateno.word1;
    if (state->key.ctr_zero >= 0) {
        row.w0_ctr_zero = (match.word0 >> state->key.ctr_zero) & 1;
        row.w1_ctr_zero = (match.word1 >> state->key.ctr_zero) & 1;
    } else
        row.w0_ctr_zero = row.w1_ctr_zero = 1;
    if (state->key.ctr_neg >= 0) {
        row.w0_ctr_neg = (match.word0 >> state->key.ctr_neg) & 1;
        row.w1_ctr_neg = (match.word1 >> state->key.ctr_neg) & 1;
    } else
        row.w0_ctr_neg = row.w1_ctr_neg = 1;
    row.w0_ver_0 = row.w1_ver_0 = 1;
    row.w0_ver_1 = row.w1_ver_1 = 1;
}

/* FIXME -- combine these next two methods into a single method on MatchKey */
/* FIXME -- factor Tofino/JBay variation better (most is common) */
template <> int Parser::State::write_lookup_config(Target::JBay::parser_regs &regs,
            Parser *pa, State *state, int row, const std::vector<State *> &prev) {
    LOG2("-- checking match from state " << name << " (" << stateno << ')');
    auto &ea_row = regs.memory[gress].ml_ea_row[row];
    int max_off = -1;
    for (int i = 0; i < 4; i++) {
        if (key.data[i].bit < 0) continue;
        bool set = true;
        for (State *p : prev) {
            if (p->key.data[i].bit >= 0) {
                set = false;
                if (p->key.data[i].byte != key.data[i].byte)
                    error(p->lineno, "Incompatible match fields between states "
                          "%s and %s, triggered from state %s", name.c_str(),
                          p->name.c_str(), state->name.c_str()); } }
        if (set && key.data[i].byte != MatchKey::USE_SAVED) {
            int off = key.data[i].byte + ea_row.shift_amt;
            if (off < 0 || off >= 32) {
                error(key.lineno, "Match offset of %d in state %s out of range "
                      "for previous state %s", key.data[i].byte, name.c_str(),
                      state->name.c_str()); }
            ea_row.lookup_offset_8[i] = off;
            ea_row.ld_lookup_8[i] = 1;
            max_off = std::max(max_off, off); } }
    return max_off;
}

template <> int Parser::State::Match::write_future_config(Target::JBay::parser_regs &regs,
            Parser *pa, State *state, int row) const {
    auto &ea_row = regs.memory[state->gress].ml_ea_row[row];
    int max_off = -1;
    for (int i = 0; i < 4; i++) {
        if (future.data[i].bit < 0) continue;
        if (future.data[i].byte != MatchKey::USE_SAVED) {
            int off = future.data[i].byte;
            if (off < 0 || off >= 32) {
                error(future.lineno, "Save offset of %d in state %s out of range",
                      future.data[i].byte, state->name.c_str()); }
            ea_row.lookup_offset_8[i] = off;
            ea_row.ld_lookup_8[i] = 1;
            max_off = std::max(max_off, off); } }
    return max_off;
}

static void write_output_slot(int lineno, Target::JBay::parser_regs::_memory::_po_action_row *row,
                              unsigned &used, int src, int dest, int bytemask, bool offset) {
    assert(bytemask > 0 && bytemask < 4);
    for (int i = 0; i < 20; ++i) {
        if (used & (1 << i)) continue;
        row->phv_dst[i] = dest;
        row->phv_src[i] = src + (bytemask == 2);
        if (offset) row->phv_offset_add_dst[i] = 1;
        row->extract_type[i] = bytemask;
        used |= 1 << i;
        return; }
    error(lineno, "Ran out of phv output slots");
}

template <> int Parser::State::Match::Save::write_output_config(Target::JBay::parser_regs &regs,
            void *_row, unsigned &used) const {
    Target::JBay::parser_regs::_memory::_po_action_row *row =
        (Target::JBay::parser_regs::_memory::_po_action_row *)_row;
    int dest = where->reg.parser_id();
    int mask = (1 << (1 + where->hi/8U)) - (1 << (where->lo/8U));
    int lo = this->lo;
    if (where->reg.size == 8 && mask == 1) {
        if (where->reg.index & 1) {
            mask <<= 1;
            --lo; } }
    if (flags & ROTATE) error(where.lineno, "no rotate support in jbay");
    if (mask & 3)
        write_output_slot(where.lineno, row, used, lo, dest, mask & 3, flags & OFFSET);
    if (mask & 0xc)
        write_output_slot(where.lineno, row, used, lo+2, dest+1, (mask>>2) & 3, flags & OFFSET);
    return hi;
}

#define SAVE_ONLY_USED_SLOTS    0xffc00
static void write_output_const_slot(
        int lineno, Target::JBay::parser_regs::_memory::_po_action_row *row, unsigned &used,
        unsigned src, int dest, int bytemask, int flags) {
    // use bits 24..27 of 'used' to track the two constant slots
    assert(bytemask > 0 && bytemask < 4);
    assert((src & ~((0xffff00ff >> (8*(bytemask-1))) & 0xffff)) == 0);
    // FIXME -- should be able to treat this as 4x8-bit rather than 2x16-bit slots, as long
    // as the ROTATE flag is consistent for each half.
    int cslot = 0;
    for (; cslot < 2; cslot++)
        if (0 == (used & (bytemask << (2*cslot + 24)))) break;
    if (cslot >= 2) {
        error(lineno, "Ran out of constant output slots");
        return; }
    if (bytemask == 1) src <<= 8;
    row->val_const[cslot] |= src;
    if (flags & 2 /*ROTATE*/) row->val_const_rot[cslot] = 1;
    used |= bytemask << (2*cslot + 24);
    unsigned tmpused = used | SAVE_ONLY_USED_SLOTS;
    write_output_slot(lineno, row, tmpused, 62 - 2*cslot - (bytemask == 2), dest, bytemask, flags);
    used |= tmpused &~ SAVE_ONLY_USED_SLOTS;
}

template <> void Parser::State::Match::Set::write_output_config(Target::JBay::parser_regs &regs,
            void *_row, unsigned &used) const
{
    Target::JBay::parser_regs::_memory::_po_action_row *row =
        (Target::JBay::parser_regs::_memory::_po_action_row *)_row;
    int dest = where->reg.parser_id();
    int mask = (1 << (1 + where->hi/8U)) - (1 << (where->lo/8U));
    unsigned what = this->what << where->lo;
    for (unsigned i = 0; i < 4; ++i)
        if (((what >> (8*i)) & 0xff) == 0)
            mask &= ~(1 << i);
    if (where->reg.size == 8) {
        assert((mask & ~1) == 0);
        if (where->reg.index & 1) {
            mask <<= 1;
            what <<= 8; } }
    if (mask & 3)
        write_output_const_slot(where.lineno, row, used, what & 0xffff, dest,
                                mask & 3, flags);
    if (mask & 0xc) {
        write_output_const_slot(where.lineno, row, used, (what >> 16) & 0xffff, dest+1,
                                (mask>>2) & 3, flags);
        if ((mask & 3) && (flags & ROTATE))
            row->val_const_32b_bond = 1; }
}

template <> void *Parser::setup_phv_output_map(Target::JBay::parser_regs &regs,
            gress_t gress, int row) {
    return &regs.memory[gress].po_action_row[row];
}
template <> void Parser::mark_unused_output_map(Target::JBay::parser_regs &,
            void *, unsigned) {
    // unneeded on jbay
}

template<> void Parser::State::Match::Clot::write_config(
        JBay::memories_parser_::_po_action_row &po_row, int idx) const {
    po_row.clot_tag[idx] = tag;
    po_row.clot_offset[idx] = start;
    if (load_length) {
        po_row.clot_type[idx] = 1;
        po_row.clot_len_src[idx] = length;
        po_row.clot_en_len_shr[idx] = length_shift;
        // po_row.clot_len_mask[idx] = length_mask; -- FIXME -- CSR reg commented out
    } else {
        po_row.clot_len_src[idx] = length-1;
        po_row.clot_type[idx] = 0;
        po_row.clot_en_len_shr[idx] = 1; }
}

template<> void Parser::State::Match::write_counter_config(
    Target::JBay::parser_regs::_memory::_ml_ea_row &ea_row) const {
    ea_row.ctr_amt_idx = counter;
    // FIXME -- counter stack config
}

template<> void Parser::write_config(Target::JBay::parser_regs &regs) {
    for (auto st : all) st->write_config(regs, this);
    if (error_count > 0) return;
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        int i = 0;
        for (auto ctr : counter_init[gress]) {
            if (ctr) ctr->write_config(regs, gress, i);
            ++i; }
        for (auto csum : checksum_use[gress])
            if (csum) csum->write_config(regs, this); }

    // FIXME -- what fixed initialization of parser buffer regs do we need?
    // FIXME -- see tofino/parser.cpp init_common_regs for ideas

    regs.egress.epbreg.chan0_group.chnl_ctrl.meta_opt = meta_opt;
    regs.egress.epbreg.chan1_group.chnl_ctrl.meta_opt = meta_opt;
    regs.egress.epbreg.chan2_group.chnl_ctrl.meta_opt = meta_opt;
    regs.egress.epbreg.chan3_group.chnl_ctrl.meta_opt = meta_opt;
    regs.egress.epbreg.chan4_group.chnl_ctrl.meta_opt = meta_opt;
    regs.egress.epbreg.chan5_group.chnl_ctrl.meta_opt = meta_opt;
    regs.egress.epbreg.chan6_group.chnl_ctrl.meta_opt = meta_opt;
    regs.egress.epbreg.chan7_group.chnl_ctrl.meta_opt = meta_opt;

    for (int i : phv_use[EGRESS]) {
        auto id = Phv::reg(i)->parser_id();
        if (id < 128)
            regs.merge.ul.phv_owner_127_0.owner[id] = 1;
        else
            regs.merge.ur.phv_owner_255_128.owner[id-128] = 1;
        regs.main[INGRESS].phv_owner.owner[id] = 1;
        regs.main[EGRESS].phv_owner.owner[id] = 1;
        if (Phv::reg(i)->size == 32) {
            if (++id < 128)
                regs.merge.ul.phv_owner_127_0.owner[id] = 1;
            else
                regs.merge.ur.phv_owner_255_128.owner[id-128] = 1;
            regs.main[INGRESS].phv_owner.owner[id] = 1;
            regs.main[EGRESS].phv_owner.owner[id] = 1;
        } else if (Phv::reg(i)->size == 8) {
            if (phv_use[INGRESS][i^1])
                error(0, "Can't use %s in ingress and %s in egress in jbay parser",
                      Phv::reg(i^1)->name, Phv::reg(i)->name); } }

    regs.main[INGRESS].hdr_len_adj.amt = hdr_len_adj[INGRESS];
    regs.main[EGRESS].hdr_len_adj.amt = hdr_len_adj[EGRESS];

    int i_start = Stage::first_table(INGRESS) & 0x1ff;
    for (auto &reg : regs.merge.ll1.i_start_table)
        reg.table = i_start;
    int e_start = Stage::first_table(EGRESS) & 0x1ff;
    for (auto &reg : regs.merge.lr1.e_start_table)
        reg.table = e_start;
    regs.merge.lr1.g_start_table.table = 0x1ff;

    for (auto &ref : regs.ingress.prsr)
        ref = "regs.parser.main.ingress";
    for (auto &ref : regs.egress.prsr)
        ref = "regs.parser.main.egress";
    if (error_count == 0) {
        if (options.condense_json) {
            // FIXME -- removing the uninitialized memory causes problems?
            // FIXME -- walle gets the addresses wrong.  Might also require explicit
            // FIXME -- zeroing in the driver on real hardware
            // regs.memory[INGRESS].disable_if_zero();
            // regs.memory[EGRESS].disable_if_zero();
            regs.ingress.disable_if_zero();
            regs.egress.disable_if_zero();
            regs.main[INGRESS].disable_if_zero();
            regs.main[EGRESS].disable_if_zero();
            regs.merge.disable_if_zero(); }
        regs.memory[INGRESS].emit_json(*open_output("memories.parser.ingress.cfg.json"), "ingress");
        regs.memory[EGRESS].emit_json(*open_output("memories.parser.egress.cfg.json"), "egress");
        regs.ingress.emit_json(*open_output("regs.parser.ingress.cfg.json"));
        regs.egress.emit_json(*open_output("regs.parser.egress.cfg.json"));
        regs.main[INGRESS].emit_json(*open_output("regs.parser.main.ingress.cfg.json"), "ingress");
        regs.main[EGRESS].emit_json(*open_output("regs.parser.main.egress.cfg.json"), "egress");
        regs.merge.emit_json(*open_output("regs.parse_merge.cfg.json")); }
    for (auto &ref : TopLevel::regs<Target::JBay>()->mem_pipe.parde.i_prsr_mem)
        ref = "memories.parser.ingress";
    for (auto &ref : TopLevel::regs<Target::JBay>()->mem_pipe.parde.e_prsr_mem)
        ref = "memories.parser.egress";
    for (auto &ref : TopLevel::regs<Target::JBay>()->reg_pipe.pardereg.pgstnreg.ipbprsr4reg)
        ref = "regs.parser.ingress";
    for (auto &ref : TopLevel::regs<Target::JBay>()->reg_pipe.pardereg.pgstnreg.epbprsr4reg)
        ref = "regs.parser.egress";
    TopLevel::regs<Target::JBay>()->reg_pipe.pardereg.pgstnreg.pmergereg = "regs.parse_merge";
    for (auto st : all)
        TopLevel::all->name_lookup["directions"][st->gress ? "1" : "0"]
                ["parser_states"][std::to_string(st->stateno.word1)] = st->name;
}

template<> 
void Parser::gen_configuration_cache(Target::JBay::parser_regs &regs, json::vector &cfg_cache) {
    std::string reg_fqname;
    std::string reg_name;
    unsigned reg_value;
    std::string reg_value_str;
    unsigned reg_width = 13;

    /* Publishing meta_opt field for chnl_ctrl register */
    /* Are ovr_pipeid, chnl_clean, init_dprsr_credit, init_ebuf_credit always handled by the
     * driver?
     */
    for (int i = 0; i < 9; i++) {
        reg_fqname = "pardereg.pgstnreg.epbprsr4reg["
            + std::to_string(i) + "].epbreg.chan0_group.chnl_ctrl.meta_opt";
        reg_name = "epb" + std::to_string(i) + "parser0_chnl_ctrl_0";
        reg_value = meta_opt;
        reg_value_str = int_to_hex_string(meta_opt, reg_width);
        add_cfg_reg(cfg_cache, reg_fqname, reg_name, reg_value_str);
    }
}
