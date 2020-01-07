/* parser template specializations for cloudbreak -- #included directly in top-level parser.cpp */

template <> void Parser::Checksum::write_config(Target::Cloudbreak::parser_regs &regs, Parser *parser) {
         if (unit == 0) write_row_config(regs.memory[gress].po_csum_ctrl_0_row[addr]);
    else if (unit == 1) write_row_config(regs.memory[gress].po_csum_ctrl_1_row[addr]);
    else if (unit == 2) write_row_config(regs.memory[gress].po_csum_ctrl_2_row[addr]);
    else if (unit == 3) write_row_config(regs.memory[gress].po_csum_ctrl_3_row[addr]);
    else if (unit == 4) write_row_config(regs.memory[gress].po_csum_ctrl_4_row[addr]);
    else error(lineno, "invalid unit for parser checksum");
}

struct cloudbreak_row_output_state {
    gress_t     gress;
    int         row;
    Target::Cloudbreak::parser_regs::_memory::_po_action_row    *regs;
    struct slot {
        int phv_dst;
        int phv_offset_add_dst;
        int phv_src;
    };
    std::vector<slot>   extracts[4];  // indexed by mask;
};

template <>
void Parser::Checksum::write_output_config(Target::Cloudbreak::parser_regs &regs, Parser *pa,
    void *_row, unsigned &used) const {
    if (type != 0 || !dest) return;

    cloudbreak_row_output_state *row = (cloudbreak_row_output_state *)_row;

    // checksum verification outputs "steal" extractors, see parser uArch (6.3.6)
    if ((++used & 0xfff) > 20)
        error(lineno, "Ran out of phv output extractor slots");
    else
        row->extracts[3].push_back({ dest->reg.parser_id(), 0, 0 });
}

template <> void Parser::CounterInit::write_config(Target::Cloudbreak::parser_regs &regs,
                                                   gress_t gress, int idx) {
    auto &ctr_init_ram = regs.memory[gress].ml_ctr_init_ram[idx];
    ctr_init_ram.add = add;
    ctr_init_ram.mask_8 = mask;
    ctr_init_ram.rotate = rot;
    ctr_init_ram.max = max;
    ctr_init_ram.src = src;
}

template<> void Parser::State::Match::write_lookup_config(Target::Cloudbreak::parser_regs &regs,
                                                          State *state, int r) const {
    auto &row = regs.memory[state->gress].ml_tcam_row[r];
    match_t lookup = { 0, 0 };
    unsigned dont_care = 0;
    for (int i = 0; i < 4; i++) {
        lookup.word0 <<= 8;
        lookup.word1 <<= 8;
        dont_care <<= 8;
        if (state->key.data[i].bit >= 0) {
            lookup.word0 |= ((match.word0 >> state->key.data[i].bit) & 0xff);
            lookup.word1 |= ((match.word1 >> state->key.data[i].bit) & 0xff);
        } else {
            dont_care |= 0xff; } }
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
/* FIXME -- factor Tofino/JBay/Cloudbreak variation better (most is common) */
template <> int Parser::State::write_lookup_config(Target::Cloudbreak::parser_regs &regs,
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

template <> int Parser::State::Match::write_load_config(Target::Cloudbreak::parser_regs &regs,
            Parser *pa, State *state, int row) const {
    auto &ea_row = regs.memory[state->gress].ml_ea_row[row];
    int max_off = -1;
    for (int i = 0; i < 4; i++) {
        if (load.data[i].bit < 0) continue;
        if (load.data[i].byte != MatchKey::USE_SAVED) {
            int off = load.data[i].byte;
            if (off < 0 || off >= 32) {
                error(load.lineno, "Save offset of %d in state %s out of range",
                      load.data[i].byte, state->name.c_str()); }
            ea_row.lookup_offset_8[i] = off;
            ea_row.ld_lookup_8[i] = 1;
            max_off = std::max(max_off, off);
        }
        ea_row.sv_lookup_8[i] = (1 << i) && load.save;
    }

    for (int i = 0; i < 4; i++) {
        if (load.save && (1 << i))
            ea_row.lookup_offset_8[i] = 60 + i;
    }
    return max_off;
}

static void write_output_slot(int lineno, cloudbreak_row_output_state *row,
                              unsigned &used, int src, int dest, int bytemask, bool offset) {
    BUG_CHECK(bytemask > 0 && bytemask < 4);
    if ((++used & 0xfff) > 20)
        error(lineno, "Ran out of phv output slots");
    else
        row->extracts[bytemask].push_back({ dest, offset, src });
}

template <> int Parser::State::Match::Save::write_output_config(Target::Cloudbreak::parser_regs &regs,
            void *_row, unsigned &used) const {
    cloudbreak_row_output_state *row = (cloudbreak_row_output_state *)_row;
    int dest = where->reg.parser_id();
    int mask = (1 << (1 + where->hi/8U)) - (1 << (where->lo/8U));
    int lo = this->lo;
    if (where->reg.size == 8 && mask == 1) {
        if (where->reg.index & 1) {
            mask <<= 1;
            --lo; } }
    if (flags & ROTATE) error(where.lineno, "no rotate support in Tofino2");

    int bytemask = (mask >> 2) & 3;
    if (bytemask) {
        write_output_slot(where.lineno, row, used, lo + (bytemask == 2), dest+1, bytemask, flags & OFFSET);
        lo += bitcount(mask & 0xc); }

    bytemask = mask & 3;
    if (bytemask)
        write_output_slot(where.lineno, row, used, lo + (bytemask == 2), dest, bytemask, flags & OFFSET);
    return hi;
}

static void write_output_const_slot(
        int lineno, cloudbreak_row_output_state *row, unsigned &used,
        unsigned src, int dest, int bytemask, int flags) {
    // use bits 24..27 of 'used' to track the two constant slots
    BUG_CHECK(bytemask > 0 && bytemask < 4);
    BUG_CHECK((src & ~((0xffff00ff >> (8*(bytemask-1))) & 0xffff)) == 0);
    // FIXME -- should be able to treat this as 4x8-bit rather than 2x16-bit slots, as long
    // as the ROTATE flag is consistent for each half.
    int cslot = 0;
    for (; cslot < 2; cslot++)
        if (0 == (used & (bytemask << (2*cslot + 24)))) break;
    if (cslot >= 2) {
        error(lineno, "Ran out of constant output slots");
        return; }
    row->regs->val_const[cslot] |= src;
    if (flags & 2 /*ROTATE*/)
        row->regs->val_const_rot[cslot] = 1;
    used |= bytemask << (2*cslot + 24);
    write_output_slot(lineno, row, used, 62 - 2*cslot + (bytemask == 1), dest, bytemask, flags);
}

template <> void Parser::State::Match::Set::write_output_config(Target::Cloudbreak::parser_regs &regs,
            void *_row, unsigned &used) const
{
    cloudbreak_row_output_state *row = (cloudbreak_row_output_state *)_row;

    int dest = where->reg.parser_id();
    int mask = (1 << (1 + where->hi/8U)) - (1 << (where->lo/8U));
    unsigned what = this->what << where->lo;
    if (what) {
        for (unsigned i = 0; i < 4; ++i)
            if (((what >> (8*i)) & 0xff) == 0)
                mask &= ~(1 << i); }
    if (where->reg.size == 8) {
        BUG_CHECK((mask & ~1) == 0);
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
            row->regs->val_const_32b_bond = 1; }
}

/* Tofino3 has a simple uniform array of 20 extractors, but they are not individually
 * configurable as to what type of extraction they do.  Instead, we can only configure
 * how many extractors do each type of extraction; the first extractors will do an
 * 16-bit write, the next group do 8-bit-hi, and following do 8-bit-lo, with any left
 * over extractor doing nothing.  So instead of actually configuring the registers in
 * the write_output_config routines, we just save the config into the output_map,
 * sorting by type, and then in `mark_usused_output_map` we copy them into the
 * actual register config.  In this mode the `used` mask still tracks the 4 constant
 * bytes (as in jbay) in bits [23:20], but the lower bits are just used to track how
 * many extractors have been used, not which specific extractors.
 */
template <> void *Parser::setup_phv_output_map(Target::Cloudbreak::parser_regs &regs,
            gress_t gress, int row) {
    static cloudbreak_row_output_state      output_state;
    output_state.gress = gress;
    output_state.row = row;
    output_state.regs = &regs.memory[gress].po_action_row[row];
    for (auto &set : output_state.extracts) set.clear();
    return &output_state;
}

template <> void Parser::mark_unused_output_map(Target::Cloudbreak::parser_regs &regs,
            void *_row, unsigned) {
    cloudbreak_row_output_state *row = (cloudbreak_row_output_state *)_row;

    ubits<5> *counts[4] = { 0,
            &row->regs->phv_ext_cnt_8_lo,
            &row->regs->phv_ext_cnt_8_hi,
            &row->regs->phv_ext_cnt_16 };
    BUG_CHECK(row->extracts[0].empty());
    int idx = 0;
    for (int i = 3; i > 0; --i) {
        for (auto &sl : row->extracts[i]) {
            row->regs->phv_dst[idx] = sl.phv_dst;
            row->regs->phv_offset_add_dst[idx] = sl.phv_offset_add_dst;
            row->regs->phv_src[idx] = sl.phv_src;
            ++idx; }
        *counts[i] = row->extracts[i].size(); }
}

template<> void Parser::State::Match::HdrLenIncStop::write_config(
        Cloudbreak::memories_parser_::_po_action_row &po_row) const {
    // FIXME -- how to implement the amount on cloudbreak?  It doesn't really support it.
    po_row.hdr_len_inc_stop = 1;
}

template<> void Parser::State::Match::Clot::write_config(
        Cloudbreak::memories_parser_::_po_action_row &po_row, int idx) const {
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
    po_row.clot_has_csum[idx] = csum_unit > 0;
}

template<> void Parser::State::Match::write_counter_config(
    Target::Cloudbreak::parser_regs::_memory::_ml_ea_row &ea_row) const {

    if (ctr_load) {
        switch (ctr_ld_src) {
            case 0: ea_row.ctr_op = 2; break;
            case 1: ea_row.ctr_op = 3; break;
            default: error(lineno, "Unsupported parser counter load instruction (Cloudbreak)");
        } 
    } else {  // add
        ea_row.ctr_op = 0;
    }

    ea_row.ctr_amt_idx = ctr_instr ? ctr_instr->addr : ctr_imm_amt;

    // TODO -- counter stack config
    // ea_row.ctr_op = 1; (load ctr from stack top and add imm)
    // ea_row.ctr_stack_push = ?
    // ea_row.ctr_stack_upd_w_top = ?
}

template<> void Parser::State::Match::write_row_config(Target::Cloudbreak::parser_regs  &regs,
        Parser *pa, State *state, int row, Match *def, json::map &ctxt_json) {
    write_common_row_config(regs, pa, state, row, def, ctxt_json);
    auto &action_row = regs.memory[state->gress].po_action_row[row];
    // FIXME -- CB Parser uArch doc recommends only doing this in the last state for a
    // specific header, though its not clear why
    if (shift || (def && def->shift))
        action_row.hdr_len_inc = 1;
}

template<> void Parser::write_config(Target::Cloudbreak::parser_regs &regs, json::map &ctxt_json, bool single_parser) {
    if (single_parser) {
        for (auto st : all)
            st->write_config(regs, this, ctxt_json[st->gress == EGRESS ? "egress" : "ingress"]);
    } else {
        ctxt_json["states"] = json::vector();
        for (auto st : all)
            st->write_config(regs, this, ctxt_json["states"]);
    }
    if (error_count > 0) return;

    int i = 0;
    for (auto ctr : counter_init) {
        if (ctr) ctr->write_config(regs, gress, i);
        ++i; }

    for (i = 0; i < checksum_use.size(); i++) {
        for (auto csum : checksum_use[i])
            if (csum) csum->write_config(regs, this); }

    if (gress == EGRESS) {
        regs.egress.epbreg.chan0_group.chnl_ctrl.meta_opt = meta_opt;
        regs.egress.epbreg.chan1_group.chnl_ctrl.meta_opt = meta_opt;
        regs.egress.epbreg.chan2_group.chnl_ctrl.meta_opt = meta_opt;
        regs.egress.epbreg.chan3_group.chnl_ctrl.meta_opt = meta_opt;
        regs.egress.epbreg.chan4_group.chnl_ctrl.meta_opt = meta_opt;
        regs.egress.epbreg.chan5_group.chnl_ctrl.meta_opt = meta_opt;
        regs.egress.epbreg.chan6_group.chnl_ctrl.meta_opt = meta_opt;
        regs.egress.epbreg.chan7_group.chnl_ctrl.meta_opt = meta_opt;

    }

    setup_jbay_ownership(phv_use,
                         regs.merge.ul.phv_owner_127_0.owner,
                         regs.merge.ur.phv_owner_255_128.owner,
                         regs.main[INGRESS].phv_owner.owner,
                         regs.main[EGRESS].phv_owner.owner);

    setup_jbay_clear_on_write(phv_allow_clear_on_write,
                              regs.merge.ul.phv_clr_on_wr_127_0.clr,
                              regs.merge.ur.phv_clr_on_wr_255_128.clr,
                              regs.main[INGRESS].phv_clr_on_wr.clr,
                              regs.main[EGRESS].phv_clr_on_wr.clr);

    setup_jbay_no_multi_write(phv_allow_bitwise_or,
                              phv_allow_clear_on_write,
                              regs.main[INGRESS].no_multi_wr.nmw,
                              regs.main[EGRESS].no_multi_wr.nmw);

    regs.main[gress].hdr_len_adj.amt = hdr_len_adj;

    if (parser_error.lineno >= 0) {
        for (auto i : {0, 1}) {
            regs.main[gress].err_phv_cfg[i].en = 1;
            regs.main[gress].err_phv_cfg[i].dst = parser_error->reg.parser_id();
            regs.main[gress].err_phv_cfg[i].no_tcam_match_err_en = 1;
            regs.main[gress].err_phv_cfg[i].partial_hdr_err_en = 1;
            regs.main[gress].err_phv_cfg[i].ctr_range_err_en = 1;
            regs.main[gress].err_phv_cfg[i].timeout_iter_err_en = 1;
            regs.main[gress].err_phv_cfg[i].timeout_cycle_err_en = 1;
            regs.main[gress].err_phv_cfg[i].src_ext_err_en = 1;
            regs.main[gress].err_phv_cfg[i].phv_owner_err_en = 1;
            regs.main[gress].err_phv_cfg[i].multi_wr_err_en = 1;
            regs.main[gress].err_phv_cfg[i].aram_mbe_en = 1;
            regs.main[gress].err_phv_cfg[i].fcs_err_en = 1;
            regs.main[gress].err_phv_cfg[i].csum_mbe_en = 1;
        }
    } else {
        // en has a reset value of 1 and that is why we have to explicitly disable it
        // otherwise dst will assume default value of 0
        for (auto i : {0, 1})
            regs.main[gress].err_phv_cfg[i].en = 0;
    }

    int i_start = Stage::first_table(INGRESS) & 0x1ff;
    for (auto &reg : regs.merge.ll1.i_start_table)
        reg.table = i_start;

    int e_start = Stage::first_table(EGRESS) & 0x1ff;
    for (auto &reg : regs.merge.lr1.e_start_table)
        reg.table = e_start;

    regs.merge.lr1.g_start_table.table = Stage::first_table(GHOST) & 0x1ff;
    if (ghost_parser) {
        // FIXME -- regs have changed
        // regs.merge.lr1.tm_status_phv.phv = ghost_parser->reg.parser_id();
        regs.merge.lr1.tm_status_phv.en = 1; }

    if (gress == INGRESS) {
        for (auto &ref : regs.ingress.prsr)
            ref.set("regs.parser.main.ingress", &regs.main[INGRESS]);
    }
    if (gress == EGRESS) {
        for (auto &ref : regs.egress.prsr)
            ref.set("regs.parser.main.egress", &regs.main[EGRESS]);
    }
    if (error_count == 0) {
        if (options.condense_json) {
            // FIXME -- removing the uninitialized memory causes problems?
            // FIXME -- walle gets the addresses wrong.  Might also require explicit
            // FIXME -- zeroing in the driver on real hardware
            // regs.memory[INGRESS].disable_if_reset_value();
            // regs.memory[EGRESS].disable_if_reset_value();
            // regs.ingress.disable_if_reset_value();
            // regs.egress.disable_if_reset_value();
            regs.main[INGRESS].disable_if_reset_value();
            regs.main[EGRESS].disable_if_reset_value();
            regs.merge.disable_if_reset_value(); }
        if (options.gen_json) {
            if (single_parser) {
                regs.memory[INGRESS].emit_json(*open_output("memories.parser.ingress.cfg.json"),
                                               "ingress");
                regs.memory[EGRESS].emit_json(*open_output("memories.parser.egress.cfg.json"),
                                              "egress");
                regs.ingress.emit_json(*open_output("regs.parser.ingress.cfg.json"));
                regs.egress.emit_json(*open_output("regs.parser.egress.cfg.json"));
                regs.main[INGRESS].emit_json(*open_output("regs.parser.main.ingress.cfg.json"),
                                             "ingress");
                regs.main[EGRESS].emit_json(*open_output("regs.parser.main.egress.cfg.json"),
                                            "egress");
                regs.merge.emit_json(*open_output("regs.parse_merge.cfg.json"));
            } else {
                regs.memory[INGRESS].emit_json(*open_output("memories.parser.ingress.%02x.cfg.json", parser_no),
                                               "ingress");
                regs.memory[EGRESS].emit_json(*open_output("memories.parser.egress.%02x.cfg.json", parser_no),
                                              "egress");
                regs.ingress.emit_json(*open_output("regs.parser.ingress.%02x.cfg.json", parser_no));
                regs.egress.emit_json(*open_output("regs.parser.egress.%02x.cfg.json", parser_no));
                regs.main[INGRESS].emit_json(*open_output("regs.parser.main.ingress.cfg.json"),
                                             "ingress");
                regs.main[EGRESS].emit_json(*open_output("regs.parser.main.egress.cfg.json"),
                                            "egress");
                regs.merge.emit_json(*open_output("regs.parse_merge.cfg.json")); } } }

    /* multiple Cloudbreak parser mem blocks can respond to same address range to allow programming
     * the device with a single write operation. See: pardereg.pgstnreg.ibprsr4reg.prsr.mem_ctrl */
    if (gress == INGRESS) {
        for (unsigned i = 0; i < TopLevel::regs<Target::Cloudbreak>()->mem_pipe.parde.i_prsr_mem.size();
             options.singlewrite ? i += 4 : i += 1) {
            TopLevel::regs<Target::Cloudbreak>()->mem_pipe.parde.i_prsr_mem[i].set("memories.parser.ingress",
                                                                             &regs.memory[INGRESS]);
        }
    }

    if (gress == EGRESS) {
        for (unsigned i = 0; i < TopLevel::regs<Target::Cloudbreak>()->mem_pipe.parde.e_prsr_mem.size();
             options.singlewrite ? i += 4 : i += 1) {
            TopLevel::regs<Target::Cloudbreak>()->mem_pipe.parde.e_prsr_mem[i].set("memories.parser.egress",
                                                                             &regs.memory[EGRESS]);
        }
    }

    if (gress == INGRESS) {
        for (auto &ref : TopLevel::regs<Target::Cloudbreak>()->reg_pipe.pardereg.pgstnreg.ipbprsr4reg)
            ref.set("regs.parser.ingress", &regs.ingress);
    }

    if (gress == EGRESS) {
        for (auto &ref : TopLevel::regs<Target::Cloudbreak>()->reg_pipe.pardereg.pgstnreg.epbprsr4reg)
            ref.set("regs.parser.egress", &regs.egress);
    }
    TopLevel::regs<Target::Cloudbreak>()->reg_pipe.pardereg.pgstnreg.pmergereg
        .set("regs.parse_merge", &regs.merge);
    for (auto st : all)
        TopLevel::all->name_lookup["directions"][st->gress ? "1" : "0"]
                ["parser_states"][std::to_string(st->stateno.word1)] = st->name;
}

template<>
void Parser::gen_configuration_cache(Target::Cloudbreak::parser_regs &regs, json::vector &cfg_cache) {
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
