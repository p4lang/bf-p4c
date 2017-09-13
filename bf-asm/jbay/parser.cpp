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
        row.w0_lookup_8[1] = lookup.word0 & 0xff;
        row.w1_lookup_8[1] = lookup.word1 & 0xff;
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

template <> int Parser::State::Match::Save::write_output_config(Target::JBay::parser_regs &regs,
            void *_row, unsigned &used) const {
    Target::JBay::parser_regs::_memory::_po_action_row *row =
        (Target::JBay::parser_regs::_memory::_po_action_row *)_row;
    unsigned mask = 1, inc = 1;
    if (hi-lo == 3) {
        mask = 3;
        inc = 2; }
    for (int i = 0; i < 20; i += inc) {
        if (used & (mask << i)) continue;
        row->phv_dst[i] = where->reg.index;
        row->phv_src[i] = lo;
        if (flags & OFFSET) row->phv_offset_add_dst[i] = 1;
        if (flags & ROTATE) error(where.lineno, "no rotate support in jbay");
        if (hi == lo) {
            row->extract_type[i] = 1;
        } else if (hi-lo == 3) {
            row->extract_type[i] = 3;
            row->phv_dst[i+1] = where->reg.index;
            row->phv_src[i+1] = lo+2;
            row->extract_type[i+1] = 3;
            if (flags & OFFSET) row->phv_offset_add_dst[i+1] = 1;
        } else {
            row->extract_type[i] = 3; }
        used |= mask << i;
        return hi; }
    error(where.lineno, "Ran out of phv output slots");
    return -1;
}

template <> void Parser::State::Match::Set::write_output_config(Target::JBay::parser_regs &regs,
            void *_row, unsigned &used) const
{
    error(where.lineno, "no constant output support in jbay");
}

template <> void *Parser::setup_phv_output_map(Target::JBay::parser_regs &regs,
            gress_t gress, int row) {
    return &regs.memory[gress].po_action_row[row];
}
template <> void Parser::mark_unused_output_map(Target::JBay::parser_regs &regs,
            void *_row, unsigned used) {
    Target::JBay::parser_regs::_memory::_po_action_row *row =
        (Target::JBay::parser_regs::_memory::_po_action_row *)_row;
    for (int i = 0; i < 20; ++i)
        if (!(used & (1U << i)))
            row->phv_dst[i] = 0xff;
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
}

template<> 
void Parser::gen_configuration_cache(Target::JBay::parser_regs &regs, json::vector &cfg_cache) {
}

