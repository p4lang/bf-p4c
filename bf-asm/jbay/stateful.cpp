/* mau table template specializations for jbay -- #included directly in match_tables.cpp */

/* for jbay counter mode, we may need both a push and a pop mode, as well as counter_function,
 * so we pack them all into an int with some shifts and masks */
enum {
    PUSHPOP_BITS = 5,
    PUSHPOP_MASK = 0xf,
    PUSHPOP_CONTROLPLANE = 0x10,
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
};

static int decode_push_pop(const value_t &v) {
    static const std::map<std::string, int> modes = {
        { "hit", PUSH_HIT }, { "miss", PUSH_MISS }, { "gateway", PUSH_GATEWAY },
        { "active", PUSH_ALL }, { "control_plane", PUSHPOP_CONTROLPLANE } };
    if (!CHECKTYPE(v, tSTR)) return 0;
    if (!modes.count(v.s)) {
        error(v.lineno, "Unknown push/pop mode %s", v.s);
        return 0; }
    return modes.at(v.s);
}

bool StatefulTable::setup_jbay(const pair_t &kv) {
    if (kv.key.type == tCMD && kv.key == "sbus") {
        if (!CHECKTYPE(kv.value, tMAP)) return true;
        for (auto &el : kv.value.map) {
            if (el.key == "match")
                parse_vector(sbus_match, el.value);
            else if (el.key == "learn")
                parse_vector(sbus_learn, el.value);
            else
                warning(el.key.lineno, "ignoring unknown item %s in sbus of table %s",
                        value_desc(el.key), name()); }
        for (auto &el : kv.key.vec) {
            if (el == "and") sbus_and = true;
            else if (el == "or") sbus_or = true;
            else if (el == "not") sbus_invert = true;
            else if (el != "sbus")
                warning(el.lineno, "ignoring unknown item %s in sbus of table %s",
                        value_desc(el), name()); }
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
        else if (CHECKTYPE(kv.value[1], tINT))
            watermark_level = kv.value[1].i / 128;
            if (kv.value[1].i % 128 != 0)
                error(kv.value[1].lineno, "watermark level must be a mulitple of 128");
    } else
        return false;
    return true;
}

int StatefulTable::parse_counter_mode(Target::JBay target, const value_t &v) {
    if (v != "counter") return -1;
    if (v.type == tSTR) return PUSH_ALL + FUNCTION_LOG;
    if (v.type != tCMD || v.vec.size != 2) return -1;
    static const std::map<std::string, int> modes = {
        { "hit", PUSH_HIT }, { "miss", PUSH_MISS }, { "gateway", PUSH_GATEWAY } };
    if (!modes.count(v[1].s)) return -1;
    return modes.at(v[1].s) + FUNCTION_LOG;
}

template<> void StatefulTable::write_logging_regs(Target::JBay::mau_regs &regs) {
    auto &adrdist =  regs.rams.match.adrdist;
    auto &merge =  regs.rams.match.merge;
    unsigned meter_group = layout.at(0).row/4U;
    for (MatchTable *m : match_tables) {
        merge.mau_stateful_log_counter_ctl[m->logical_id/8U][0].set_subfield(
            stateful_counter_mode & PUSHPOP_MASK , 3*(m->logical_id % 8U), 3);
        merge.mau_stateful_log_counter_ctl[m->logical_id/8U][1].set_subfield(
            (stateful_counter_mode >> PUSHPOP_BITS) & PUSHPOP_MASK , 3*(m->logical_id % 8U), 3);
        for (auto &rep : merge.mau_stateful_log_ctl_ixbar_map[m->logical_id/8U])
            rep[0].set_subfield(meter_group, 2*(m->logical_id % 8U), 2); }
    auto &ctl2 = merge.mau_stateful_log_counter_ctl2[meter_group];
    ctl2.slog_counter_function = stateful_counter_mode >> FUNCTION_SHIFT;
    ctl2.slog_instruction_width = format->log2size - 3;
    if (stateful_counter_mode & PUSHPOP_CONTROLPLANE)
        ctl2.slog_push_event_ctl = 1;
    if ((stateful_counter_mode >> PUSHPOP_BITS) & PUSHPOP_CONTROLPLANE)
        ctl2.slog_pop_event_ctl = 1;
    ctl2.slog_vpn_base = logvpn_min;
    ctl2.slog_vpn_limit = logvpn_max;
    if (watermark_level) {
        ctl2.slog_watermark_ctl = watermark_pop_not_push;
        ctl2.slog_watermark_enable = 1;
        merge.mau_stateful_log_watermark_threshold[meter_group] = watermark_level; }
}
