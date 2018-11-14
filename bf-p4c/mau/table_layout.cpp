#include "bf-p4c/mau/table_layout.h"
#include <math.h>

#include <set>
#include "bf-p4c/mau/input_xbar.h"
#include "bf-p4c/mau/memories.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/mau/resource_estimate.h"
#include "bf-p4c/mau/table_format.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/bitops.h"
#include "lib/log.h"

Visitor::profile_t DoTableLayout::init_apply(const IR::Node *root) {
    alloc_done = phv.alloc_done();
    return MauModifier::init_apply(root);
}

bool DoTableLayout::backtrack(trigger &trig) {
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
void DoTableLayout::check_for_atcam(IR::MAU::Table::Layout &layout, const IR::MAU::Table *tbl,
                                  cstring &partition_index, const PhvInfo& phv) {
    auto annot = tbl->match_table->getAnnotations();
    bool index_found = false;
    bool partitions_found = false;
    int partition_count = -1;

    if (auto s = annot->getSingle("atcam_partition_index")) {
        auto pragma_val = s->expr.at(0)->to<IR::StringLiteral>();
        ERROR_CHECK(pragma_val != nullptr, "%s: Please provide a valid atcam_partition_index "
                    "for table %s", tbl->srcInfo, tbl->name);
        if (pragma_val) {
            // The pragma name may not be fully qualified, eg. "bar.f" instead
            // of the full "foo.bar.f".  PHV::Field objects use fully qualified
            // names, but `phv.field()` can look up partial names; use that to
            // look up the Field object using the partial name from the
            // annotation, so that all name comparisons are done using
            // fully-qualified names.
            auto gress = cstring::to_cstring(tbl->gress);
            auto* partition_index_field = phv.field(gress + "::" + pragma_val->value);
            if (partition_index_field) {
                partition_index = partition_index_field->name;
                index_found = true; } }
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

void DoTableLayout::check_for_alpm(IR::MAU::Table::Layout &, const IR::MAU::Table *tbl,
                                  cstring &partition_index) {
    auto hdr_instance_name = tbl->name + "__metadata";
    auto pidx_field_name = tbl->name + "_partition_index";
    partition_index = hdr_instance_name + "." + pidx_field_name;
    ERROR_CHECK(phv.field(partition_index) != nullptr, "%s: The partition index %s for table "
                "%s is not found in the PHV", tbl->srcInfo, partition_index, tbl->name);
}


void DoTableLayout::check_for_ternary(IR::MAU::Table::Layout &layout, const IR::MAU::Table *tbl) {
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

/**
 * Determines whether a table is set to a proxy hash table, based on the proxy_hash_width
 * function.
 */
void DoTableLayout::check_for_proxy_hash(IR::MAU::Table::Layout &layout,
        const IR::MAU::Table *tbl) {
    auto annot = tbl->match_table->getAnnotations();
    if (auto s = annot->getSingle("proxy_hash_width")) {
        if (s->expr.size() <= 0) {
            ::warning("Proxy hash pragma ignored for table %s because value is undefined",
                      tbl->name);
        } else {
            auto pragma_val =  s->expr.at(0)->to<IR::Constant>();
            ERROR_CHECK(pragma_val != nullptr, "%s: The proxy hash pragma on table %s is "
                        "not a constant", tbl->srcInfo, tbl->name);
            ERROR_CHECK(pragma_val->asInt() > 0 && pragma_val->asInt() <= IXBar::HASH_MATRIX_SIZE,
                "%s: Proxy hash width %d on table %s invalid, as it cannot fit on the "
                "hash matrix", tbl->srcInfo, pragma_val->asInt(), tbl->name);
            layout.proxy_hash = true;
            layout.proxy_hash_width = pragma_val->asInt();
        }
    }
}

/** Because the input xbar allocates by container bytes, the estimate should also be
 *  based on container bytes rather than field bytes.  The point of this byte_impact
 *  maps is to build container bytes and run analysis on that.
 */
void DoTableLayout::determine_byte_impacts(const IR::MAU::Table *tbl,
        IR::MAU::Table::Layout &layout,
        std::map<MatchByteKey, safe_vector<le_bitrange>> &byte_impacts, bool &partition_found,
        cstring partition_index) {
    for (auto ixbar_read : tbl->match_key) {
        if (!ixbar_read->for_match()) continue;
        le_bitrange bits = { 0, 0 };
        auto *field = phv.field(ixbar_read->expr, &bits);
        int match_multiplier = layout.proxy_hash ? 0 : 1;
        int ixbar_multiplier = 1;

        int bytes = 0;
        if (field) {
            /* FIXME -- if a field is allocated to non-contiguous bits of a byte,
             * this will count that byte twice, when it is only needed once.  The
             * match layout in asm_output will likewise lay it out twice, so this
             * is consistent.  Should fix PHV alloc to not make such bad allocations */
            bool is_partition = false;
            if (layout.atcam) {
                auto* partition_index_field = phv.field(partition_index);
                if (partition_index_field && partition_index_field->name == field->name) {
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
}

void DoTableLayout::setup_match_layout(IR::MAU::Table::Layout &layout, const IR::MAU::Table *tbl) {
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
    check_for_proxy_hash(layout, tbl);

    if (!layout.alpm && !layout.atcam && !layout.ternary && !layout.proxy_hash)
        layout.exact = true;
    if (layout.proxy_hash) {
        ERROR_CHECK(!layout.atcam && !layout.ternary, "%s: A proxy hash table cannot be ternary, "
                    "as specified for table %s", tbl->srcInfo, tbl->name);
    }

    safe_vector<int> byte_sizes;
    bool partition_found = false;

    std::map<MatchByteKey, safe_vector<le_bitrange>> byte_impacts;
    determine_byte_impacts(tbl, layout, byte_impacts, partition_found, partition_index);

    // Code responsible for determining the ixbar_width_bits and match_width_bits
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

    if (!layout.ternary && !layout.atcam && !layout.proxy_hash) {
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
    } else if (layout.proxy_hash) {
        layout.match_width_bits = layout.proxy_hash_width;
    }
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

void DoTableLayout::setup_gateway_layout(IR::MAU::Table::Layout &layout, IR::MAU::Table *tbl) {
    for (auto &gw : tbl->gateway_rows)
        gw.first->apply(GatewayLayout(layout));
    // should count gw tcam width and depth to support gw splitting when needed
}

/** Initializes the list of action formats that are possible for the table, with different
 *  layouts in both action data tables as well as immediate
 */
void DoTableLayout::setup_action_layout(IR::MAU::Table *tbl) {
    tbl->layout.action_data_bytes = 0;
    safe_vector<ActionFormat::Use> uses;
    ActionFormat af(tbl, phv, alloc_done);
    bool immediate_allowed = true;
    // Action Profiles cannot have any immediate data
    if (tbl->layout.action_addr.address_bits != 0)
        immediate_allowed = false;
    // chained salus need the immediate path for the address, so can't use it for data
    for (auto att : tbl->attached)
        if (auto salu = att->attached->to<IR::MAU::StatefulAlu>())
            if (salu->chain_vpn)
                immediate_allowed = false;
    af.allocate_format(uses, immediate_allowed);
    lc.total_action_formats[tbl->name] = uses;
    tbl->layout.action_data_bytes = af.action_data_bytes;
}

/* Setting up the potential layouts for ternary, either with or without immediate
   data if immediate is possible */
void DoTableLayout::setup_ternary_layout_options(IR::MAU::Table *tbl) {
    LOG2("Setup TCAM match layouts " << tbl->name);
    if (tbl->hit_actions() == 1)
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
void DoTableLayout::setup_exact_match(IR::MAU::Table *tbl, int action_data_bytes_in_table,
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
    if (auto s = annot->getSingle("dynamic_table_key_masks")) {
        ERROR_CHECK(s->expr.size() > 0,
                "%s: dynamic_table_key_masks pragma has no value for table %s",
                    tbl->srcInfo, tbl->name);
        auto pragma_val = s->expr.at(0)->to<IR::Constant>();
        ERROR_CHECK(pragma_val != nullptr, "%s: pack pragma value for table %s must be a "
                    "constant", tbl->srcInfo, tbl->name);
        if (pragma_val) {
            auto dkm = pragma_val->asInt();
            if (dkm == 1) {
                tbl->dynamic_key_masks = true;
            } else {
                ::warning("%s: The dynammic_table_key_masks pragma value for table %s is %d"
                        ", when the compiler only supports value of 1", tbl->srcInfo,
                          tbl->name, dkm);
            }
        }
    }

    if (pack_val > 0 && tbl->layout.sel_len_bits > 0 && pack_val != 1) {
        ::error("%s: Table %s has a pack %d provided, but also uses a wide selector, which "
                "requires a pack of 1", tbl->srcInfo, tbl->name, pack_val);
        return;
    }

    for (int entry_count = MIN_PACK; entry_count <= MAX_PACK; entry_count++) {
        if (pack_val > 0 && entry_count != pack_val)
            continue;
        if (entry_count != 1 && tbl->layout.sel_len_bits > 0)
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

        // ATCAM tables can only have one payload bus, as the priority ranking happens on
        // a single bus
        if ((overhead_width > 1 || entry_count > MAX_ENTRIES_PER_ROW) && tbl->layout.atcam)
            break;

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
void DoTableLayout::setup_layout_options(IR::MAU::Table *tbl) {
    LOG2("Determining SRAM match layouts " << tbl->name);
    int index = 0;
    bool hash_action_only = false;
    add_hash_action_option(tbl, hash_action_only);
    if (hash_action_only)
        return;

    for (auto &use : lc.get_action_formats(tbl)) {
        setup_exact_match(tbl, use.action_data_bytes[ActionFormat::ADT],
                          use.immediate_bits(), index);
        index++;
    }

    bool possible_pack_formats = lc.total_layout_options.size();
    LOG2("Total number of layout options " << possible_pack_formats);
    ERROR_CHECK(possible_pack_formats > 0, "The table %s cannot find a valid packing, and "
                "cannot be placed", tbl->name);
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
void DoTableLayout::setup_layout_option_no_match(IR::MAU::Table *tbl) {
    LOG2("Determining no match table layouts " << tbl->name);
    GetHashDistReqs ghdr;
    tbl->attached.apply(ghdr);
    for (auto v : Values(tbl->actions))
        v->apply(ghdr);

    // No match tables are required to have only one layout option in a later pass, so the
    // algorithm picks the action format that has the most immediate.  This is the option
    // that is preferred generally, but not always, if somehow it couldn't fit on the action
    // data bus.  Action data bus allocation could properly be optimized a lot more before this
    // choice would have to be made
    auto uses = lc.get_action_formats(tbl);
    BUG_CHECK(!uses.empty(), "no uses?");
    auto &use = uses.back();
    IR::MAU::Table::Layout layout = tbl->layout;
    layout.immediate_bits = use.immediate_bits();
    layout.action_data_bytes_in_table = use.action_data_bytes[ActionFormat::ADT];
    layout.overhead_bits += use.immediate_bits();
    LayoutOption lo(layout, uses.size() - 1);
    lc.total_layout_options[tbl->name].push_back(lo);
}

/**
 * A table can be a hash action table under the following condition:
 *     - The table has no overhead required
 *     - The number of entries is equivalent to 2^(key bits)
 *     - The table would initially be a standard exact match table
 *     - The table has no idletime table (no hash dist bus for idletime)
 *     - All side-effect tables are not addressed by an overhead field
 *
 * To note, direct addressed tables such as counters/meters/stateful tables can also have
 * their address replaced, similar to action data tables.
 */
bool DoTableLayout::can_be_hash_action(IR::MAU::Table *tbl, std::string &reason) {
    if (tbl->layout.atcam || tbl->layout.no_match_data())
        return false;

    int entries = 0;
    if (tbl->match_table) {
        if (auto k = tbl->match_table->getConstantProperty("size"))
            entries = k->asInt();
        else if (auto k = tbl->match_table->getConstantProperty("min_size"))
            entries = k->asInt();
    } else {
        return false;
    }

    /* this doesnt have to be a power of 2. This check is mostly
     * to make the driver happy. Here's a JIRA for the driver to
     * fix this constraint: https://barefootnetworks.atlassian.net/browse/DRV-2116 */
    if (entries != pow(2, tbl->layout.ixbar_width_bits)) {
        reason = "the size is not 2^(key bits)";
        return false;
    }
    if (tbl->layout.overhead_bits > 0) {
        reason = "the table requires match overhead";
        return false;
    }
    if (tbl->actions.size() > 1) {
        reason = "the table has multiple actions";
        return false;
    }

    for (auto ba : tbl->attached) {
        if (ba->attached->is<IR::MAU::IdleTime>()) {
            reason = "the table has idletime requirements";
            return false;
        }
    }
    return true;
}

/**
 * Adds the hash action layout as a potential choice for a layout for a table, if that
 * layout is possible.
 */
void DoTableLayout::add_hash_action_option(IR::MAU::Table *tbl, bool &hash_action_only) {
    std::string hash_action_reason = "";
    bool possible = can_be_hash_action(tbl, hash_action_reason);
    hash_action_only = false;
    if (!tbl->match_table)
        return;

    auto annot = tbl->match_table->getAnnotations();
    if (auto s = annot->getSingle("use_hash_action")) {
        auto pragma_val = s->expr.at(0)->to<IR::Constant>();
        ERROR_CHECK(pragma_val != nullptr, "%s: Please provide a 1 vs. 0 for the use_hash_action"
                    "for table %s", tbl->srcInfo, tbl->name);
        hash_action_only = pragma_val->asInt() == 1;
    }

    if (hash_action_only) {
        ERROR_CHECK(possible, "%s: Table %s is required to be a hash action table, but cannot "
                              "be due to %s", tbl->srcInfo, tbl->name, hash_action_reason);
    }

    if (!possible)
        return;

    auto uses = lc.get_action_formats(tbl);
    auto &use = uses[0];
    BUG_CHECK(use.immediate_bits() == 0, "Cannot have overhead bits in a hash action table");
    IR::MAU::Table::Layout layout = tbl->layout;
    layout.immediate_bits = 0;
    layout.action_data_bytes_in_table = use.action_data_bytes[ActionFormat::ADT];
    layout.hash_action = true;
    LayoutOption lo(layout, 0);
    lc.total_layout_options[tbl->name].push_back(lo);
}

namespace {
class VisitAttached : public Inspector {
    IR::MAU::Table::Layout &layout;
    enum addr_type_t { STATS, METER, TYPES };
    const IR::MAU::AttachedMemory *users[TYPES] = { 0 };

    cstring addr_type_name(addr_type_t type) {
        switch (type) {
            case STATS: return "stats";
            case METER: return "meter";
            default: return "";
        }
    }

    bool free_address(const IR::MAU::AttachedMemory *am, IR::MAU::Table::IndirectAddress &ia,
            addr_type_t type) {
        auto ba = findContext<IR::MAU::BackendAttached>();
        if (users[type] != nullptr) {
            ::error("%s: Both %s and %s require the %s address hardware, and cannot be on "
                "the same table %s", am->srcInfo, am->name, users[type]->name,
                addr_type_name(type), tbl->name);
            return false;
        }
        users[type] = am;

        if (!am->direct) {
            if (am->size <= 0) {
                ::error("%s Indirect attached table %s does not have a size", am->srcInfo,
                    am->name);
                return false;
            }
        }

        BUG_CHECK(am->direct == (IR::MAU::AddrLocation::DIRECT == ba->addr_location), "%s: "
            "Instruction Selection did not correctly set up the addressing scheme for %s",
            am->srcInfo, am->name);

        ia.shifter_enabled = true;
        bool from_hash = false;
        if (ba->addr_location == IR::MAU::AddrLocation::OVERHEAD) {
            ia.address_bits += std::max(ceil_log2(am->size), 10);
        } else if (ba->addr_location == IR::MAU::AddrLocation::HASH) {
            from_hash = true;
        }

        if (ba->pfe_location == IR::MAU::PfeLocation::OVERHEAD) {
            if (from_hash) {
                if (layout.no_match_data()) {
                    ::error("%s: When an attached memory %s is addressed by hash and requires "
                            "per action enabling, then the table %s must have match data",
                             am->srcInfo, am->name, tbl->name);
                    return false;
                }
            }
            ia.per_flow_enable = true;
        }

        if (type == METER && ba->type_location == IR::MAU::TypeLocation::OVERHEAD) {
            if (from_hash) {
                if (layout.no_match_data()) {
                    ::error("%s: When an attached memory %s is addressed by hash and requires "
                            "multiple meter_type, then the table %s must have match data",
                            am->srcInfo, am->name, tbl->name);
                    return false;
                }
            }
            ia.meter_type_bits = 3;
        }
        layout.overhead_bits += ia.total_bits();
        return true;
    }


    /** The purpose of this function is to determine whether or not the tables using stateful
     *  tables are allowed within Tofino.  Essentially the constraints are the following:
     *  - Multiple counters, meters, or registers can be found on a table if they use the
     *    same exact addressing scheme.
     *  - A table can only have a meter, a stateful alu, or a selector, as they use
     *    the same address in match central
     *  - Indirect addresses for twoport tables require a per flow enable bit as well
     */
    bool preorder(const IR::MAU::Counter *cnt) override {
        free_address(cnt, layout.stats_addr, STATS);
        return false;
    }

    bool preorder(const IR::MAU::Meter *mtr) override {
        free_address(mtr, layout.meter_addr, METER);
        return false;
    }

    bool preorder(const IR::MAU::StatefulAlu *salu) override {
        free_address(salu, layout.meter_addr, METER);
        return false;
    }
    bool preorder(const IR::MAU::Selector *as) override {
        free_address(as, layout.meter_addr, METER);
        int sel_len = SelectorLengthBits(as);
        if (sel_len > 0) {
            layout.overhead_bits += sel_len;
            layout.sel_len_bits = sel_len;
        }
        return false;
    }
    bool preorder(const IR::MAU::TernaryIndirect *) override {
        BUG("No ternary indirect should exist before table placement");
        return false; }
    bool preorder(const IR::MAU::ActionData *ad) override {
        BUG_CHECK(!ad->direct, "Cannot have a direct action data table before table placement");
        if (ad->size <= 0)
            error("%s: No size count in %s %s", ad->srcInfo, ad->kind(), ad->name);
        int vpn_bits_needed = std::max(10, ceil_log2(ad->size)) + 1;
        layout.overhead_bits += vpn_bits_needed;
        layout.action_addr.address_bits = vpn_bits_needed;
        layout.action_addr.shifter_enabled = true;
        return false;
    }
    bool preorder(const IR::MAU::IdleTime *) override {
        return false;
    }
    bool preorder(const IR::Attached *att) override {
        BUG("Unknown attached table type %s", typeid(*att).name()); }

    const IR::MAU::Table *tbl;

 public:
    explicit VisitAttached(IR::MAU::Table::Layout *l, const IR::MAU::Table *t)
        : layout(*l), tbl(t) {}
};
}  // namespace

void DoTableLayout::setup_instr_and_next(IR::MAU::Table::Layout &layout,
         const IR::MAU::Table *tbl) {
    layout.total_actions = tbl->actions.size();
    int hit_actions = tbl->hit_actions();
    if (hit_actions > 0) {
        if (hit_actions <= TableFormat::IMEM_MAP_TABLE_ENTRIES)
            layout.overhead_bits += ceil_log2(hit_actions);
        else
            layout.overhead_bits += TableFormat::FULL_IMEM_ADDRESS_BITS;
    }

    if (tbl->action_chain() && hit_actions > TableFormat::NEXT_MAP_TABLE_ENTRIES) {
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

bool DoTableLayout::preorder(IR::MAU::Table *tbl) {
    LOG1("## layout table " << tbl->name);
    tbl->layout.ixbar_bytes = tbl->layout.match_bytes = tbl->layout.match_width_bits =
    tbl->layout.action_data_bytes = tbl->layout.overhead_bits = 0;
    setup_instr_and_next(tbl->layout, tbl);
    if (tbl->match_table)
        setup_match_layout(tbl->layout, tbl);
    if ((tbl->layout.gateway = tbl->uses_gateway()))
        setup_gateway_layout(tbl->layout, tbl);
    VisitAttached visit_attached(&tbl->layout, tbl);
    tbl->attached.apply(visit_attached);
    setup_action_layout(tbl);
    tbl->random_seed = tbl->get_random_seed();
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


bool DoTableLayout::preorder(IR::MAU::Action *act) {
    auto tbl = findContext<IR::MAU::Table>();
    if (tbl->layout.no_match_hit_path())
        return false;
    GetHashDistReqs ghdr;
    act->apply(ghdr);
    if (!ghdr.is_hash_dist_needed())
        return false;

    ERROR_CHECK(!act->init_default, "%s: Cannot specify %s as the default action, as it requires "
                "the hash distribution unit", act->srcInfo, act->name);
    /**
     * This check is to validate that a keyless table that has to go through the miss path,
     * because the driver has to potentially program the table, does not have any actions that
     * require hash.  These actions have to go through the hit path, and thus must go through
     * a mstch with no key table.
     */
    if (tbl->layout.no_match_miss_path()) {
        std::string error_reason = "";
        std::string solution = "";
        if (tbl->layout.total_actions > 1) {
            error_reason = "the table has multiple actions";
            solution = "declare only one action on the table, and mark it as the default action";
        } else if (tbl->layout.action_data_bytes > 0) {
            error_reason = "the table requires programming action data";
            solution = "remove all action data from the action";
        } else {
            error_reason = "the table requires overhead";
            solution = "remove all match overhead";
        }
        ::error("%s: The table %s with no key cannot have the action %s.  This action requires "
                "hash, which can only be done through the hit pathway.  However, because %s, "
                "the driver may need to change at runtime, and the driver can only currently "
                "program the miss pathway.  The solution may be to %s.", act->srcInfo, tbl->name,
                act->name, error_reason, solution);
    }

    ERROR_CHECK(!tbl->layout.no_match_miss_path(), "%s: This table with no key cannot have the "
                "action %s as an action here, because it requires hash distribution, which "
                "utilizes the hit path in Tofino, while the driver configures the miss path",
                act->srcInfo, act->name);

    act->hit_path_imp_only = false;
    act->disallowed_reason = "uses_hash_dist";
    return false;
}

bool DoTableLayout::preorder(IR::MAU::InputXBarRead *read) {
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

        // Look up the PHV::Field objects to ensure that we compare
        // fully-qualified names.
        auto* readInfo = phv.field(read->expr);
        auto* indexInfo = phv.field(partition_index);
        if (readInfo && indexInfo && readInfo->name == indexInfo->name)
            read->partition_index = true;
    }
    return false;
}

bool DoTableLayout::preorder(IR::MAU::Selector *sel) {
    auto tbl = findContext<IR::MAU::Table>();
    if (SelectorLengthBits(sel) <= 0) {
        return false;
    }

    IR::Vector<IR::Expression> components;
    IR::ListExpression *field_list = new IR::ListExpression(components);
    for (auto ixbar_read : tbl->match_key) {
        if (!ixbar_read->for_selection())
            continue;
        field_list->push_back(ixbar_read->expr);
    }
    auto *hd = new IR::MAU::HashDist(sel->srcInfo, IR::Type::Bits::get(SelectorHashModBits(sel)),
                                     field_list, sel->algorithm);
    hd->bit_width = SelectorHashModBits(sel);
    sel->hash_mod = hd;
    return false;
}

static double eqn(double current, int num_counters ) {
    return (current-1) + (log(num_counters) / (log(current/(current-1))) + 2*current);
}

static bool tol(double b, double maxVal, int num_counters) {
    auto tmp = maxVal - 5000.0;
    auto eqnval = eqn(b, num_counters);
    if ((tmp <= eqnval) && (eqnval < maxVal)) {
        return true;
    }
    return false;
}

void calculate_lrt_threshold_and_interval(const IR::MAU::Table *tbl, IR::MAU::Counter *cntr) {
    if (cntr->threshold != -1) return; /* calculated already? */
    auto annot = cntr->annotations;
    bool lrt_enabled = false;
    if (auto s = annot->getSingle("lrt_enable")) {
        ERROR_CHECK(s->expr.size() >= 1, "%s: lrt_enable pragma on counter does not have a"
            "value", cntr->srcInfo, cntr->name);
        auto pragma_val = s->expr.at(0)->to<IR::Constant>();
        if (pragma_val == nullptr) {
            ::error("%s: lrt_enable value on counter %s is not a constant", cntr->srcInfo,
                cntr->name);
            return;
        }
        auto real_val = pragma_val->asInt();
        if (real_val == 0) return;  // disabled
        if (real_val != 1) {
            ::error("%s: invalid lrt_enable value on counter %s", cntr->srcInfo, cntr->name);
            return;
        }
        lrt_enabled = true;
    }

    if (lrt_enabled == false) return;

    // now get the lrt_scale
    auto s = annot->getSingle("lrt_scale");
    auto lrt_val = s->expr.at(0)->to<IR::Constant>();
    if (lrt_val == nullptr) {
        ::error("%s: lrt_scale value on counter %s is not a constant", cntr->srcInfo, cntr->name);
        return;
    }
    int lrt_scale = lrt_val->asInt();
    if (lrt_scale <= 0) {
        ::error("%s: invalid lrt_scale value on counter %s", cntr->srcInfo, cntr->name);
        return;
    }
    if (cntr->min_width >= 64) {
        ::error("%s: LR(t) cannot be used on 64 bit counter %s", cntr->srcInfo, cntr->name);
        return;
    }

    auto &mem = tbl->resources->memuse.at(tbl->unique_id(cntr));
    int rams = 0;
    for (auto &row : mem.row)
        rams += row.col.size();
    auto num_counters = (rams-1) * 1024 * CounterPerWord(cntr);
    auto width = CounterWidth(cntr);
    if (width == 1) return;

    double maxVal = pow(2, width) - 1;
    double b_last = 0.0;
    double b_cur = 50000.0;
    int iterations = 0;

    LOG3("Calulating LR(t) on counter:  " << cntr->name);
    LOG3("num_counters: " << num_counters);
    LOG3("width: " << width);
    LOG3("maxVal: " << maxVal);

    while (eqn(b_cur, num_counters) < maxVal) {
        b_last = b_cur;
        b_cur *= 2.0;
        iterations++;
    }

    double step = floor(b_cur - b_last);
    std::set<double> saw;
    while ((!tol(b_cur, maxVal, num_counters)) && (b_cur > 1.0)) {
        if (step > 4.0) {
            step /= 2.0;
            step = floor(step);
        }
        iterations++;

        auto e = eqn(b_cur, num_counters);

        if (e > maxVal) {
            b_cur -= step;
        } else if (e < maxVal) {
            auto it = saw.find(e);
            if (*it == e)
              break;
            else
              b_cur += step;
        } else {
            b_cur -= 1.0;
            break;
        }
        saw.insert(e);
        if (iterations > 10000) break;
    }

    auto threshold = static_cast<unsigned long>(b_cur) >> 4;
    auto interval = static_cast<unsigned long>(b_cur);
    if (cntr->type != IR::MAU::DataAggregation::PACKETS)
        interval = static_cast<unsigned long>(b_cur) >> 8;

    if (interval >= pow(2, 28)) {
        interval = pow(2, 28) - 1;
    }

#define roundUp(n, b) ( ( ((n)+(b)-1) - (((n)-1)%(b)) ) )
    auto scaled_threshold = threshold / lrt_scale;
    /* threshold - must be a multiple of 16 */
    cntr->threshold = roundUp(scaled_threshold, 16);
    LOG3("threshold: " << cntr->threshold);
    auto scaled_interval = interval / lrt_scale;
    /* interval - must be a multiple of 256 */
    cntr->interval = roundUp(scaled_interval, 256);
    LOG3("interval: " << cntr->interval);
#undef roundUp
}

bool FinalTableLayout::preorder(IR::MAU::Counter *cntr) {
    calculate_lrt_threshold_and_interval(findContext<IR::MAU::Table>(), cntr);
    return false;
}

/**
 * An action profile requires action data to be saved somewhere in RAM space.  If the action
 * profile does not require action data, then the profile is pointless, and is currently not
 * allowed in Brig, as the driver needs some RAM space in order to figure out where to save
 * entries
 */
bool ValidateActionProfileFormat::preorder(const IR::MAU::ActionData *ad) {
    auto tbl = findContext<IR::MAU::Table>();
    auto formats = lc.get_action_formats(tbl);
    BUG_CHECK(formats.size() == 1, "%s: Compiler generated multiple formats for action profile "
              "%s on table %s", ad->srcInfo, ad->name, tbl->name);
    if (formats.size() > 0)
        ERROR_CHECK(formats[0].action_data_bytes[ActionFormat::ADT] > 0, "%s: Action profile "
                    "%s on table %s does not have any action data (either because no action data "
                    "has been provided, or the action data has been dead code eliminated.  "
                    "An action data free action profile is not supported", ad->srcInfo, ad->name,
                    tbl->name);
    return false;
}
/**
 * This constraint code is copied from handle_assign.cpp, where this is validated
 *
 * Due to the register rams.match.merge.mau_meter_alu_to_logical_map being an OXBar,
 * one can only assign a single logical table to a wide hash mod.  Thus, a selector
 * that requires a hash mod cannot be shared
 */
bool ProhibitAtcamWideSelectors::preorder(const IR::MAU::Selector *as) {
    auto tbl = findContext<IR::MAU::Table>();
    if (as->max_pool_size > StageUseEstimate::SINGLE_RAMLINE_POOL_SIZE && tbl->layout.atcam) {
        ::error("%s: ATCAM table %s cannot have selector %s.  An ATCAM table may require "
                "multiple logical tables, and a selector that has a max pool size greater "
                "than %d, (in this instance %d), the selector can only belong to a single "
                "logical table", as->srcInfo, tbl->name, as->name,
                 StageUseEstimate::SINGLE_RAMLINE_POOL_SIZE, as->max_pool_size);
    }
    return false;
}

Visitor::profile_t TableLayout::init_apply(const IR::Node *node) {
    auto rv = PassManager::init_apply(node);
    lc.clear();
    return rv;
}

TableLayout::TableLayout(const PhvInfo &p, LayoutChoices &l) : phv(p), lc(l) {
    addPasses({
        new DoTableLayout(p, lc),
        new ValidateActionProfileFormat(lc),
        new ProhibitAtcamWideSelectors
    });
}
