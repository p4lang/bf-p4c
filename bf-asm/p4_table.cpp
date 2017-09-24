#include "p4_table.h"
#include "tables.h"

std::map<unsigned, P4Table *>                                   P4Table::by_handle;
std::map<P4Table::type, std::map<std::string, P4Table *>>       P4Table::by_name;
unsigned                                P4Table::max_handle[7];
const char *P4Table::type_name[] = { 0,
"match", "action", "selection", "statistics", "meter", "stateful" };

P4Table *P4Table::get(P4Table::type t, VECTOR(pair_t) &data) {
    P4Table *rv;
    auto *h = ::get(data, "handle");
    auto *n = ::get(data, "name");
    if (h) {
        if (!CHECKTYPE(*h, tINT)) return nullptr;
        unsigned handle = h->i;
        if (handle >> 24 && handle >> 24 != t) {
            error(h->lineno, "Incorrect handle type %d for %s table", handle >> 24, type_name[t]);
            return 0; }
        handle &= 0xffffff;
        if (!handle) {
            error(h->lineno, "zero handle");
            return 0; }
        if (handle > max_handle[t]) max_handle[t] = handle;
        handle |= t << 24;
        if (!(rv = by_handle[handle])) {
            if (!n || !CHECKTYPE(*n, tSTR) || !by_name[t].count(n->s) ||
                (rv = by_name[t][n->s])->handle != (unsigned)t << 24)
                rv = by_handle[handle] = new P4Table;
            rv->handle = handle; }
    } else if (n) {
        if (!CHECKTYPE(*n, tSTR)) return 0;
        if (!(rv = by_name[t][n->s])) {
            rv = by_name[t][n->s] = new P4Table;
            rv->name = n->s;
            rv->handle = t << 24; }
    } else {
        error(data[0].key.lineno, "no handle or name in p4 info");
        return 0; }
    for (auto &kv : MapIterChecked(data)) {
        if (rv->lineno <= 0 || rv->lineno > kv.key.lineno)
            rv->lineno = kv.key.lineno;
        if (kv.key == "handle") {
            ;
        } else if (kv.key == "name") {
            if (CHECKTYPE(kv.value, tSTR)) {
                if (!rv->name.empty() && rv->name != kv.value.s) {
                    error(kv.value.lineno, "Inconsistent P4 name for handle 0x%x", rv->handle);
                    warning(rv->lineno, "Previously set here");
                } else if (rv->name.empty()) {
                    rv->name = kv.value.s;
                    if (!by_name[t].count(rv->name))
                        by_name[t][rv->name] = rv; } }
        } else if (kv.key == "size") {
            if (CHECKTYPE(kv.value, tINT)) {
                if (rv->explicit_size && rv->size != (unsigned)kv.value.i) {
                    error(kv.value.lineno, "Inconsistent size for P4 handle 0x%x", rv->handle);
                    warning(rv->lineno, "Previously set here");
                } else {
                    rv->size = kv.value.i;
                    rv->explicit_size = true; } }
        } else if (kv.key == "action_profile") {
            if (CHECKTYPE(kv.value, tSTR))
                rv->action_profile = kv.value.s;
        } else if (kv.key == "match_type") {
            if (CHECKTYPE(kv.value, tSTR))
                rv->match_type = kv.value.s;
        } else if (kv.key == "preferred_match_type") {
            if (CHECKTYPE(kv.value, tSTR))
                rv->preferred_match_type = kv.value.s;
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in p4 info", value_desc(kv.key)); }
    return rv;
}

P4Table *P4Table::alloc(P4Table::type t, Table *tbl) {
    unsigned handle = ++max_handle[t] | (t << 24);
    P4Table *rv = by_handle[handle] = new P4Table;
    rv->handle = handle;
    rv->name = tbl->name();
    return rv;
}

void P4Table::check(Table *tbl) {
    if (name.empty()) name = tbl->name();
    if (!(handle & 0xffffff))
        handle += ++max_handle[handle >> 24];
}

json::map *P4Table::base_tbl_cfg(json::vector &out, int size, Table *table) {
    if (options.new_ctx_json) {
        if (!config) {
            out.emplace_back(json::mkuniq<json::map>());
            json::map &tbl = dynamic_cast<json::map &>(*out.back());
            config = &tbl;
            tbl["direction"] = table->gress ? "egress" : "ingress";
            if (handle) tbl["handle"] = handle;
            tbl["name"] = p4_name();
            tbl["table_type"] = type_name[handle >> 24];
            tbl["size"] = explicit_size ? this->size : size;
            tbl["stage_tables"] = json::mkuniq<json::vector>();
            if (auto *attached = table->get_attached()) {
                json::vector *vec = &(tbl["statistics_table_refs"] = json::vector());
                for (auto &tblcall : attached->stats) {
                    json::map stats;
                    stats["name"] = tblcall->p4_name();
                    stats["handle"] = tblcall->handle();
                    stats["how_referenced"] = tblcall.args.empty() ? "direct" : "indirect";
                    vec->push_back(std::move(stats)); }
                vec = 0;
                for (auto &tblcall : attached->meter) {
                    if (!vec) vec = &(tbl["meter_table_refs"] = json::vector());
                    json::map meter;
                    meter["name"] = tblcall->p4_name();
                    meter["handle"] = tblcall->handle();
                    meter["how_referenced"] = tblcall.args.empty() ? "direct" : "indirect";
                    vec->push_back(std::move(meter)); } } }
        return config;
    } else {
        if (!config) {
            out.emplace_back(json::mkuniq<json::map>());
            json::map &tbl = dynamic_cast<json::map &>(*out.back());
            config = &tbl;
            tbl["name"] = p4_name();
            if (handle) tbl["handle"] = handle;
            tbl["table_type"] = type_name[handle >> 24];
            tbl["direction"] = table->gress ? "egress" : "ingress";
            tbl["number_entries"] = explicit_size ? this->size : size;
            tbl["stage_tables_length"] = 0L;
            if (!preferred_match_type.empty())
                tbl["preferred_match_type"] = preferred_match_type;
            tbl["stage_tables"] = json::mkuniq<json::vector>();
            if (options.match_compiler && handle >> 24 == MatchEntry) {
                tbl["p4_action_data_tables"] = json::vector();
                tbl["p4_selection_tables"] = json::vector(); }
            if (options.match_compiler && handle >> 24 == Selection)
                tbl["p4_action_data_table"] = json::vector();
            if (auto &action = table->action_call()) if ((Table *)action != table) {
                json::map act;
                act["name"] = action->p4_name();
                act["handle_reference"] = action->handle();
                if (options.match_compiler && handle >> 24 == Selection) {
                    (tbl["p4_action_data_table"] = json::vector()).push_back(std::move(act));
                } else {
                    act["how_referenced"] = action.args.size() > 1 ? "indirect" : "direct";
                    (tbl["p4_action_data_tables"] = json::vector()).push_back(std::move(act)); } }
            if (auto *selector = table->get_selector()) if (selector != table) {
                json::map sel;
                sel["name"] = selector->p4_name();
                sel["handle_reference"] = selector->handle();
                sel["how_referenced"] = "indirect";
                (tbl["p4_selection_tables"] = json::vector()).push_back(std::move(sel)); }
            if (auto *attached = table->get_attached()) {
                json::vector *vec = 0;
                if (options.match_compiler)
                    vec = &(tbl["p4_statistics_tables"] = json::vector());
                for (auto &tblcall : attached->stats) {
                    if (!vec) vec = &(tbl["p4_statistics_tables"] = json::vector());
                    json::map stats;
                    stats["name"] = tblcall->p4_name();
                    stats["handle_reference"] = tblcall->handle();
                    stats["how_referenced"] = tblcall.args.empty() ? "direct" : "indirect";
                    vec->push_back(std::move(stats)); }
                vec = 0;
                for (auto &tblcall : attached->meter) {
                    if (!vec) vec = &(tbl["p4_meter_tables"] = json::vector());
                    json::map meter;
                    meter["name"] = tblcall->p4_name();
                    meter["handle_reference"] = tblcall->handle();
                    meter["how_referenced"] = tblcall.args.empty() ? "direct" : "indirect";
                    vec->push_back(std::move(meter)); } }
            if (!explicit_size)
                this->size = size;
        } else if (!explicit_size)
            (*config)["number_entries"] = this->size += size;
        return config; }
}
