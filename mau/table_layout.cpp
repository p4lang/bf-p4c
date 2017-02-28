#include "table_layout.h"
#include "lib/bitops.h"
#include "lib/log.h"
#include "input_xbar.h"
#include "tofino/phv/phv_fields.h"

Visitor::profile_t TableLayout::init_apply(const IR::Node *root) {
    alloc_done = phv.alloc_done();
    return MauModifier::init_apply(root);
}

bool TableLayout::backtrack(trigger &trig) {
    return trig.is<IXBar::failure>() && !alloc_done;
}

cstring HashDistReq::algorithm() const {
    if (instr != nullptr && instr->name == "hash") {
        return instr->operands[1]->to<IR::Member>()->member;  
    }
    return "";
}

int HashDistReq::bits_required(const PhvInfo &phv) const {
    if (instr != nullptr) {
        if (instr->name == "hash") {
            return instr->operands[2]->type->width_bits();
        }
    }

    if (attached != nullptr) {
        if (auto *c = attached->to<IR::MAU::MAUCounter>())
            return phv.field(c->indirect_index)->size;
    }
    return -1;
}

void TableLayout::setup_match_layout(IR::MAU::Table::Layout &layout, const IR::MAU::Table *tbl) {
    if (auto k = tbl->match_table->getConstantProperty("size"))
        layout.entries = k->asInt();
    else if (auto k = tbl->match_table->getConstantProperty("min_size"))
        layout.entries = k->asInt();
    auto key = tbl->match_table->getKey();
    if (key) {
        for (auto t : *key->keyElements)
            if (t->matchType->path->name == "ternary" || t->matchType->path->name == "lpm") {
                layout.ternary = true;
                break; } }
    layout.match_width_bits = 0;
    if (key) {
        for (auto el : *key->keyElements) {
            if (el->matchType->path->name == "selector") continue;
            auto r = el->expression;
            PhvInfo::Field::bitrange bits = { 0, 0 };
            auto *field = phv.field(r, &bits);
            if (auto mask = r->to<IR::Mask>()) {
                if (auto mval = mask->right->to<IR::Constant>()) {
                    /* find highest and lowest set bit in the mask, and use them to slice
                     * down the field */
                    field = phv.field((r = mask->left), &bits);
                    int hi = floor_log2(mval->value);
                    if (hi >= 0 && hi < bits.size())
                        bits.hi = bits.lo + hi;
                    int lo = ffs(mval->value);
                    if (lo > 0)
                        bits.lo = lo; } }
            if (field) {
                int bytes = (bits.size() + 7)/8;
                if (!field->alloc.empty()) {
                    /* count the number of actual distinct PHV bytes alloced for these bits */
                    /* FIXME -- factor this into a PhvInfo::Field method? or iterator? */
                    bytes = 0;
                    for (auto &sl : field->alloc) {
                        /* we want to iterate over just the part of the allocation covered by
                         * 'bits' (a slice), so we skip parts entirely above and chops down parts
                         * that overlap as needed, so as to just count the bytes in the slice */
                        /* FIXME -- if a field is allocated to non-contiguous bits of a byte,
                         * this will count that byte twice, when it is only needed once.  The
                         * match layout in asm_output will likewise lay it out twice, so this
                         * is consistent.  Should fix PHV alloc to not make such bad allocations */
                        if (sl.field_bit > bits.hi) continue;
                        if (sl.field_hi() < bits.lo) break;
                        PhvInfo::Field::bitrange cbits = { sl.container_bit, sl.container_hi() };
                        if (bits.hi < sl.field_hi())
                            cbits.hi -= sl.field_hi() - bits.hi;
                        if (bits.lo > sl.field_bit)
                            cbits.lo += bits.lo - sl.field_bit;
                        assert(cbits.hi >= cbits.lo);
                        bytes += cbits.hi/8U + 1 - cbits.lo/8U; } }
                layout.match_bytes += bytes;
                layout.match_width_bits += bits.size();
                if (!layout.ternary)
                    layout.ixbar_bytes += bytes;
            } else if (auto prim = r->to<IR::Primitive>()) {
                if (prim->name != "valid")
                    BUG("unexpected reads expression %s", r);
                layout.match_bytes += 1;   // FIXME don't always need a whole byte
                layout.match_width_bits += 1;
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

void TableLayout::setup_gateway_layout(IR::MAU::Table::Layout &layout, IR::MAU::Table *tbl) {
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

static void setup_hash_dist(IR::MAU::Table *tbl, const PhvInfo &phv, HashDistChoices &hdc) {
    vector<HashDistReq> hash_dist_reqs;
    for (auto action : Values(tbl->actions)) {
        const IR::MAU::ActionFunctionEx *af = action->to<IR::MAU::ActionFunctionEx>();
        if (af == nullptr) continue;

        for (auto instr : af->modify_with_hash) {
            if (instr->name == "hash") {
                hash_dist_reqs.emplace_back(true, instr, nullptr);
                hash_dist_reqs.back().bits_required(phv);
            }
        }
    }
    for (auto *at : tbl->attached) {
        const IR::MAU::MAUCounter *cnt = at->to<IR::MAU::MAUCounter>();
        const IR::MAU::MAUMeter *mtr = at->to<IR::MAU::MAUMeter>();
        if (cnt != nullptr) {
            if (cnt->indirect_index && phv.field(cnt->indirect_index) != nullptr) {
                hash_dist_reqs.emplace_back(true, nullptr, cnt);
                if (hash_dist_reqs.back().bits_required(phv) > 23)
                    BUG("The size of this particular field %s is too large to be "
                         "used as an address", cnt->indirect_index);
            }
        } else if (mtr != nullptr) {
            if (mtr->indirect_index && phv.field(mtr->indirect_index) != nullptr)
                hash_dist_reqs.emplace_back(true, nullptr, mtr);
        }
    }
    hdc.total_hash_dist_reqs[tbl->name] = hash_dist_reqs;
}

/* Setting up the potential layouts for ternary, either with or without immediate
   data if immediate is possible */
void TableLayout::setup_ternary_layout_options(IR::MAU::Table *tbl, int immediate_bytes_reserved,
                                               bool has_action_profile) {
    bool no_action_data = (tbl->layout.action_data_bytes == 0);

    IR::MAU::Table::Layout *layout = new IR::MAU::Table::Layout();
    *layout = tbl->layout;
    IR::MAU::Table::LayoutOption lo(layout);
    tbl->layout_options.push_back(lo);

    if (no_action_data || has_action_profile
        || tbl->layout.action_data_bytes > 4 - immediate_bytes_reserved)
        return;

    layout = new IR::MAU::Table::Layout();
    *layout = tbl->layout;
    layout->action_data_bytes_in_overhead = tbl->layout.action_data_bytes;
    layout->overhead_bits += tbl->layout.action_data_bytes * 8;
    IR::MAU::Table::LayoutOption lo_tern(layout);
    tbl->layout_options.push_back(lo_tern);
}

/* Setting up the potential layouts for exact match, with different numbers of entries per row,
   different ram widths, and immediate data on and off */
void TableLayout::setup_layout_options(IR::MAU::Table *tbl, int immediate_bytes_reserved,
                                       bool has_action_profile) {
    bool no_action_data = (tbl->layout.action_data_bytes == 0);

    for (int entry_count = 1; entry_count < 10; entry_count++) {
        int match_group_bits = std::max(8*tbl->layout.match_bytes-8, 0) +
                               tbl->layout.overhead_bits + 4;
        int width = (entry_count * match_group_bits + 127) / 128;
        while (entry_count / width > 4)
            width++;
        while (tbl->layout.overhead_bits * entry_count > width * 64)
            width++;
        if (width > 8) break;

        IR::MAU::Table::Layout *layout = new IR::MAU::Table::Layout();
        IR::MAU::Table::Way *way = new IR::MAU::Table::Way();
        *layout = tbl->layout;
        way->match_groups = entry_count; way->width = width;
        IR::MAU::Table::LayoutOption lo(layout, way);
        tbl->layout_options.push_back(lo);
    }

    if (no_action_data || has_action_profile
        || tbl->layout.action_data_bytes > 4 - immediate_bytes_reserved)
        return;

    for (int entry_count = 1; entry_count < 10; entry_count++) {
        int match_group_bits = std::max(8*tbl->layout.match_bytes-8, 0) +
                               tbl->layout.overhead_bits + tbl->layout.action_data_bytes * 8
                               + 4;
        int width = (entry_count * match_group_bits + 127) / 128;
        while ((tbl->layout.overhead_bits + 8 * tbl->layout.action_data_bytes * entry_count)
                > width * 64)
            width++;
        if (width > 8) break;

        IR::MAU::Table::Layout *layout = new IR::MAU::Table::Layout();
        IR::MAU::Table::Way *way = new IR::MAU::Table::Way();
        *layout = tbl->layout;
        layout->action_data_bytes_in_overhead = tbl->layout.action_data_bytes;
        layout->overhead_bits += tbl->layout.action_data_bytes * 8;
        way->match_groups = entry_count; way->width = width;
        IR::MAU::Table::LayoutOption lo(layout, way);
        tbl->layout_options.push_back(lo);
    }
}

/* FIXME: This function is for the setup of a table with no match data.  This is currently hacked
   together in order to pass many of the test cases */
void TableLayout::setup_layout_option_no_match(IR::MAU::Table *tbl, int immediate_bytes_reserved) {
    IR::MAU::Table::Layout *layout = new IR::MAU::Table::Layout();
    *layout = tbl->layout;
    if (layout->action_data_bytes - immediate_bytes_reserved <= 4) {
        layout->action_data_bytes_in_overhead = layout->action_data_bytes;
    }
    if (!hdc.get_hash_dist_req(tbl).empty()) {
        tbl->layout.hash_action = true;
        layout->hash_action = true;
    }
    IR::MAU::Table::LayoutOption lo(layout);
    tbl->layout_options.push_back(lo);
}

namespace {
class VisitAttached : public Inspector {
    IR::MAU::Table::Layout &layout;
    int immediate_bytes_needed;
    int counter_vpn_bits_needed;
    int meter_vpn_bits_needed;
    bool preorder(const IR::Stateful *st) override {
        if (!st->direct) {
            if (st->instance_count <= 0)
                error("%s: No instance count in indirect %s %s", st->srcInfo, st->kind(), st->name);
            int vpn_bits_needed = std::max(10, ceil_log2(st->instance_count));
            layout.overhead_bits += vpn_bits_needed;
            if (auto *mtr = st->to<IR::Meter>()) {
                if (meter_vpn_bits_needed < vpn_bits_needed) {
                    layout.meter_overhead_bits = vpn_bits_needed;
                    meter_vpn_bits_needed = vpn_bits_needed;
                }
                if (!mtr->implementation.name) {
                    immediate_bytes_needed = 1;
                }
            } else if (st->is<IR::Counter>()) {
                if (counter_vpn_bits_needed < vpn_bits_needed) {
                    layout.counter_overhead_bits = vpn_bits_needed;
                    counter_vpn_bits_needed = vpn_bits_needed;
                }
            }
        }
        return false; }
    bool preorder(const IR::ActionProfile *ap) override {
        have_action_data = true;
        have_action_profile = true;
        if (ap->size <= 0)
            error("%s: No size count in %s %s", ap->srcInfo, ap->kind(), ap->name);
        int vpn_bits_needed = std::max(10, ceil_log2(ap->size));
        layout.overhead_bits += vpn_bits_needed;
        layout.indirect_action_overhead_bits = vpn_bits_needed;
        return false; }
    bool preorder(const IR::ActionSelector *) override {
        // TODO(cdodd) -- what does this require from the layout?
        int vpn_bits_needed = 17;  // FIXME: This is not correct
        layout.overhead_bits += vpn_bits_needed;
        layout.selector_overhead_bits = vpn_bits_needed;
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
    explicit VisitAttached(IR::MAU::Table::Layout *l) : layout(*l),
        immediate_bytes_needed(0), counter_vpn_bits_needed(0), meter_vpn_bits_needed(0) {}
    bool have_ternary_indirect = false;
    bool have_action_data = false;
    bool have_action_profile = false;
    int immediate_reserved() { return immediate_bytes_needed; }
};
}  // namespace

bool TableLayout::preorder(IR::MAU::Table *tbl) {
    LOG1("## layout table " << tbl->name);
    tbl->layout.ixbar_bytes = tbl->layout.match_bytes = tbl->layout.match_width_bits =
    tbl->layout.action_data_bytes = tbl->layout.overhead_bits = 0;
    if (tbl->match_table)
        setup_match_layout(tbl->layout, tbl);
    if ((tbl->layout.gateway = tbl->uses_gateway()))
        setup_gateway_layout(tbl->layout, tbl);
    setup_action_layout(tbl);
    setup_hash_dist(tbl, phv, hdc);
    VisitAttached attached(&tbl->layout);
    for (auto at : tbl->attached)
        at->apply(attached);
    int immediate_bytes_reserved = attached.immediate_reserved();
    if (tbl->layout.gateway)
        return true;
    else if (tbl->layout.match_width_bits == 0)
        setup_layout_option_no_match(tbl, immediate_bytes_reserved);
    else if (tbl->layout.ternary)
        setup_ternary_layout_options(tbl, immediate_bytes_reserved, attached.have_action_profile);
    else
        setup_layout_options(tbl, immediate_bytes_reserved, attached.have_action_profile);
    return true;
}
