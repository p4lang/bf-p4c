#include "stateful.h"

// FIXME -- factor better with identical JBay code
int StatefulTable::parse_counter_mode(Target::Cloudbreak target, const value_t &v) {
    return parse_jbay_counter_mode(v); }

void StatefulTable::set_counter_mode(Target::Cloudbreak target, int mode) {
    set_counter_mode(Target::JBay(), mode);
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
    gen_tbl_cfg(Target::JBay(), tbl, stage_tbl);
}
