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

template<class REGS>
void IdletimeTable::write_merge_regs(REGS &regs, int type, int bus) {
    auto &merge = regs.rams.match.merge;
    merge.mau_payload_shifter_enable[type][bus].idletime_adr_payload_shifter_en = 1;
    merge.mau_idletime_adr_mask[type][bus] = (~1U << precision_bits[precision]) 
        & ((1U << IDLETIME_ADDRESS_BITS) - 1);
    merge.mau_idletime_adr_default[type][bus] = 
        (1U << IDLETIME_ADDRESS_PER_FLOW_ENABLE_START_BIT) 
        | ((1 << precision_bits[precision]) - 1);
}

int IdletimeTable::precision_shift() { return precision_bits[precision] + 1; }

template<class REGS>
void IdletimeTable::write_regs(REGS &regs) {
    LOG1("### Idletime table " << name() << " write_regs");
    auto &map_alu = regs.rams.map_alu;
    auto &adrdist = regs.rams.match.adrdist;
    int minvpn = 1000000, maxvpn = -1;
    for (Layout &logical_row : layout)
        for (auto v : logical_row.vpns) {
            if (v < minvpn) minvpn = v;
            if (v > maxvpn) maxvpn = v; }
    //regs.cfg_regs.mau_cfg_lt_has_idle |= 1 << logical_id;
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
            if ((precision == 1) || (precision == 2)) {
                mapram_cfg.mapram_parity_generate = 1;
                mapram_cfg.mapram_parity_check = 1;
            } else {
                if ((precision != 3) && (precision != 6))
                    error(lineno, "Unknown idletime precision = %d", precision);
                mapram_cfg.mapram_ecc_generate = 1;
                mapram_cfg.mapram_ecc_check = 1; }
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
                regs.cfg_regs.mau_cfg_mram_thread[col/3U] |= 1U << (col%3U*8U + row.row); }
        unsigned bus_index = row.bus;
        if (bus_index < 8 && row.row >= 4)
            bus_index += 10;
        adrdist.adr_dist_idletime_adr_oxbar_ctl[bus_index/4]
            .set_subfield(logical_id | 0x10, 5 * (bus_index%4), 5); }
    //don't enable initially -- runtime will enable
    //adrdist.idletime_sweep_ctl[logical_id].idletime_en = 1;
    adrdist.idletime_sweep_ctl[logical_id].idletime_sweep_offset = minvpn;
    adrdist.idletime_sweep_ctl[logical_id].idletime_sweep_size = layout_size() - 1;
    adrdist.idletime_sweep_ctl[logical_id].idletime_sweep_remove_hole_pos = 0;  // TODO
    adrdist.idletime_sweep_ctl[logical_id].idletime_sweep_remove_hole_en = 0;  // TODO
    adrdist.idletime_sweep_ctl[logical_id].idletime_sweep_interval = sweep_interval;
    auto &idle_dump_ctl = regs.cfg_regs.idle_dump_ctl[logical_id];
    idle_dump_ctl.idletime_dump_offset = minvpn;
    idle_dump_ctl.idletime_dump_size = maxvpn;
    idle_dump_ctl.idletime_dump_remove_hole_pos = 0;  // TODO
    idle_dump_ctl.idletime_dump_remove_hole_en = 0;  // TODO
    adrdist.movereg_idle_ctl[logical_id].movereg_idle_ctl_size = precision_bits[precision];
    adrdist.movereg_idle_ctl[logical_id].movereg_idle_ctl_direct = 1;
    adrdist.movereg_ad_direct[MoveReg::IDLE] |= 1 << logical_id;
}

void IdletimeTable::gen_stage_tbl_cfg(json::map &out) {
    if (options.new_ctx_json) {
        unsigned number_entries = layout_size() * (8U/precision) * 1024;
        json::map &tbl = out["idletime_stage_table"] = json::map();
        tbl["stage_number"] = stage->stageno;
        tbl["size"] = number_entries;
        tbl["stage_table_type"] = "idletime";
        tbl["precision"] = precision;
        tbl["disable_notification"] = disable_notification;
        tbl["two_way_notification"] = two_way_notification;
        tbl["enable_pfe"] = per_flow_enable;
        add_pack_format(tbl, 11, 1, 8U/precision);
        tbl["memory_resource_allocation"] = gen_memory_resource_allocation_tbl_cfg("map_ram", layout);
    } else {
        unsigned number_entries = layout_size() * (8U/precision) * 1024;
        json::map &tbl = out["stage_idletime_table"] = json::map();
        tbl["stage_number"] = stage->stageno;
        tbl["stage_table_type"] = "idletime";
        tbl["number_entries"] = number_entries;
        add_pack_format(tbl, 11, 1, 8U/precision);
        tbl["memory_resource_allocation"] = gen_memory_resource_allocation_tbl_cfg("map_ram", layout);
        tbl["stage_table_handle"] = logical_id;
        tbl["idletime_precision"] = precision;
        tbl["idletime_disable_notification"] = disable_notification;
        tbl["idletime_two_way_notification"] = two_way_notification;
        tbl["idletime_per_flow_idletime"] = per_flow_enable; }
}
