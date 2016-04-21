#include "table_layout.h"
#include "lib/bitops.h"
#include "lib/log.h"

static void setup_match_layout(IR::MAU::Table::Layout &layout, const IR::V1Table *tbl) {
    layout.entries = tbl->size;
    for (auto t : tbl->reads_types)
        if (t == "ternary" || t == "lpm") {
            layout.ternary = true;
            break; }
    layout.match_width_bits = 0;
    if (tbl->reads) {
        for (auto r : *tbl->reads) {
            if (auto mask = r->to<IR::Mask>()) {
                auto mval = mask->right->to<IR::Constant>();
                layout.match_width_bits += bitcount(mval->value);
                if (!layout.ternary)
                    layout.ixbar_bytes += (mask->left->type->width_bits()+7)/8;
            } else if (auto prim = r->to<IR::Primitive>()) {
                if (prim->name != "valid")
                    BUG("unexpected reads expression %s", r);
                layout.match_width_bits += 1;
            } else if (r->is<IR::Member>() || r->is<IR::Slice>()) {
                layout.match_width_bits += r->type->width_bits();
                if (!layout.ternary)
                    layout.ixbar_bytes += (r->type->width_bits() + 7)/8;
            } else {
                BUG("unexpected reads expression %s", r); } } }
    layout.overhead_bits = ceil_log2(tbl->actions.size());
}

class GatewayLayout : public MauInspector {
    IR::MAU::Table::Layout &layout;
    set<cstring> added;
    bool preorder(const IR::Member *f) {
        cstring name = f->toString();
        if (!added.count(name)) {
            added.insert(name);
            layout.ixbar_bytes += (f->type->width_bits() + 7)/8; }
        return false; }

 public:
    explicit GatewayLayout(IR::MAU::Table::Layout &l) : layout(l) {}
};

static void
setup_gateway_layout(IR::MAU::Table::Layout &layout, IR::MAU::Table *tbl) {
    for (auto &gw : tbl->gateway_rows)
        gw.first->apply(GatewayLayout(layout));
    // should count gw tcam width and depth to support gw splitting when needed
}

static void setup_action_layout(IR::MAU::Table *tbl) {
    tbl->layout.action_data_bytes = 0;
    for (auto action : Values(tbl->actions)) {
        int action_data_bytes = 0;
        for (auto arg : action->args)
            action_data_bytes += (arg->type->width_bits() + 7) / 8U;
        if (action_data_bytes > tbl->layout.action_data_bytes)
            tbl->layout.action_data_bytes = action_data_bytes; }
}

namespace {
class VisitAttached : public Inspector {
    IR::MAU::Table::Layout &layout;
    bool preorder(const IR::Stateful *st) override {
        if (!st->direct) {
            if (st->instance_count <= 0)
                error("%s: No instance count in indirect %s %s", st->srcInfo, st->kind(), st->name);
            layout.overhead_bits += ceil_log2(st->instance_count); }
        return false; }
    bool preorder(const IR::ActionProfile *ap) override {
        have_action_data = true;
        if (ap->size <= 0)
            error("%s: No size count in %s %s", ap->srcInfo, ap->kind(), ap->name);
        layout.overhead_bits += ceil_log2(ap->size);
        return false; }
    bool preorder(const IR::ActionSelector *) override {
        // TODO(cdodd) -- what does this require from the layout?
        return false; }
    bool preorder(const IR::MAU::TernaryIndirect *) override {
        have_ternary_indirect = true;
        return false; }
    bool preorder(const IR::MAU::ActionData *) override {
        have_action_data = true;
        return false; }
    bool preorder(const IR::Attached *att) override {
        BUG("Unknown attached table type %s", typeid(*att).name()); }

 public:
    explicit VisitAttached(IR::MAU::Table::Layout *l) : layout(*l) {}
    bool have_ternary_indirect = false;
    bool have_action_data = false;;
};
}  // namespace

bool TableLayout::preorder(IR::MAU::Table *tbl) {
    LOG1("## layout table " << tbl->name);
    tbl->layout.ixbar_bytes = tbl->layout.match_width_bits =
    tbl->layout.action_data_bytes = tbl->layout.overhead_bits = 0;
    if (tbl->match_table)
        setup_match_layout(tbl->layout, tbl->match_table);
    if ((tbl->layout.gateway = tbl->uses_gateway()))
        setup_gateway_layout(tbl->layout, tbl);
    setup_action_layout(tbl);
    VisitAttached attached(&tbl->layout);
    for (auto at : tbl->attached)
        at->apply(attached);
    bool add_action_data = false;
    if (!attached.have_action_data) {
        if (tbl->layout.action_data_bytes > 4) {   // too big for overhead
            add_action_data = true;
        } else if (!tbl->layout.ternary) {
            // match size duplicated from way allocation below
            int match_group_bits = std::max(tbl->layout.match_width_bits-10, 0) +
                                   tbl->layout.overhead_bits + 4;
            int w_overhead_bits = match_group_bits + 8*tbl->layout.action_data_bytes;
            if ((match_group_bits + 127)/128U != (w_overhead_bits + 127)/128U) {
                // would increase table width in rams (bad)
                add_action_data = true;
            } else if (128U/match_group_bits != 128U/w_overhead_bits) {
                // would decrease the number of match groups (not good)
                if (1024 * (128/w_overhead_bits) >= tbl->layout.entries) {
                    // all the entries we want still fits in one ram, so ok
                } else {
                    add_action_data = true; } } } }
    if (add_action_data) {
        LOG2("  adding action data table");
        auto *act_data = new IR::MAU::ActionData(tbl->name);
        tbl->attached.push_back(act_data);
        act_data->apply(attached); }
    if (!attached.have_action_data) {
        LOG2("  putting " << tbl->layout.action_data_bytes << " bytes of action data in overhead");
        tbl->layout.action_data_bytes_in_overhead = tbl->layout.action_data_bytes;
        tbl->layout.overhead_bits += 8 * tbl->layout.action_data_bytes_in_overhead; }
    if (tbl->layout.ternary) {
        if (tbl->layout.overhead_bits > 1 && !attached.have_ternary_indirect) {
            LOG2("  adding ternary indirect table");
            auto *tern_indir = new IR::MAU::TernaryIndirect(tbl->name);
            tbl->attached.push_back(tern_indir);
            tern_indir->apply(attached); }
    } else if (tbl->match_table) {
        // determine ways and match groups?
        int match_group_bits = std::max(tbl->layout.match_width_bits-10, 0) +
                               tbl->layout.overhead_bits + 4;
        int width = (match_group_bits+127)/128U;
        int match_groups = width > 1 ? 1 : 128 / match_group_bits;
        int ways = tbl->layout.entries / 1024U / match_groups;
        // FIXME -- quick hack to choose a non-silly number of ways.  Should do for real
        if (ways > 6) {
            ways = 6;
        } else if (ways < 3) {
            if (match_groups == 1)
                ways = 3;
            else if (match_groups == 2)
                ways = 2;
            else if (ways < 1)
                ways = 1; }
        if ((ways+1)/2 * width > 8)
            ways = (8/width) * 2;
        tbl->ways.resize(ways);
        int entries = (tbl->layout.entries + match_groups - 1)/ match_groups;
        for (auto &way : tbl->ways) {
            way.match_groups = match_groups;
            way.width = width;
            way.entries = std::max(1024U, 1U << (ceil_log2(entries / ways--) + 1) >> 1);
            if ((entries -= way.entries) < 0)
                entries = 0;
            way.entries *= match_groups; } }
    return true;
}

bool TableLayout::backtrack(trigger &) {
    return false;
}
