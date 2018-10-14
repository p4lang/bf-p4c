#include "p4_table.h"
#include "tables.h"


static std::map<const P4Table *, alpm_t>                        alpms;

std::map<unsigned, P4Table *>                                   P4Table::by_handle;
std::map<P4Table::type, std::map<std::string, P4Table *>>       P4Table::by_name;
unsigned                                                        P4Table::max_handle[7];

// handle[29:24] is used as type field.
const char *P4Table::type_name[] = { 0,
"match", "action", "selection", "statistics", "meter", "stateful" };

// handle[31:30] is used as handle offset field for multipipe
static unsigned apply_handle_offset(unsigned handle, unsigned offset) {
    return handle | offset << 30;
}

static unsigned clear_handle_offset(unsigned handle) {
    return handle & 0x3fffffff;
}

P4Table *P4Table::get(P4Table::type t, VECTOR(pair_t) &data) {
    P4Table *rv;
    auto *h = ::get(data, "handle");
    auto *n = ::get(data, "name");
    if (h) {
        if (!CHECKTYPE(*h, tINT)) return nullptr;
        unsigned handle = h->i;
        handle = clear_handle_offset(handle);
        if (handle >> 24 && handle >> 24 != t) {
            error(h->lineno, "Incorrect handle type %d for %s table", handle >> 24, type_name[t]);
            return 0; }
        handle &= 0xffffff;
        if (!handle) {
            error(h->lineno, "zero handle");
            return 0; }
        if (handle > max_handle[t]) max_handle[t] = handle;
        handle |= t << 24;
        handle = apply_handle_offset(handle, unique_table_offset);
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
            rv->handle = apply_handle_offset(t << 24, unique_table_offset); }
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
        } else if (kv.key == "disable_atomic_modify") {
            if (CHECKTYPE(kv.value, tSTR))
                if (strncmp(kv.value.s, "true", 4) == 0)
                    rv->disable_atomic_modify = true;
        } else if (kv.key == "how_referenced") {
            if (CHECKTYPE(kv.value, tSTR)) {
                if (strcmp(kv.value.s, "direct") != 0 && strcmp(kv.value.s, "indirect") != 0)
                    error(kv.value.lineno, "how_referenced must be either direct or indirect");
                else
                    rv->how_referenced = kv.value.s;
            }
        } else
            warning(kv.key.lineno, "ignoring unknown item %s in p4 info", value_desc(kv.key)); }
    return rv;
}

P4Table *P4Table::alloc(P4Table::type t, Table *tbl) {
    unsigned handle = apply_handle_offset(++max_handle[t] | (t << 24),  unique_table_offset);
    P4Table *rv = by_handle[handle] = new P4Table;
    rv->handle = handle;
    rv->name = tbl->name();
    return rv;
}

void P4Table::check(Table *tbl) {
    if (name.empty()) name = tbl->name();
    if (!(handle & 0xffffff)) {
        auto table_type = (handle >> 24) & 0x3f;
        handle += ++max_handle[table_type];
    }
}

json::map *P4Table::base_tbl_cfg(json::vector &out, int size, const Table *table) const {
    json::map *tbl_ptr = nullptr;
    for (auto &_table_o : out) {
        auto &_table = _table_o->to<json::map>();
        if (_table["name"] == name) {
            if (_table["handle"]
                    && _table["handle"] != handle) continue;
            tbl_ptr = &_table;
            break; } }
    if (!tbl_ptr) {
        tbl_ptr = new json::map();
        out.emplace_back(tbl_ptr); }
    json::map &tbl = *tbl_ptr;
    tbl["direction"] = table->gress ? "egress" : "ingress";
    if (handle) tbl["handle"] = handle;
    auto table_type = (handle >> 24) & 0x3f;
    tbl["name"] = p4_name();
    tbl["table_type"] = type_name[table_type];
    tbl["size"] = explicit_size ? this->size : size;
    return &tbl;
}

void P4Table::base_alpm_tbl_cfg(json::map &out, int size, const Table *table, P4Table::alpm_type atype) const {
    if (is_alpm()) {
        json::map **alpm_cfg = nullptr;
        unsigned *alpm_table_handle = nullptr;
        auto *alpm = &alpms[this];
        if (alpm) {
            if (atype == P4Table::PreClassifier) {
                alpm_cfg = &alpm->alpm_pre_classifier_table_cfg;
                alpm_table_handle = &alpm->alpm_pre_classifier_table_handle;
            } else if (atype == P4Table::Atcam) {
                alpm_cfg = &alpm->alpm_atcam_table_cfg;
                alpm_table_handle = &alpm->alpm_atcam_table_handle; }
            *alpm_cfg = &out;
            json::map &tbl = out;
            tbl["direction"] = table->gress ? "egress" : "ingress";
            auto table_type = (handle >> 24) & 0x3f;
            if (!(*alpm_table_handle & 0xffffff))
                *alpm_table_handle = apply_handle_offset((P4Table::MatchEntry << 24) + (++max_handle[table_type]),
                                                         unique_table_offset);
            if (*alpm_table_handle)
                tbl["handle"] = *alpm_table_handle;
            tbl["name"] = p4_name();
            tbl["table_type"] = type_name[table_type];
            tbl["size"] = explicit_size ? this->size : size;
        } }
}

void P4Table::set_partition_action_handle(unsigned handle) {
    alpms[this].set_partition_action_handle = handle;
}

void P4Table::set_partition_field_name(std::string name) {
    alpms[this].partition_field_name = name;
}

std::string P4Table::get_partition_field_name() const {
    if (alpms.count(this))
        return alpms[this].partition_field_name;
    return "";
}

unsigned P4Table::get_partition_action_handle() const {
    if (alpms.count(this))
        return alpms[this].set_partition_action_handle;
    return 0;
}

unsigned P4Table::get_alpm_atcam_table_handle() const {
    if (alpms.count(this))
        return alpms[this].alpm_atcam_table_handle;
    return 0;
}
