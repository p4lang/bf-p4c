#include "bf-p4c/mau/table_layout.h"

#include <set>
#include "bf-p4c/mau/input_xbar.h"
#include "bf-p4c/mau/memories.h"
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

/** Algorithmic TCAM is a third type of table, in the same vein as ternary and exact.  An
 *  ATCAM table is a ternary table that Tofino can implement using exact hardware, specifically
 *  the SRAM array.
 *
 *  A ternary match requires two things that a normal exact match cannot.  A ternary match
 *  must be able to specify a don't care for any bit, and must have a priority system in order
 *  to rank the matches.  By using particular features of the SRAM array, the Tofino target
 *  can create these features.
 *
 *  The don't care bit is possible due by containing any ternary match data twice in the RAM
 *  line.  The match data is encoded to match as 0, 1, or don't care.  This is briefly
 *  described in section 6.4.2.2 Algorithmic TCAM section of the Tofino uArch, while the
 *  encoding scheme for ternary match in general is described in section 6.3.1 TCAM Data
 *  Representation.  The terms s0q1 and s1q0 describe these different encodings.
 *
 *  Priority is engineered through the placement of RAMs in a row.  If the RAMs are in the same
 *  row, and belong to the same ATCAM table, then if multiple tables match, as is possible
 *  within a single TCAM table, the one closer to the edge of the chip will have higher
 *  priority and will be the match.  If the algorithm cannot fit all of the entries within
 *  a single row, then the table will be split into multiple logical tables, and will use
 *  hit/miss predication of these logical tables in order to generate priority across tables.
 *  This is described by section 1.4.5 Algorithmic TCAM Overview in the uArch.
 *
 *  An ATCAM table requires a partition index.  This is an field in the key that must be
 *  an exact match.  This partition index is used as an identity hash to find the correct
 *  partition within the massive ATCAM table.
 *
 *  The user can also specify the number of partitions. In a standard TCAM, the size of the
 *  table specifies how many entries are looked up (logically) simultaneously.  In an ATCAM
 *  table, the number of entries that are looked up simultaneously is:
 *      table_size / number_of_partitions
 *
 *  If no number of partitions is specified, then the number of partitions is:
 *      2 ^ (partition index bits)
 */
void TableLayout::check_for_atcam(IR::MAU::Table::Layout &layout, const IR::MAU::Table *tbl,
                                  cstring &partition_index, const PhvInfo& phv) {
    auto annot = tbl->match_table->getAnnotations();
    bool index_found = false;
    bool partitions_found = false;
    int partition_count = -1;

    if (auto s = annot->getSingle("atcam_partition_index")) {
        auto pragma_val = s->expr.at(0)->to<IR::StringLiteral>();
        ERROR_CHECK(pragma_val != nullptr, "%s: Please provide a valid atcam_partition_index "
                    "for table %s", tbl->srcInfo, tbl->name);
        if (pragma_val)
            partition_index = pragma_val->value;
        index_found = true;
    }

    if (auto s = annot->getSingle("atcam_number_partitions")) {
        auto pragma_val = s->expr.at(0)->to<IR::Constant>();
        ERROR_CHECK(pragma_val != nullptr, "%s: Please provide a valid atcam_number_partitions "
                    "for table %s", tbl->srcInfo, tbl->name);
        if (pragma_val) {
            partition_count = pragma_val->asInt();
            ERROR_CHECK(partition_count > 0, "%s: The number of partitions specified for table %s "
                        "has to be greater than 0", tbl->srcInfo, tbl->name);
        }
        partitions_found = true;
    }

    if (partitions_found) {
        WARN_CHECK(index_found, "%s: Number of partitions specified for table %s but will be "
                   "ignored because no partition index specified", tbl->srcInfo, tbl->name);
    }

    if (index_found) {
        if (tbl->gress == INGRESS)
            partition_index = "ingress::" + partition_index;
        else
            partition_index = "egress::" + partition_index;
        ERROR_CHECK(phv.field(partition_index) != nullptr, "%s: The partition index %s for table "
                    "%s is not found in the PHV", tbl->srcInfo, partition_index, tbl->name);
    }

    layout.atcam = (index_found);
    if (partitions_found)
        layout.partition_count = partition_count;
}

void TableLayout::check_for_alpm(IR::MAU::Table::Layout &, const IR::MAU::Table *tbl,
                                  cstring &partition_index) {
    auto hdr_instance_name = tbl->name + "__metadata";
    auto pidx_field_name = tbl->name + "_partition_index";
    partition_index = hdr_instance_name + "." + pidx_field_name;
    ERROR_CHECK(phv.field(partition_index) != nullptr, "%s: The partition index %s for table "
                "%s is not found in the PHV", tbl->srcInfo, partition_index, tbl->name);
}


void TableLayout::check_for_ternary(IR::MAU::Table::Layout &layout, const IR::MAU::Table *tbl) {
    auto annot = tbl->match_table->getAnnotations();
    if (auto s = annot->getSingle("ternary")) {
        if (s->expr.size() <= 0) {
            ::warning("Pragma ternary ignored for table %s because value is undefined", tbl->name);
        } else {
            auto pragma_val =  s->expr.at(0)->to<IR::Constant>();
            ERROR_CHECK(pragma_val != nullptr,
                "%s: Cannot interpret the ternary pragma on table %s", tbl->srcInfo, tbl->name);
            if (pragma_val->asInt() == 1)
                layout.ternary = true;
            else
                ::warning("Pragma ternary ignored for table %s because value is not 1", tbl->name);
        }
    } else {
        for (auto ixbar_read : tbl->match_key) {
            if (ixbar_read->match_type.name == "ternary" || ixbar_read->match_type.name == "lpm") {
                layout.ternary = true;
                break;
            }
        }
        for (auto ixbar_read : tbl->match_key) {
            if (ixbar_read->match_type == "range") {
                layout.ternary = true;
                layout.has_range = true;
                break;
            }
        }
    }
}

void TableLayout::setup_match_layout(IR::MAU::Table::Layout &layout, const IR::MAU::Table *tbl) {
    if (tbl->layout.pre_classifier)
        layout.entries = tbl->layout.pre_classifer_number_entries;
    else if (auto k = tbl->match_table->getConstantProperty("size"))
        layout.entries = k->asInt();
    else if (auto k = tbl->match_table->getConstantProperty("min_size"))
        layout.entries = k->asInt();
    layout.match_width_bits = 0;
    if (tbl->match_key.empty())
        return;

    cstring partition_index;
    if (layout.alpm)
        check_for_alpm(layout, tbl, partition_index);
    if (!layout.atcam)
        check_for_atcam(layout, tbl, partition_index, phv);
    if (!layout.atcam)
        check_for_ternary(layout, tbl);

    safe_vector<int> byte_sizes;
    bool partition_found = false;

    /** Because the input xbar allocates by container bytes, the estimate should also be
     *  based on container bytes rather than field bytes.  The point of this byte_impact
     *  maps is to build container bytes and run analysis on that.
     */
    std::map<MatchByteKey, safe_vector<le_bitrange>> byte_impacts;
    for (auto ixbar_read : tbl->match_key) {
        if (ixbar_read->match_type.name == "selector") continue;
        le_bitrange bits = { 0, 0 };
        auto *field = phv.field(ixbar_read->expr, &bits);
        int match_multiplier = 1;
        int ixbar_multiplier = 1;

        int bytes = 0;
        if (field) {
            /* FIXME -- if a field is allocated to non-contiguous bits of a byte,
             * this will count that byte twice, when it is only needed once.  The
             * match layout in asm_output will likewise lay it out twice, so this
             * is consistent.  Should fix PHV alloc to not make such bad allocations */
            bool is_partition = false;
            if (layout.atcam) {
                if (field->name == partition_index) {
                    match_multiplier = 0;
                    is_partition = true;
                    partition_found = true;
                    ERROR_CHECK(ixbar_read->match_type.name == "exact", "%s: The partition index "
                                "of algorithmic TCAM table %s must be an exact field");
                } else if (ixbar_read->match_type.name == "ternary" ||
                           ixbar_read->match_type.name == "lpm") {
                    match_multiplier = 2;
                }
            }

            if (ixbar_read->match_type.name == "range") {
                ixbar_multiplier = 2;
                match_multiplier = 2;
            }

            // FIXME: This will currently not work before PHV allocation, because the
            // foreach_byte over alloc_slices only works if the alloc_slice has been allocated
            // If we move PHV allocation back to after Table Placement, this will need to
            // change
            field->foreach_byte(bits, [&](const PHV::Field::alloc_slice &sl) {
                cstring name = sl.container.toString();
                int lo = (sl.container_bit / 8) * 8;
                MatchByteKey mbk(name, lo, ixbar_multiplier, match_multiplier);
                byte_impacts[mbk].push_back(sl.container_bits());
                bytes++;
            });

            if (bytes == 0)  // FIXME: Better sanity check needed?
                ERROR("Field " << field->name << " allocated to tagalong but used in MAU pipe");

            if (is_partition) {
                layout.partition_bits = bits.size();
                // If partition count is set and requires less bits than
                // partition index, set partition bits to lesser value. Rams are
                // determined based on this value and below check will ensure
                // select mask generated in ways is correct
                if (layout.partition_count > 0)
                    layout.partition_bits = std::min(layout.partition_bits,
                                            ceil_log2(layout.partition_count));
            }
        } else {
            BUG("unexpected reads expression %s", ixbar_read->expr);
        }
    }

    for (auto entry : byte_impacts) {
        safe_vector<bitvec> individual_bytes;
        auto &mbk = entry.first;

        for (auto range : entry.second) {
            bitvec entry_range(range.lo, range.size());
            auto it = individual_bytes.begin();
            while (it != individual_bytes.end()) {
                if ((*it & entry_range).empty())
                    break;
                it++;
            }
            if (it == individual_bytes.end())
                individual_bytes.push_back(entry_range);
            else
                *it |= entry_range;
        }

        for (auto bv : individual_bytes) {
            layout.ixbar_bytes += mbk.ixbar_multiplier;
            layout.match_bytes += mbk.match_multiplier;
            layout.ixbar_width_bits += bv.popcount() * mbk.ixbar_multiplier;
            layout.match_width_bits += bv.popcount() * mbk.match_multiplier;
            byte_sizes.push_back(bv.popcount());
        }
    }

    if (layout.atcam) {
        ERROR_CHECK(partition_found, "%s: Table %s is specified to be an atcam, but partition "
                    "index %s is not found within the table key", tbl->srcInfo, tbl->name,
                    partition_index);
        if (partition_found) {
            int possible_partitions = 1 << layout.partition_bits;
            ERROR_CHECK(layout.partition_count <= possible_partitions, "%s: Table %s has "
                        "specified %d partitions, but the actual possible partitions due to the "
                        "number of bits in the partition index is %d", tbl->srcInfo, tbl->name,
                        layout.partition_count, possible_partitions);
            if (layout.partition_count == 0)
                layout.partition_count = possible_partitions;
        }
    }

    if (!layout.ternary && !layout.atcam) {
        int ghost_bits_left = TableFormat::RAM_GHOST_BITS;
        std::sort(byte_sizes.begin(), byte_sizes.end());
        for (auto byte_size : byte_sizes) {
            if (ghost_bits_left >= byte_size) {
                ghost_bits_left -= byte_size;
                layout.ghost_bytes++;
                layout.match_bytes--;
            }
        }
        layout.match_width_bits -= TableFormat::RAM_GHOST_BITS;
    }
}

int TableLayout::get_hit_actions(const IR::MAU::Table *tbl) {
    int hit_actions = 0;
    for (auto act : Values(tbl->actions)) {
        if (!act->miss_action_only)
            hit_actions++;
    }
    return hit_actions;
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

/** Initializes the list of action formats that are possible for the table, with different
 *  layouts in both action data tables as well as immediate
 */
void TableLayout::setup_action_layout(IR::MAU::Table *tbl) {
    tbl->layout.action_data_bytes = 0;
    safe_vector<ActionFormat::Use> uses;
    ActionFormat af(tbl, phv, alloc_done);
    // Action Profiles cannot have any immediate data
    af.allocate_format(uses, tbl->layout.action_addr_bits == 0);
    lc.total_action_formats[tbl->name] = uses;
    tbl->layout.action_data_bytes = af.action_data_bytes;
}

/* Setting up the potential layouts for ternary, either with or without immediate
   data if immediate is possible */
void TableLayout::setup_ternary_layout_options(IR::MAU::Table *tbl) {
    LOG2("Setup TCAM match layouts " << tbl->name);
    if (get_hit_actions(tbl) == 1)
        tbl->layout.overhead_bits++;

    int index = 0;
    for (auto &use : lc.get_action_formats(tbl)) {
        IR::MAU::Table::Layout layout = tbl->layout;
        layout.action_data_bytes_in_table = use.action_data_bytes[ActionFormat::ADT];
        layout.immediate_bits = use.immediate_bits();
        layout.overhead_bits += use.immediate_bits();
        LayoutOption lo(layout, index);
        lc.total_layout_options[tbl->name].push_back(lo);
        index++;
    }
}

/**
 * Responsible for the calculation of the potential layouts to try, and later adapt
 * if necessary in the try_place_table algorithm.
 *
 * Constraints generally come from the following:
 *    1. 128 bits maximally can be packed per RAM
 *    2. 16 individual bytes / (with some exceptions for the upper nibbles), can be
 *       matched in the algorithm.
 *    3. 64 bits of overhead are allowed maximally per RAM.  Overhead is any information
 *       that has to head to match central.
 *    4. At most 5 entries can be packed per RAM line.
 *
 * Lastly, the width <= 8, as that is the maximal width of the RAM array on which to
 * perform a wide match.
 */
void TableLayout::setup_exact_match(IR::MAU::Table *tbl, int action_data_bytes_in_table,
                                    int immediate_bits, int index) {
    auto annot = tbl->match_table->getAnnotations();
    int pack_val = 0;
    if (auto s = annot->getSingle("pack")) {
        ERROR_CHECK(s->expr.size() > 0, "%s: pack pragma has no value for table %s",
                    tbl->srcInfo, tbl->name);
        auto pragma_val = s->expr.at(0)->to<IR::Constant>();
        ERROR_CHECK(pragma_val != nullptr, "%s: pack pragma value for table %s must be a "
                    "constant", tbl->srcInfo, tbl->name);
        if (pragma_val) {
            pack_val = pragma_val->asInt();
            if (pack_val < MIN_PACK || pack_val > MAX_PACK) {
                ::warning("%s: The provide pack pragma value for table %s is %d, when the "
                          "compiler only supports pack values between %d and %d", tbl->srcInfo,
                          tbl->name, pack_val, MIN_PACK, MAX_PACK);
                pack_val = 0;
            }
        }
    }

    for (int entry_count = MIN_PACK; entry_count <= MAX_PACK; entry_count++) {
        if (pack_val > 0 && entry_count != pack_val)
            continue;

        int single_overhead_bits = immediate_bits + tbl->layout.overhead_bits;
        int single_entry_bits = single_overhead_bits;
        single_entry_bits += TableFormat::VERSION_BITS;
        single_entry_bits += tbl->layout.match_width_bits;

        int total_bits = entry_count * single_entry_bits;
        int total_bytes = entry_count * tbl->layout.match_bytes;
        int total_overhead_bits = entry_count * single_overhead_bits;

        int bit_limit_width = (total_bits + TableFormat::SINGLE_RAM_BITS - 1)
                              / TableFormat::SINGLE_RAM_BITS;
        int byte_limit_width = (total_bytes + TableFormat::SINGLE_RAM_BYTES - 1)
                               / TableFormat::SINGLE_RAM_BYTES;
        int overhead_width = (total_overhead_bits + TableFormat::OVERHEAD_BITS - 1)
                             / TableFormat::OVERHEAD_BITS;
        int pack_width = (entry_count + MAX_ENTRIES_PER_ROW - 1)
                          / MAX_ENTRIES_PER_ROW;
        int width = std::max({ bit_limit_width, byte_limit_width, overhead_width, pack_width });

        int mod_value;
        int min_value = 0;

        if (width > entry_count) {
            mod_value = width % entry_count;
            min_value = entry_count;
        } else {
            mod_value = entry_count % width;
            min_value = width;
         }

        // Skip potential doubling of layouts: i.e. if the layout is 2 entries per RAM row,
        // and 1 RAM wide, then there is no point to adding the double, 4 entries per RAM row,
        // and 2 RAM wide.  This is the same packing, and wider matches are more constrained
        if (mod_value == 0 && min_value != 1 && pack_val == 0)
            continue;

        if (width > Memories::SRAM_ROWS) break;

        LOG2(" Potential Layout Option: { pack : " << entry_count << ", width : " << width
             << ", action data table bytes : " << action_data_bytes_in_table
             << ", immediate bits : " << immediate_bits << " }");
        IR::MAU::Table::Layout layout = tbl->layout;
        IR::MAU::Table::Way way;
        layout.action_data_bytes_in_table = action_data_bytes_in_table;
        layout.immediate_bits = immediate_bits;
        layout.overhead_bits += immediate_bits;
        way.match_groups = entry_count;
        way.width = width;
        LayoutOption lo(layout, way, index);
        lc.total_layout_options[tbl->name].push_back(lo);
    }
}

/* Setting up the potential layouts for exact match, with different numbers of entries per row,
   different ram widths, and immediate data on and off */
void TableLayout::setup_layout_options(IR::MAU::Table *tbl) {
    LOG2("Determining SRAM match layouts " << tbl->name);
    int index = 0;
    for (auto &use : lc.get_action_formats(tbl)) {
        setup_exact_match(tbl, use.action_data_bytes[ActionFormat::ADT],
                          use.immediate_bits(), index);
        index++;
    }
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
void TableLayout::setup_layout_option_no_match(IR::MAU::Table *tbl) {
    LOG2("Determining no match table layouts " << tbl->name);
    GetHashDistReqs ghdr;
    tbl->attached.apply(ghdr);
    tbl->actions.apply(ghdr);
    if (ghdr.is_hash_dist_needed()) {
        tbl->layout.hash_action = true;
    }

    // No match tables are required to have only one layout option in a later pass, so the
    // algorithm picks the action format that has the most immediate.  This is the option
    // that is preferred generally, but not always, if somehow it couldn't fit on the action
    // data bus.  Action data bus allocation could properly be optimized a lot more before this
    // choice would have to be made
    auto uses = lc.get_action_formats(tbl);
    auto &use = uses.back();
    IR::MAU::Table::Layout layout = tbl->layout;
    layout.immediate_bits = use.immediate_bits();
    layout.action_data_bytes_in_table = use.action_data_bytes[ActionFormat::ADT];
    layout.overhead_bits += use.immediate_bits();
    LayoutOption lo(layout, uses.size() - 1);
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
               error("Tofino does not allow %s to use different address schemes on one "
                    "table.  %s and %s have different address schemes",
                     sp->kind(), sp_addr_name, sp->name);
        } else {
            if (sp->size <= 0)
                error("%s: No instance count in indirect %s %s", sp->srcInfo, sp->kind(),
                      sp->name);
            if (sp_set && sp_addr_bits_needed == 0)
                error("Tofino does not allow %s to use different address schemes on one "
                    "table.  %s and %s have different address schemes",
                     sp->kind(), sp_addr_name, sp->name);
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
        ERROR_CHECK(!meter_set, "Currently the compiler is not supporting multiple meters "
                    "on a single table, as the color will overwrite each other");
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
        if (salu->instruction.size() > 1) {
            layout.meter_type_bits = salu->instruction.size() > 2 ? 2 : 1;
            layout.overhead_bits += layout.meter_type_bits; }
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
        layout.action_addr_bits = vpn_bits_needed;
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

void TableLayout::setup_instr_and_next(IR::MAU::Table::Layout &layout, const IR::MAU::Table *tbl) {
    layout.total_actions = tbl->actions.size();
    int action_count = get_hit_actions(tbl);
    if (get_hit_actions(tbl) > 0) {
        if (get_hit_actions(tbl) <= TableFormat::IMEM_MAP_TABLE_ENTRIES)
            layout.overhead_bits += ceil_log2(action_count);
        else
            layout.overhead_bits += TableFormat::FULL_IMEM_ADDRESS_BITS;
    }

    if (tbl->action_chain() && get_hit_actions(tbl) > TableFormat::NEXT_MAP_TABLE_ENTRIES) {
        int next_tables = tbl->action_next_paths();
        if (!tbl->has_default_path())
            next_tables++;
        if (next_tables <= TableFormat::NEXT_MAP_TABLE_ENTRIES) {
            layout.overhead_bits += ceil_log2(next_tables);
        } else {
            layout.overhead_bits += TableFormat::FULL_NEXT_TABLE_BITS;
        }
    }
}

bool TableLayout::preorder(IR::MAU::Table *tbl) {
    LOG1("## layout table " << tbl->name);
    tbl->layout.ixbar_bytes = tbl->layout.match_bytes = tbl->layout.match_width_bits =
    tbl->layout.action_data_bytes = tbl->layout.overhead_bits = 0;
    setup_instr_and_next(tbl->layout, tbl);
    if (tbl->match_table)
        setup_match_layout(tbl->layout, tbl);
    if ((tbl->layout.gateway = tbl->uses_gateway()))
        setup_gateway_layout(tbl->layout, tbl);
    VisitAttached visit_attached(&tbl->layout);
    tbl->attached.apply(visit_attached);
    setup_action_layout(tbl);
    if (tbl->layout.gateway)
        return true;
    else if (tbl->layout.no_match_data())
        setup_layout_option_no_match(tbl);
    else if (tbl->layout.ternary)
        setup_ternary_layout_options(tbl);
    else
        setup_layout_options(tbl);
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
    act->disallowed_reason = "uses_hash_dist";
    return false;
}

bool TableLayout::preorder(IR::MAU::InputXBarRead *read) {
    auto tbl = findContext<IR::MAU::Table>();
    if (tbl->layout.atcam) {
        cstring partition_index;
        if (tbl->layout.alpm) {
            auto hdr_instance_name = tbl->name + "__metadata";
            auto pidx_field_name = tbl->name + "_partition_index";
            partition_index = hdr_instance_name + "." + pidx_field_name;
        } else {
            auto annot = tbl->match_table->getAnnotations();
            auto s = annot->getSingle("atcam_partition_index");
            partition_index = s->expr.at(0)->to<IR::StringLiteral>()->value;
            if (VisitingThread(this) == INGRESS)
                partition_index = "ingress::" + partition_index;
            else
                partition_index = "egress::" + partition_index;
        }
        if (phv.field(read->expr)->name == partition_index)
            read->partition_index = true;
    }
    return false;
}
