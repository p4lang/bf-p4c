/* mau table template specializations for cloudbreak -- #included directly in stateful.cpp */

//FIXME -- factor better with identical JBay code
int StatefulTable::parse_counter_mode(Target::Cloudbreak target, const value_t &v) {
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

void StatefulTable::set_counter_mode(Target::Cloudbreak target, int mode) {
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
template<> void StatefulTable::write_logging_regs(Target::Cloudbreak::mau_regs &regs) {
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
        if (address_used)
            adrdist.meter_alu_adr_range_check_icxbar_map[meter_group()] |= 1U << m->logical_id;
        if (offset_vpn) {
            if (!address_used)
                warning(lineno, "Adjusting output address of %s for next stage, but noone is "
                        "reading it", name());
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
        if (const_vals[i] > (INT64_C(1) << 33) || const_vals[i] <= -(INT64_C(1) << 33))
            error(const_vals_lineno[i], "constant value %" PRId64 " too large for stateful alu",
                  const_vals[i]);
        salu.salu_const_regfile[i] = const_vals[i] & 0xffffffffU;
        salu.salu_const_regfile_msbs[i] = (const_vals[i] >> 32) & 0x3;
    }
    if (stage_alu_id >= 0) {
        salu.stateful_ctl.salu_stage_id = stage_alu_id;
        salu.stateful_ctl.salu_stage_id_enable = 1; }
}

/// Compute the proper value for the register
///    map_alu.meter_alu_group_data_delay_ctl[].meter_alu_right_group_delay
/// which controls the two halves of the ixbar->meter_alu fifo, based on a bytemask of which
/// bytes are needed in the meter_alu.  On Cloudbreak, the fifo is 128 bits wide, so each enable
/// bit controls 64 bits
int AttachedTable::meter_alu_fifo_enable_from_mask(Target::Cloudbreak::mau_regs &,
                                                   unsigned bytemask) {
    int rv = 0;
    if (bytemask & 0xff) rv |= 1;
    if (bytemask & 0xff00) rv |= 2;
    return rv;
}

void StatefulTable::gen_tbl_cfg(Target::Cloudbreak, json::map &tbl, json::map &stage_tbl) const {
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
