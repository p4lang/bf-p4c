#include "action_table.h"
#include "action_bus.h"
#include "stage.h"
#include "top_level.h"

void Target::Flatrock::ActionTable::pass1() {
    ::ActionTable::pass1();
    if (match_tables.size() != 1)
        error(lineno, "Action table can only be used by a single match table on Flatrock");
    for (auto physid : physical_ids) {
        if (stage->action_unit_use[physid])
            error(lineno, "aram unit %d used by both %s and %s", physid,
                  stage->action_unit_use[physid]->name(), name());
        stage->action_unit_use[physid] = this;
    }
    if (!physical_ids.empty())
        alloc_global_busses();
}

void Target::Flatrock::ActionTable::pass2() {
    ::ActionTable::pass2();
    if (physical_ids.empty()) {
        for (auto &row : layout) {
            for (auto &memunit : row.memunits) {
                int unit = memunit.col/2 - 1;
                if (unit >= 0 && !stage->action_unit_use[unit]) {
                    physical_ids[unit] = 1;
                    break; } }
            if (!physical_ids.empty()) break; }
        if (physical_ids.empty()) {
            for (int unit = 0; unit < ARAM_UNITS_PER_STAGE; ++unit) {
                if (!stage->action_unit_use[unit]) {
                    physical_ids[unit] = 1;
                    break; } } }
        if (!physical_ids.empty()) {
            for (auto physid : physical_ids)
                stage->action_unit_use[physid] = this;
            alloc_global_busses();
        } else {
            error(lineno, "No action unit available for %s", name()); } }
}

void Target::Flatrock::ActionTable::pass3() {
    ::ActionTable::pass3();
    for (auto &slot : action_bus->slots()) {
        int lo = -1;
        for (auto &[src, off] : slot.data) {
            BUG_CHECK(src.type == ActionBusSource::Field,
                      "non-field on action bus for action table");
            BUG_CHECK(off == 0, "non-zero offset for field on action bus for action table");
            BUG_CHECK(src.field->size == slot.size, "field doesn't match slot size");
            BUG_CHECK(lo == -1, "more than one field in slot?");
            lo = src.field->bit(0); }
        BUG_CHECK(lo >= 0, "no field in slot");
        if (slot.byte < 16) {
            // badb
            int start = slot.byte - lo/8;
            if (start < 0 || (badb_start >= 0 && badb_start != start))
                error(action_bus->lineno, "action data misaligned on badb");
            else
                badb_start = start;
            int end = (lo + slot.size - 1)/8;
            if (badb_size <= end)
                badb_size = end + 1;
        } else {
            // wadb
            int start = slot.byte/4 - 4 - lo/32;
            if (start < 0 || (wadb_start >= 0 && wadb_start != start))
                error(action_bus->lineno, "action data misaligned on wadb");
            else
                wadb_start = start;
            int end = (lo + slot.size - 1)/32;
            if (wadb_size <= end)
                wadb_size = end + 1;
        }
    }
}

unsigned Target::Flatrock::ActionTable::determine_shiftcount(Table::Call &call,
                                                             int, unsigned, int) const {
    if (call.args[0] == "$DIRECT") {
        return get_match_table()->format->overhead_size;
    } else if (auto *field = call.args[0].field()) {
        return field->bit(0) - field->fmt->overhead_start;
    } else {
        BUG("can't decode action call");
    }
}

template<> void ActionTable::write_regs_vt(Target::Flatrock::mau_regs &regs) { BUG(); }

void Target::Flatrock::ActionTable::write_regs(Target::Flatrock::mau_regs &regs) {
    LOG1("### Action table " << name() << " write_regs " << loc());

    int dconfig = 0;  // FIXME -- some parts of this support selecting config based on
    // dconfig bits -- for now we just use config 0

    unsigned fmt_log2size = format ? format->log2size : 0;
    unsigned width = format ? (format->size-1)/128 + 1 : 1;
    for (auto &fmt : Values(action_formats)) {
        fmt_log2size = std::max(fmt_log2size, fmt->log2size);
        width = std::max(width, (fmt->size-1)/128U + 1);
    }
    if (width != 1)
        ::error(lineno, "wide action table not supported yet.");
    auto *mt = get_match_table();
    for (auto physid : physical_ids) {
        auto& aram = regs.ppu_aram[physid];
        auto &mrd = regs.ppu_mrd.rf;
        int sub_addr_size = log2(128U) - fmt_log2size;
        assert(sub_addr_size >= 0 && sub_addr_size <= 7);
        aram.rf.aram_sub_addr.sub_addr_size[dconfig] = sub_addr_size;

        // TODO
        // aram.rf.aram_cfg.dconfig_sel_hi
        // aram.rf.aram_cfg.dconfig_sel_lo
        aram.rf.aram_cfg.stm_rd_delay = 4;   // min value
        // aram.rf.aram_cfg.stm_miss_allow

        if (badb_start >= 0) {
            mrd.mrd_aram_cfg[physid].badb_rot = badb_start;
            mrd.mrd_aram_cfg[physid].badb_mask = ((1U << badb_size) - 1) << badb_start; }
        if (wadb_start >= 0) {
            mrd.mrd_aram_cfg[physid].wadb_rot = wadb_start & 3;
            mrd.mrd_aram_cfg[physid].wadb_mask = ((1U << wadb_size) - 1) << wadb_start; }

        mrd.mrd_p2a_xbar[physid].en[dconfig] = 1;
        BUG_CHECK(mt->physical_ids.popcount() == 1,
                  "Not exactly one physical id in %s", mt->name());
        mrd.mrd_p2a_xbar[physid].unit[dconfig] = *mt->physical_ids.begin();
        mrd.mrd_aram_ext[physid].ext_start[dconfig] = determine_shiftcount(mt->action, 0, 0, 0);
        if (mt->action.args[0] == "$DIRECT") {
            mrd.mrd_aram_ext[physid].ext_size[dconfig] = 20;  // FIXME -- how big is the index?
        } else if (auto *field = mt->action.args[0].field()) {
            mrd.mrd_aram_ext[physid].ext_size[dconfig] = field->size;
        }
    }

    auto &ppu = TopLevel::regs<Target::Flatrock>()->reg_pipe.ppu_pack;
    int maxdelay = 0;
    for (auto &row : layout)
        for (auto &ram : row.memunits)
            maxdelay = std::max(maxdelay, std::abs(ram.stage/2 - stage->stageno/2));
    BUG_CHECK(physical_ids.popcount() == 1, "not exactly one physical id in %s", name());
    // FIXME -- if there's more than one physical id (wide table), the rams need to
    // be split between them
    int vcol = *physical_ids.begin() + 1;
    for (auto &row : layout) {
        auto vpn = row.vpns.begin();
        for (auto &ram : row.memunits) {
            BUG_CHECK(row.row == ram.row, "ram row mismatch");
            BUG_CHECK(vpn != row.vpns.end(), "not enough vpns on row");
            if (gress != EGRESS)
                stm_bus_rw_config(ppu.istm, stage->stageno, vcol, 4, row.bus, ram,
                                  false, *vpn, maxdelay);
            else
                stm_bus_rw_config(ppu.estm, stage->stageno, vcol, 4, row.bus, ram,
                                  false, *vpn, maxdelay);
            ++vpn; }
        BUG_CHECK(vpn == row.vpns.end(), "too many vpns on row"); }

    if (action_bus) action_bus->write_regs(regs, this);
    if (actions) actions->write_regs(regs, this);
}
