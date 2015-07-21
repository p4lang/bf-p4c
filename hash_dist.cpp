#include "hash_dist.h"
#include "stage.h"

HashDistribution::HashDistribution(value_t &v, int u) : lineno(v.lineno), use(u) {
    if (v.type ==  tMAP) {
        int func = -1, group = -1;
        for (auto &kv : MapIterChecked(v.map)) {
            if (kv.key == "func") {
                if (CHECKTYPE(kv.value, tINT) && (unsigned)(func = kv.value.i) >= 2U)
                    error(kv.value.lineno, "Invalid hash distribulion function id");
            } else if (kv.key == "group") {
                if (CHECKTYPE(kv.value, tINT) && (unsigned)(group = kv.value.i) >= 3U)
                    error(kv.value.lineno, "Invalid hash distribulion group id");
            } else if (kv.key == "hash") {
                if (CHECKTYPE(kv.value, tINT) && (unsigned)(hash_group = kv.value.i) >= 8U)
                    error(kv.value.lineno, "Invalid hash group");
            } else if (kv.key == "mask") {
                if (CHECKTYPE(kv.value, tINT))
                    mask = kv.value.i;
            } else if (kv.key == "shift") {
                if (CHECKTYPE(kv.value, tINT))
                    shift = kv.value.i;
            } else
                warning(kv.key.lineno, "ignoring unknown item %s in hash_dist", kv.key.s); }
        if (id < 0) {
            if (func < 0 || group < 0)
                error(v.lineno, "Need func and group in hash_dist");
            id = func*3 + group; }
        return; }
    else if (!CHECKTYPEPM(v, tVEC, v.vec.size == 4, "hash_dist vector")) return;
    else if (!CHECKTYPE(v[0], tINT) || v[0].i < 0 || v[0].i >= 8)
        error(v[0].lineno, "Invalid hash group");
    else if (!CHECKTYPE(v[1], tINT) || v[1].i < 0 || v[1].i >= 2)
        error(v[1].lineno, "Invalid hash distribulion function id");
    else if (!CHECKTYPE(v[2], tINT) || v[2].i < 0 || v[2].i >= 3)
        error(v[2].lineno, "Invalid hash distribulion group id");
    else if (CHECKTYPE(v[3], tINT)) {
        hash_group = v[0].i;
        id = v[1].i*3 + v[2].i;
        mask = v[3].i; }
}
HashDistribution::HashDistribution(int id_, value_t &data, int u)
    : lineno(data.lineno), id (id_), use(u)
{
    if (id < 0 || id >= 6)
        error(data.lineno, "Invalid hash_dist unit id %d", id);
    if (CHECKTYPE(data, tMAP))
        for (auto &kv : MapIterChecked(data.map)) {
            if (kv.key == "hash") {
                if (CHECKTYPE(kv.value, tINT) && (unsigned)(hash_group = kv.value.i) >= 8U)
                    error(kv.value.lineno, "Invalid hash group");
            } else if (kv.key == "mask") {
                if (CHECKTYPE(kv.value, tINT))
                    mask = kv.value.i;
            } else if (kv.key == "shift") {
                if (CHECKTYPE(kv.value, tINT))
                    shift = kv.value.i;
            } else
                warning(kv.key.lineno, "ignoring unknown item %s in hash_dist", kv.key.s); }
}

void HashDistribution::parse(std::vector<HashDistribution> &out, value_t &data, int use) {
    if (data.type == tVEC && data.vec.size > 0 && data[0].type != tINT) {
        for (auto &v : data.vec)
            out.emplace_back(v, use);
    } else if (data.type == tMAP && data.map.size > 0 && data.map[0].key.type == tINT) {
        for (auto &kv : data.map)
            if (CHECKTYPE(kv.key, tINT))
                out.emplace_back(kv.key.i, kv.value, use);
    } else
        out.emplace_back(data, use);
}

void HashDistribution::pass1(Table *tbl) {
    auto &use = tbl->stage->hash_dist_use[id];
    if (use.first) {
        error(lineno, "hash_dist unit %d in table %s multiple uses", id, tbl->name());
        warning(use.second ? use.second->lineno : use.first->lineno, "previous use in table %s",
                use.first->name());
        return; }
    use.first = tbl;
    use.second = this;
    for (int i = 0; i < 3; i++) {
        if (id%3 == i) continue;
        int m = 3 * (id/3) + i;
        if (tbl->stage->hash_dist_use[m].second &&
            tbl->stage->hash_dist_use[m].second->hash_group != hash_group) {
            error(lineno, "hash_dist %d and %d use different hash groups", id, m);
            warning(tbl->stage->hash_dist_use[m].second->lineno, "previous use here"); } }
}

void HashDistribution::write_regs(Table *tbl, int type, bool non_linear) {
    /* from HashDistributionResourceAllocation.write_config: */
    auto &merge = tbl->stage->regs.rams.match.merge;
    if (non_linear)
        merge.mau_selector_hash_sps_enable |= 1 << id;
    if (tbl->gress == EGRESS)
        merge.mau_hash_group_config.hash_group_egress |= 1 << id;
    merge.mau_hash_group_config.hash_group_enable |= 1 << id;
    merge.mau_hash_group_config.hash_group_sel.set_subfield(hash_group, 4 * (id/3), 3);
    merge.mau_hash_group_config.hash_group_sel.set_subfield(1, 4 * (id/3) + 3, 1);
    merge.mau_hash_group_config.hash_group_ctl.set_subfield(type, 2 * id, 2);
    merge.mau_hash_group_shiftcount.set_subfield(shift, 3 * id, 3);
    merge.mau_hash_group_mask[id] = mask;
    // FIXME -- these are for combining to get wider than 16-bit groups...
    switch (id % 3) {
    case 0: merge.mau_hash_group_expand[id/3].hash_slice_group0_expand = 0; break;
    case 1: merge.mau_hash_group_expand[id/3].hash_slice_group1_expand = 0; break;
    case 2: merge.mau_hash_group_expand[id/3].hash_slice_group2_expand = 0; break;
    default: assert(0); }
    if (use >= 0)
        merge.mau_hash_group_xbar_ctl[use][tbl->logical_id/8U].set_subfield(
            8|id, 4*(tbl->logical_id%8U), 4);
}
