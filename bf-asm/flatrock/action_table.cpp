#include "tables.h"
#include "action_table.h"

template<> void ActionTable::write_regs_vt(Target::Flatrock::mau_regs &regs) {
    LOG1("### Action table " << name() << " write_regs " << loc());
    unsigned fmt_log2size = format ? format->log2size : 0;
    unsigned width = format ? (format->size-1)/128 + 1 : 1;
    for (auto &fmt : Values(action_formats)) {
        fmt_log2size = std::max(fmt_log2size, fmt->log2size);
        width = std::max(width, (fmt->size-1)/128U + 1);
    }
    ::error(width != 1, "wide action table not supported yet.");
    auto& aram = regs.ppu_aram[0];
    int sub_addr_size = log2(128U) - fmt_log2size;
    assert(sub_addr_size >= 0 && sub_addr_size <= 7);
    aram.rf.aram_sub_addr.sub_addr_size[0] = sub_addr_size;

    // TODO
    // aram.rf.aram_stm.stm_rd_delay
    // aram.rf.aram_cfg.stm_miss_allow
    // aram.rf.aram_dconfig.dconfig_sel_hi
    // aram.rf.aram_dconfig.dconfig_sel_lo
    // aram.rf.aram_ecc.aram_dis
    // aram.rf.aram_err_intr_en
    // aram.rf.aram_err_stat
}
