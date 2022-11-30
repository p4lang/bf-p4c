#include <tables.h>
#include <stage.h>
#include <top_level.h>

void Synth2Port::mark_dual_port_use() {
    for (auto physid : physical_ids) {
        if (stage->dp_unit_use[physid])
            error(lineno, "dual port unit %d used by both %s and %s", physid,
                  stage->dp_unit_use[physid]->name(), name());
        stage->dp_unit_use[physid] = this;
    }
}

void Synth2Port::alloc_dual_port(unsigned usable) {
    for (auto &row : layout) {
        if (row.row != 0) continue;  // need spares in row 0
        for (auto &memunit : row.memunits) {
            int unit = memunit.col/2 - 1;
            if (!((1 << unit) & usable)) continue;
            if (unit >= 0 && !stage->dp_unit_use[unit]) {
                physical_ids[unit] = 1;
                break; } }
        if (!physical_ids.empty()) break; }
    if (physical_ids.empty()) {
        for (int unit = 0; unit < Target::DP_UNITS_PER_STAGE(); ++unit) {
            if (!((1 << unit) & usable)) continue;
            if (!stage->dp_unit_use[unit]) {
                physical_ids[unit] = 1;
                break; } } }
    if (!physical_ids.empty()) {
        for (auto physid : physical_ids)
            stage->dp_unit_use[physid] = this;
    } else {
        error(lineno, "No dual port unit available for %s", name()); }
}

void Synth2Port::alloc_vpns(Target::Flatrock) {
    if (physical_ids.empty()) return;
    if (no_vpns || layout_size() == 0 || layout[0].vpns.size() > 0) return;
    int vpn = 0;
    int spare_vpn = 0;
    int vcol = stm_vbus_column();
    for (auto &row : layout) {
        for (auto &ram : row.memunits) {
            if (ram.row == 0 && ram.stage == stage->stageno && ram.col/2 == vcol) {
                row.vpns.push_back(spare_vpn++);
            } else {
                row.vpns.push_back(vpn++); } } }
}

std::vector<int>
Synth2Port::determine_spare_bank_memory_units(Target::Flatrock) const {
    std::vector<int> spare_mem;

    bool ddp_mode = true;
    int vbus_col = stm_vbus_column();
    for (auto &row : layout) {
        if (row.row != 0) {
            ddp_mode = false;
            continue; }
        for (auto &ram : row.memunits) {
            BUG_CHECK(ram.row == row.row, "bogus %s in row %d", ram.desc(), row.row);
            if (ram.stage != stage->stageno || ram.col/2 != vbus_col) {
                ddp_mode = false;
                continue; }
            spare_mem.push_back(json_memunit(ram)); } }
    if (spare_mem.size() != 2) {
        error(layout.empty() ? lineno : layout.begin()->lineno, "%s needs both rams in "
              "row 0 cols %d-%d for spares", name(), 2*vbus_col, 2*vbus_col + 1);
    } else if (ddp_mode) {
        // in ddp_mode, we just have the spares, but this corresponds to a table with 1 ram
        // so we call one spare amd the other not
        spare_mem.erase(spare_mem.begin()); }
    return spare_mem;
}

void Synth2Port::write_regs(Target::Flatrock::mau_regs &regs) {
    int dconfig = 0;  // FIXME -- some parts of this support selecting config based on
    // dconfig bits -- for now we just use config 0

    auto *mt = get_match_table();
    BUG_CHECK(physical_ids.popcount() == 1, "not exactly one physical id in %s", name());
    int physid = *physical_ids.begin();
    auto &dpm = regs.ppu_dpm.module.dpu[physid];
    auto &mrd = regs.ppu_mrd.rf;

    dpm.dpm_dpu_cfg.delay = 4;  // FIXME
    dpm.dpm_dpu_cfg.mode = layout.size() > 2;

    mrd.mrd_p2a_xbar[physid+4].en[dconfig] = 1;
    BUG_CHECK(mt->physical_ids.popcount() == 1,
              "Not exactly one physical id in %s", mt->name());
    mrd.mrd_p2a_xbar[physid+4].unit[dconfig] = *mt->physical_ids.begin();
    auto *call = mt->get_call(this);
    BUG_CHECK(call, "can't find call to %s in %s", name(), mt->name());
    if (call->args[0] == "$DIRECT") {
        mrd.mrd_au_ext[physid].addr_ext_start[dconfig] = mt->format->overhead_size;
        mrd.mrd_au_ext[physid].addr_ext_size[dconfig] = 20;  // FIXME -- how big is the index?
    } else if (auto *field = call->args[0].field()) {
        mrd.mrd_au_ext[physid].addr_ext_start[dconfig] = field->bit(0) - field->fmt->overhead_start;
        mrd.mrd_au_ext[physid].addr_ext_size[dconfig] = field->size;
    } else {
        BUG("can't decode counter call"); }
    if (call->args[1] == "$DIRECT") {
        mrd.mrd_au_ext[physid].ctl_ext_start[dconfig] = mt->format->overhead_size;  // FIXME
        mrd.mrd_au_ext[physid].ctl_ext_size[dconfig] = 1;
    } else if (auto *field = call->args[1].field()) {
        mrd.mrd_au_ext[physid].ctl_ext_start[dconfig] = field->bit(0) - field->fmt->overhead_start;
        mrd.mrd_au_ext[physid].ctl_ext_size[dconfig] = field->size;
    } else {
        BUG("can't decode counter call"); }

    auto &ppu = TopLevel::regs<Target::Flatrock>()->reg_pipe.ppu_pack;
    int maxdelay = 0;
    for (auto &row : layout)
        for (auto &ram : row.memunits)
            maxdelay = std::max(maxdelay, std::abs(ram.stage/2 - stage->stageno/2));
    dpm.dpm_dpu_cfg.rd_req_delay = maxdelay;
    BUG_CHECK(physical_ids.popcount() == 1, "not exactly one physical id in %s", name());
    // FIXME -- if there's more than one physical id (wide table), the rams need to
    // be split between them
    int vcol = stm_vbus_column();
    for (auto &row : layout) {
        auto vpn = row.vpns.begin();
        for (auto &ram : row.memunits) {
            BUG_CHECK(row.row == ram.row, "ram row mismatch");
            BUG_CHECK(vpn != row.vpns.end(), "not enough vpns on row");
            if (gress != EGRESS)
                stm_bus_rw_config(ppu.istm, stage->stageno, vcol, 5, row.bus, ram,
                                  true, *vpn, maxdelay);
            else
                stm_bus_rw_config(ppu.estm, stage->stageno, vcol, 5, row.bus, ram,
                                  true, *vpn, maxdelay);
            ++vpn; }
        BUG_CHECK(vpn == row.vpns.end(), "too many vpns on row"); }
}
