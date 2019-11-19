/* mau table template specializations for cloudbreak -- #included directly in stateful.cpp */

//FIXME -- factor better with identical JBay code
int StatefulTable::parse_counter_mode(Target::Cloudbreak target, const value_t &v) {
    return parse_jbay_counter_mode(v); }

void StatefulTable::set_counter_mode(Target::Cloudbreak target, int mode) {
    int fnmode = mode & FUNCTION_MASK;
    BUG_CHECK(fnmode > 0 && (fnmode >> FUNCTION_SHIFT) <= FUNCTION_FAST_CLEAR);
    if (stateful_counter_mode && (stateful_counter_mode & FUNCTION_MASK) != fnmode)
        error(lineno, "Incompatible uses (%s and %s) of stateful alu counters",
              function_names[stateful_counter_mode >> FUNCTION_SHIFT],
              function_names[mode >> FUNCTION_SHIFT]);
    else
        stateful_counter_mode |= fnmode;
    if (mode & PUSH_MASK) stateful_counter_mode |= PUSH_ANY;
    if (mode & POP_MASK) stateful_counter_mode |= POP_ANY;
}

template<> void StatefulTable::write_logging_regs(Target::Cloudbreak::mau_regs &regs) {
    write_tofino2_common_regs(regs);
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
