#include <config.h>

#include "hash_dist.h"
#include "stage.h"
#include "range.h"

static void set_output_bit(unsigned &xbar_use, value_t &v) {
    if (CHECKTYPE(v, tSTR)) {
        if (v == "immediate_lo" || v == "lo")
            xbar_use |= HashDistribution::IMMEDIATE_LOW;
        else if (v == "immediate_hi" || v == "hi")
            xbar_use |= HashDistribution::IMMEDIATE_HIGH;
        else if (v == "meter" || v == "meter_address")
            xbar_use |= HashDistribution::METER_ADDRESS;
        else if (v == "stats" || v == "stats_address")
            xbar_use |= HashDistribution::STATISTICS_ADDRESS;
        else if (v == "action" || v == "action_address")
            xbar_use |= HashDistribution::ACTION_DATA_ADDRESS;
        else if (v == "hashmod")
            xbar_use |= HashDistribution::HASHMOD_DIVIDEND;
        else
            error(v.lineno, "Unrecognized hash_dist output %s", v.s);
    }
}

HashDistribution::HashDistribution(int id_, value_t &data, unsigned u)
    : lineno(data.lineno), id (id_), xbar_use(u)
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
            } else if (kv.key == "expand") {
                if (CHECKTYPE(kv.value, tINT))
                    expand = kv.value.i;
            } else if (kv.key == "output") {
                if (kv.value.type == tVEC)
                    for (auto &s : kv.value.vec)
                        set_output_bit(xbar_use, s);
                else
                    set_output_bit(xbar_use, kv.value);
            } else
                warning(kv.key.lineno, "ignoring unknown item %s in hash_dist",
                        value_desc(kv.key)); }
}

void HashDistribution::parse(std::vector<HashDistribution> &out, const value_t &data,
                             unsigned xbar_use) {
    if (CHECKTYPE(data, tMAP))
        for (auto &kv : data.map)
            if (CHECKTYPE(kv.key, tINT))
                out.emplace_back(kv.key.i, kv.value, xbar_use);
}

bool HashDistribution::compatible(HashDistribution *a) {
    if (hash_group != a->hash_group) return false;
    if (id != a->id) return false;
    if (shift != a->shift) return false;
    if (expand != a->expand) return false;
    if (meter_pre_color && !a->meter_pre_color && (mask & ~a->mask)) return false;
    if (!meter_pre_color && a->meter_pre_color && (~mask & a->mask)) return false;
    return true;
}

void HashDistribution::pass1(Table *tbl) {
    this->tbl = tbl;
    bool err = false;
    for (auto *use : tbl->stage->hash_dist_use[id]) {
        if (!compatible(use)) {
            err = true;
            error(lineno, "hash_dist unit %d in table %s not compatible with", id, tbl->name());
            warning(use->lineno, "previous use in table %s", use->tbl->name()); } }
    if (expand >= 0) {
        int min_shift = 7, diff = 7, other = id-1;
        switch(id%3) {
        case 0:
            min_shift = 0; diff = -7; other = id+1;
            // fall through
        case 1:
            if (expand < min_shift || expand >= min_shift + 16) {
                error(lineno, "hash_dist unit %d expand can't pull from bit %d", id, expand);
                err = true; }
            break;
        case 2:
            error(lineno, "hash_dist unit %d cannot be expanded", id);
            err = true;
            break;
        default:
            error(lineno, "a mod 3 check should only hit these particular cases, of 0, 1, and 2");
            assert(0);
        }
        if (!err) {
            for (auto *use : tbl->stage->hash_dist_use[other])
                if (use->expand != expand - diff) {
                    error(lineno, "hash_dist unit %d int table %s expand not compatible with",
                          id, tbl->name());
                    warning(use->lineno, "previous use in table %s", use->tbl->name()); } } }
    if (err) return;
    tbl->stage->hash_dist_use[id].push_back(this);
    for (int i = 0; i < 3; i++) {
        if (id%3 == i) continue;
        int m = 3 * (id/3) + i;
        for (auto *use : tbl->stage->hash_dist_use[id]) {
            if (use->hash_group != hash_group) {
                error(lineno, "hash_dist %d and %d use different hash groups", id, m);
                warning(use->lineno, "previous use here"); } } }
}

template<class REGS>
void HashDistribution::write_regs(REGS &regs, Table *tbl, int type, bool non_linear) {
    /* from HashDistributionResourceAllocation.write_config: */
    auto &merge = regs.rams.match.merge;
    if (non_linear)
        merge.mau_selector_hash_sps_enable |= 1 << id;
    if (tbl->gress == EGRESS)
        merge.mau_hash_group_config.hash_group_egress |= 1 << id;
    merge.mau_hash_group_config.hash_group_enable |= 1 << id;
    merge.mau_hash_group_config.hash_group_sel.set_subfield(hash_group | 8U, 4 * (id/3), 4);
    merge.mau_hash_group_config.hash_group_ctl.set_subfield(type, 2 * id, 2);
    merge.mau_hash_group_shiftcount.set_subfield(shift, 3 * id, 3);
    merge.mau_hash_group_mask[id] |= mask;
    if (expand >= 0) switch (id % 3) {
    case 0:
        merge.mau_hash_group_expand[id/3].hash_slice_group0_expand = 1;
        merge.mau_hash_group_expand[id/3].hash_slice_group2_expand = expand;
        merge.mau_hash_group_config.hash_group_enable |= 1 << (id + 2);
        merge.mau_hash_group_config.hash_group_ctl.set_subfield(type, 2 * (id + 2), 2);
        break;
    case 1:
        merge.mau_hash_group_expand[id/3].hash_slice_group1_expand = 1;
        merge.mau_hash_group_expand[id/3].hash_slice_group2_expand = expand - 7;
        merge.mau_hash_group_config.hash_group_enable |= 1 << (id + 1);
        merge.mau_hash_group_config.hash_group_ctl.set_subfield(type, 2 * (id + 2), 2);
        break;
    default: assert(0); }
    for (int oxbar : Range(0, 4))
        if ((xbar_use >> oxbar) & 1)
            merge.mau_hash_group_xbar_ctl[oxbar][tbl->logical_id/8U].set_subfield(
                8|id, 4*(tbl->logical_id%8U), 4);
    if (xbar_use & HASHMOD_DIVIDEND) {
        int mgroup = tbl->get_selector()->meter_group();
        merge.mau_hash_group_xbar_ctl[5][mgroup/8U].set_subfield(8|id, 4*(mgroup%8U), 4); }
    if (meter_pre_color) {
        merge.mau_meter_precolor_hash_sel.set_subfield(8|id, 4 * (id/3), 4);
        int ctl = 16 | meter_mask_index;
        if (id >= 3) ctl |= 8;
        merge.mau_meter_precolor_hash_map_to_logical_ctl[tbl->logical_id/4U].set_subfield(
            ctl, 5 * (tbl->logical_id%4U), 5); }
}
FOR_ALL_TARGETS(INSTANTIATE_TARGET_TEMPLATE,
                void HashDistribution::write_regs, mau_regs &, Table *, int, bool)
