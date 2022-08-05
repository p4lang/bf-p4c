#include "bf-p4c/mau/flatrock/table_format.h"
#include "bf-p4c/mau/flatrock/table_layout.h"
#include "bf-p4c/mau/memories.h"

namespace Flatrock {
/* FIXME: This function is for the setup of a table with no match data.  This is currently hacked
   together in order to pass many of the test cases.  This needs to have some standardization
   within the assembly so that all tables that do not require match can possibly work */
void LayoutChoices::setup_layout_option_no_match(const IR::MAU::Table *tbl,
        const IR::MAU::Table::Layout &layout_proto, ActionData::FormatType_t format_type) {
    BUG_CHECK(format_type.valid(),
              "invalid format type in LayoutChoices::setup_layout_option_no_match");
    LOG2("Determining no match table layouts " << tbl->name << ":" << format_type);
    GetActionRequirements ghdr;
    tbl->attached.apply(ghdr);
    for (auto v : Values(tbl->actions))
        v->apply(ghdr);
    IR::MAU::Table::Layout layout = layout_proto;
    if (ghdr.is_hash_dist_needed() || ghdr.is_rng_needed()) {
        layout.hash_action = true;
    } else if (!format_type.matchThisStage()) {
        // post split gets index via hash_dist, so it needs to be hash_action
        layout.hash_action = true; }

    // Flatrock does not support no_match_miss tables, so force it to be hit path
    // if we need to run an action.
    if (!tbl->actions.empty()) {
        // should use gateway table?  Needs table_layout/table_format updates for flatrock
        layout.hash_action = true; }

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
void LayoutChoices::setup_exact_match(const IR::MAU::Table *tbl,
        const IR::MAU::Table::Layout &layout_proto, ActionData::FormatType_t format_type,
        int action_data_bytes_in_table, int immediate_bits, int index) {
    BUG_CHECK(format_type.valid(), "invalid format type in LayoutChoices::setup_exact_match");
    auto MIN_PACK = Device::sramMinPackEntries();
    auto MAX_PACK = Device::sramMaxPackEntries();
    // auto MAX_ENTRIES_PER_ROW = Device::sramMaxPackEntriesPerRow();

    auto annot = tbl->match_table->getAnnotations();
    int pack_val = 0;
    if (auto s = annot->getSingle("pack")) {
        ERROR_CHECK(s->expr.size() > 0, ErrorType::ERR_INVALID,
                    "pack pragma. It has no value for table %1%.", tbl);
        auto pragma_val = s->expr.at(0)->to<IR::Constant>();
        ERROR_CHECK(pragma_val != nullptr, ErrorType::ERR_INVALID,
                    "pack pragma value for table %1%. Must be a constant.", tbl);
        if (pragma_val) {
            pack_val = pragma_val->asInt();
            if (pack_val < MIN_PACK || pack_val > MAX_PACK) {
                ::warning(ErrorType::WARN_INVALID,
                          "%1%: The provide pack pragma value for table %2% is %3%, when the "
                          "compiler only supports pack values between %4% and %5%",
                          tbl, tbl->externalName(), pack_val, MIN_PACK, MAX_PACK);
                pack_val = 0;
            }
        }
    }

    if (pack_val > 0 && layout_proto.sel_len_bits > 0 && pack_val != 1) {
        ::error(ErrorType::ERR_INVALID,
                "table %1%. It has a pack value of %2% provided, but also uses a wide selector, "
                "which requires a pack of 1.", tbl, pack_val);
        return;
    }

    // Determine single entry bits first and then the no. of entries possible within a word
    // For n entries add layouts 1..n?

    // Lamb Based LayoutChoices
    IR::MAU::Table::Layout layout_for_pack = layout_proto;
    IR::MAU::Table::Way way;

    way.width = 1;  // Wide matches not possible for lambs?
    layout_for_pack.action_data_bytes_in_table = action_data_bytes_in_table;
    layout_for_pack.immediate_bits = immediate_bits;
    layout_for_pack.overhead_bits += immediate_bits;
    layout_for_pack.valid_bits = 1;  // 1 valid bit per entry (set by pragma / table property?)
    layout_for_pack.overhead_bits += layout_for_pack.valid_bits;
    layout_for_pack.action_data_bytes = action_data_bytes_in_table + (immediate_bits + 7) / 8;
    layout_for_pack.is_lamb = true;
    int action_bits = ceil_log2(layout_for_pack.total_actions);

    // LAMB - Direct
    int ld_single_overhead_bits = layout_proto.overhead_bits + immediate_bits + action_bits;
    int ld_single_entry_bits = 1ULL << ceil_log2(ld_single_overhead_bits);
    if (ld_single_entry_bits == 0) ld_single_entry_bits++;  // Cant be zero?
    int ld_entries = TableFormat::SINGLE_RAM_BITS / ld_single_entry_bits;
    int max_lamb_entries_direct = Memories::TOTAL_LAMBS * Memories::LAMB_DEPTH * ld_entries;
    if (layout_proto.entries <= max_lamb_entries_direct) {
        // Check and set layout for direct lookup
        // A direct lookup is preferred if entries required is ~ 2^match_key_width
        auto match_key_width = tbl->get_match_key_width();
        int min_size_for_direct_lamb = 1ULL << (match_key_width - 1);
        int max_size_for_direct_lamb = 1ULL << match_key_width;
        layout_for_pack.is_direct = (layout_for_pack.entries > min_size_for_direct_lamb
                                    && layout_for_pack.entries <= max_size_for_direct_lamb);
        if (layout_for_pack.is_direct) {
            layout_for_pack.entries_per_set = 1;  // Always 1 for direct
            layout_for_pack.sets_per_word = ld_entries;
            way.match_groups = ld_entries;

            add_layout_option(tbl, layout_for_pack, way, format_type, ld_entries,
                                ld_single_entry_bits, ld_single_overhead_bits, index);
        }
    }

    // LAMB - Cuckoo
    int lc_single_overhead_bits = std::max(0, ld_single_overhead_bits
                                        + (layout_for_pack.match_width_bits
                                        - layout_for_pack.get_ram_ghost_bits() + action_bits));
    int lc_single_entry_bits = 1ULL << ceil_log2(lc_single_overhead_bits);
    if (lc_single_entry_bits == 0) lc_single_entry_bits++;  // Cant be zero?
    int lc_entries = TableFormat::SINGLE_RAM_BITS / lc_single_entry_bits;
    int max_lamb_entries_cuckoo = Memories::TOTAL_LAMBS * Memories::LAMB_DEPTH * lc_entries;
    if (layout_proto.entries <= max_lamb_entries_cuckoo) {
        layout_for_pack.is_direct = false;
        layout_for_pack.entries_per_set = lc_entries;
        layout_for_pack.sets_per_word = 1;  // TODO: When to configure multiple sets?
        way.match_groups = lc_entries;

        add_layout_option(tbl, layout_for_pack, way, format_type, lc_entries,
                            lc_single_entry_bits, lc_single_overhead_bits, index);
    }

    // TODO: STM Based LayoutChoices
}

void LayoutChoices::setup_ternary_layout(const IR::MAU::Table *tbl,
        const IR::MAU::Table::Layout &layout_proto, ActionData::FormatType_t format_type,
        int action_data_bytes_in_table, int immediate_bits, int index) {
    IR::MAU::Table::Layout layout = layout_proto;
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

void LayoutChoices::add_layout_option(const IR::MAU::Table *tbl,
        const IR::MAU::Table::Layout &layout, const IR::MAU::Table::Way &way,
        ActionData::FormatType_t format_type, const int entries,
        const int single_entry_bits, const int overhead_bits, const int index) {
    auto lo_key = std::make_pair(tbl->name, format_type);
    int total_bits = entries * single_entry_bits;

    // Per entry cannot exceed 64 bits overhead
    if ((overhead_bits <= TableFormat::OVERHEAD_BITS)
        // Total bits cannot exceed single RAM width
            && (total_bits <= TableFormat::SINGLE_RAM_BITS)) {
        cache_layout_options[lo_key].emplace_back(layout, way, index);
        LOG2("Adding " << cache_layout_options[lo_key].back());
    }
}

}  // namespace Flatrock
