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
    FUNCTION_MASK = 0xf << FUNCTION_SHIFT,
};

static const char *function_names[] = { "none", "log", "fifo", "stack", "bloom" };

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
        else if (CHECKTYPE(kv.value[1], tINT))
            watermark_level = kv.value[1].i / 128;
            if (kv.value[1].i % 128 != 0)
                error(kv.value[1].lineno, "watermark level must be a mulitple of 128");
    } else if (kv.key == "underflow") {
        if (CHECKTYPE(kv.value, tSTR))
            underflow_action = kv.value;
    } else if (kv.key == "overflow") {
        if (CHECKTYPE(kv.value, tSTR))
            overflow_action = kv.value;
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
    mode &= FUNCTION_MASK;
    assert(mode > 0 && (mode >> FUNCTION_SHIFT) <= FUNCTION_BLOOM_CLR);
    if (stateful_counter_mode && stateful_counter_mode != mode)
        error(lineno, "Incompatible uses (%s and %s) of stateful alu counters",
              function_names[stateful_counter_mode >> FUNCTION_SHIFT],
              function_names[mode >> FUNCTION_SHIFT]);
    else
        stateful_counter_mode = mode;
}

template<> void StatefulTable::write_logging_regs(Target::JBay::mau_regs &regs) {
    auto &adrdist =  regs.rams.match.adrdist;
    auto &merge =  regs.rams.match.merge;
    for (MatchTable *m : match_tables) {
        int mode = stateful_counter_mode;
        if (auto *call = m->get_call(this))
            if (call->args.size() >= 2 && call->args.at(1).type == Call::Arg::Counter)
                mode = call->args.at(1).count_mode();
        // adrdist.mau_stateful_log_counter_logical_map[m->logical_id] = ???
        merge.mau_stateful_log_counter_ctl[m->logical_id/8U][0].set_subfield(
            mode & PUSHPOP_MASK , 4*(m->logical_id % 8U), 4);
        merge.mau_stateful_log_counter_ctl[m->logical_id/8U][1].set_subfield(
            (mode >> PUSHPOP_BITS) & PUSHPOP_MASK , 4*(m->logical_id % 8U), 4);
        for (auto &rep : merge.mau_stateful_log_ctl_ixbar_map[m->logical_id/8U]) {
            if (mode & PUSHPOP_MASK)
                rep[0].set_subfield(meter_group() | 0x4, 3*(m->logical_id % 8U), 3);
            if ((mode >> PUSHPOP_BITS) & PUSHPOP_MASK)
                rep[1].set_subfield(meter_group() | 0x4, 3*(m->logical_id % 8U), 3); } }
    // adrdist.mau_meter_alu_vpn_range[meter_goup] = ???
    auto &oxbar_map = adrdist.mau_stateful_log_counter_oxbar_map[meter_group()];
    oxbar_map.stateful_log_counter_oxbar_ctl = meter_group();
    oxbar_map.stateful_log_counter_oxbar_enable = 1;
    auto &ctl2 = merge.mau_stateful_log_counter_ctl2[meter_group()];
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
        merge.mau_stateful_log_watermark_threshold[meter_group()] = watermark_level; }
    auto &ctl3 = merge.mau_stateful_log_counter_ctl3[meter_group()];
    if (underflow_action.set())
        // 4-bit stateful address MSB encoding for instruction, as given by table 6-67 (6.4.4.11)
        ctl3.slog_underflow_instruction = actions->action(underflow_action.name)->code * 2 + 1;
    if (overflow_action.set())
        ctl3.slog_overflow_instruction = actions->action(overflow_action.name)->code * 2 + 1;
}

void StatefulTable::gen_tbl_cfg(Target::JBay, json::map &tbl, json::map &stage_tbl) {
    static const char *table_type[] = { "normal", "log", "fifo", "stack", "bloom_clear" };
    tbl["stateful_table_type"] = table_type[stateful_counter_mode >> FUNCTION_SHIFT];
    bool has_push = (stateful_counter_mode & PUSHPOP_MASK) != 0;
    bool has_pop = (stateful_counter_mode & (PUSHPOP_MASK << PUSHPOP_BITS)) != 0;
    for (MatchTable *m : match_tables) {
        if (auto *call = m->get_call(this)) {
            if (call->args.size() >= 2 && call->args.at(1).type == Call::Arg::Counter) {
                unsigned mode = call->args.at(1).count_mode();
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
