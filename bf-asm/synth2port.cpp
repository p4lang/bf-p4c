#include "algorithm.h"
#include "data_switchbox.h"
#include "input_xbar.h"
#include "misc.h"
#include "stage.h"
#include "tables.h"

void Synth2Port::common_init_setup(const VECTOR(pair_t) &data, bool, P4Table::type p4type) {
    auto *row = get(data, "row");
    if (!row) row = get(data, "logical_row");
    setup_layout(layout, row, get(data, "column"), get(data, "bus"));
    if (auto *fmt = get(data, "format")) {
        if (CHECKTYPEPM(*fmt, tMAP, fmt->map.size > 0, "non-empty map"))
            format = new Format(fmt->map); }
}

bool Synth2Port::common_setup(pair_t &kv, const VECTOR(pair_t) &data, P4Table::type p4type) {
    if (kv.key == "vpns") {
        if (kv.value == "null")
            no_vpns = true;
    else if (CHECKTYPE(kv.value, tVEC))
        setup_vpns(layout, &kv.value.vec, true);
    } else if (kv.key == "maprams") {
        if (CHECKTYPE(kv.value, tVEC))
            setup_maprams(&kv.value.vec);
    } else if (kv.key == "global_binding") {
        global_binding = get_bool(kv.value);
    } else if (kv.key == "per_flow_enable") {
        per_flow_enable = get_bool(kv.value);
    } else if (kv.key == "p4") {
        if (CHECKTYPE(kv.value, tMAP))
            p4_table = P4Table::get(p4type, kv.value.map);
    } else if (kv.key == "format" || kv.key == "row" || kv.key == "logical_row" ||
               kv.key == "column" || kv.key == "bus") {
        /* already done in setup_layout */
    } else
        return false;
    return true;
}

template<class REGS>
void Synth2Port::write_regs(REGS &) {
}

json::map *Synth2Port::base_tbl_cfg(json::vector &out, const char *type, int size) {
    json::map &tbl = *AttachedTable::base_tbl_cfg(out, type, size);
    tbl.erase("p4_selection_tables");
    tbl.erase("p4_action_data_tables");
    tbl["enable_per_flow_enable"] = per_flow_enable;
    tbl["per_flow_enable_bit_position"] = per_flow_enable_bit;
    return &tbl;
}

json::map *Synth2Port::add_stage_tbl_cfg(json::map &tbl, const char *type, int size) {
    json::map &stage_tbl = *AttachedTable::add_stage_tbl_cfg(tbl, type, size);
    if (options.new_ctx_json) {
        tbl["how_referenced"] = indirect ? "indirect" : "direct";
        int entries = 1;
        if (format) {
            assert(format->log2size <= 7);
            if (format->groups() > 1) {
                assert(format->log2size == 7);
                entries = format->groups();
            } else {
                entries = 128U >> format->log2size; } }
        add_pack_format(stage_tbl, 128, 1, entries);
        stage_tbl["memory_resource_allocation"] =
            gen_memory_resource_allocation_tbl_cfg("sram", layout, true);
        return &stage_tbl;
    } else {
        stage_tbl["how_referenced"] = indirect ? "indirect" : "direct";
        int entries = 1;
        if (format) {
            assert(format->log2size <= 7);
            if (format->groups() > 1) {
                assert(format->log2size == 7);
                entries = format->groups();
            } else {
                entries = 128U >> format->log2size; } }
        add_pack_format(stage_tbl, 128, 1, entries);
        stage_tbl["memory_resource_allocation"] =
            gen_memory_resource_allocation_tbl_cfg("sram", layout, true);
        stage_tbl["stage_table_handle"] = logical_id;
        json::vector &bindings = tbl["binding"];
        if (global_binding) {
            if (bindings.empty()) {
                bindings.push_back("global");
                bindings.push_back(nullptr);
            } else if (*bindings[0] != (indirect ? "static" : "direct"))
                ERROR("Incompatible bindings for " << name());
        } else {
            if (bindings.empty())
                bindings.push_back(indirect ? "static" : "direct");
            else if (*bindings[0] != (indirect ? "static" : "direct"))
                ERROR("Incompatible bindings for " << name());
            for (auto table : match_tables) {
                const char *name = table->p4_name();
                if (!name) name = table->name();
                size_t i;
                for (i = 1; i < bindings.size(); ++i)
                    if (*bindings[i] == name)
                        break;
                if (i == bindings.size())
                    bindings.push_back(name); } }
        return &stage_tbl; }
}
