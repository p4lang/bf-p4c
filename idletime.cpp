#include "misc.h"
#include "stage.h"
#include "tables.h"

void IdletimeTable::setup(VECTOR(pair_t) &data) {
    setup_layout(layout, get(data, "row"), get(data, "column"), get(data, "bus"));
    for (auto &kv : MapIterChecked(data, true)) {
        if (kv.key == "precision") {
            if (CHECKTYPE(kv.value, tINT)) {
                precision = kv.value.i;
                if (precision != 1 && precision != 2 && precision != 3 && precision != 6)
                    error(kv.value.lineno, "Invalid idletime precision %d", precision); }
        } else if (kv.key == "sweep_interval") {
            if (CHECKTYPE(kv.value, tINT))
                sweep_interval = kv.value.i;
        } else if (kv.key == "notification") {
            if (kv.value == "disable") disable_notification = true;
            else if (kv.value == "two_way") two_way_notification = true;
            else if (kv.value != "enable")
                error(kv.value.lineno, "Unknown notification style '%s'",
                      value_desc(kv.value));
        } else if (kv.key == "per_flow_enable") {
            per_flow_enable = get_bool(kv.value);
        } else if (kv.key == "row" || kv.key == "column" || kv.key == "bus") {
            /* already done in setup_layout */
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in table %s",
                    value_desc(kv.key), name()); }
    alloc_rams(false, stage->mapram_use);
}

void IdletimeTable::pass1() {
    LOG1("### Idletime table " << name() << " pass1");
    alloc_vpns();
}

void IdletimeTable::pass2() {
    LOG1("### Idletime table " << name() << " pass2");
}

static int precision_bits[] = { 0, 0, 1, 2, 0, 0, 3 };

void IdletimeTable::write_merge_regs(int type, int bus) {
    auto &merge = stage->regs.rams.match.merge;
    merge.mau_idletime_adr_mask[type][bus] = (~1U << precision_bits[precision]) & 0x1fffff;
    merge.mau_idletime_adr_default[type][bus] = 0x100000 | ((1 << precision_bits[precision]) - 1);
}

int IdletimeTable::precision_shift() { return precision_bits[precision] + 1; }

void IdletimeTable::write_regs() {
    LOG1("### Idletime table " << name() << " write_regs");
    auto &map_alu = stage->regs.rams.map_alu;
    auto &adrdist = stage->regs.rams.match.adrdist;
    stage->regs.cfg_regs.idle_dump_ctl[logical_id].idletime_dump_size = layout_size() - 1;
    //stage->regs.cfg_regs.mau_cfg_lt_has_idle |= 1 << logical_id;
    for (Layout &row : layout) {
        auto &map_alu_row = map_alu.row[row.row];
        auto &adrmux = map_alu_row.adrmux;
        auto vpn = row.vpns.begin();
        for (int col : row.cols) {
            setup_muxctl(map_alu_row.vh_xbars.adr_dist_idletime_adr_xbar_ctl[col], row.bus);
            auto &mapram_cfg = adrmux.mapram_config[col];
            //auto &mapram_ctl = adrmux.mapram_ctl[col];
            if (disable_notification)
                mapram_cfg.idletime_disable_notification = 1;
            if (two_way_notification)
                mapram_cfg.two_way_idletime_notification = 1;
            if (per_flow_enable)
                mapram_cfg.per_flow_idletime = 1;
            mapram_cfg.idletime_bitwidth = precision_bits[precision];
            mapram_cfg.mapram_type = MapRam::IDLETIME;
            mapram_cfg.mapram_logical_table = logical_id;
            mapram_cfg.mapram_vpn_members = 0; // FIXME
            mapram_cfg.mapram_vpn = *vpn++;
            if (gress == INGRESS)
                mapram_cfg.mapram_ingress = 1;
            else
                mapram_cfg.mapram_egress = 1;
            mapram_cfg.mapram_enable = 1;
            auto &adrmux_ctl = adrmux.ram_address_mux_ctl[1][col];
            adrmux_ctl.map_ram_wadr_mux_select = MapRam::Mux::IDLETIME;
            adrmux_ctl.map_ram_wadr_mux_enable = 1;
            adrmux_ctl.map_ram_radr_mux_select_smoflo = 1;
            adrmux_ctl.ram_ofo_stats_mux_select_statsmeter = 1;
            adrmux_ctl.ram_stats_meter_adr_mux_select_idlet = 1;
            setup_muxctl(adrmux.idletime_logical_to_physical_sweep_grant_ctl[col], logical_id);
            setup_muxctl(adrmux.idletime_physical_to_logical_req_inc_ctl[col], logical_id);
            unsigned clear_val = ~(~0U << precision);
            if (per_flow_enable || precision == 1)
                clear_val &= ~1U;
            for (unsigned i = 0; i < 8U/precision; i++)
                adrmux.idletime_cfg_rd_clear_val[col]
                    .set_subfield(clear_val, i*precision, precision);
            if (gress)
                stage->regs.cfg_regs.mau_cfg_mram_thread[col/3U] |= 1U << (col%3U*8U + row.row); }
        unsigned bus_index = row.bus;
        if (bus_index < 8 && row.row >= 4)
            bus_index += 10;
        adrdist.adr_dist_idletime_adr_oxbar_ctl[bus_index/4]
            .set_subfield(logical_id | 0x10, 5 * (bus_index%4), 5);
    }
    //don't enable initially -- runtime will enable
    //adrdist.idletime_sweep_ctl[logical_id].idletime_en = 1;
    adrdist.idletime_sweep_ctl[logical_id].idletime_sweep_size = layout_size() - 1;
    adrdist.idletime_sweep_ctl[logical_id].idletime_sweep_interval = sweep_interval;
    //adrdist.movereg_ad_ctl[logical_id].movereg_ad_direct_idle = 1;
    //adrdist.movereg_ad_ctl[logical_id].movereg_ad_idle_size = precision_bits[precision];
}

void IdletimeTable::gen_stage_tbl_cfg(json::map &out) {
    unsigned number_entries = layout_size() * (8U/precision) * 1024;
    json::map &tbl = out["stage_idletime_table"] = json::map();
    tbl["stage_number"] = stage->stageno;
    tbl["stage_table_type"] = "idletime";
    tbl["number_entries"] = number_entries;
    add_pack_format(tbl, 10, 1, 8U/precision);
    tbl["memory_resource_allocation"] = gen_memory_resource_allocation_tbl_cfg("map_ram", layout);
    tbl["stage_table_handle"] = logical_id;
    tbl["idletime_precision"] = precision;
    tbl["idletime_disable_notification"] = disable_notification;
    tbl["idletime_two_way_notification"] = two_way_notification;
    tbl["idletime_per_flow_idletime"] = per_flow_enable;
}
