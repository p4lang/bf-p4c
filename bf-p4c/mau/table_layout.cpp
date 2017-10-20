#include "bf-p4c/mau/table_layout.h"

#include <set>
#include "bf-p4c/mau/input_xbar.h"
#include "bf-p4c/mau/table_format.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/bitops.h"
#include "lib/log.h"

Visitor::profile_t TableLayout::init_apply(const IR::Node *root) {
    alloc_done = phv.alloc_done();
    lc.clear();
    return MauModifier::init_apply(root);
}

bool TableLayout::backtrack(trigger &trig) {
    return (trig.is<IXBar::failure>() || trig.is<ActionFormat::failure>()) && !alloc_done;
}

void TableLayout::setup_match_layout(IR::MAU::Table::Layout &layout, const IR::MAU::Table *tbl) {
    if (auto k = tbl->match_table->getConstantProperty("size"))
        layout.entries = k->asInt();
    else if (auto k = tbl->match_table->getConstantProperty("min_size"))
        layout.entries = k->asInt();
    layout.match_width_bits = 0;
    if (tbl->match_key.empty())
        return;

    auto annot = tbl->match_table->getAnnotations();
    if (auto s = annot->getSingle("ternary")) {
        auto pragma_val =  s->expr.at(0)->to<IR::Constant>()->asInt();
        if (pragma_val == 1)
            layout.ternary = true;
        else
            ::warning("Pragma ternary ignored for table %s because value is not 1", tbl->name);
    } else {
        for (auto ixbar_read : tbl->match_key) {
            if (ixbar_read->match_type.name == "ternary" || ixbar_read->match_type.name == "lpm") {
                layout.ternary = true;
                break;
            }
        }
    }

    safe_vector<int> byte_sizes;

    for (auto ixbar_read : tbl->match_key) {
        if (ixbar_read->match_type.name == "selector") continue;
        bitrange bits = { 0, 0 };
        auto *field = phv.field(ixbar_read->expr, &bits);
        int bytes = 0;
        if (field) {
            /* FIXME -- if a field is allocated to non-contiguous bits of a byte,
             * this will count that byte twice, when it is only needed once.  The
             * match layout in asm_output will likewise lay it out twice, so this
             * is consistent.  Should fix PHV alloc to not make such bad allocations */
            field->foreach_byte(bits, [&](const PHV::Field::alloc_slice &sl) {
                bytes++;
                byte_sizes.push_back(sl.width);
            });
            if (bytes == 0)  // FIXME: Better sanity check needed?
                ERROR("Field " << field->name << " allocated to tagalong but used in MAU pipe");

            layout.ixbar_bytes += bytes;
            layout.match_bytes += bytes;
            layout.match_width_bits += bits.size();
        } else {
            BUG("unexpected reads expression %s", ixbar_read->expr);
        }
    }

    if (!layout.ternary) {
        int ghost_bits_left = TableFormat::RAM_GHOST_BITS;
        std::sort(byte_sizes.begin(), byte_sizes.end());
        for (auto byte_size : byte_sizes) {
            if (ghost_bits_left >= byte_size) {
                ghost_bits_left -= byte_size;
                layout.ghost_bytes++;
                layout.match_bytes--;
            }
        }
    }

    int hit_actions = 0;
    for (auto act : Values(tbl->actions)) {
        if (!act->miss_action_only)
            hit_actions++;
    }

    layout.overhead_bits = ceil_log2(hit_actions);
}

class GatewayLayout : public MauInspector {
    IR::MAU::Table::Layout &layout;
    std::set<cstring> added;
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

static void setup_action_layout(IR::MAU::Table *tbl, LayoutChoices &lc, const PhvInfo &phv,
                                bool alloc_done) {
    tbl->layout.action_data_bytes = 0;
    ActionFormat::Use af_use;
    ActionFormat af(tbl, phv, alloc_done);
    af.allocate_format(&af_use);
    tbl->layout.action_data_bytes = af_use.action_data_bytes;
    lc.total_action_formats[tbl->name] = af_use;
}

/* Setting up the potential layouts for ternary, either with or without immediate
   data if immediate is possible */
void TableLayout::setup_ternary_layout_options(IR::MAU::Table *tbl, int immediate_bytes_reserved) {
    bool no_action_data = (tbl->layout.action_data_bytes == 0);

    IR::MAU::Table::Layout layout = tbl->layout;
    LayoutOption lo(layout);
    lc.total_layout_options[tbl->name].push_back(lo);

    if (no_action_data || tbl->layout.indirect_action_addr_bits > 0
        || tbl->layout.action_data_bytes > 4 - immediate_bytes_reserved)
        return;

    // Potential layout with immediate data
    layout.action_data_bytes_in_overhead = tbl->layout.action_data_bytes;
    layout.overhead_bits += tbl->layout.action_data_bytes * 8;
    LayoutOption lo_tern(layout);
    lc.total_layout_options[tbl->name].push_back(lo_tern);
}

void TableLayout::setup_exact_match(IR::MAU::Table *tbl, int action_data_bytes) {
    for (int entry_count = 1; entry_count < 10; entry_count++) {
        int match_group_bits = 8*tbl->layout.match_bytes +
                               tbl->layout.overhead_bits + action_data_bytes * 8 + 4;
        LOG1("Match group bits " << match_group_bits);
        int width = (entry_count * match_group_bits + 127) / 128;
        while (entry_count / width > 4)
            width++;
        while (((tbl->layout.overhead_bits + 8 * action_data_bytes) * entry_count)
                > width * 64)
            width++;
        if (width > 8) break;

        IR::MAU::Table::Layout layout = tbl->layout;
        IR::MAU::Table::Way way;
        layout.action_data_bytes_in_overhead = action_data_bytes;
        layout.overhead_bits += action_data_bytes * 8;
        way.match_groups = entry_count; way.width = width;
        LayoutOption lo(layout, way);
        lc.total_layout_options[tbl->name].push_back(lo);
    }
}

/* Setting up the potential layouts for exact match, with different numbers of entries per row,
   different ram widths, and immediate data on and off */
void TableLayout::setup_layout_options(IR::MAU::Table *tbl, int immediate_bytes_reserved) {
    bool no_action_data = (tbl->layout.action_data_bytes == 0);
    setup_exact_match(tbl, 0);
    if (no_action_data || tbl->layout.indirect_action_addr_bits > 0
        || tbl->layout.action_data_bytes > 4 - immediate_bytes_reserved)
        return;
    // Potential layouts with immediate data
    setup_exact_match(tbl, tbl->layout.action_data_bytes);
}

/** Checks to see if the table has a hash distribution access somewhere */
class GetHashDistReqs : public MauInspector {
    bool _hash_dist_needed;
    bool preorder(const IR::MAU::HashDist *) {
        _hash_dist_needed = true;
        return false;
    }

 public:
    bool is_hash_dist_needed() { return _hash_dist_needed; }
    GetHashDistReqs() : _hash_dist_needed(false) { }
};

/* FIXME: This function is for the setup of a table with no match data.  This is currently hacked
   together in order to pass many of the test cases.  This needs to have some standardization
   within the assembly so that all tables that do not require match can possibly work */
void TableLayout::setup_layout_option_no_match(IR::MAU::Table *tbl, int immediate_bytes_reserved) {
    IR::MAU::Table::Layout layout = tbl->layout;
    if (layout.action_data_bytes - immediate_bytes_reserved <= 4) {
        layout.action_data_bytes_in_overhead = layout.action_data_bytes;
    }

    GetHashDistReqs ghdr;
    tbl->attached.apply(ghdr);
    tbl->actions.apply(ghdr);
    if (ghdr.is_hash_dist_needed()) {
        tbl->layout.hash_action = true;
        layout.hash_action = true;
    }
    LayoutOption lo(layout);
    lc.total_layout_options[tbl->name].push_back(lo);
}

namespace {
class VisitAttached : public Inspector {
    IR::MAU::Table::Layout &layout;
    int immediate_bytes_needed;
    int counter_addr_bits_needed = 0;
    int meter_addr_bits_needed = 0;
    bool counter_set = false;
    bool meter_set = false;
    bool register_set = false;
    cstring counter_addr_name;
    cstring meter_addr_name;

    /** The purpose of this function is to determine whether or not the tables using stateful
     *  tables are allowed within Tofino.  Essentially the constraints are the following:
     *  - Multiple counters, meters, or registers can be found on a table if they use the
     *    same exact addressing scheme.
     *  - A table can only have a meter, a stateful alu, or a selector, as they use
     *    the same address in match central
     *  - Indirect addresses for twoport tables require a per flow enable bit as well
     */
    void interpret_stateful(const IR::MAU::Synth2Port *sp, cstring &sp_addr_name, bool &sp_set,
                            int &sp_addr_bits_needed, int *layout_addr_bits) {
        if (sp->direct) {
            if (sp_set && sp_addr_bits_needed > 0)
               error("Tofino does not allow counter to use different address schemes on one "
                    "table.  Counters %s and %s have different address schemes",
                     sp_addr_name, sp->name);
        } else {
            if (sp->size <= 0)
                error("%s: No instance count in indirect %s %s", sp->srcInfo, sp->kind(),
                      sp->name);
            if (sp_set && sp_addr_bits_needed == 0)
                error("Tofino does not allow meters to use different address schemes on one "
                    "table.  Meters %s and %s have different address schemes",
                     sp_addr_name, sp->name);

            int addr_bits_needed = std::max(10, ceil_log2(sp->size)) + 1;
            int addition_to_overhead = addr_bits_needed;
            int diff;
            if ((diff = addr_bits_needed - sp_addr_bits_needed) > 0) {
                addition_to_overhead = diff;
                *(layout_addr_bits) = addr_bits_needed;
            }
            layout.overhead_bits += addition_to_overhead;
        }
        sp_set = true;
        sp_addr_name = sp->name;
    }

    bool preorder(const IR::MAU::Counter *cnt) override {
        interpret_stateful(cnt, counter_addr_name, counter_set, counter_addr_bits_needed,
                           &(layout.counter_addr_bits));
        return false;
    }

    bool preorder(const IR::MAU::Meter *mtr) override {
        if ((!meter_set && meter_addr_bits_needed > 0) || register_set) {
            BUG("Table cannot have both attached tables %s and %s as they use the same "
                "address hardware", meter_addr_name, mtr->name);
        }
        interpret_stateful(mtr, meter_addr_name, meter_set, meter_addr_bits_needed,
                           &(layout.meter_addr_bits));
        return false;
    }

    bool preorder(const IR::MAU::StatefulAlu *salu) override {
        if ((!register_set && meter_addr_bits_needed > 0) || meter_set) {
            BUG("Table cannot have both attached tables %s and %s as they use the same "
                "address hardware", meter_addr_name, salu->name);
        }
        interpret_stateful(salu, meter_addr_name, register_set, meter_addr_bits_needed,
                           &(layout.meter_addr_bits));
        return false;
    }
    bool preorder(const IR::MAU::Selector *as) override {
        int vpn_bits_needed =  11;  // FIXME: Eventually based off of pool sizes
        if (meter_addr_bits_needed > 0 || meter_set || register_set)
            BUG("Table cannot have both attached tables %s and %s as they use the same "
                "address hardware", meter_addr_name, as->name);
        meter_addr_name = as->name;
        layout.overhead_bits += vpn_bits_needed;
        layout.meter_addr_bits = vpn_bits_needed;
        return false; }
    bool preorder(const IR::MAU::TernaryIndirect *) override {
        BUG("No ternary indirect should exist before table placement");
        return false; }
    bool preorder(const IR::MAU::ActionData *ad) override {
        BUG_CHECK(!ad->direct, "Cannot have a direct action data table before table placement");
        if (ad->size <= 0)
            error("%s: No size count in %s %s", ad->srcInfo, ad->kind(), ad->name);
        int vpn_bits_needed = std::max(10, ceil_log2(ad->size)) + 1;
        layout.overhead_bits += vpn_bits_needed;
        layout.indirect_action_addr_bits = vpn_bits_needed;
        return false;
    }
    bool preorder(const IR::MAU::IdleTime *) override {
        return false;
    }
    bool preorder(const IR::Attached *att) override {
        BUG("Unknown attached table type %s", typeid(*att).name()); }

 public:
    explicit VisitAttached(IR::MAU::Table::Layout *l) : layout(*l),
        immediate_bytes_needed(0) {}
    bool have_ternary_indirect = false;
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
    setup_action_layout(tbl, lc, phv, alloc_done);
    VisitAttached attached(&tbl->layout);
    for (auto at : tbl->attached) {
        at->apply(attached);
    }
    int immediate_bytes_reserved = attached.immediate_reserved();
    if (tbl->layout.gateway)
        return true;
    else if (tbl->layout.match_width_bits == 0)
        setup_layout_option_no_match(tbl, immediate_bytes_reserved);
    else if (tbl->layout.ternary)
        setup_ternary_layout_options(tbl, immediate_bytes_reserved);
    else
        setup_layout_options(tbl, immediate_bytes_reserved);
    return true;
}


bool TableLayout::preorder(IR::MAU::Action *act) {
    auto tbl = findContext<IR::MAU::Table>();
    if (tbl->layout.no_match_hit_path())
        return false;
    GetHashDistReqs ghdr;
    act->apply(ghdr);
    if (!ghdr.is_hash_dist_needed())
        return false;

    ERROR_CHECK(!act->init_default, "%s: Cannot specify %s as the default action, as it requires "
                "the hash distribution unit", act->srcInfo, act->name);
    ERROR_CHECK(!tbl->layout.no_match_miss_path(), "%s: This table with no key cannot have the "
                "action %s as an action here, because it requires hash distribution, which "
                "utilizes the hit path in Tofino, while the driver configures the miss path",
                act->srcInfo, act->name);

    act->default_allowed = false;
    act->disallowed_reason = "USES_HASH_DIST";
    return false;
}
