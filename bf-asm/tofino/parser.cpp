/* parser template specializations for tofino -- #included directly in top-level parser.cpp */

#include "misc.h"

template <> void Parser::Checksum::write_config(Target::Tofino::parser_regs &regs, Parser *parser) {
         if (unit == 0) write_row_config(regs.memory[gress].po_csum_ctrl_0_row[addr]);
    else if (unit == 1) write_row_config(regs.memory[gress].po_csum_ctrl_1_row[addr]);
    else error(lineno, "invalid unit for parser checksum");
}

template <> void Parser::CounterInit::write_config(Target::Tofino::parser_regs &regs,
                                                   gress_t gress, int idx) {
    auto &ctr_init_ram = regs.memory[gress].ml_ctr_init_ram[idx];
    ctr_init_ram.add = add;
    ctr_init_ram.mask = mask;
    ctr_init_ram.rotate = rot;
    ctr_init_ram.max = max;
    ctr_init_ram.src = src;
}

template<> void Parser::State::Match::write_lookup_config(Target::Tofino::parser_regs &regs,
                                                          State *state, int row) const {
    auto &word0 = regs.memory[state->gress].ml_tcam_row_word0[row];
    auto &word1 = regs.memory[state->gress].ml_tcam_row_word1[row];
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
    word0.lookup_16 = (lookup.word0 >> 16) & 0xffff;
    word1.lookup_16 = (lookup.word1 >> 16) & 0xffff;
    word0.lookup_8[0] = (lookup.word0 >> 8) & 0xff;
    word1.lookup_8[0] = (lookup.word1 >> 8) & 0xff;
    word0.lookup_8[1] = lookup.word0 & 0xff;
    word1.lookup_8[1] = lookup.word1 & 0xff;
    word0.curr_state = state->stateno.word0;
    word1.curr_state = state->stateno.word1;
    if (state->key.ctr_zero >= 0) {
        word0.ctr_zero = (match.word0 >> state->key.ctr_zero) & 1;
        word1.ctr_zero = (match.word1 >> state->key.ctr_zero) & 1;
    } else
        word0.ctr_zero = word1.ctr_zero = 1;
    if (state->key.ctr_neg >= 0) {
        word0.ctr_neg = (match.word0 >> state->key.ctr_neg) & 1;
        word1.ctr_neg = (match.word1 >> state->key.ctr_neg) & 1;
    } else
        word0.ctr_neg = word1.ctr_neg = 1;
    word0.ver_0 = word1.ver_0 = 1;
    word0.ver_1 = word1.ver_1 = 1;
}

/* FIXME -- combine these next two methods into a single method on MatchKey */
/* FIXME -- factor Tofino/JBay variation better (most is common) */
template <> int Parser::State::write_lookup_config(Target::Tofino::parser_regs &regs,
            Parser *pa, State *state, int row, const std::vector<State *> &prev) {
    LOG2("-- checking match from state " << name << " (" << stateno << ')');
    auto &ea_row = regs.memory[gress].ml_ea_row[row];
    int max_off = -1;
    for (int i = 0; i < 4; i++) {
        if (i == 1) continue;
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
                      state->name.c_str());
            } else if (i) {
                ea_row.lookup_offset_8[(i-2)] = off;
                ea_row.ld_lookup_8[(i-2)] = 1;
                max_off = std::max(max_off, off);
            } else {
                ea_row.lookup_offset_16 = off;
                ea_row.ld_lookup_16 = 1;
                max_off = std::max(max_off, off+1); } } }
    return max_off;
}

template <> int Parser::State::Match::write_future_config(Target::Tofino::parser_regs &regs,
            Parser *pa, State *state, int row) const {
    auto &ea_row = regs.memory[state->gress].ml_ea_row[row];
    int max_off = -1;
    for (int i = 0; i < 4; i++) {
        if (i == 1) continue;
        if (future.data[i].bit < 0) continue;
        if (future.data[i].byte != MatchKey::USE_SAVED) {
            int off = future.data[i].byte;
            if (off < 0 || off >= 32) {
                error(future.lineno, "Save offset of %d in state %s out of range",
                      future.data[i].byte, state->name.c_str());
            } else if (i) {
                ea_row.lookup_offset_8[(i-2)] = off;
                ea_row.ld_lookup_8[(i-2)] = 1;
                max_off = std::max(max_off, off);
            } else {
                ea_row.lookup_offset_16 = off;
                ea_row.ld_lookup_16 = 1;
                max_off = std::max(max_off, off+1); } } }
    return max_off;
}

/* remapping structure for getting at the config bits for phv output
 * programming in a systematic way */
struct tofino_phv_output_map {
    int         size;   /* 8, 16, or 32 */
    ubits<9>    *dst;
    ubits_base  *src;   /* 6 or 8 bits */
    ubits<1>    *src_type, *offset_add, *offset_rot;
};

enum {
    /* enum for indexes in the tofino_phv_output_map */
    phv_32b_0, phv_32b_1, phv_32b_2, phv_32b_3,
    phv_16b_0, phv_16b_1, phv_16b_2, phv_16b_3,
    phv_8b_0, phv_8b_1, phv_8b_2, phv_8b_3,
    tofino_phv_output_map_size,
};

static struct phv_use_slots { int idx; unsigned usemask, shift, size; }
phv_32b_slots[] = {
    { phv_32b_0, 1U << phv_32b_0, 0, 32 },
    { phv_32b_1, 1U << phv_32b_1, 0, 32 },
    { phv_32b_2, 1U << phv_32b_2, 0, 32 },
    { phv_32b_3, 1U << phv_32b_3, 0, 32 },
    { phv_16b_0, 3U << phv_16b_0, 16, 16 },
    { phv_16b_2, 3U << phv_16b_2, 16, 16 },
    { phv_8b_0, 0xfU << phv_8b_0, 24, 8 },
    { 0, 0 }
},
phv_16b_slots[] = {
    { phv_16b_0, 1U << phv_16b_0, 0, 16 },
    { phv_16b_1, 1U << phv_16b_1, 0, 16 },
    { phv_16b_2, 1U << phv_16b_2, 0, 16 },
    { phv_16b_3, 1U << phv_16b_3, 0, 16 },
    { phv_8b_0, 3U << phv_8b_0, 8, 8 },
    { phv_8b_2, 3U << phv_8b_2, 8, 8 },
    { 0, 0 }
},
phv_8b_slots[] = {
    { phv_8b_0, 1U << phv_8b_0, 0, 8 },
    { phv_8b_1, 1U << phv_8b_1, 0, 8 },
    { phv_8b_2, 1U << phv_8b_2, 0, 8 },
    { phv_8b_3, 1U << phv_8b_3, 0, 8 },
    { 0, 0 }
};

template <>
void Parser::Checksum::write_output_config(Target::Tofino::parser_regs &regs, void *_map, unsigned &used) const
{   
    if (type != 0) return;

    // checksum verification requires the last extractor to be a dummy (to work around a RTL bug)
    // see MODEL-210 for discussion.

    tofino_phv_output_map *map = (tofino_phv_output_map *)_map;
    phv_use_slots *usable_slots;

         if (dest->reg.size == 8)  usable_slots = phv_8b_slots;
    else if (dest->reg.size == 16) usable_slots = phv_16b_slots;
    else if (dest->reg.size == 32) usable_slots = phv_32b_slots;

    auto &slot = usable_slots[3];
    *map[slot.idx].dst = dest->reg.parser_id();
    used |= slot.usemask;
}

template <>
int Parser::State::Match::Save::write_output_config(Target::Tofino::parser_regs &regs, void *_map, unsigned &used) const
{
    tofino_phv_output_map *map = (tofino_phv_output_map *)_map;
    phv_use_slots *usable_slots;
    if (hi-lo == 3) {
        usable_slots = phv_32b_slots;
    } else if (hi-lo == 1) {
        usable_slots = phv_16b_slots;
    } else {
        assert(hi == lo);
        usable_slots = phv_8b_slots; }
    for (int i = 0; usable_slots[i].usemask; i++) {
        auto &slot = usable_slots[i];
        if (used & slot.usemask) continue;
        if ((flags & ROTATE) && !map[slot.idx].offset_rot)
            continue;
        int byte = lo;
        for (int i = slot.idx; slot.usemask & (1U << i); i++, byte += slot.size/8U) {
            *map[i].dst = where->reg.parser_id();
            *map[i].src = byte;
            if (flags & OFFSET) *map[i].offset_add = 1;
            if (flags & ROTATE) *map[i].offset_rot = 1; }
        used |= slot.usemask;
        return hi; }
    error(where.lineno, "Ran out of phv output slots");
    return -1;
}

static int encode_constant_for_slot(int slot, unsigned val) {
    if (val == 0) return val;
    switch(slot) {
    case phv_32b_0: case phv_32b_1: case phv_32b_2: case phv_32b_3:
        for (int i = 0; i < 32; i++) {
            if ((val & 1) && (0x7 & val) == val)
                return (i << 3) | val;
            val = ((val >> 1) | (val << 31)) & 0xffffffffU; }
        return -1;
    case phv_16b_0: case phv_16b_1: case phv_16b_2: case phv_16b_3:
        if ((val >> 16) && encode_constant_for_slot(slot, val >> 16) < 0)
            return -1;
        val &= 0xffff;
        for (int i = 0; i < 16; i++) {
            if ((val & 1) && (0xf & val) == val)
                return (i << 4) | val;
            val = ((val >> 1) | (val << 15)) & 0xffffU; }
        return -1;
    case phv_8b_0: case phv_8b_1: case phv_8b_2: case phv_8b_3:
        return val & 0xff;
    default:
        assert(0);
        return -1; }
}

template <>
void Parser::State::Match::Set::write_output_config(Target::Tofino::parser_regs &regs, void *_map, unsigned &used) const
{
    tofino_phv_output_map *map = (tofino_phv_output_map *)_map;
    phv_use_slots *usable_slots;
    if (where->reg.size == 32)
        usable_slots = phv_32b_slots;
    else if (where->reg.size == 16)
        usable_slots = phv_16b_slots;
    else if (where->reg.size == 8)
        usable_slots = phv_8b_slots;
    else
        assert(0);
    for (int i = 0; usable_slots[i].usemask; i++) {
        auto &slot = usable_slots[i];
        if (used & slot.usemask) continue;
        if (!map[slot.idx].src_type) continue;
        if ((flags & ROTATE) && (!map[slot.idx].offset_rot || slot.shift))
            continue;
        if (encode_constant_for_slot(slot.idx, what << where->lo) < 0)
            continue;
        unsigned shift = slot.shift;
        for (int i = slot.idx; slot.usemask & (1U << i); i++) {
            *map[i].dst = where->reg.parser_id();
            *map[i].src_type = 1;
            *map[i].src = encode_constant_for_slot(i, (what << where->lo) >> shift);
            if (flags & OFFSET) *map[i].offset_add = 1;
            if (flags & ROTATE) *map[i].offset_rot = 1;
            shift -= slot.size; }
        used |= slot.usemask;
        return; }
    error(where.lineno, "Ran out of phv output slots");
}

#define OUTPUT_MAP_INIT(MAP, ROW, SIZE, INDEX) \
    MAP[phv_##SIZE##b_##INDEX].size = SIZE;                                             \
    MAP[phv_##SIZE##b_##INDEX].dst = &ROW.phv_##SIZE##b_dst_##INDEX;                    \
    MAP[phv_##SIZE##b_##INDEX].src = &ROW.phv_##SIZE##b_src_##INDEX;                    \
    MAP[phv_##SIZE##b_##INDEX].src_type = &ROW.phv_##SIZE##b_src_type_##INDEX;          \
    MAP[phv_##SIZE##b_##INDEX].offset_add = &ROW.phv_##SIZE##b_offset_add_dst_##INDEX;  \
    MAP[phv_##SIZE##b_##INDEX].offset_rot = &ROW.phv_##SIZE##b_offset_rot_imm_##INDEX;
#define OUTPUT_MAP_INIT_PART(MAP, ROW, SIZE, INDEX) \
    MAP[phv_##SIZE##b_##INDEX].size = SIZE;                                             \
    MAP[phv_##SIZE##b_##INDEX].dst = &ROW.phv_##SIZE##b_dst_##INDEX;                    \
    MAP[phv_##SIZE##b_##INDEX].src = &ROW.phv_##SIZE##b_src_##INDEX;                    \
    MAP[phv_##SIZE##b_##INDEX].src_type = 0;                                            \
    MAP[phv_##SIZE##b_##INDEX].offset_add = &ROW.phv_##SIZE##b_offset_add_dst_##INDEX;  \
    MAP[phv_##SIZE##b_##INDEX].offset_rot = 0;

template <> void *Parser::setup_phv_output_map(Target::Tofino::parser_regs &regs,
            gress_t gress, int row) {
    static tofino_phv_output_map map[tofino_phv_output_map_size];
    auto &action_row = regs.memory[gress].po_action_row[row];
    OUTPUT_MAP_INIT(map, action_row, 32, 0)
    OUTPUT_MAP_INIT(map, action_row, 32, 1)
    OUTPUT_MAP_INIT_PART(map, action_row, 32, 2)
    OUTPUT_MAP_INIT_PART(map, action_row, 32, 3)
    OUTPUT_MAP_INIT(map, action_row, 16, 0)
    OUTPUT_MAP_INIT(map, action_row, 16, 1)
    OUTPUT_MAP_INIT_PART(map, action_row, 16, 2)
    OUTPUT_MAP_INIT_PART(map, action_row, 16, 3)
    OUTPUT_MAP_INIT(map, action_row, 8, 0)
    OUTPUT_MAP_INIT(map, action_row, 8, 1)
    OUTPUT_MAP_INIT(map, action_row, 8, 2)
    OUTPUT_MAP_INIT(map, action_row, 8, 3)
    return map;
}

template <> void Parser::mark_unused_output_map(Target::Tofino::parser_regs &regs,
            void *_map, unsigned used) {
    tofino_phv_output_map *map = (tofino_phv_output_map *)_map;
    for (int i = 0; i < tofino_phv_output_map_size; i++)
        if (!(used & (1U << i)))
            *map[i].dst = 0x1ff;
}

template<> void Parser::State::Match::Clot::write_config(
        Tofino::memories_all_parser_::_po_action_row &, int) const {
    assert(0);  // no CLOTs on tofino; should not get here
}

template<> void Parser::State::Match::write_counter_config(
    Target::Tofino::parser_regs::_memory::_ml_ea_row &ea_row) const {
    ea_row.ctr_amt_idx = counter;
    ea_row.ctr_ld_src = counter_load;
    ea_row.ctr_load = counter_reset;
}

template <class COMMON> void init_common_regs(Parser *p, COMMON &regs, gress_t gress) {
    // TODO: fixed config copied from compiler -- needs to be controllable
    for (int i = 0; i < 4; i++) {
        if (p->start_state[gress][i]) {
            regs.start_state.state[i] = p->start_state[gress][i]->stateno.word1;
            regs.enable_.enable_[i] = 1; }
        regs.pri_start.pri[i] = p->priority[gress][i];
        regs.pri_thresh.pri[i] = p->pri_thresh[gress][i]; }
    regs.mode = 4;
    regs.max_iter.max = 128;
    if (p->parser_error[gress].lineno >= 0) {
        regs.err_phv_cfg.dst = p->parser_error[gress]->reg.parser_id();
        regs.err_phv_cfg.aram_mbe_en = 1;
        regs.err_phv_cfg.ctr_range_err_en = 1;
        regs.err_phv_cfg.dst_cont_err_en = 1;
        regs.err_phv_cfg.fcs_err_en = 1;
        regs.err_phv_cfg.multi_wr_err_en = 1;
        regs.err_phv_cfg.no_tcam_match_err_en = 1;
        regs.err_phv_cfg.partial_hdr_err_en = 1;
        regs.err_phv_cfg.phv_owner_err_en = 1;
        regs.err_phv_cfg.src_ext_err_en = 1;
        regs.err_phv_cfg.timeout_cycle_err_en = 1;
        regs.err_phv_cfg.timeout_iter_err_en = 1; }
}

template<> void Parser::write_config(Target::Tofino::parser_regs &regs, json::map &ctxt_json) {
    for (auto st : all)
        st->write_config(regs, this, ctxt_json[st->gress ? "egress" : "ingress"]);
    if (error_count > 0) return;
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        int i = 0;
        for (auto ctr : counter_init[gress]) {
            if (ctr) ctr->write_config(regs, gress, i);
            ++i; }
        for (auto csum : checksum_use[gress])
            if (csum) csum->write_config(regs, this); }

    init_common_regs(this, regs.ingress.prsr_reg, INGRESS);
    regs.ingress.ing_buf_regs.glb_group.disable();
    regs.ingress.ing_buf_regs.chan0_group.chnl_drop.disable();
    regs.ingress.ing_buf_regs.chan0_group.chnl_metadata_fix.disable();
    regs.ingress.ing_buf_regs.chan1_group.chnl_drop.disable();
    regs.ingress.ing_buf_regs.chan1_group.chnl_metadata_fix.disable();
    regs.ingress.ing_buf_regs.chan2_group.chnl_drop.disable();
    regs.ingress.ing_buf_regs.chan2_group.chnl_metadata_fix.disable();
    regs.ingress.ing_buf_regs.chan3_group.chnl_drop.disable();
    regs.ingress.ing_buf_regs.chan3_group.chnl_metadata_fix.disable();

    init_common_regs(this, regs.egress.prsr_reg, EGRESS);
    for (int i = 0; i < 4; i++)
        regs.egress.epb_prsr_port_regs.chnl_ctrl[i].meta_opt = meta_opt;

    regs.ingress.prsr_reg.hdr_len_adj.amt = hdr_len_adj[INGRESS];
    regs.egress.prsr_reg.hdr_len_adj.amt = hdr_len_adj[EGRESS];

    if (options.match_compiler) {
        phv_use[INGRESS] |= Phv::use(INGRESS);
        phv_use[EGRESS] |= Phv::use(EGRESS); }
    for (int i : phv_use[EGRESS]) {
        auto id = Phv::reg(i)->parser_id();
        if (id >= 256) {
            regs.merge.phv_owner.t_owner[id-256] = 1;
            regs.ingress.prsr_reg.phv_owner.t_owner[id-256] = 1;
            regs.egress.prsr_reg.phv_owner.t_owner[id-256] = 1;
        } else if (id < 224) {
            regs.merge.phv_owner.owner[id] = 1;
            regs.ingress.prsr_reg.phv_owner.owner[id] = 1;
            regs.egress.prsr_reg.phv_owner.owner[id] = 1; } }
    for (int i = 0; i < 224; i++) {
        if (!phv_allow_multi_write[i]) {
            regs.ingress.prsr_reg.no_multi_wr.nmw[i] = 1;
            regs.egress.prsr_reg.no_multi_wr.nmw[i] = 1;
        }
        if (phv_allow_multi_write[i] || phv_init_valid[i])
            regs.merge.phv_valid.vld[i] = 1;
    }

    for (int i = 0; i < 112; i++)
        if (!phv_allow_multi_write[256+i]) {
            regs.ingress.prsr_reg.no_multi_wr.t_nmw[i] = 1;
            regs.egress.prsr_reg.no_multi_wr.t_nmw[i] = 1; }
    if (options.condense_json) {
        // FIXME -- removing the uninitialized memory causes problems?
        // FIXME -- walle gets the addresses wrong.  Might also require explicit
        // FIXME -- zeroing in the driver on real hardware
        // regs.memory[INGRESS].disable_if_zero();
        // regs.memory[EGRESS].disable_if_zero();
        regs.ingress.disable_if_zero();
        regs.egress.disable_if_zero();
        regs.merge.disable_if_zero(); }
    if (error_count == 0 && options.gen_json) {
        regs.memory[INGRESS].emit_json(
            *open_output("memories.all.parser.ingress.cfg.json"), "ingress");
        regs.memory[EGRESS].emit_json(
            *open_output("memories.all.parser.egress.cfg.json"), "egress");
        regs.ingress.emit_json(*open_output("regs.all.parser.ingress.cfg.json"));
        regs.egress.emit_json(*open_output("regs.all.parser.egress.cfg.json"));
        regs.merge.emit_json(*open_output("regs.all.parse_merge.cfg.json")); }
    for (int i = 0; i < 18; i++) {
        TopLevel::regs<Target::Tofino>()->mem_pipe.i_prsr[i]
            .set("memories.all.parser.ingress", &regs.memory[INGRESS]);
        TopLevel::regs<Target::Tofino>()->reg_pipe.pmarb.ibp18_reg.ibp_reg[i]
            .set( "regs.all.parser.ingress", &regs.ingress);
        TopLevel::regs<Target::Tofino>()->mem_pipe.e_prsr[i]
            .set("memories.all.parser.egress", &regs.memory[EGRESS]);
        TopLevel::regs<Target::Tofino>()->reg_pipe.pmarb.ebp18_reg.ebp_reg[i]
            .set("regs.all.parser.egress", &regs.egress); }
    TopLevel::regs<Target::Tofino>()->reg_pipe.pmarb.prsr_reg.set("regs.all.parse_merge", &regs.merge);
    for (auto st : all)
        TopLevel::all->name_lookup["directions"][st->gress ? "1" : "0"]
                ["parser_states"][std::to_string(st->stateno.word1)] = st->name;
}

template<> 
void Parser::gen_configuration_cache(Target::Tofino::parser_regs &regs, json::vector &cfg_cache) {
    std::string reg_fqname;
    std::string reg_name;
    unsigned reg_value;
    std::string reg_value_str;
    unsigned reg_width = 8;

    // epb_prsr_port_regs.chnl_ctrl
    for (int i = 0; i < 4; i++) {
        reg_fqname = "pmarb.ebp18_reg.ebp_reg[0].epb_prsr_port_regs.chnl_ctrl[" 
            + std::to_string(i) + "]"; 
        reg_name = "parser0_chnl_ctrl_" + std::to_string(i);
        reg_value =
               (regs.egress.epb_prsr_port_regs.chnl_ctrl[i].meta_opt        & 0x00001FFF)
            | ((regs.egress.epb_prsr_port_regs.chnl_ctrl[i].chnl_ena        & 0x00000001)  << 16)
            | ((regs.egress.epb_prsr_port_regs.chnl_ctrl[i].afull_thr       & 0x00000007)  << 17)
            | ((regs.egress.epb_prsr_port_regs.chnl_ctrl[i].aemp_thr        & 0x00000007)  << 20)
            | ((regs.egress.epb_prsr_port_regs.chnl_ctrl[i].prsr_stall_full & 0x00000001)  << 23)
            | ((regs.egress.epb_prsr_port_regs.chnl_ctrl[i].timestamp_shift & 0x0000000F)  << 24)
            | ((regs.egress.epb_prsr_port_regs.chnl_ctrl[i].pipeid_ovr      & 0x00000007)  << 28); 
        if ((reg_value != 0) || (options.match_compiler)) {
            reg_value_str = int_to_hex_string(reg_value, reg_width);
            add_cfg_reg(cfg_cache, reg_fqname, reg_name, reg_value_str); } }
     
    // epb_prsr_port_regs.multi_threading
    reg_fqname = "pmarb.ebp18_reg.ebp_reg[0].epb_prsr_port_regs.multi_threading"; 
    reg_name = "parser0_multi_threading";
    reg_value = 
               (regs.egress.epb_prsr_port_regs.multi_threading.prsr_dph_max    & 0x000003FF) 
            | ((regs.egress.epb_prsr_port_regs.multi_threading.stall_thr       & 0x00000007) << 12)
            | ((regs.egress.epb_prsr_port_regs.multi_threading.mult_thrd       & 0x00000001) << 16)
            | ((regs.egress.epb_prsr_port_regs.multi_threading.sngl_thrd       & 0x00000001) << 17)
            | ((regs.egress.epb_prsr_port_regs.multi_threading.mthrd_afull_pkt & 0x0000000F) << 20)
            | ((regs.egress.epb_prsr_port_regs.multi_threading.mthrd_afull_ent & 0x0000003F) << 24);
    if ((reg_value != 0) || (options.match_compiler)) {
        reg_value_str = int_to_hex_string(reg_value, reg_width);
        add_cfg_reg(cfg_cache, reg_fqname, reg_name, reg_value_str); }
}

