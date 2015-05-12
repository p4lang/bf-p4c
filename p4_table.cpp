#include "p4_table.h"
#include "tables.h"

std::map<unsigned, P4Table *>           P4Table::by_handle;
std::map<std::string, P4Table *>        P4Table::by_name;
unsigned                                P4Table::max_handle[7];
const char *P4Table::type_name[] = { 0,
"match_entry", "action_data", "selection", "statistics", "meter", "stateful" };

P4Table *P4Table::get(P4Table::type t, VECTOR(pair_t) &data) {
    auto *h = ::get(data, "handle");
    if (!h) {
        error(data[0].key.lineno, "no handle in p4 info");
        return 0; }
    if (!CHECKTYPE(*h, tINT));
    unsigned handle = h->i;
    if (handle >> 24 && handle >> 24 != t) {
        error(h->lineno, "Inncorect handle type %d for %s table", handle >> 24, type_name[t]);
        return 0; }
    handle &= 0xffffff;
    if (!handle) {
        error(h->lineno, "zero handle");
        return 0; }
    if (handle > max_handle[t]) max_handle[t] = handle;
    handle |= t << 24;
    if (!by_handle.count(handle))
        by_handle[handle] = new P4Table; 
    P4Table *rv = by_handle[handle];
    rv->handle = handle;
    for (auto &kv : MapIterChecked(data)) {
        if (rv->lineno == 0 || rv->lineno > kv.key.lineno)
            rv->lineno = kv.key.lineno;
        if (kv.key == "handle") {
            ;
        } else if (kv.key == "name") {
            if (CHECKTYPE(kv.value, tSTR)) {
                if (!rv->name.empty() && rv->name != kv.value.s) {
                    error(kv.value.lineno, "Inconsistent P4 name for handle 0x%x", handle);
                    warning(rv->lineno, "Previously set here");
                } else if (rv->name.empty()) {
                    rv->name = kv.value.s;
                    if (!by_name.count(rv->name))
                        by_name[rv->name] = rv; } }
        } else if (kv.key == "size") {
            if (CHECKTYPE(kv.value, tINT)) {
                if (rv->explicit_size && rv->size != (unsigned)kv.value.i) {
                    error(kv.value.lineno, "Inconsistent size for P4 handle 0x%x", handle);
                    warning(rv->lineno, "Previously set here");
                } else {
                    rv->size = kv.value.i;
                    rv->explicit_size = true; } }
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in p4 info", kv.key.s); }
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
}

json::map *P4Table::base_tbl_cfg(json::vector &out, int size, Table *table) {
    if (!config) {
        out.emplace_back(std::make_unique<json::map>());
        json::map &tbl = dynamic_cast<json::map &>(*out.back());
        config = &tbl;
        tbl["name"] = p4_name();
        if (handle) tbl["handle"] = handle;
        tbl["table_type"] = type_name[handle >> 24];
        tbl["direction"] = table->gress ? "egress" : "ingress";
        tbl["number_entries"] = explicit_size ? this->size : size;
        tbl["stage_tables_length"] = 0L;
        tbl["stage_tables"] = std::make_unique<json::vector>();
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
            (tbl["p4_selection_tables"] = json::vector()).push_back(std::move(sel)); }
        if (!explicit_size)
            this->size = size;
    } else if (!explicit_size)
        (*config)["number_entries"] = this->size += size;
    return config;
}
