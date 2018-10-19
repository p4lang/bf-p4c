/* mau table template specializations for jbay -- #included directly in match_tables.cpp */

/* for jbay counter mode, we may need both a push and a pop mode, as well as counter_function,
 * so we pack them all into an int with some shifts and masks */
enum {
    PUSHPOP_BITS = 5,
    PUSHPOP_MASK = 0xf,
    PUSHPOP_ANY = 0x10,
    PUSH_MASK = PUSHPOP_MASK,
    PUSH_ANY = PUSHPOP_ANY,
    POP_MASK = PUSHPOP_MASK << PUSHPOP_BITS,
    POP_ANY = PUSHPOP_ANY << PUSHPOP_BITS,
    PUSH_MISS = 1,
    PUSH_HIT = 2,
    PUSH_GATEWAY = 3,
    PUSH_ALL = 4,
    PUSH_GW_ENTRY = 5,
    POP_MISS = PUSH_MISS << PUSHPOP_BITS,
    POP_HIT = PUSH_HIT << PUSHPOP_BITS,
    POP_GATEWAY = PUSH_GATEWAY << PUSHPOP_BITS,
    POP_ALL = PUSH_ALL << PUSHPOP_BITS,
    POP_GW_ENTRY = PUSH_GW_ENTRY << PUSHPOP_BITS,
    FUNCTION_SHIFT = 2 * PUSHPOP_BITS,
    FUNCTION_LOG = 1 << FUNCTION_SHIFT,
    FUNCTION_FIFO = 2 << FUNCTION_SHIFT,
    FUNCTION_STACK = 3 << FUNCTION_SHIFT,
    FUNCTION_BLOOM_CLR = 4 << FUNCTION_SHIFT,
    FUNCTION_MASK = 0xf << FUNCTION_SHIFT,
};

static const char *function_names[] = { "none", "log", "fifo", "stack", "bloom" };

static int decode_push_pop(const value_t &v) {
    static const std::map<std::string, int> modes = {
        { "hit", PUSH_HIT }, { "miss", PUSH_MISS }, { "gateway", PUSH_GATEWAY },
        { "active", PUSH_ALL } };
    if (!CHECKTYPE(v, tSTR)) return 0;
    if (!modes.count(v.s)) {
        error(v.lineno, "Unknown push/pop mode %s", v.s);
        return 0; }
    return modes.at(v.s);
}

bool StatefulTable::setup_jbay(const pair_t &kv) {
    if (kv.key == "sbus") {
        // FIXME -- this should be in the stateful action setup as it is per action?
        if (!CHECKTYPE(kv.value, tMAP)) return true;
        for (auto &el : kv.value.map) {
            if (el.key == "match")
                parse_vector(sbus_match, el.value);
            else if (el.key == "learn")
                parse_vector(sbus_learn, el.value);
            else
                warning(el.key.lineno, "ignoring unknown item %s in sbus of table %s",
                        value_desc(el.key), name()); }
    } else if (kv.key == "fifo" || kv.key == "stack") {
        if (stateful_counter_mode) {
            error(kv.key.lineno, "Conflicting log counter functions in %s", name());
            return true; }
        if (kv.key == "fifo")
            stateful_counter_mode = FUNCTION_FIFO;
        else if (kv.key == "stack")
            stateful_counter_mode = FUNCTION_STACK;
        if (!CHECKTYPE(kv.value, tMAP)) return true;
        for (auto &el : MapIterChecked(kv.value.map)) {
            if (el.key == "push")
                stateful_counter_mode |= decode_push_pop(el.value);
            else if (el.key == "pop")
                stateful_counter_mode |= decode_push_pop(el.value) << PUSHPOP_BITS;
            else
                error(el.key.lineno, "Syntax error, expecting push or pop"); }
    } else if (kv.key == "bloom") {
        if (stateful_counter_mode) {
            error(kv.key.lineno, "Conflicting log counter functions in %s", name());
            return true; }
        stateful_counter_mode = FUNCTION_BLOOM_CLR;
        stateful_counter_mode |= decode_push_pop(kv.value);
    } else if (kv.key == "watermark") {
        if (kv.value == "pop") watermark_pop_not_push = 1;
        else if (kv.value != "push")
            error(kv.value.lineno, "Syntax error, expecting push or pop");
        if (kv.value.type == tSTR)
            watermark_level = 1;
        else if (CHECKTYPE(kv.value[1], tINT)) {
            watermark_level = kv.value[1].i / 128;
        }
        if (kv.value[1].i % 128 != 0) {
            error(kv.value[1].lineno, "watermark level must be a mulitple of 128");
        }
    } else if (kv.key == "underflow") {
        if (CHECKTYPE(kv.value, tSTR))
            underflow_action = kv.value;
    } else if (kv.key == "overflow") {
        if (CHECKTYPE(kv.value, tSTR))
            overflow_action = kv.value;
    } else if (kv.key == "offset_vpn") {
        offset_vpn = get_bool(kv.value);
    } else if (kv.key == "address_shift") {
        if (CHECKTYPE(kv.value, tINT))
            meter_adr_shift = kv.value.i;
    } else if (kv.key == "phv_hash_shift") {
        if (CHECKTYPE(kv.value, tINT)) {
            phv_hash_shift = kv.value.i / 8U;
            if (kv.value.i % 8U != 0)
                error(kv.value.lineno, "phv_hash_shift must be a mulitple of 8");
            else if (phv_hash_shift < 0 || phv_hash_shift > 15)
                error(kv.value.lineno, "phv_hash_shift %ld out of range", kv.value.i); }
    } else if (kv.key == "phv_hash_mask") {
        if (CHECKTYPE2(kv.value, tINT, tBIGINT)) {
            if (kv.value.type == tINT)
                phv_hash_mask.setraw(kv.value.i);
            else
                phv_hash_mask.setraw(kv.value.bigi.data, kv.value.bigi.size); }
    } else
        return false;
    return true;
}

int StatefulTable::parse_counter_mode(Target::JBay target, const value_t &v) {
    int rv = 0;
    if (v == "counter") rv = FUNCTION_LOG;
    else if (v == "fifo") rv = FUNCTION_FIFO;
    else if (v == "stack") rv = FUNCTION_STACK;
    else return -1;
    if (v.type == tSTR) return rv | PUSH_ALL;
    if (v.type != tCMD) return -1;
    int flag = 0;
    for (int i = 1; i < v.vec.size; ++i) {
        if (v[i] == "hit") flag |= PUSH_HIT;
        else if (v[i] == "miss") flag |= PUSH_MISS;
        else if (v[i] == "gateway") flag |= PUSH_GATEWAY;
        else if (v[i] == "gw0") flag |= PUSH_GW_ENTRY;
        else if (v[i] == "gw1") flag |= (PUSH_GW_ENTRY << 1);
        else if (v[i] == "gw2") flag |= (PUSH_GW_ENTRY << 2);
        else if (v[i] == "gw3") flag |= (PUSH_GW_ENTRY << 3);
        else if (v[i] == "push" && (rv & FUNCTION_MASK) != FUNCTION_LOG) {
            rv |= flag ? flag : PUSH_ALL;
            flag = 0;
        } else if (v[i] == "pop" && (rv & FUNCTION_MASK) != FUNCTION_LOG) {
            rv |= (flag ? flag : PUSH_ALL) << PUSHPOP_BITS;
            flag = 0;
        } else
            return -1; }
    return rv | flag;
}

void StatefulTable::set_counter_mode(Target::JBay target, int mode) {
    int fnmode = mode & FUNCTION_MASK;
    BUG_CHECK(fnmode > 0 && (fnmode >> FUNCTION_SHIFT) <= FUNCTION_BLOOM_CLR);
    if (stateful_counter_mode && (stateful_counter_mode & FUNCTION_MASK) != fnmode)
        error(lineno, "Incompatible uses (%s and %s) of stateful alu counters",
              function_names[stateful_counter_mode >> FUNCTION_SHIFT],
              function_names[mode >> FUNCTION_SHIFT]);
    else
        stateful_counter_mode |= fnmode;
    if (mode & PUSH_MASK) stateful_counter_mode |= PUSH_ANY;
    if (mode & POP_MASK) stateful_counter_mode |= POP_ANY;
}

// This is called write_logging_regs, but it handles all target (jbay) specific
// registers, as write_regs is not specialized and this is.  Should rename?
template<> void StatefulTable::write_logging_regs(Target::JBay::mau_regs &regs) {
    auto &adrdist = regs.rams.match.adrdist;
    auto &merge = regs.rams.match.merge;
    auto &vpn_range = adrdist.mau_meter_alu_vpn_range[meter_group()];
    auto &salu = regs.rams.map_alu.meter_group[meter_group()].stateful;
    int minvpn, maxvpn;
    layout_vpn_bounds(minvpn, maxvpn, true);
    vpn_range.meter_vpn_base = minvpn;
    vpn_range.meter_vpn_limit = maxvpn;
    vpn_range.meter_vpn_range_check_enable = 1;
    for (MatchTable *m : match_tables) {
        int mode = stateful_counter_mode;
        if (auto *call = m->get_call(this))
            if (call->args.at(0).type == Call::Arg::Counter)
                mode = call->args.at(0).count_mode();
        if (address_used) {
            auto &slog_map = adrdist.mau_stateful_log_counter_logical_map[m->logical_id];
            slog_map.stateful_log_counter_logical_map_ctl = meter_group();
            slog_map.stateful_log_counter_logical_map_enable = 1; }
        merge.mau_stateful_log_counter_ctl[m->logical_id/8U][0].set_subfield(
            mode & PUSHPOP_MASK , 4*(m->logical_id % 8U), 4);
        merge.mau_stateful_log_counter_ctl[m->logical_id/8U][1].set_subfield(
            (mode >> PUSHPOP_BITS) & PUSHPOP_MASK , 4*(m->logical_id % 8U), 4);
        for (auto &rep : merge.mau_stateful_log_ctl_ixbar_map[m->logical_id/8U]) {
            if (mode & PUSHPOP_MASK)
                rep[0].set_subfield(meter_group() | 0x4, 3*(m->logical_id % 8U), 3);
            if ((mode >> PUSHPOP_BITS) & PUSHPOP_MASK)
                rep[1].set_subfield(meter_group() | 0x4, 3*(m->logical_id % 8U), 3); }
        adrdist.meter_alu_adr_range_check_icxbar_map[meter_group()] |= 1U << m->logical_id;
        if (offset_vpn) {
            adrdist.mau_stateful_log_stage_vpn_offset[m->logical_id]
                .stateful_log_stage_vpn_offset = maxvpn - minvpn + 1; }
        adrdist.stateful_instr_width_logical[m->logical_id] = format->log2size - 3; }
    switch (meter_group()) {
    case 0: adrdist.meter_adr_shift.meter_adr_shift0 = meter_adr_shift; break;
    case 1: adrdist.meter_adr_shift.meter_adr_shift1 = meter_adr_shift; break;
    case 2: adrdist.meter_adr_shift.meter_adr_shift2 = meter_adr_shift; break;
    case 3: adrdist.meter_adr_shift.meter_adr_shift3 = meter_adr_shift; break; }
    if (stateful_counter_mode) {
        auto &oxbar_map = adrdist.mau_stateful_log_counter_oxbar_map[meter_group()];
        oxbar_map.stateful_log_counter_oxbar_ctl = meter_group();
        oxbar_map.stateful_log_counter_oxbar_enable = 1;
        auto &ctl2 = merge.mau_stateful_log_counter_ctl2[meter_group()];
        ctl2.slog_counter_function = stateful_counter_mode >> FUNCTION_SHIFT;
        ctl2.slog_instruction_width = format->log2size - 3;
        if ((stateful_counter_mode & PUSH_ANY) == 0)
            ctl2.slog_push_event_ctl = 1;
        if ((stateful_counter_mode & POP_ANY) == 0)
            ctl2.slog_pop_event_ctl = 1;
        ctl2.slog_vpn_base = logvpn_min;
        ctl2.slog_vpn_limit = logvpn_max;
        if (watermark_level) {
            ctl2.slog_watermark_ctl = watermark_pop_not_push;
            ctl2.slog_watermark_enable = 1;
            merge.mau_stateful_log_watermark_threshold[meter_group()] = watermark_level; }
        auto &ctl3 = merge.mau_stateful_log_counter_ctl3[meter_group()];
        if (underflow_action.set())
            // 4-bit stateful addr MSB encoding for instruction, as given by table 6-67 (6.4.4.11)
            ctl3.slog_underflow_instruction = actions->action(underflow_action.name)->code * 2 + 1;
        if (overflow_action.set())
            ctl3.slog_overflow_instruction = actions->action(overflow_action.name)->code * 2 + 1;
    }
    regs.rams.map_alu.meter_alu_group_phv_hash_shift[meter_group()] = phv_hash_shift;
    unsigned idx = 0;
    for (auto &slice : regs.rams.map_alu.meter_alu_group_phv_hash_mask[meter_group()])
        slice = phv_hash_mask.getrange(32*idx++, 32);

    for (size_t i = 0; i < const_vals.size(); ++i) {
        salu.salu_const_regfile[i] = const_vals[i] & 0xffffffffU;
        salu.salu_const_regfile_msbs[i] = (const_vals[i] >> 32) & 0x3;
    }

}

/// Compute the proper value for the register
///    map_alu.meter_alu_group_data_delay_ctl[].meter_alu_right_group_delay
/// which controls the two halves of the ixbar->meter_alu fifo, based on a bytemask of which
/// bytes are needed in the meter_alu.  On JBay, the fifo is 128 bits wide, so each enable
/// bit controls 64 bits
int AttachedTable::meter_alu_fifo_enable_from_mask(Target::JBay::mau_regs &, unsigned bytemask) {
    int rv = 0;
    if (bytemask & 0xff) rv |= 1;
    if (bytemask & 0xff00) rv |= 2;
    return rv;
}

void StatefulTable::gen_tbl_cfg(Target::JBay, json::map &tbl, json::map &stage_tbl) const {
    static const char *table_type[] = { "normal", "log", "fifo", "stack", "bloom_clear" };
    if (tbl["stateful_table_type"]) {
        // overall table info already set in an earlier stage; don't override it
        return; }
    tbl["stateful_table_type"] = table_type[stateful_counter_mode >> FUNCTION_SHIFT];
    bool has_push = (stateful_counter_mode & PUSHPOP_MASK) != 0;
    bool has_pop = (stateful_counter_mode & (PUSHPOP_MASK << PUSHPOP_BITS)) != 0;
    for (MatchTable *m : match_tables) {
        if (auto *call = m->get_call(this)) {
            if (call->args.at(0).type == Call::Arg::Counter) {
                unsigned mode = call->args.at(0).count_mode();
                has_push |= (mode & PUSHPOP_MASK) != 0;
                has_pop |= (mode & (PUSHPOP_MASK << PUSHPOP_BITS)) != 0; } } }
    if (has_push) {
        if (has_pop)
            tbl["stateful_direction"] = "inout";
        else
            tbl["stateful_direction"] = "in";
    } else if (has_pop)
        tbl["stateful_direction"] = "out";
    tbl["stateful_counter_index"] = meter_group();
}
