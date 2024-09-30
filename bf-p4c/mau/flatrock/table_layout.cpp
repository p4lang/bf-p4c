#include "bf-p4c/mau/flatrock/table_format.h"
#include "bf-p4c/mau/flatrock/table_layout.h"
#include "bf-p4c/mau/memories.h"
#include "lib/indent.h"

namespace Flatrock {
/* FIXME: This function is for the setup of a table with no match data.  This is currently hacked
   together in order to pass many of the test cases.  This needs to have some standardization
   within the assembly so that all tables that do not require match can possibly work
   */
void LayoutChoices::setup_layout_option_no_match(const P4::IR::MAU::Table *tbl,
        const P4::IR::MAU::Table::Layout &layout_proto, ActionData::FormatType_t format_type) {
    BUG_CHECK(format_type.valid(),
              "invalid format type in LayoutChoices::setup_layout_option_no_match");
    LOG2("Determining no match table layouts " << tbl->name << ":" << format_type);
    GetActionRequirements ghdr;
    tbl->attached.apply(ghdr);
    for (auto v : Values(tbl->actions))
        v->apply(ghdr);
    P4::IR::MAU::Table::Layout layout = layout_proto;
#if 0
    if (ghdr.is_hash_dist_needed() || ghdr.is_rng_needed()) {
        layout.hash_action = true;
    } else if (!format_type.matchThisStage()) {
        // post split gets index via hash_dist, so it needs to be hash_action
        layout.hash_action = true; }
#endif

    // Flatrock does not support no_match_miss tables, so no match tables allways need
    // to have the hash_action flag set (which is a bit of a misnomer and a hack) which
    // causes them to be allocated as mo-match-hit tables (really just gateways)
    layout.hash_action = true;

    // No match tables are required to have only one layout option in a later pass, so the
    // algorithm picks the action format that has the most immediate.  This is the option
    // that is preferred generally, but not always, if somehow it couldn't fit on the action
    // data bus.  Action data bus allocation could properly be optimized a lot more before this
    // choice would have to be made
    auto uses = get_action_formats(tbl, format_type);
    if (uses.empty())
        return;
    auto &use = uses.back();
    layout.immediate_bits = use.immediate_bits();
    layout.action_data_bytes_in_table = use.bytes_per_loc[ActionData::ACTION_DATA_TABLE];
    layout.overhead_bits += use.immediate_bits();
    LayoutOption lo(layout, uses.size() - 1);
    if (layout.hash_action) {
        lo.way.match_groups = 1;
        lo.way.width = 1;
    }
    cache_layout_options[std::make_pair(tbl->name, format_type)].push_back(lo);
}

/**
 * Responsible for the calculation of the potential layouts to try, and later adapt
 * if necessary in the try_place_table algorithm.
 */
void LayoutChoices::setup_exact_match(const P4::IR::MAU::Table *tbl,
        const P4::IR::MAU::Table::Layout &layout_proto, ActionData::FormatType_t format_type,
        int action_data_bytes_in_table, int immediate_bits, int index) {
    Log::TempIndent indent;
    LOG3("Setting up layouts for exact match table " << tbl->name
            << " with ADB " << action_data_bytes_in_table
            << ", immediate_bits " << immediate_bits << ", index " << index << indent);
    BUG_CHECK(format_type.valid(), "invalid format type in LayoutChoices::setup_exact_match");

    // TODO: Skip Adding layout with Action Data until support is added
    if (action_data_bytes_in_table > 0) {
        // if action data can't possibly fit in immed, then continue
        if (immediate_bits + action_data_bytes_in_table*8 <= 32)
            return; }

    auto pack_val = get_pack_pragma_val(tbl, layout_proto);
    // Determine single entry bits first and then the no. of entries possible within a word
    // For n entries add layouts 1..n?

    P4::IR::MAU::Table::Layout layout_for_pack = layout_proto;
    P4::IR::MAU::Table::Way way;

    way.width = 1;  // Wide matches not possible for lambs?
    layout_for_pack.action_data_bytes_in_table = action_data_bytes_in_table;
    layout_for_pack.immediate_bits = immediate_bits;
    layout_for_pack.valid_bits = 1;  // 1 valid bit per entry (set by pragma / table property?)
    // FIXME -- why are we recalculating this rather than using layout_proto.overhead_bits?
    layout_for_pack.overhead_bits = layout_for_pack.immediate_bits + layout_for_pack.valid_bits
            + layout_for_pack.meter_addr.total_bits() + layout_for_pack.stats_addr.total_bits()
            + layout_for_pack.action_addr.total_bits();
    layout_for_pack.action_data_bytes = action_data_bytes_in_table + (immediate_bits + 7) / 8;
    int action_bits = ceil_log2(layout_for_pack.total_actions);

    // LAMB / STM - Direct
    LOG3("Adding Direct layouts");
    int ld_single_overhead_bits = layout_for_pack.overhead_bits + action_bits;
    int ld_single_entry_bits = 1ULL << ceil_log2(ld_single_overhead_bits);
    if (ld_single_entry_bits == 0) ld_single_entry_bits++;  // Cant be zero?
    int ld_entries = (pack_val > 0) ?
        pack_val : TableFormat::SINGLE_RAM_BITS / ld_single_entry_bits;
    int max_lamb_direct_entry_bits =
        ceil_log2(Memories::TOTAL_LAMBS * Memories::LAMB_DEPTH * ld_entries);
    int max_stm_direct_entry_bits =
        ceil_log2(Memories::TOTAL_SRAMS * Memories::SRAM_DEPTH * ld_entries);
    int match_bits_required = ceil_log2(layout_for_pack.entries);
    // Check and set layout for direct lookup
    // A direct lookup should be used whereever possible - entries required is ~ 2^match_key_width
    // or in other words bits required for entries = match_key_width. This bypasses the hash
    // distribution calculation and saves hw resources
    //
    // NOTE: For large match keys, match bits required could result is wasting RAM space
    // since they its evaluated with a ceil_log2 function and could add many unnecessary RAMs
    // and bloat the table size
    int match_key_width = tbl->get_match_key_width();
    LOG4("  Match key width : " << match_key_width
            << ", Entry bits required: " << match_bits_required
            << ", Max Entry Bits: Lamb - " << max_lamb_direct_entry_bits
            << ", STM - " << max_stm_direct_entry_bits);
    layout_for_pack.is_direct = match_bits_required == match_key_width;
    layout_for_pack.is_lamb = false;
    bool add_lo = false;
    if (layout_for_pack.is_direct) {
        if (match_bits_required <= max_lamb_direct_entry_bits) {
            layout_for_pack.is_lamb = true;
            add_lo = true;
        } else if (match_bits_required <= max_stm_direct_entry_bits){
            add_lo = true;
        }
    }
    if (add_lo) {
        layout_for_pack.entries_per_set = 1;  // Always 1 for direct
        layout_for_pack.sets_per_word = ld_entries;
        way.match_groups = ld_entries;
        add_layout_option(tbl, layout_for_pack, way, format_type, ld_entries,
                            ld_single_entry_bits, ld_single_overhead_bits, index);
    } else {  // If a direct lookup is possible there is no need for a cuckoo layout
        // LAMB / STM - Cuckoo
        LOG3("Adding Cuckoo layouts");
        int lc_single_overhead_bits = std::max(0, ld_single_overhead_bits
                                            + (layout_for_pack.match_width_bits
                                            - layout_for_pack.get_ram_ghost_bits()
                                            + action_bits));
        int lc_single_entry_bits = 1ULL << ceil_log2(lc_single_overhead_bits);
        if (lc_single_entry_bits == 0) lc_single_entry_bits++;  // Cant be zero?
        int lc_entries = (pack_val > 0) ?
            pack_val : TableFormat::SINGLE_RAM_BITS / lc_single_entry_bits;
        int max_lamb_entries_cuckoo =
            Memories::TOTAL_LAMBS * Memories::LAMB_DEPTH * lc_entries;
        int max_stm_entries_cuckoo =
            Memories::TOTAL_SRAMS * Memories::SRAM_DEPTH * lc_entries;
        add_lo = false;
        layout_for_pack.is_lamb = false;
        layout_for_pack.is_direct = false;
        if (layout_proto.entries <= max_lamb_entries_cuckoo) {
            layout_for_pack.is_lamb = true;
            add_lo = true;
        } else if (layout_proto.entries <= max_stm_entries_cuckoo) {
            add_lo = true;
        }
        if (add_lo) {
            layout_for_pack.entries_per_set = lc_entries;
            layout_for_pack.sets_per_word = 1;  // TODO: When to configure multiple sets?
            way.match_groups = lc_entries;
            add_layout_option(tbl, layout_for_pack, way, format_type, lc_entries,
                                lc_single_entry_bits, lc_single_overhead_bits, index);
        }
    }
}

void LayoutChoices::setup_ternary_layout(const P4::IR::MAU::Table *tbl,
        const P4::IR::MAU::Table::Layout &layout_proto, ActionData::FormatType_t format_type,
        int action_data_bytes_in_table, int immediate_bits, int index) {
    P4::IR::MAU::Table::Layout layout = layout_proto;
    layout.action_data_bytes_in_table = action_data_bytes_in_table;
    layout.immediate_bits = immediate_bits;
    layout.overhead_bits += immediate_bits;
    LayoutOption lo(layout, index);
    cache_layout_options[std::make_pair(tbl->name, format_type)].push_back(lo);
    if (layout.overhead_bits &&
        layout.overhead_bits <= Flatrock::TableFormat::LOCAL_TIND_OVERHEAD_BITS) {
        // This layout is eligible to be tried on local tind.
        lo.layout.is_local_tind = true;
        cache_layout_options[std::make_pair(tbl->name, format_type)].push_back(lo);
    }
}

void LayoutChoices::add_layout_option(const P4::IR::MAU::Table *tbl,
        const P4::IR::MAU::Table::Layout &layout, const P4::IR::MAU::Table::Way &way,
        ActionData::FormatType_t format_type, const int entries,
        const int single_entry_bits, const int overhead_bits, const int index) {
    auto lo_key = std::make_pair(tbl->name, format_type);
    int total_bits = entries * single_entry_bits;

    // Per entry cannot exceed 64 bits overhead
    if ((overhead_bits <= TableFormat::OVERHEAD_BITS)
        // Total bits cannot exceed single RAM width
            && (total_bits <= TableFormat::SINGLE_RAM_BITS)) {
        cache_layout_options[lo_key].emplace_back(layout, way, index);
        LOG2("\tAdding " << cache_layout_options[lo_key].back());
    }
}

}  // namespace Flatrock
