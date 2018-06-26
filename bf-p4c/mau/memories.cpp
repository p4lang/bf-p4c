#include "bf-p4c/device.h"
#include "bf-p4c/mau/memories.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/mau/resource_estimate.h"
#include "lib/bitops.h"
#include "lib/range.h"

static const char *use_type_to_str[] = {
    "EXACT", "ATCAM", "TERNARY", "GATEWAY", "TIND", "IDLETIME",
    "COUNTER", "METER", "SELECTOR", "STATEFUL", "ACTIONDATA"
};


static const char *sram_group_type_to_str[] = {
    "Exact", "Action", "Stats", "Meter", "Register", "Selector", "Tind", "Idletime", "Atcam"
};

/** Building a UniqueId per table alloc.  The stage table comes from initialization, all other
 *  data must be provided
 */
UniqueId Memories::table_alloc::build_unique_id(const IR::MAU::AttachedMemory *at,
        bool is_gw, int logical_table, UniqueAttachedId::pre_placed_type_t ppt) const {
    return table->pp_unique_id(at, is_gw, stage_table, logical_table, ppt);
}

UniqueId Memories::SRAM_group::build_unique_id() const {
    return ta->build_unique_id(attached, false, logical_table, ppt);
}

void Memories::SRAM_group::dbprint(std::ostream &out) const {
    out << "SRAM group: " << ta->table->name << ", type: " << sram_group_type_to_str[type]
        << ", width: " << width << ", number: " << number;
    out << " { is placed: " << placed << ", to place: " << depth << "}";
}

bool Memories::SRAM_group::same_wide_action(const SRAM_group &a) {
    return ta == a.ta && type == ACTION && a.type == ACTION && logical_table == a.logical_table;
}


unsigned Memories::side_mask(RAM_side_t side) {
    switch (side) {
        case LEFT:
            return (1 << LEFT_SIDE_COLUMNS) - 1;
        case RIGHT:
            return ((1 << SRAM_COLUMNS) - 1) & ~((1 << LEFT_SIDE_COLUMNS) - 1);
        case RAM_SIDES:
             return ((1 << SRAM_COLUMNS) - 1);
        default:
             BUG("Unrecognizable RAM side to allocate");
    }
    return 0;
}

unsigned Memories::partition_mask(RAM_side_t side) {
    unsigned mask = (1 << MAX_PARTITION_RAMS_PER_ROW) - 1;
    if (side == RIGHT)
        mask <<= MAX_PARTITION_RAMS_PER_ROW;
    return mask;
}

int Memories::mems_needed(int entries, int depth, int per_mem_row, bool is_twoport) {
    int mems_needed = (entries + per_mem_row * depth - 1) / (depth * per_mem_row);
    return is_twoport ? mems_needed + 1 : mems_needed;
}

void Memories::clear_uses() {
    sram_use.clear();
    memset(sram_inuse, 0, sizeof(sram_inuse));
    tcam_use.clear();
    gateway_use.clear();
    sram_search_bus.clear();
    sram_print_search_bus.clear();
    sram_match_bus.clear();
    memset(tcam_midbyte_use, -1, sizeof(tcam_midbyte_use));
    tind_bus.clear();
    action_data_bus.clear();
    overflow_bus.clear();
    twoport_bus.clear();
    vert_overflow_bus.clear();
    mapram_use.clear();
    memset(mapram_inuse, 0, sizeof(mapram_inuse));
    stateful_bus.clear();
    idletime_bus.clear();
    memset(gw_bytes_reserved, false, sizeof(gw_bytes_reserved));
    stats_alus.clear();
    meter_alus.clear();
}

void Memories::clear() {
    tables.clear();
    clear_table_vectors();
    clear_uses();
}

void Memories::clear_table_vectors() {
    exact_tables.clear();
    exact_match_ways.clear();
    ternary_tables.clear();
    tind_tables.clear();
    tind_groups.clear();
    action_tables.clear();
    indirect_action_tables.clear();
    selector_tables.clear();
    stats_tables.clear();
    meter_tables.clear();
    stateful_tables.clear();
    action_bus_users.clear();
    synth_bus_users.clear();
    gw_tables.clear();
    no_match_hit_tables.clear();
    no_match_miss_tables.clear();
    payload_gws.clear();
    normal_gws.clear();
    no_match_gws.clear();
    idletime_tables.clear();
    idletime_groups.clear();
}

void Memories::clear_allocation() {
    for (auto ta : tables) {
        for (auto &kv : *(ta->memuse)) {
            kv.second.clear_allocation();
        }
    }
}

/* Creates a new table_alloc object for each of the tables within the memory allocation */
void Memories::add_table(const IR::MAU::Table *t, const IR::MAU::Table *gw,
                         TableResourceAlloc *resources, const LayoutOption *lo,
                         int entries, int stage_table) {
    table_alloc *ta;
    if (!t->gateway_only())
        ta = new table_alloc(t, &resources->match_ixbar, &resources->table_format,
                             &resources->memuse, lo, entries, stage_table);
    else
        ta = new table_alloc(t, &resources->gateway_ixbar, nullptr, &resources->memuse, lo,
                             entries, stage_table);
    LOG2("Adding table " << ta->table->name << " with " << entries << " entries");
    tables.push_back(ta);
    if (gw != nullptr)  {
        auto *ta_gw = new table_alloc(gw, &resources->gateway_ixbar, nullptr, &resources->memuse,
                                      lo, -1, stage_table);
        LOG2("Adding gateway table " << ta_gw->table->name << " to table "
             << ta_gw->table->name);
        ta_gw->link_table(ta);
        ta->link_table(ta_gw);
        tables.push_back(ta_gw);
    }
}

/** Due to gateways potentially requiring search buses that could may be used
 *  by exact match tables, the memories allocation can be run multiple times.  The difference
 *  factor would be the total number of RAMs per row exact match tables can be allocated to.
 *  If an exact match table can fit in a single row, only one search bus is required, which
 *  will provide access for gateways.
 *
 *  The algorithm is making a trade-off between search buses, and balance for other tables
 *  such as tind, synth2port, and action tables later.
 */
bool Memories::single_allocation_balance(mem_info &mi, unsigned row) {
    LOG3(" Allocating all ATCAM partitions");
    if (!allocate_all_atcam(mi))
        return false;

    LOG3(" Allocating all exact tables");
    if (!allocate_all_exact(row))
        return false;

    LOG3(" Allocating all ternary tables");
    if (!allocate_all_ternary()) {
        return false;
    }

    LOG3(" Allocating all ternary indirect tables");
    if (!allocate_all_tind()) {
        return false;
    }

    LOG3(" Allocating all action tables");
    if (!allocate_all_swbox_users()) {
        return false;
    }

    LOG3(" Allocating all idletime tables");
    if (!allocate_all_idletime()) {
        return false;
    }

    LOG3(" Allocating all gateway tables");
    if (!allocate_all_gw()) {
        return false;
    }

    LOG3(" Allocate all no match miss");
    if (!allocate_all_no_match_miss()) {
        return false;
    }

    return true;
}

/* Function that tests whether all added tables can be allocated to the stage */
bool Memories::allocate_all() {
    mem_info mi;

    LOG3(" Analyzing tables");
    if (!analyze_tables(mi)) {
        return false;
    }
    unsigned row = 0;
    bool finished = false;

    do {
        clear_uses();
        clear_allocation();
        calculate_column_balance(mi, row);
        LOG2(" Column balance 0x" << hex(row));
        if (single_allocation_balance(mi, row)) {
            finished = true;
        }

        if (!finished)
            LOG2(" Increasing balance");
    } while (bitcount(row) < SRAM_COLUMNS && !finished);

    if (!finished) {
        return false;
    }

    LOG2("Memory allocation fits");
    return true;
}

/* This class is responsible for filling in all of the particular lists with the corresponding
   twoport tables, as well as getting the sharing of indirect action tables and selectors correct
*/
class SetupAttachedTables : public MauInspector {
    Memories &mem;
    Memories::table_alloc *ta;
    int entries;
    Memories::mem_info &mi;
    bool stats_pushed = false, meter_pushed = false, stateful_pushed = false;

    profile_t init_apply(const IR::Node *root) {
        profile_t rv = MauInspector::init_apply(root);
        if (ta->layout_option == nullptr) return rv;

        if (!ta->layout_option->layout.no_match_data() &&
            ta->layout_option->layout.ternary_indirect_required()) {
            auto unique_id = ta->build_unique_id(nullptr, false, -1, UniqueAttachedId::TIND_PP);
            (*ta->memuse)[unique_id].type = Memories::Use::TIND;

            mem.tind_tables.push_back(ta);
            mi.tind_tables++;
            mi.tind_RAMs += mem.mems_needed(entries, Memories::SRAM_DEPTH, 1, false);
        }

        if (ta->layout_option->layout.direct_ad_required()) {
            if (ta->table->layout.atcam) {
                for (int lt = 0; lt < ta->layout_option->logical_tables(); lt++) {
                    auto unique_id = ta->build_unique_id(nullptr, false, lt,
                                                         UniqueAttachedId::ADATA_PP);
                    (*ta->memuse)[unique_id].type = Memories::Use::ACTIONDATA;
                }
            } else {
                auto unique_id = ta->build_unique_id(nullptr, false, -1,
                                     UniqueAttachedId::ADATA_PP);
                (*ta->memuse)[unique_id].type = Memories::Use::ACTIONDATA;
            }
            mem.action_tables.push_back(ta);
            mi.action_tables++;
            int width = 1;
            int per_row = ActionDataPerWord(&ta->layout_option->layout, &width);
            int depth = mem.mems_needed(entries, Memories::SRAM_DEPTH, per_row, false);
            mi.action_bus_min += width; mi.action_RAMs += depth * width;
        }
        return rv;
    }

    /** For all ATCAM tables, all indirect tables are allocated on logical table 0.  For all
     *  other logical tables, an entry to the unattached tables needs to be added.
     */
    void initialize_indirect_atcam(const IR::MAU::AttachedMemory *at) {
        int logical_tables = ta->layout_option->partition_sizes.size();
        for (int lt = 1; lt < logical_tables; lt++) {
            auto current_lt_id = ta->build_unique_id(at, false, lt);
            auto tbl_id = ta->build_unique_id(nullptr, false, lt);
            auto lt_0_id = ta->build_unique_id(at, false, 0);
            (*ta->memuse)[tbl_id].unattached_tables.emplace(current_lt_id, lt_0_id);
        }
    }

    /** For shared attached tables, this initializes the unattached maps, if the attached
     *  table is already associated with a table
     */
    bool determine_unattached(const IR::MAU::AttachedMemory *at) {
        if (!mem.shared_attached.count(at)) {
            if (ta->table->layout.atcam && !at->direct)
                initialize_indirect_atcam(at);
            return false;
        }
        auto linked_id = mem.shared_attached.at(at)->build_unique_id(at);

        if (ta->table->layout.atcam) {
            int logical_tables = ta->layout_option->partition_sizes.size();
            for (int lt = 0; lt < logical_tables; lt++) {
                auto tbl_id = ta->build_unique_id(nullptr, false, lt);
                auto at_id = ta->build_unique_id(at, false, lt);
                (*ta->memuse)[tbl_id].unattached_tables.emplace(at_id, linked_id);
            }
        } else {
            auto tbl_id = ta->build_unique_id();
            auto at_id = ta->build_unique_id(at);
            (*ta->memuse)[tbl_id].unattached_tables.emplace(at_id, linked_id);
        }
        return true;
    }


    /* In order to only visit the attached tables of the current table */
    bool preorder(const IR::MAU::TableSeq *) { return false; }
    bool preorder(const IR::MAU::Action *) { return false; }

    bool preorder(const IR::MAU::ActionData *ad) {
        BUG_CHECK(!ad->direct, "No direct action data tables before table placement");

        if (determine_unattached(ad))
            return false;

        auto ad_id = ta->build_unique_id(ad);
        (*ta->memuse)[ad_id].type = Memories::Use::ACTIONDATA;

        mem.indirect_action_tables.push_back(ta);
        mem.shared_attached[ad] = ta;
        mi.action_tables++;
        int width = 1;
        int per_row = ActionDataPerWord(&ta->table->layout, &width);
        int depth = mem.mems_needed(ad->size, Memories::SRAM_DEPTH, per_row, false);
        mi.action_bus_min += width; mi.action_RAMs += depth * width;
        return false;
    }

    bool preorder(const IR::MAU::Meter *mtr) {
        if (determine_unattached(mtr))
            return false;

        auto mtr_id = ta->build_unique_id(mtr);
        (*ta->memuse)[mtr_id].type = Memories::Use::METER;
        mi.meter_tables++;
        mem.shared_attached[mtr] = ta;
        if (mtr->direct)
            mi.meter_RAMs += mem.mems_needed(entries, Memories::SRAM_DEPTH, 1, true);
        else
            mi.meter_RAMs += mem.mems_needed(entries, Memories::SRAM_DEPTH, 1, true);

        if (!meter_pushed) {
            mem.meter_tables.push_back(ta);
            meter_pushed = true;
        }
        return false;
    }

    bool preorder(const IR::MAU::Counter *cnt) {
        if (determine_unattached(cnt))
            return false;

        auto ctr_id = ta->build_unique_id(cnt);
        (*ta->memuse)[ctr_id].type = Memories::Use::COUNTER;
        mi.stats_tables++;
        mem.shared_attached[cnt] = ta;
        int per_row = CounterPerWord(cnt);
        if (cnt->direct)
            mi.stats_RAMs += mem.mems_needed(entries, Memories::SRAM_DEPTH, per_row, true);
        else
            mi.stats_RAMs += mem.mems_needed(cnt->size, Memories::SRAM_DEPTH, per_row, true);

        if (!stats_pushed) {
            mem.stats_tables.push_back(ta);
            stats_pushed = true;
        }
        return false;
    }

    void handle_dleft(const IR::MAU::StatefulAlu *salu) {
        auto &dleft_hash_sizes = ta->layout_option->dleft_hash_sizes;
        if (mem.shared_attached.count(salu)) {
            BUG("Currently sharing a dleft table between two tables is impossible");
        }


        for (int lt = 0; lt < ta->layout_option->logical_tables(); lt++) {
            int RAMs_needed = dleft_hash_sizes[lt] + 1;
            auto salu_id = ta->build_unique_id(salu, false, lt);
            mi.stateful_tables++;
            mi.stateful_RAMs += RAMs_needed;
            (*ta->memuse)[salu_id].type = Memories::Use::STATEFUL;
            // For setting up the learn/match associated IDs with a particular dleft hash table
            for (int lt_learn = 0; lt_learn < lt; lt++) {
                auto salu_learn_id = ta->build_unique_id(salu, false, lt_learn);
                (*ta->memuse)[salu_id].dleft_learn.push_back(salu_learn_id);
            }

            for (int lt_match = 0; lt_match < ta->layout_option->logical_tables(); lt_match++) {
                if (lt_match == lt)
                    continue;
                auto salu_match_id = ta->build_unique_id(salu, false, lt_match);
                (*ta->memuse)[salu_id].dleft_match.push_back(salu_match_id);
            }
        }

        if (!stateful_pushed) {
            mem.stateful_tables.push_back(ta);
            stateful_pushed = true;
        }
    }

    bool preorder(const IR::MAU::StatefulAlu *salu) {
        if (ta->table->for_dleft()) {
            handle_dleft(salu);
            return false;
        }
        if (determine_unattached(salu))
            return false;

        auto salu_id = ta->build_unique_id(salu);
        (*ta->memuse)[salu_id].type = Memories::Use::STATEFUL;

        mi.stateful_tables++;
        mem.shared_attached[salu] = ta;
        int per_row = RegisterPerWord(salu);
        if (salu->direct)
            mi.stateful_RAMs += mem.mems_needed(entries, Memories::SRAM_DEPTH, per_row, true);
        else
            mi.stateful_RAMs += mem.mems_needed(salu->size, Memories::SRAM_DEPTH, per_row, true);

        if (!stateful_pushed) {
            mem.stateful_tables.push_back(ta);
            stateful_pushed = true;
        }
        return false;
    }

    bool preorder(const IR::MAU::TernaryIndirect *) {
        BUG("Should be no Ternary Indirect before table placement is complete");
    }

    bool preorder(const IR::MAU::Selector *as) {
        if (determine_unattached(as))
            return false;

        auto sel_id = ta->build_unique_id(as);
        (*ta->memuse)[sel_id].type = Memories::Use::SELECTOR;
        mem.selector_tables.push_back(ta);
        mem.shared_attached[as] = ta;
        mi.selector_RAMs += 2;
        return false;
    }

    bool preorder(const IR::MAU::IdleTime *idle) {
        auto idle_id = ta->build_unique_id(idle);
        (*ta->memuse)[idle_id].type = Memories::Use::IDLETIME;

        mem.idletime_tables.push_back(ta);

        int per_row = IdleTimePerWord(idle);
        mi.idletime_RAMs += mem.mems_needed(entries, Memories::SRAM_DEPTH, per_row, false);
        return false;
    }

 public:
     explicit SetupAttachedTables(Memories &m, Memories::table_alloc *t, int e,
         Memories::mem_info &i) : mem(m), ta(t), entries(e), mi(i) {}
};

/* Run a quick analysis on all tables added by the table placement algorithm,
   and add the tables to their corresponding lists */
bool Memories::analyze_tables(mem_info &mi) {
    mi.clear();
    clear_table_vectors();
    for (auto *ta : tables) {
        if (ta->provided_entries == -1 || ta->provided_entries == 0) {
            auto unique_id = ta->build_unique_id(nullptr, true);
            if (ta->table_link != nullptr) {
                unique_id = ta->table_link->build_unique_id(nullptr, true);
            } else {
                mi.independent_gw_tables++;
                mi.logical_tables++;
            }
            (*ta->memuse)[unique_id].type = Use::GATEWAY;
            gw_tables.push_back(ta);
            LOG4("Gateway table for " << ta->table->name);
            continue;
        }
        auto table = ta->table;
        int entries = ta->provided_entries;
        if (ta->table->for_dleft()) {
            mi.logical_tables += ta->layout_option->logical_tables();
            BUG_CHECK(ta->layout_option->layout.no_match_hit_path(), "DLeft tables can only part"
                      "of the hit path");
            for (int lt = 0; lt < ta->layout_option->logical_tables(); lt++) {
                auto unique_id = ta->build_unique_id(nullptr, false, lt);
                (*ta->memuse)[unique_id].type = Use::EXACT;
            }
            no_match_hit_tables.push_back(ta);
        } else if (ta->layout_option->layout.no_match_data()) {
            auto unique_id = ta->build_unique_id();
            if (ta->layout_option->layout.no_match_hit_path()) {
                no_match_hit_tables.push_back(ta);
                (*ta->memuse)[unique_id].type = Use::EXACT;
            } else {
                // In order to potentially provide potential sizes for attached tables,
                // must at least have a size of 1
                (*ta->memuse)[unique_id].type = Use::TERNARY;
                ta->calculated_entries = 1;
                no_match_miss_tables.push_back(ta);
            }
            mi.no_match_tables++;
            mi.logical_tables++;
        } else if (table->layout.atcam) {
            atcam_tables.push_back(ta);
            mi.atcam_tables++;
            mi.logical_tables += ta->layout_option->logical_tables();
            int width = ta->layout_option->way.width;
            int groups = ta->layout_option->way.match_groups;
            for (size_t i = 0; i < ta->layout_option->partition_sizes.size(); i++) {
                int logical_table = static_cast<int>(i);
                auto unique_id = ta->build_unique_id(nullptr, false, logical_table);
                (*ta->memuse)[unique_id].type = Use::ATCAM;
            }
            int depth = mems_needed(entries, SRAM_DEPTH, groups, false);
            mi.match_RAMs += depth * width;
            mi.match_bus_min += ta->layout_option->logical_tables();
        } else if (!table->layout.ternary) {
            auto unique_id = ta->build_unique_id();
            LOG4("Exact match table " << unique_id.build_name());
            (*ta->memuse)[unique_id].type = Use::EXACT;
            exact_tables.push_back(ta);
            mi.match_tables++;
            mi.logical_tables++;
            int width = ta->layout_option->way.width;
            int groups = ta->layout_option->way.match_groups;
            int depth = mems_needed(entries, SRAM_DEPTH, groups, false);
            mi.match_bus_min += width;
            mi.match_RAMs += depth;
        } else {
           auto unique_id = ta->build_unique_id();
           LOG4("Ternary match table " << unique_id.build_name());
           (*ta->memuse)[unique_id].type = Use::TERNARY;
           ternary_tables.push_back(ta);
           mi.logical_tables++;
           mi.ternary_tables++;
           int bytes = table->layout.match_bytes;
           int TCAMs_needed = 0;
           while (bytes > 11) {
               bytes -= 11;
               TCAMs_needed += 2;
           }

           if (bytes == 11)
               TCAMs_needed += 3;
           else if (bytes > 5)
               TCAMs_needed += 2;
           else
               TCAMs_needed += 1;

           int depth = mems_needed(entries, TCAM_DEPTH, 1, false);
           mi.ternary_TCAMs += TCAMs_needed * depth;
           ta->calculated_entries = depth * 512;
        }
        SetupAttachedTables setup(*this, ta, entries, mi);
        ta->table->apply(setup);
    }
    return mi.constraint_check();
}

bool Memories::mem_info::constraint_check() const {
    if (match_tables + no_match_tables + ternary_tables + independent_gw_tables >
           Memories::TABLES_MAX
        || match_bus_min > Memories::SRAM_ROWS * Memories::BUS_COUNT
        || tind_tables > Memories::TERNARY_TABLES_MAX
        || action_tables > Memories::ACTION_TABLES_MAX
        || action_bus_min > Memories::SRAM_ROWS * Memories::BUS_COUNT
        || match_RAMs + action_RAMs + tind_RAMs > Memories::SRAM_ROWS * Memories::SRAM_COLUMNS
        || ternary_tables > Memories::TERNARY_TABLES_MAX
        || ternary_TCAMs > Memories::TCAM_ROWS * Memories::TCAM_COLUMNS
        || stats_tables > Memories::STATS_ALUS
        || meter_tables + stateful_tables + selector_tables > Memories::METER_ALUS
        || meter_RAMs + stats_RAMs + stateful_RAMs + selector_RAMs + idletime_RAMs >
           Memories::MAPRAM_COLUMNS * Memories::SRAM_ROWS
        || logical_tables > Memories::LOGICAL_TABLES) {
        return false;
    }
    return true;
}

/* Calculate the size of the ways given the number of RAMs necessary */
safe_vector<int> Memories::way_size_calculator(int ways, int RAMs_needed) {
    safe_vector<int> vec;
    if (ways == -1) {
    // FIXME: If the number of ways are not provided, not yet considered
    } else {
        for (int i = 0; i < ways; i++) {
            if (RAMs_needed < ways - i) {
                RAMs_needed = ways - i;
            }

            int depth = (RAMs_needed + ways - i - 1)/(ways - i);
            int log2sz = floor_log2(depth);
            if (depth != (1 << log2sz))
                depth = 1 << (log2sz + 1);

            RAMs_needed -= depth;
            vec.push_back(depth);
        }
    }
    return vec;
}

/* Find the rows of SRAMs that can hold the table, verified as well by the busses set in SRAM
*/
safe_vector<std::pair<int, int>>
Memories::available_SRAMs_per_row(unsigned mask, SRAM_group *group, int width_sect) {
    safe_vector<std::pair<int, int>> available_rams;
    auto group_search_bus = group->build_search_bus(width_sect);
    for (int i = 0; i < SRAM_ROWS; i++) {
        if (!search_bus_available(i, group_search_bus))
            continue;
        available_rams.push_back(std::make_pair(i, bitcount(mask & ~sram_inuse[i])));
    }

    std::sort(available_rams.begin(), available_rams.end(),
             [=](const std::pair<int, int> a, const std::pair<int, int> b) {
         int t;
         if ((t = a.second - b.second) != 0) return t > 0;
         return a > b;
    });
    return available_rams;
}

/* Simple now.  Just find rows with the available RAMs that it is asking for */
safe_vector<int> Memories::available_match_SRAMs_per_row(unsigned selected_columns_mask,
        unsigned total_mask, std::set<int> used_rows, SRAM_group *group, int width_sect) {
    safe_vector<int> matching_rows;
    auto group_search_bus = group->build_search_bus(width_sect);

    for (int i = 0; i < SRAM_ROWS; i++) {
        if (used_rows.find(i) != used_rows.end()) continue;
        if (!search_bus_available(i, group_search_bus))
            continue;

        if (bitcount(selected_columns_mask & ~sram_inuse[i]) == bitcount(selected_columns_mask))
            matching_rows.push_back(i);
    }

    std::sort(matching_rows.begin(), matching_rows.end(),
              [=] (const int a, const int b) {
        int t;
        if ((t = bitcount(~sram_inuse[a] & total_mask) -
                 bitcount(~sram_inuse[b] & total_mask)) != 0)
            return t < 0;

        auto bus = sram_search_bus[a];
        bool a_matching_bus = bus[0] == group_search_bus || bus[1] == group_search_bus;
        bus = sram_search_bus[b];
        bool b_matching_bus = bus[0] == group_search_bus || bus[1] == group_search_bus;

        if (a_matching_bus != b_matching_bus)
            return a_matching_bus;

        return a > b;
    });
    return matching_rows;
}

/* Based on the number of ways provided by the layout option, the ways sizes and
   select masks are initialized and provided to the way allocation algorithm */
void Memories::break_exact_tables_into_ways() {
    exact_match_ways.clear();
    for (auto *ta : exact_tables) {
        ta->calculated_entries = 0;
        auto unique_id = ta->build_unique_id();
        (*ta->memuse)[unique_id].ways.clear();
        (*ta->memuse)[unique_id].row.clear();
        int index = 0;
        ta->calculated_entries = ta->layout_option->entries;
        index = 0;
        assert(ta->match_ixbar->way_use.size() == ta->layout_option->way_sizes.size());
        for (auto &way : ta->match_ixbar->way_use) {
            SRAM_group *wa = new SRAM_group(ta, ta->layout_option->way_sizes[index],
                                             ta->layout_option->way.width, index,
                                             way.group, SRAM_group::EXACT);
            exact_match_ways.push_back(wa);
            (*ta->memuse)[unique_id].ways.emplace_back(ta->layout_option->way_sizes[index],
                                                       way.mask);
            index++;
        }
    }

    std::sort(exact_match_ways.begin(), exact_match_ways.end(),
              [=](const SRAM_group *a, const SRAM_group *b) {
         int t;
         if ((t = a->width - b->width) != 0) return t > 0;
         if ((t = (a->depth - a->placed) - (b->depth - b->placed)) != 0) return t > 0;
         if ((t = a->ta->calculated_entries - b->ta->calculated_entries) != 0) return t < 0;
         return a->number < b->number;
    });
}

/* Selects the best way to begin placing on the row, based on what was previously placed
   within this row.
*/
Memories::SRAM_group *Memories::find_best_candidate(SRAM_group *placed_wa, int row, int &loc) {
    if (exact_match_ways.empty()) return nullptr;
    auto bus = sram_search_bus[row];

    loc = 0;
    for (auto emw : exact_match_ways) {
        if (placed_wa->ta == emw->ta) {
            return emw;
        }
        loc++;
    }

    loc = 0;
    for (auto emw : exact_match_ways) {
        auto group_bus = emw->build_search_bus(placed_wa->width - 1);
        if ((!bus[0].free() && bus[0] == group_bus) || (!bus[1].free() && bus[1] == group_bus))
            return emw;
        loc++;
    }

    if (!bus[0].free() && !bus[1].free()) {
        return nullptr;
    }

    // FIXME: Perhaps do a best fit algorithm here
    loc = 0;
    return exact_match_ways[0];
}

/* Fill out the remainder of the row with other ways! */
bool Memories::fill_out_row(SRAM_group *placed_way, int row, unsigned column_mask) {
    int loc = 0;
    // FIXME: Need to adjust to the proper mask provided by earlier function
    while (bitcount(column_mask & ~sram_inuse[row]) > 0) {
        SRAM_group *way = find_best_candidate(placed_way, row, loc);
        if (way == nullptr)
            return true;

        match_selection match_select;
        if (!determine_match_rows_and_cols(way, row, column_mask, match_select, false))
            return false;
        fill_out_match_alloc(way, match_select, false);

        if (way->all_placed())
            exact_match_ways.erase(exact_match_ways.begin() + loc);
    }
    return true;
}

bool Memories::search_bus_available(int search_row, search_bus_info &sbi) {
    for (auto bus : sram_search_bus[search_row]) {
        if (bus.free() || bus == sbi)
            return true;
    }
    return false;
}

/* Returns the search bus that we are selecting on this row */
int Memories::select_search_bus(SRAM_group *group, int width_sect, int row) {
     auto group_search_bus = group->build_search_bus(width_sect);
     int index = 0;
     for (auto bus : sram_search_bus[row]) {
         if (bus == group_search_bus)
             return index;
         index++;
     }

     index = 0;
     for (auto bus : sram_search_bus[row]) {
         if (bus.free())
             return index;
         index++;
     }
     return -1;
}

/* Picks an empty/most open row, and begins to fill it in within a way */
bool Memories::find_best_row_and_fill_out(unsigned column_mask) {
    SRAM_group *way = exact_match_ways[0];
    safe_vector<std::pair<int, int>> available_rams
        = available_SRAMs_per_row(column_mask, way, way->width - 1);
    // No memories left to place anything
    if (available_rams.size() == 0)
        return false;

    int row = available_rams[0].first;
    match_selection match_select;
    if (available_rams[0].second == 0)
        return false;
    if (!determine_match_rows_and_cols(way, row, column_mask, match_select, false))
        return false;
    fill_out_match_alloc(way, match_select, false);

    if (way->all_placed())
        exact_match_ways.erase(exact_match_ways.begin());

    if (bitcount(~sram_inuse[row] & column_mask) == 0)
        return true;
    else
        return fill_out_row(way, row, column_mask);
}

/* Determining if the side from which we want to give extra columns to the exact match
   allocation, potentially cutting room from either tind tables or twoport tables */
bool Memories::cut_from_left_side(const mem_info &mi, int left_given_columns,
                                          int right_given_columns) {
    if (right_given_columns > mi.columns(mi.right_side_RAMs())
        && left_given_columns <= mi.columns(mi.left_side_RAMs())) {
        return false;
    } else if (right_given_columns <= mi.columns(mi.right_side_RAMs())
               && left_given_columns > mi.columns(mi.left_side_RAMs())) {
        return true;
    } else if (mi.columns(mi.left_side_RAMs()) < left_given_columns) {
        return true;
    } else if (mi.columns(mi.right_side_RAMs()) < right_given_columns) {
        return false;
    } else if (left_given_columns > 0) {
        return true;
    } else if (left_given_columns == 0) {
        return false;
    } else {
        BUG("We have a problem in calculate column balance");
    }
}

/* Calculates the number of columns and the distribution of columns on the left and
   right side of the SRAM array in order to place all exact match tables */
void Memories::calculate_column_balance(const mem_info &mi, unsigned &row) {
    int min_columns_required = (mi.match_RAMs + SRAM_COLUMNS - 1) / SRAM_COLUMNS;
    int left_given_columns = 0;
    int right_given_columns = 0;

    if (bitcount(row) == 0) {
        left_given_columns = mi.left_side_RAMs();
        right_given_columns = mi.right_side_RAMs();

        bool add_to_right = true;
        while (mi.columns(mi.non_SRAM_RAMs()) > left_given_columns + right_given_columns) {
            if (add_to_right) {
                right_given_columns++;
                add_to_right = false;
            } else {
                left_given_columns++;
                add_to_right = true;
            }
        }
        while (min_columns_required > SRAM_COLUMNS - (left_given_columns + right_given_columns)) {
            if (cut_from_left_side(mi, left_given_columns, right_given_columns))
                left_given_columns--;
            else
                right_given_columns--;
        }
    } else {
        left_given_columns = bitcount(~row & 0xf);
        right_given_columns = bitcount(~row & 0x3f0);
        if (cut_from_left_side(mi, left_given_columns, right_given_columns))
            left_given_columns--;
        else
            right_given_columns--;
    }

    unsigned mask = 0;
    for (int i = 0; i < LEFT_SIDE_COLUMNS - left_given_columns; i++) {
        mask |= (1 << i);
    }
    for (int i = 0; i < SRAM_COLUMNS - LEFT_SIDE_COLUMNS - right_given_columns; i++) {
        mask |= (1 << (i + LEFT_SIDE_COLUMNS));
    }
    row = mask;
}

/* Allocates all of the ways */
bool Memories::allocate_all_exact(unsigned column_mask) {
    allocation_count = 0;
    break_exact_tables_into_ways();
    while (exact_match_ways.size() > 0) {
        if (find_best_row_and_fill_out(column_mask) == false) {
            return false;
        }
    }
    compress_ways(false);
    for (auto *ta : exact_tables) {
        auto unique_id = ta->build_unique_id();
        LOG4("Exact match table " << unique_id.build_name());
        auto alloc = (*ta->memuse)[unique_id];
        for (auto row : alloc.row) {
            LOG4("Row is " << row.row << " and bus is " << row.bus);
            LOG4("Col is " << row.col);
        }
    }
    return true;
}


void Memories::compress_row(Use &alloc) {
    std::stable_sort(alloc.row.begin(), alloc.row.end(),
        [=](const Memories::Use::Row a, const Memories::Use::Row b) {
            int t;
            if ((t = a.row - b.row) != 0) return t < 0;
            if ((t = a.bus - b.bus) != 0) return t < 0;
            return a.alloc < b.alloc;
        });
    for (size_t i = 0; i < alloc.row.size() - 1; i++) {
        if (alloc.row[i].row == alloc.row[i+1].row &&
            alloc.row[i].bus == alloc.row[i+1].bus) {
            BUG_CHECK(alloc.row[i].word == alloc.row[i+1].word, "SRAMs that share a row "
                      "and bus must share the same word");
            alloc.row[i].col.insert(alloc.row[i].col.end(), alloc.row[i+1].col.begin(),
                                    alloc.row[i+1].col.end());
            alloc.row.erase(alloc.row.begin() + i + 1);
            i--;
        }
    }

    std::stable_sort(alloc.row.begin(), alloc.row.end(),
        [=](const Memories::Use::Row &a, const Memories::Use::Row &b) {
        int t;
        if ((t = a.alloc - b.alloc) != 0) return t < 0;
        if ((t = a.word - b.word) != 0) return t < 0;
        return a.row < b.row;
    });
}

/** Adjust the Use structures so that there is is only one Use::Row object per row and bus.
 *  Otherwise, the algorithm will complain of a bus collision on a row for the same table
 */
void Memories::compress_ways(bool atcam) {
    if (atcam) {
       for (auto *ta : atcam_tables) {
           for (int lt = 0; lt < ta->layout_option->logical_tables(); lt++) {
                auto unique_id = ta->build_unique_id(nullptr, false, lt);
                auto &alloc = (*ta->memuse)[unique_id];
                compress_row(alloc);
           }
       }
    } else {
        for (auto *ta : exact_tables) {
            auto unique_id = ta->build_unique_id();
            auto &alloc = (*ta->memuse)[unique_id];
            compress_row(alloc);
        }
    }
}

/** Creates the separate SRAM_group objects for the atcam partitions.  A partition is created per
 *  logical table per way in that logical table.  Let me demonstrate the math in the following
 *  example:
 *
 *  Say table t has a size of 122880 entries.  The partition index will be 12 bits in size, and
 *  the table key can fit two entries per RAM, and is only one RAM wide.  How many RAMs are
 *  required, and how should the algorithm split these partitions.
 *
 *  A 12 bit partition index will require 4 independent RAMs to lookup simultaneously.  This
 *  is because selecting a RAM line requires 10 bits, as the RAMs have 2^10 = 1024 entries.  The
 *  2 bits provides 2^2 = 4 degrees of freedom to select one of the RAMs.
 *
 *  The smaller table with this setup will be the following amount of entries:
 *      1024 RAM rows * 2 entries per RAM * 1 RAM per wide match * 4 degrees of freedom
 *
 *  This is equal to 8096 entries.  Furthermore, as the table grows, it grows by 4 RAMs, as
 *  a RAM is required by each degree of freedom.
 *
 *  The total number of RAMs will be:
 *     122880 entries / (1024 RAM rows * 2 entries per RAM) = 60 RAMs.
 *  However, the number of simultaneous RAMs looked up will be:
 *      60 RAMs / 4 degrees of freedom = 15 RAMs
 *  This means that the simultaneous entries looked up will be:
 *      15 RAMs * 2 entries per RAM = 30 simultaneous entries.
 *
 *  Now, due to the constraints of Tofino, if used in an algorithmic TCAM table, in order to
 *  cascade the priority, RAMs that are simultaneously looked up have to be within the same
 *  SRAM row.  Furthermore, one can only have a maximum of 6 RAMs cascading priority.  This is
 *  described in section 6.4.3.1.1 Exact Match Prioritization in the uArch.  In the algorithm
 *  we limit the maximum cascading to 5 RAMs.  The reason for this discrepancy is that the
 *  RAM rows are only 10 RAMs, and the algorithm tries to balance putting partitions on the right
 *  and left side of the RAM array.  6 cascading priorities comes out of the RAM row initially
 *  being 12 RAMs.
 *
 *  Thus with our example, we require the following number of rows:
 *      15 RAMs / 5 maximum rams per row = 3 total rows.
 *
 *  In order to get the prioritization to cross rows, the original ATCAM must be split into
 *  separate logical tables.  The number of logical tables required is the number of independent
 *  simultaneous look up rows, in our example 3 logical tables.  These logical tables are chained
 *  in a hit/miss chain.  On a hit a logical table will point to the original next table of the
 *  algorithmic TCAM table.  On a miss, the logical table will go to the next logical table in the
 *  chain.  Through this structure, earlier logical tables have a higher priority.
 */
void Memories::break_atcams_into_partitions() {
    atcam_partitions.clear();

    for (auto *ta : atcam_tables) {
        ta->calculated_entries = 0;
        for (int lt = 0; lt < ta->layout_option->logical_tables(); lt++) {
            auto unique_id = ta->build_unique_id(nullptr, false, lt);
            (*ta->memuse)[unique_id].row.clear();
            (*ta->memuse)[unique_id].ways.clear();
        }
        int total_depth = (ta->provided_entries + ta->table->layout.partition_count - 1) /
                          ta->table->layout.partition_count;
        int max_partition_rams = (total_depth + ta->layout_option->way.match_groups - 1) /
                                  ta->layout_option->way.match_groups;
        int search_bus_per_lt = (ta->table->layout.partition_count + SRAM_DEPTH - 1) / SRAM_DEPTH;
        ta->calculated_entries = search_bus_per_lt * max_partition_rams * SRAM_DEPTH;


        int logical_table = 0;
        for (auto partition_size : ta->layout_option->partition_sizes) {
            for (int j = 0; j < search_bus_per_lt; j++) {
                auto part = new SRAM_group(ta, partition_size, ta->layout_option->way.width,
                                           j, 0, SRAM_group::ATCAM);
                part->logical_table = logical_table;
                atcam_partitions.push_back(part);
            }
            logical_table++;
        }

        for (int lt = 0; lt < ta->layout_option->logical_tables(); lt++) {
            BUG_CHECK(ta->match_ixbar->way_use.size() == 1, "Somehow multiple ixbar ways "
                      "calculated for an ATCAM table");
            auto way = ta->match_ixbar->way_use[0];
            auto unique_id = ta->build_unique_id(nullptr, false, lt);
            for (int j = 0; j < ta->layout_option->partition_sizes[lt]; j++) {
                (*ta->memuse)[unique_id].ways.emplace_back(search_bus_per_lt, way.mask);
            }
        }
    }
    std::sort(atcam_partitions.begin(), atcam_partitions.end(),
              [=](const SRAM_group *a, const SRAM_group *b) {
        int t;
        if ((t = a->width - b->width) != 0) return t > 0;
        if ((t = (a->depth - a->placed) - (b->depth - b->placed)) != 0) return t > 0;
        if ((t = a->ta->calculated_entries - b->ta->calculated_entries) != 0) return t < 0;
        if ((t = a->logical_table - b->logical_table) != 0) return t < 0;
        return a->number < b->number;
    });
}

/** Given an initial row to place a way or partition on, determine which search/match bus,
 *  and which RAMs in that row to assign to the partition.  If the match is wide, then one
 *  must find rows with columns.  Due to the constraint that wide matches must be in the same
 *  row in order for the hit signals to be able to traverse wide matches, the columns in each
 *  row must be the same.
 */
bool Memories::determine_match_rows_and_cols(SRAM_group *group, int row, unsigned column_mask,
        match_selection &match_select, bool atcam) {
    // Pick a bus
    int match_bus = select_search_bus(group, group->width - 1, row);
    BUG_CHECK(match_bus >= 0, "Search somehow found an impossible bus");
    match_select.rows.push_back(row);
    match_select.buses[row] = match_bus;
    int cols = 0;
    std::set<int> determined_rows;
    determined_rows.emplace(row);
    match_select.widths[row] = group->width - 1;

    // Pick available columns
    for (int i = 0; i < SRAM_COLUMNS && cols < group->left_to_place(); i++) {
        if (((1 << i) & column_mask) == 0) continue;
        if (sram_use[row][i]) continue;
        match_select.column_mask |= (1 << i);
        match_select.cols.push_back(i);
        cols++;
    }

    // If the match is wide, pick rows that have these columns available
    for (int i = group->width - 2; i >= 0; i--) {
        safe_vector<int> matching_rows =
            available_match_SRAMs_per_row(match_select.column_mask, column_mask,
                                          determined_rows, group, i);
        if (matching_rows.size() == 0)
            return false;
        int wide_row = matching_rows[0];
        match_select.rows.push_back(wide_row);
        int match_bus = select_search_bus(group, i, wide_row);
        BUG_CHECK(match_bus >= 0, "Search somehow found an impossible bus");
        match_select.buses[wide_row] = match_bus;
        match_select.widths[wide_row] = i;
        determined_rows.emplace(wide_row);
    }

    // A logical table partition must be fully placed
    if (atcam &&
        bitcount(match_select.column_mask) != static_cast<size_t>(group->left_to_place()))
        return false;

    std::sort(match_select.rows.begin(), match_select.rows.end());
    std::reverse(match_select.rows.begin(), match_select.rows.end());
    std::sort(match_select.cols.begin(), match_select.cols.end());
    // In order to maintain prioritization on the right side of the array
    if (atcam && column_mask == partition_mask(RIGHT))
        std::reverse(match_select.cols.begin(), match_select.cols.end());

    return true;
}

/** Given a list of rows and columns, save this in the Memories::Use object for each table,
 *  as well as store this information within the Memories object structure
 */
void Memories::fill_out_match_alloc(SRAM_group *group, match_selection &match_select, bool atcam) {
    auto unique_id = group->build_unique_id();
    auto &alloc = (*group->ta->memuse)[unique_id];
    auto name = unique_id.build_name();

    // Save row and column information
    for (auto row : match_select.rows) {
        auto bus = match_select.buses.at(row);
        int width = match_select.widths.at(row);
        alloc.row.emplace_back(row, bus, width, allocation_count);
        auto &back_row = alloc.row.back();
        for (auto col : match_select.cols) {
            sram_use[row][col] = name;
            back_row.col.push_back(col);
        }

        auto group_search_bus = group->build_search_bus(width);
        sram_inuse[row] |= match_select.column_mask;
        if (!sram_search_bus[row][bus].free()) {
            BUG_CHECK(sram_search_bus[row][bus] == group_search_bus,
                      "Search bus initialization mismatch");
        } else {
            sram_search_bus[row][bus] = group_search_bus;
            sram_match_bus[row][bus] = group_search_bus.name;
            sram_print_search_bus[row][bus] = group_search_bus.name;
        }
    }

    group->placed += bitcount(match_select.column_mask);
    // Store information on ways.  Only one RAM in each way will be searched per packet.  The
    // RAM is chosen by the select bits in the upper 12 bits of the hash matrix
    if (atcam) {
        alloc.type = Use::ATCAM;
        int number = 0;
        for (auto col : match_select.cols) {
            safe_vector<std::pair<int, int>> ram_pairs(match_select.rows.size());
            for (auto row : match_select.rows) {
                ram_pairs[match_select.widths.at(row)] = std::make_pair(row, col);
            }
            std::reverse(ram_pairs.begin(), ram_pairs.end());
            alloc.ways[number].rams.insert(alloc.ways[number].rams.end(),
                                           ram_pairs.begin(), ram_pairs.end());
            number++;
        }
    } else {
        for (auto col : match_select.cols) {
            safe_vector<std::pair<int, int>> ram_pairs(match_select.rows.size());
            for (auto row : match_select.rows) {
                ram_pairs[match_select.widths.at(row)] = std::make_pair(row, col);
            }
            std::reverse(ram_pairs.begin(), ram_pairs.end());
            alloc.ways[group->number].rams.insert(alloc.ways[group->number].rams.end(),
                                                  ram_pairs.begin(), ram_pairs.end());
        }
    }
    allocation_count++;
}

/** Given a partition, find a set of rows, buses, and columns for that partition.  An ATCAM
 *  partition must be fully placed, as the prioritization can only pass down through a row
 */
bool Memories::find_best_partition_for_atcam(unsigned partition_mask) {
    auto part = atcam_partitions[0];

    safe_vector<std::pair<int, int>> available_rams
        = available_SRAMs_per_row(partition_mask, part, part->width - 1);
    if (available_rams.size() == 0) {
        return false;
    }
    int row = available_rams[0].first;
    if (available_rams[0].second == 0) {
        return false;
    }

    match_selection match_select;
    if (!determine_match_rows_and_cols(part, row, partition_mask, match_select, true)) {
        return false;
    }
    fill_out_match_alloc(part, match_select, true);

    BUG_CHECK(part->all_placed(), "The partition was not fully placed within the partition");
    atcam_partitions.erase(atcam_partitions.begin());
    return fill_out_partition(row, partition_mask);
}

/** Given that a partition has already been placed within the row and partition side, find
 *  another partition that can be placed within that same space
 */
Memories::SRAM_group *Memories::best_partition_candidate(int row, unsigned column_mask,
        int &loc) {
    loc = -1;
    auto search_bus = sram_search_bus[row];
    int available_rams = bitcount(column_mask & ~sram_inuse[row]);
    for (auto part : atcam_partitions) {
        loc++;
        auto group_search_bus = part->build_search_bus(0);
        if (group_search_bus != search_bus[0] && group_search_bus != search_bus[1])
            continue;
        if (part->left_to_place() > available_rams)
            continue;
        return part;
    }
    return nullptr;
}

/** Given that a partition has been placed on this row and side, try to fill in the remainder of
 *  the space with potentially another partition.  If the partition depth is 2 for instance, one
 *  can fit partitions on the same search and result bus, as long as it's in the same logical
 *  table.
 */
bool Memories::fill_out_partition(int row, unsigned partition_mask) {
    int loc = 0;
    while ((partition_mask & ~sram_inuse[row]) > 0) {
        auto part = best_partition_candidate(row, partition_mask, loc);
        if (part == nullptr)
            return true;

        match_selection match_select;
        if (!determine_match_rows_and_cols(part, row, partition_mask, match_select, true))
            return false;

        fill_out_match_alloc(part, match_select, true);
        BUG_CHECK(part->all_placed(), "A partition has to be entirely placed in a row");
        atcam_partitions.erase(atcam_partitions.begin() + loc);
    }
    return true;
}

/** Pick a side to allocate the next partition.  Based on how left and right RAMs are available,
 *  given what is required to be on either side and what has been previously allocated.  Tries to
 *  maintain a level of balance between the sides in order to allocate tind and swbox tables
 *  later.
 */
unsigned Memories::best_partition_side(mem_info &mi) {
    int RAMs_placed[RAM_SIDES] = {0, 0};
    int partitions_allocated[RAM_SIDES] = {0, 0};

    for (int i = 0; i < SRAM_ROWS; i++) {
        for (int side = 0; side < RAM_SIDES; side++) {
            int RAMs = bitcount(side_mask(static_cast<RAM_side_t>(side)) & sram_inuse[i]);
            RAMs_placed[side] += RAMs;
            if (RAMs > 0)
                partitions_allocated[side]++;
        }
    }

    int left_side_needed = RAMs_placed[LEFT] + mi.left_side_RAMs();
    int right_side_needed = RAMs_placed[RIGHT] + mi.right_side_RAMs();

    int left_RAMs_avail = LEFT_SIDE_RAMS - left_side_needed;
    int right_RAMs_avail = RIGHT_SIDE_RAMS - right_side_needed;

    RAM_side_t preferred_side;
    // If no partitions available on a side, pick the other
    if (partitions_allocated[LEFT] == SRAM_ROWS)
        preferred_side = RIGHT;
    else if (partitions_allocated[RIGHT] == SRAM_ROWS)
        preferred_side = LEFT;
    // Pick the side that has more relative RAMs available
    else if (right_RAMs_avail / RIGHT_SIDE_COLUMNS < left_RAMs_avail / LEFT_SIDE_COLUMNS)
        preferred_side = LEFT;
    else
        preferred_side = RIGHT;
    return partition_mask(preferred_side);
}

bool Memories::allocate_all_atcam(mem_info &mi) {
    allocation_count = 0;
    break_atcams_into_partitions();
    while (!atcam_partitions.empty()) {
        auto partition_mask = best_partition_side(mi);
        if (!find_best_partition_for_atcam(partition_mask))
            return false;
    }
    compress_ways(true);
    return true;
}


/* Number of continuous TCAMs needed for table width */
int Memories::ternary_TCAMs_necessary(table_alloc *ta, int &midbyte) {
    midbyte = ta->table_format->split_midbyte;
    return ta->table_format->tcam_use.size();
}

/* Finds the stretch on the ternary array that can hold entries */
bool Memories::find_ternary_stretch(int TCAMs_necessary, int &row, int &col,
                                    int midbyte, bool &split_first) {
    for (int j = 0; j < TCAM_COLUMNS; j++) {
        int clear_cols = 0;
        split_first = false;

        for (int i = 0; i < TCAM_ROWS; i++) {
            if (tcam_use[i][j]) {
                clear_cols = 0;
                split_first = false;
                continue;
            }

            // These checks are enforcing that the midbyte is shared correctly between two
            // contiguous blocks.
            if ((TCAMs_necessary % 2) == 0) {
                if ((i % 2) == 1 && clear_cols == 0)
                    continue;
            } else {
                if ((i % 2) == 1 && clear_cols == 0) {
                    if (midbyte >= 0 && tcam_midbyte_use[i / 2][j] >= 0
                        && midbyte != tcam_midbyte_use[i / 2][j]) {
                        continue;
                    }
                    split_first = true;
                }
            }

            clear_cols++;
            if (clear_cols == TCAMs_necessary) {
                col = j;
                row = i - clear_cols + 1;
                return true;
            }
        }
    }
    return false;
}

/* Allocates all ternary entries within the stage */
bool Memories::allocate_all_ternary() {
    allocation_count = 0;
    std::sort(ternary_tables.begin(), ternary_tables.end(),
        [=](const table_alloc *a, table_alloc *b) {
        int t;
        if ((t = a->table->layout.match_bytes - b->table->layout.match_bytes) != 0) return t > 0;
        if ((t = a->calculated_entries - b->calculated_entries) != 0) return t > 0;
        return true;
    });

    // FIXME: All of this needs to be changed on this to match up with xbar
    for (auto *ta : ternary_tables) {
        int midbyte = -1;
        int TCAMs_necessary = ternary_TCAMs_necessary(ta, midbyte);
        // FIXME: If the table is just a default action table, essentially a hack
        if (TCAMs_necessary == 0)
            continue;

        int row = 0; int col = 0;
        auto unique_id = ta->build_unique_id();
        Memories::Use &alloc = (*ta->memuse)[unique_id];
        for (int i = 0; i < ta->calculated_entries / 512; i++) {
            bool split_midbyte = false;
            if (!find_ternary_stretch(TCAMs_necessary, row, col, midbyte, split_midbyte))
                return false;
            int word = 0;
            if (split_midbyte)
                word = TCAMs_necessary - 1;
            for (int i = row; i < row + TCAMs_necessary; i++) {
                 tcam_use[i][col] = unique_id.build_name();
                 auto tcam = ta->table_format->tcam_use[word];
                 if (tcam_midbyte_use[i/2][col] >= 0 && tcam.byte_group >= 0)
                     BUG_CHECK(tcam_midbyte_use[i/2][col] == tcam.byte_group, "Two contiguous "
                         "TCAMs cannot correct share midbyte");
                 else if (tcam_midbyte_use[i/2][col] < 0)
                     tcam_midbyte_use[i/2][col] = tcam.byte_group;
                 alloc.row.emplace_back(i, col, word, allocation_count);
                 alloc.row.back().col.push_back(col);
                 word++;
                 word %= TCAMs_necessary;
            }
            allocation_count++;
        }
    }

    for (auto *ta : ternary_tables) {
        auto unique_id = ta->build_unique_id();
        auto &alloc = (*ta->memuse)[unique_id];
        std::stable_sort(alloc.row.begin(), alloc.row.end(),
            [=](const Memories::Use::Row &a, const Memories::Use::Row &b) {
            int t;
            if ((t = a.alloc - b.alloc) != 0) return t < 0;
            if ((t = a.word - b.word) != 0) return t < 0;
            return a.row < b.row;
        });
    }

    for (auto *ta : ternary_tables) {
        auto unique_id = ta->build_unique_id();
        auto &alloc = (*ta->memuse)[unique_id];
        LOG4("Allocation of " << unique_id.build_name());
        for (auto row : alloc.row) {
            LOG4("Row is " << row.row << " and bus is " << row.bus);
            LOG4("Col is " << row.col);
        }
    }

    return true;
}

/* Breaks up the tables requiring tinds into groups that can be allocated within the
   SRAM array */
void Memories::find_tind_groups() {
    tind_groups.clear(); for (auto *ta : tind_tables) {
        int depth = (ta->calculated_entries + 2047) / 2048;
        tind_groups.push_back(new SRAM_group(ta, depth, 0, SRAM_group::TIND));
        tind_groups.back()->ppt = UniqueAttachedId::TIND_PP;
    }
}

/* Finds the best row in which to put the tind table */
int Memories::find_best_tind_row(SRAM_group *tg, int &bus) {
    int open_space = 0;
    unsigned left_mask = 0xf;
    safe_vector<int> available_rows;
    auto name = tg->build_unique_id().build_name();
    for (int i = 0; i < SRAM_ROWS; i++) {
        auto tbus = tind_bus[i];
        if (!tbus[0] || tbus[0] == name || !tbus[1] || tbus[1] == name) {
            available_rows.push_back(i);
            open_space += bitcount(~sram_inuse[i] & left_mask);
        }
    }

    if (open_space == 0)
        return -1;

    std::sort(available_rows.begin(), available_rows.end(),
        [=] (const int a, const int b) {
        int t;
        if ((t = bitcount(~sram_inuse[a] & left_mask)
               - bitcount(~sram_inuse[b] & left_mask)) != 0) return t > 0;

        auto tbus0 = tind_bus[a];
        auto tbus1 = tind_bus[b];
        if ((tbus0[0] == name || tbus0[1] == name)
            && !(tbus1[0] == name || tbus1[1] == name))
            return true;
        if ((tbus1[0] == name || tbus1[1] == name)
            && !(tbus0[0] == name || tbus0[1] == name))
            return false;
        return a < b;
    });


    int best_row = available_rows[0];
    if (!tind_bus[best_row][0] || tind_bus[best_row][0] == name)
        bus = 0;
    else
        bus = 1;

    return best_row;
}

/* Compresses the tind groups on the same row in the use, into one row */
void Memories::compress_tind_groups() {
    for (auto *ta : tind_tables) {
        auto unique_id = ta->build_unique_id(nullptr, false, -1, UniqueAttachedId::TIND_PP);
        auto &alloc = (*ta->memuse)[unique_id];
        std::sort(alloc.row.begin(), alloc.row.end(),
            [=](const Memories::Use::Row a, const Memories::Use::Row b) {
                int t;
                if ((t = a.row - b.row) != 0) return t < 0;
                if ((t = a.bus - b.bus) != 0) return t < 0;
                return false;
            });
        for (size_t i = 0; i < alloc.row.size() - 1; i++) {
            if (alloc.row[i].row == alloc.row[i+1].row &&
                alloc.row[i].bus == alloc.row[i+1].bus) {
                alloc.row[i].col.insert(alloc.row[i].col.end(), alloc.row[i+1].col.begin(),
                                        alloc.row[i+1].col.end());
                alloc.row.erase(alloc.row.begin() + i + 1);
                i--;
            }
        }
    }
}

/* Allocates all of the ternary indirect tables into the first column if they fit.
   FIXME: This is obviously a punt and needs to be adjusted. */
bool Memories::allocate_all_tind() {
    std::sort(tind_tables.begin(), tind_tables.end(),
        [=] (const table_alloc *a, const table_alloc *b) {
        int t;
        if ((t = a->calculated_entries - b->calculated_entries) != 0) return t > 0;
        return true;
    });
    find_tind_groups();

    while (!tind_groups.empty()) {
        auto *tg = tind_groups[0];
        int best_bus = 0;
        int best_row = find_best_tind_row(tg, best_bus);
        if (best_row == -1) return false;
        for (int i = 0; i < LEFT_SIDE_COLUMNS; i++) {
            if (~sram_inuse[best_row] & (1 << i)) {
                auto unique_id = tg->build_unique_id();
                cstring name = unique_id.build_name();
                sram_inuse[best_row] |= (1 << i);
                sram_use[best_row][i] = name;
                tg->placed++;
                if (tg->all_placed()) {
                    tind_groups.erase(tind_groups.begin());
                }
                tind_bus[best_row][best_bus] = name;

                auto &alloc = (*tg->ta->memuse)[unique_id];
                alloc.row.emplace_back(best_row, best_bus);
                alloc.row.back().col.push_back(i);
                break;
            }
        }
    }
    compress_tind_groups();
    for (auto *ta : tind_tables) {
        auto unique_id = ta->build_unique_id(nullptr, false, -1, UniqueAttachedId::TIND_PP);
        auto &alloc = (*ta->memuse)[unique_id];
        LOG4("Allocation of " << unique_id.build_name());
        for (auto row : alloc.row) {
            LOG4("Row is " << row.row << " and bus is " << row.bus);
            LOG4("Col is " << row.col);
        }
    }
    return true;
}

/* Calculates the necessary size and requirements for any and all indirect actions and selectors.
   Selectors must be done before indirect actions */
void Memories::swbox_bus_selectors_indirects() {
    for (auto *ta : selector_tables) {
        for (auto back_at : ta->table->attached) {
            auto at = back_at->attached;
            // FIXME: need to adjust if the action selector is larger than 2 RAMs, based
            // on the pragmas provided to the compiler
            const IR::MAU::Selector *as = nullptr;
            if ((as = at->to<IR::MAU::Selector>()) == nullptr)
                continue;
            auto selector_group = new SRAM_group(ta, 2, 0, SRAM_group::SELECTOR);
            selector_group->attached = as;
            synth_bus_users.insert(selector_group);
        }
    }

    for (auto *ta : indirect_action_tables) {
        for (auto back_at : ta->table->attached) {
            auto at = back_at->attached;
            const IR::MAU::ActionData *ad = nullptr;
            if ((ad = at->to<IR::MAU::ActionData>()) == nullptr)
                continue;
            int width = 1;
            int per_row = ActionDataPerWord(&ta->layout_option->layout, &width);
            int depth = mems_needed(ad->size, SRAM_DEPTH, per_row, false);
            int vpn_increment = ActionDataVPNIncrement(&ta->layout_option->layout);
            int vpn_offset = ActionDataVPNStartPosition(&ta->layout_option->layout);
            SRAM_group *selector = nullptr;

            for (auto grp : synth_bus_users) {
                if (grp->ta == ta && grp->type == SRAM_group::SELECTOR) {
                    selector = grp;
                    break;
                }
            }
            for (int i = 0; i < width; i++) {
                auto action_group = new SRAM_group(ta, depth, i, SRAM_group::ACTION);
                action_group->attached = ad;
                action_group->vpn_increment = vpn_increment;
                action_group->vpn_offset = vpn_offset;
                if (selector != nullptr) {
                    action_group->sel.sel_group = selector;
                    selector->sel.action_groups.insert(action_group);
                }
                action_bus_users.insert(action_group);
            }
        }
    }
}

/** Sets up the SRAM_groups for stateful ALUs and the dleft hash tables.  For the dleft hash
 *  tables, the number of SRAM groups created are provided from the number of logical tables
 *  provided by the layout option.
 */
void Memories::swbox_bus_stateful_alus() {
    for (auto *ta : stateful_tables) {
        if (ta->table->for_dleft())
            continue;
        const IR::MAU::StatefulAlu *salu = nullptr;
        for (auto back_at : ta->table->attached) {
            auto at = back_at->attached;
            if ((salu = at->to<IR::MAU::StatefulAlu>()) == nullptr)
                continue;
            if (salu->selector)
                // use the selector's memory
                continue;
            int per_row = RegisterPerWord(salu);
            int depth;
            if (salu->direct) {
                depth = mems_needed(ta->calculated_entries, SRAM_DEPTH, per_row, true);
            } else {
                depth = mems_needed(salu->size, SRAM_DEPTH, per_row, true);
            }
            auto reg_group = new SRAM_group(ta, depth, 0, SRAM_group::REGISTER);
            reg_group->attached = salu;
            synth_bus_users.insert(reg_group);
            reg_group->requires_ab = salu->alu_output();
        }
    }

    for (auto *ta : stateful_tables) {
        if (!ta->table->for_dleft())
            continue;
        const IR::MAU::StatefulAlu *salu = nullptr;
        for (auto back_at : ta->table->attached) {
            salu = back_at->attached->to<IR::MAU::StatefulAlu>();
            if (salu == nullptr)
                continue;
            auto &dleft_hash_sizes = ta->layout_option->dleft_hash_sizes;
            for (int lt = 0; lt < ta->layout_option->logical_tables(); lt++) {
                int depth = dleft_hash_sizes[lt] + 1;
                auto *reg_group = new SRAM_group(ta, depth, 0, SRAM_group::REGISTER);
                reg_group->attached = salu;
                reg_group->logical_table = lt;
                synth_bus_users.insert(reg_group);
                reg_group->requires_ab = salu->alu_output();
            }
        }
    }
}

/* Calculates the necessary size and requirements for any meter and counter tables within
   the stage */
void Memories::swbox_bus_meters_counters() {
    for (auto *ta : stats_tables) {
        for (auto back_at : ta->table->attached) {
            auto at = back_at->attached;
            const IR::MAU::Counter *stats = nullptr;
            if ((stats = at->to<IR::MAU::Counter>()) == nullptr)
                continue;
            int per_row = CounterPerWord(stats);
            int depth;
            if (stats->direct) {
                depth = mems_needed(ta->calculated_entries, SRAM_DEPTH, per_row, true);
            } else {
                depth = mems_needed(stats->size, SRAM_DEPTH, per_row, true);
            }
            auto *stats_group = new SRAM_group(ta, depth, 0, SRAM_group::STATS);
            stats_group->attached = stats;
            synth_bus_users.insert(stats_group);
        }
    }

    for (auto *ta : meter_tables) {
        const IR::MAU::Meter *meter = nullptr;
        for (auto back_at : ta->table->attached) {
            auto at = back_at->attached;
            if ((meter = at->to<IR::MAU::Meter>()) == nullptr)
                continue;
            int depth;
            if (meter->direct)
                depth = mems_needed(ta->calculated_entries, SRAM_DEPTH, 1, true);
            else
                depth = mems_needed(meter->size, SRAM_DEPTH, 1, true);

            auto *meter_group = new SRAM_group(ta, depth, 0, SRAM_group::METER);

            meter_group->attached = meter;
            bool cm_needed = meter->implementation.name != "lpf" &&
                             meter->implementation.name != "wred";
            if (cm_needed) {
                if (meter->direct)
                    meter_group->cm.needed = mems_needed(ta->calculated_entries, SRAM_DEPTH,
                                                         COLOR_MAPRAM_PER_ROW, false);
                else
                    meter_group->cm.needed = mems_needed(meter->size, SRAM_DEPTH,
                                                         COLOR_MAPRAM_PER_ROW, false);
            } else {
                meter_group->requires_ab = true;
            }
            synth_bus_users.insert(meter_group);
        }
    }
}

/* Breaks up all tables requiring an action to be parsed into SRAM_group, a structure
   designed for adding to SRAM array  */
void Memories::find_swbox_bus_users() {
    action_bus_users.clear();
    synth_bus_users.clear();
    must_be_placed_in_half.clear();

    for (auto *ta : action_tables) {
        int width = 1;
        int per_row = ActionDataPerWord(&ta->layout_option->layout, &width);
        int vpn_increment = ActionDataVPNIncrement(&ta->layout_option->layout);
        int vpn_offset = ActionDataVPNStartPosition(&ta->layout_option->layout);
        if (ta->table->layout.atcam) {
            int search_bus_per_lt = (ta->table->layout.partition_count + SRAM_DEPTH - 1)
                                     / SRAM_DEPTH;
            int entries_per_part_sect = search_bus_per_lt * ta->layout_option->way.match_groups;
            int logical_table = 0;
            for (auto partition_size : ta->layout_option->partition_sizes) {
                int entries = entries_per_part_sect * partition_size * SRAM_DEPTH;
                int depth = mems_needed(entries, SRAM_DEPTH, per_row, false);
                for (int i = 0; i < width; i++) {
                    auto *act_group = new SRAM_group(ta, depth, i, SRAM_group::ACTION);
                    act_group->logical_table = logical_table;
                    act_group->direct = true;
                    act_group->vpn_increment = vpn_increment;
                    act_group->vpn_offset = vpn_offset;
                    act_group->ppt = UniqueAttachedId::ADATA_PP;
                    action_bus_users.insert(act_group);
                }
                logical_table++;
            }
        } else {
            int depth = mems_needed(ta->calculated_entries, SRAM_DEPTH, per_row, false);
            for (int i = 0; i < width; i++) {
                auto act_group = new SRAM_group(ta, depth, i, SRAM_group::ACTION);
                act_group->vpn_increment = vpn_increment;
                act_group->vpn_offset = vpn_offset;
                act_group->ppt = UniqueAttachedId::ADATA_PP;
                action_bus_users.insert(act_group);
            }
        }
    }
    swbox_bus_selectors_indirects();
    swbox_bus_meters_counters();
    swbox_bus_stateful_alus();
}

/** Due to the color mapram allocation algorithm described over color_mapram_candidates, the
 *  number of RAMs for synth2port tables and action tables are actually different.
 */
void Memories::adjust_RAMs_available(swbox_fill &curr_oflow, int RAMs_avail[OFLOW],
                                     int row, RAM_side_t side) {
    RAMs_avail[ACTION] = bitcount(~sram_inuse[row] & side_mask(side));
    if (side == LEFT)
        return;

    RAMs_avail[SYNTH] = RAMs_avail[ACTION];

    if (!(curr_oflow && curr_oflow.group->type == SRAM_group::METER))
        return;

    int open_maprams = bitcount(sram_inuse[row] & side_mask(side));
    if (open_maprams > curr_oflow.group->cm.left_to_place())
        return;

    int difference = curr_oflow.group->cm.left_to_place() - open_maprams;
    if (difference > RAMs_avail[SYNTH])
        difference = RAMs_avail[SYNTH];

    if (curr_oflow.group->left_to_place() < RAMs_avail[ACTION])
        RAMs_avail[SYNTH] -= difference;
}

void Memories::init_candidate(swbox_fill candidates[SWBOX_TYPES], switchbox_t order[SWBOX_TYPES],
                              bool bus_used[SWBOX_TYPES], switchbox_t type, int &order_index,
                              swbox_fill choice, bool test_action_bus) {
     candidates[type] = choice;
     bus_used[type] = true;
     BUG_CHECK(order_index < SWBOX_TYPES, "Only a limited number of buses per row");
     order[order_index++] = type;
     if (test_action_bus)
         bus_used[ACTION] |= candidates[type].group->needs_ab();
}

/** Determines the potential candidates, as well as the order, of the candidates to be placed
 *  in this row.  The following constraints mapped in these decision are:
 *
 *  Synth2Port tables can only have 1 home row, as you can only have one ALU coordinated to
 *  a synth2port table.  However, action data tables can have multiple home rows, as only one bus
 *  is going to fire due to addressing, and the other all 0 buses will be ORed into the same
 *  location on the action data bus.
 *
 *  The algorithm prefers to place synth2port tables if it can, because there is less
 *  space for these tables in the first place.  It goes best fit, then overflow, then next
 *  largest candidate as choices, for synth2port, then for action.  One can put a best fit only
 *  because the overflow can just skip over this particular row.
 */
void Memories::determine_candidates_order(swbox_fill candidates[SWBOX_TYPES],
                                    swbox_fill best_fits[OFLOW], swbox_fill &curr_oflow,
                                    swbox_fill nexts[OFLOW], int RAMs_avail[OFLOW],
                                    RAM_side_t side, switchbox_t order[SWBOX_TYPES]) {
    bool bus_used[SWBOX_TYPES] = {false, false, false};
    int order_i = 0;

    if (side == RIGHT) {
        if (best_fits[SYNTH] && best_fits[SYNTH].group->left_to_place() == RAMs_avail[SYNTH]
        && !bus_used[ACTION] && !bus_used[SYNTH] && !bus_used[OFLOW]) {
            init_candidate(candidates, order, bus_used, SYNTH, order_i, best_fits[SYNTH], true);
        }

        if (curr_oflow && curr_oflow.group->type != SRAM_group::ACTION && !bus_used[OFLOW]) {
            init_candidate(candidates, order, bus_used, OFLOW, order_i, curr_oflow, false);
        }
        if (nexts[SYNTH] && !bus_used[SYNTH]) {
            init_candidate(candidates, order, bus_used, SYNTH, order_i, nexts[SYNTH], true);
        }
    }


    if (best_fits[ACTION] && best_fits[ACTION].group->left_to_place() == RAMs_avail[ACTION]
        && !bus_used[ACTION] && !bus_used[SYNTH] && !bus_used[OFLOW]) {
        init_candidate(candidates, order, bus_used, ACTION, order_i, best_fits[ACTION], false);
    }


    if (curr_oflow && curr_oflow.group->type == SRAM_group::ACTION && !bus_used[OFLOW]) {
        init_candidate(candidates, order, bus_used, OFLOW, order_i, curr_oflow, false);
    }

    if (nexts[ACTION] && !bus_used[ACTION]) {
        init_candidate(candidates, order, bus_used, ACTION, order_i, nexts[ACTION], false);
    }
}

/** Is a test within best candidates to see if even though sel unplaced is not yet finished,
 *  its action can be placed within this next row so that a new selector can be placed as well
 *
 *  Currently commented out as this doesn't fit in, but the optimization could be used in
 *  another PR
bool Memories::can_place_selector(action_fill &curr_oflow, SRAM_group *curr_check,
                                  int suppl_RAMs_available, int action_RAMs_available,
                                  action_fill &sel_unplaced) {
    Currently removed as it is an optimization that needs a better approach
    if (!sel_unplaced.group->sel.one_action_left())
        return false;

    if (curr_oflow.group && curr_oflow.group->type != SRAM_group::ACTION) {
        if (curr_check->left_to_place() > suppl_RAMs_available) {
            return false;
        }
        if (sel_unplaced.group->sel.one_action_left()
            && (sel_unplaced.group->sel.action_left_to_place() + curr_check->left_to_place()
            > action_RAMs_available))
            return false;

    } else {
        if (sel_unplaced.group->sel.one_action_left()
            && (sel_unplaced.group->sel.action_left_to_place() + 1 > action_RAMs_available))
            return false;
    }
    return true;
}
*/

/** This function called is used in the particular scenario where a previous selector's action
 *  can be placed within the same row as a new selector.  This has the possibility to use
 *  up potentially some RAMs in a particular row
 *
 *  Currently removed as it is an optimization that needs a better approach
void Memories::selector_candidate_setup(action_fill candidates[SWBOX_TYPES],
                                        action_fill &curr_oflow, action_fill &sel_oflow,
                                        action_fill nexts[OFLOW], int order[SWBOX_TYPES],
                                        int RAMs_avail[OFLOW]) {
    bool bus_used[SWBOX_TYPES] = {false, false, false};
    int order_i = 0;
    if (

    if (curr_oflow && curr_oflow.group->type != SRAM_group::ACTION && !bus_used[OFLOW])
        set_cand_and_order(candidates, order, bus_used, OFLOW, order_i, curr_oflow, false);

    // FIXME: Potentially could save room if the action group that is overflowing is the
    // sel_unplaced group

    if (curr_oflow && curr_oflow.group->type != SRAM_group::ACTION) {
        candidates[SYNTH] = nexts[SYNTH];
        order[SUPPL_IND] = 0;
        if (candidates[SYNTH].group->left_to_place() < RAMs_avail[ACTION]) {
            candidates[ACTION].group = sel_unplaced.group->sel.action_group_left();
            order[ACTION_IND] = 1;
            if (candidates[SYNTH].group->left_to_place() + candidates[ACTION].group->left_to_place()
                < RAMs_avail[SYNTH]) {
                candidates[OFLOW].group = curr_oflow.group;
                order[OFLOW_IND] = 2;
            }
        }
    } else {
        candidates[ACTION].group = sel_unplaced.group->sel.action_group_left();
        order[ACTION_IND] = 0;
        candidates[SYNTH] = nexts[SYNTH];
        order[SUPPL_IND] = 1;
        // FIXME: Double check fo putting the correct information
        if (candidates[ACTION].group->left_to_place() + candidates[SYNTH].group->left_to_place()
            > RAMs_avail[ACTION]) {
            if (candidates[ACTION].group->left_to_place() + 1 != RAMs_avail[ACTION])
                BUG("We have an issue in the double selector algorithm");
        } else if (candidates[ACTION].group->left_to_place()
                   + candidates[SYNTH].group->left_to_place()
                   < RAMs_avail[ACTION]
                   && curr_oflow && curr_oflow.group != candidates[ACTION].group
                   && candidates[SYNTH].group != curr_oflow.group) {
            order[OFLOW_IND] = 2;
            candidates[OFLOW].group = curr_oflow.group;
        }
    }
}
*/

/** Given a list of candidates, and an order in which they can be placed, determine how
 *  many RAMs each of the candidates get.  If a candidate requires no RAMs, and no maprams,
 *  that candidate is cleared.
 */
void Memories::set_up_RAM_counts(swbox_fill candidates[SWBOX_TYPES],
                                 switchbox_t order[SWBOX_TYPES], int RAMs_avail[OFLOW],
                                 int RAMs[SWBOX_TYPES]) {
    int RAMs_used = 0;
    int maprams_used = 0;
    bool synth_oflow_fully_placed = true;
    for (int i = 0; i < SWBOX_TYPES; i++) {
        if (order[i] == SWBOX_TYPES) continue;
        auto &candidate = candidates[order[i]];
        BUG_CHECK(candidate, "No candidate when an order is specified for this type");
        BUG_CHECK(!(candidate.group->all_placed() && candidate.group->cm.all_placed()),
                  "Trying to place a candidate that should have been already completely placed");

        auto type = candidate.group->is_synth_type() ? SYNTH : ACTION;

        int RAMs_needed = candidate.group->left_to_place();
        RAMs[i] = std::min(RAMs_needed, RAMs_avail[type] - RAMs_used);

        if (order[i] == OFLOW && type == SYNTH && RAMs_needed > RAMs[i])
            synth_oflow_fully_placed = false;
        BUG_CHECK(RAMs[i] >= 0, "Cannot have negative RAMs available");
        RAMs_used += RAMs[i];
        if (type == SYNTH)
            maprams_used += RAMs[i];
    }

    for (int i = 0; i < SWBOX_TYPES; i++) {
        if (order[i] != SWBOX_TYPES) {
            auto &candidate = candidates[order[i]];
            if (RAMs[i] > 0) continue;
            if (!candidate.group->cm.all_placed()) {
                if (order[i] == OFLOW)
                    continue;
                if (order[i] == SYNTH && synth_oflow_fully_placed)
                    continue;
            }
            candidate.clear();
        }
    }
}

int Memories::half_RAMs_available(int row, bool right_only) {
    int lowest_row = row >= LOGICAL_ROW_MISSING_OFLOW / 2 ? LOGICAL_ROW_MISSING_OFLOW / 2 : 0;
    int RAMs = 0;
    for (int i = row; i >= lowest_row; i--) {
        if (right_only)
            RAMs += bitcount(side_mask(RIGHT) & ~sram_inuse[i]);
        else
            RAMs += bitcount(side_mask(RAM_SIDES) & ~sram_inuse[i]);
    }
    return RAMs;
}

int Memories::half_map_RAMs_available(int row) {
    int lowest_row = row >= LOGICAL_ROW_MISSING_OFLOW / 2 ? LOGICAL_ROW_MISSING_OFLOW / 2 : 0;

    int map_RAMs = 0;
    unsigned mapram_mask = (1 << MAPRAM_COLUMNS) - 1;
    for (int i = row; i >= lowest_row; i--) {
        map_RAMs += bitcount(mapram_mask & ~mapram_inuse[i]);
    }
    return map_RAMs;
}

int Memories::synth_half_RAMs_to_place() {
    int RAMs = 0;
    for (auto grp : must_be_placed_in_half) {
        if (!grp->is_synth_type())
            continue;
        RAMs += grp->left_to_place();
    }
    return RAMs;
}

int Memories::synth_half_map_RAMs_to_place() {
    int map_RAMs = 0;
    for (auto grp : must_be_placed_in_half) {
        if (!grp->is_synth_type())
            continue;
        map_RAMs += grp->left_to_place() + grp->cm.left_to_place();
    }
    return map_RAMs;
}

int Memories::action_half_RAMs_to_place() {
    int RAMs = 0;
    for (auto grp : must_be_placed_in_half) {
        if (grp->is_synth_type())
            continue;
        RAMs += grp->left_to_place();
    }
    return RAMs;
}

bool Memories::action_table_best_candidate(SRAM_group *next_synth, swbox_fill &sel_oflow) {
    bool must_check = false;

#ifdef HAVE_JBAY
    if (Device::currentDevice() == "JBay")
        must_check = true;
#endif /* HAVE_JBAY */

    if (!must_check)
        return true;
    if ((next_synth && next_synth->type == SRAM_group::SELECTOR) || sel_oflow)
        return false;
    return true;
}

/** The only major difference in the memory algorithm in Tofino vs. JBay is that one
 *  cannot overflow any information over match central, specifically:
 *      1. Data through the HV switchbox
 *      2. Color mapram data and from the meter ALU
 *      3. Selector Addresses to their associated Action Data RAMs
 *
 *  The algorithm thus needs to prevent a synth2port table from being placed within a half
 *  if it fully cannot be placed within that half.  For action rows, it is less important,
 *  as the action row can start a brand new homerow.  However, a synth2port cannot begin
 *  on a new ALU.
 *
 *  Currently in the driver a synth2port table is only allocated to one stateful ALU, and
 *  cannot be moved around.  Furthermore, in the direct case, one can only use movereg across
 *  a single logical table, which means to move entries, the driver would have to support
 *  a level above movereg.
 */
bool Memories::action_table_in_half(SRAM_group *action_table, SRAM_group *next_synth,
                                   swbox_fill &sel_oflow) {
    bool must_check = false;

#ifdef HAVE_JBAY
     if (Device::currentDevice() == "JBay")
         must_check = true;
#endif /* HAVE_JBAY */

    if (!must_check)
        return true;

    if (next_synth && next_synth->type == SRAM_group::SELECTOR) {
        if (next_synth->sel.action_groups.count(action_table) == 0) {
            return false;
        }
    }
    if (sel_oflow) {
        if (sel_oflow.group->sel.action_groups.count(action_table) == 0)
            return false;
    }
    return true;
}

bool Memories::synth_in_half(SRAM_group *synth_table, int row) {
    bool must_check = false;
#ifdef HAVE_JBAY
    if (Device::currentDevice() == "JBay")
         must_check = true;
#endif /* HAVE_JBAY */

    if (!must_check)
        return true;
    int s2p_RAMs = synth_table->left_to_place();
    int map_RAMs = synth_table->left_to_place() + synth_table->cm.left_to_place();
    int total_RAMs = synth_table->total_left_to_place();


    if (total_RAMs + action_half_RAMs_to_place() + synth_half_RAMs_to_place()
        > half_RAMs_available(row, false))
        return false;
    if (s2p_RAMs + synth_half_RAMs_to_place() > half_RAMs_available(row, true))
        return false;
    if (map_RAMs + synth_half_map_RAMs_to_place() > half_map_RAMs_available(row))
        return false;
    return true;
}

/** Determine potential candidates for the allocation algorithm to choose from.  Specifically
 *  best_fits are the one that could best fit in the current row, and nexts are the one with
 *  the greatest requirements.
 *
 *  If the selector overflow is used, the algorithm will not currently place a selector,
 *  even if one could possibly be placed on a the row, as it would not require an overflow.
 *  This is an optimization that one could add later.
 */
void Memories::best_candidates(swbox_fill best_fits[OFLOW], swbox_fill nexts[OFLOW],
                               swbox_fill &curr_oflow, swbox_fill &sel_oflow,
                               bool stats_available, bool meter_available, RAM_side_t side,
                               int row, int RAMs_avail[OFLOW]) {
    int min_left = 0;
    int min_diff = 0;
    if (side == RIGHT) {
        /* Determine the best fit supplementary table on the row */

        for (auto synth_table : synth_bus_users) {
            if (curr_oflow.group == synth_table)
                continue;
            BUG_CHECK(synth_table->placed == 0, "Cannot have partially placed synth2port table "
                                                "that isn't overflow");
            if (!stats_available && synth_table->type == SRAM_group::STATS)
                continue;
            if (!meter_available && synth_table->type != SRAM_group::STATS)
                continue;
            if (synth_table->type == SRAM_group::SELECTOR && sel_oflow)
                continue;
            if (!synth_in_half(synth_table, row))
                continue;
            int RAM_diff = synth_table->left_to_place() - RAMs_avail[SYNTH];
            if (RAM_diff >= 0 && RAM_diff < min_diff) {
                best_fits[SYNTH].group = synth_table;
                min_diff = RAM_diff;
            }
        }
        min_left = 0;
        /* Determine the supplementary table with the most left to place */
        for (auto synth_table : synth_bus_users) {
            if (curr_oflow.group == synth_table)
                continue;
            if (!stats_available && synth_table->type == SRAM_group::STATS)
                continue;
            if (!meter_available && synth_table->type != SRAM_group::STATS)
                continue;
            if (synth_table->type == SRAM_group::SELECTOR && sel_oflow) {
                /*
                && !can_place_selector(curr_oflow, synth_table,
                               RAMs_avail[SYNTH], RAMs_avail[ACTION], sel_unplaced)) {
                */
                continue;
            }

            if (!synth_in_half(synth_table, row))
                continue;
            if (synth_table->total_left_to_place() > min_left) {
                nexts[SYNTH].group = synth_table;
                min_left = synth_table->total_left_to_place();
            }
        }
    }


    /*
    if (sel_unplaced && nexts[SYNTH] && nexts[SYNTH].group->type == SRAM_group::SELECTOR) {
        return;
    }
    */

    /* Determine the best fit action on the current row.  Cannot be current oflow group */
    min_diff = 0;
    for (auto action_table : action_bus_users) {
        if (curr_oflow.group == action_table)
            continue;
        if (action_table->sel.sel_linked() && !action_table->sel.sel_any_placed())
            continue;
        if (!action_table_best_candidate(nexts[SYNTH].group, sel_oflow))
            continue;

        int RAM_diff = action_table->left_to_place() - RAMs_avail[ACTION];
        if (RAM_diff >= 0 && RAM_diff < min_diff) {
            best_fits[ACTION].group = action_table;
            min_diff = RAM_diff;
        }
    }

    min_left = 0;
    /* Determine the action with the most left to place */
    for (auto action_table : action_bus_users) {
        if (curr_oflow.group == action_table) {
            continue;
        }
        // Operates under the assumption that next synth will be attempted before next action.
        // Assumed from the determine_candidates_order algorithm
        if (action_table->sel.sel_linked() && !action_table->sel.sel_any_placed()) {
            if (!(nexts[SYNTH] && nexts[SYNTH].group == action_table->sel.sel_group)) {
                continue;
            }
        }

        if (!action_table_in_half(action_table, nexts[SYNTH].group, sel_oflow))
            continue;

        if (action_table->left_to_place() > min_left) {
            nexts[ACTION].group = action_table;
            min_left = action_table->left_to_place();
        }
    }

#ifdef HAVE_JBAY
    // The algorithm, in order to place the action tables within the same half, must guarantee
    // that there is enough room for that particular table
    if (Device::currentDevice() == "Tofino")
        return;

    if (curr_oflow && must_be_placed_in_half.count(curr_oflow.group) == 0
        && nexts[SYNTH] && nexts[SYNTH].group->type == SRAM_group::SELECTOR) {
        BUG_CHECK(curr_oflow.group->type == SRAM_group::ACTION, "An overflowing synth2port table "
                  "must be in placed in that half");
        curr_oflow.clear();
    }
#endif /* HAVE_JBAY */
}

/** Given a number of RAMs to allocate, this function finds available RAMs and saves the masks
 *  used with the candidate.
 */
void Memories::fill_out_masks(swbox_fill candidates[SWBOX_TYPES], switchbox_t order[SWBOX_TYPES],
                              int RAMs[SWBOX_TYPES], int row, RAM_side_t side) {
    unsigned init_RAM_mask = ~sram_inuse[row] & side_mask(side);
    unsigned used_RAM_mask = 0;
    for (int i = 0; i < SWBOX_TYPES; i++) {
        // Initialized to SWBOX_TYPES, as this would be out of bounds of the array
        if (order[i] == SWBOX_TYPES) continue;
        auto &candidate = candidates[order[i]];
        if (!candidate) continue;
        if (RAMs[i] == 0 && !candidate.group->cm.all_placed()) continue;

        BUG_CHECK(RAMs[i] > 0, "Empty RAMs count impossible in fill_out_masks function");
        unsigned current_mask = 0;
        int RAMs_filled = 0;

        for (int j = 0; j < SRAM_COLUMNS && RAMs_filled < RAMs[i]; j++) {
            if (((1 << j) & init_RAM_mask & ~used_RAM_mask) == 0)
                continue;
            current_mask |= (1 << j);
            RAMs_filled++;
        }
        used_RAM_mask |= current_mask;
        candidate.mask = current_mask;
        if (candidate.group->type != SRAM_group::ACTION)
            candidate.mapram_mask = current_mask;
    }
}

/** This is the algorithm to determine which candidates to place on this particular row, as well
 *  as what RAMs to use on particular row.  Potential candidates are decided in the
 *  best_candidates function based on what is currently available.  These may be limited due to
 *  table currently used in overflow.
 *
 *  The function determine_candidates_order selects the potential candidates for this row.
 *  The function set_up_RAM_counts then determine the number of RAMs each of these candidates get. 
 *  Finally, fill_out_masks and color_mapram_candidates determine which RAMs/maprams go to
 *  which candidate.
 *
 *  Unfortunately the functions are not entirely independent, and corner cases will give rise
 *  to particular lines within each function.  Hopefull this is detailed throughout the comments.
 */
void Memories::find_swbox_candidates(int row, RAM_side_t side, swbox_fill candidates[SWBOX_TYPES],
                                      bool stats_available, bool meter_available,
                                      swbox_fill &curr_oflow, swbox_fill &sel_oflow) {
    if (action_bus_users.empty() && synth_bus_users.empty()) {
        return;
    }

    int RAMs_avail[OFLOW] = {0, 0};

    // Due to color mapram constraints, the RAMs_available for SYNTH vs. ACTION may be different
    adjust_RAMs_available(curr_oflow, RAMs_avail, row, side);
    // No best fits or nexts for oflow, as there is only one oflow location
    swbox_fill best_fits[OFLOW];
    swbox_fill nexts[OFLOW];

    // Determines the candidates and potential order
    best_candidates(best_fits, nexts, curr_oflow, sel_oflow, stats_available, meter_available,
                    side, row, RAMs_avail);
    if (!best_fits[ACTION] && !best_fits[SYNTH] && !curr_oflow && !nexts[ACTION] && !nexts[SYNTH]) {
        if (curr_oflow && curr_oflow.group->type == SRAM_group::METER
            && !curr_oflow.group->cm.all_placed()) {
            candidates[OFLOW] = curr_oflow;
            color_mapram_candidates(candidates, side);
        }
        bool actions_available = false;
        for (auto action_group : action_bus_users) {
            if (!action_group->sel.sel_linked() ||
                (action_group->sel.sel_linked() && action_group->sel.sel_any_placed())) {
                actions_available = true;
                break;
            }
        }
        if (!actions_available) {
            LOG3("No actions available, due to the selector");
            return;
        }
        LOG3("Nothing to place");
        return;
    }

    switchbox_t order[SWBOX_TYPES] = {SWBOX_TYPES, SWBOX_TYPES, SWBOX_TYPES};

    /*
    if (sel_unplaced && nexts[SYNTH] && nexts[SYNTH].group->type == SRAM_group::SELECTOR) {
        selector_candidate_setup(candidates, curr_oflow, sel_unplaced, nexts, order, RAMs_avail);
    }
    */

    determine_candidates_order(candidates, best_fits, curr_oflow, nexts, RAMs_avail, side, order);
    int RAMs[SWBOX_TYPES] = {0, 0, 0};
    set_up_RAM_counts(candidates, order, RAMs_avail, RAMs);
    fill_out_masks(candidates, order, RAMs, row, side);
    color_mapram_candidates(candidates, side);
}

/** Determine the masks for an individual candidates color maprams */
void Memories::set_color_maprams(swbox_fill &candidate, unsigned &avail_maprams) {
    int maprams_needed = candidate.group->cm.left_to_place();
    int maprams_placed = 0;
    unsigned mapram_mask = 0;
    for (int i = LEFT_SIDE_COLUMNS; i < SRAM_COLUMNS && maprams_placed < maprams_needed; i++) {
        if (((1 << i) & avail_maprams) == 0) continue;
        mapram_mask |= (1 << i);
        maprams_placed++;
    }
    avail_maprams &= ~mapram_mask;
    candidate.mapram_mask |= mapram_mask;
}

/** Color maprams are separate maprams that have to be reserved with a meter.  Color is Tofino
 *  is stored as a 2bit field, and a mapram can store up to 4 colors per row.  The color maprams
 *  are used to store information as the packet comes in to the MAU stage, as well as when the
 *  packet leaves the switch.  The total constraints for how color maprams must be laid out are
 *  detailed in a few sections.  First is 6.2.8.4.9 Map RAM Addressing.  The switchbox constraints
 *  are detailed in sections 6.2.11.1.7 Meter Color Map RAM Read Switchbox and 6.2.11.1.8 Meter
 *  Color Map RAM Write Switchbox.  Finally the constraints are summarized in 6.2.13.4 Meter
 *  Color Map RAMs.
 *
 *  Essentially, reads and writes happen at different times within a meter color mapram, and thus
 *  are accessed differently.  First is on read, the meter uses either the home row meter address
 *  or an overflow address bus to lookup the correct location.  This means that nothing else
 *  on that row can use that overflow bus, unless it is the meter that corresponds to that
 *  bus.
 *
 *  On a write to the color mapram, the address used is either an idletime or stats address bus,
 *  In general, it is preferable to use an idletime bus, as they're less constrained.  However,
 *  occasionally you must use a stats address bus, and thus that stats address bus cannot be
 *  accessing any other table.
 *
 *  Also on a write, the meter provides the new color to a color mapram through a color mapram
 *  switchbox.  Similar to the selector or data switchbox, only one color can pass between rows.
 *  Thus, two meters cannot require to go through the same color mapram switchbox.
 *
 *  You might wonder how the algorithm deals with all of these constraints.  The simple solution
 *  is to just require both the RAMs the color maprams to both be placed before the next
 *  synth2port table can be placed.  This is not too big of an issue, as both Action Data tables
 *  and exact match tables do not require maprams, and thus can be placed in the same location
 *  as the color mapram.  However, because of this constraint, the number of RAMs available
 *  for synth2port tables and action data tables may be different.  Thus the need of the
 *  function adjust_RAMs_available is specified.
 *
 *  This function is similar to fill_out_masks, except that it is for color maprams only,
 *  rather than maprams.  Right now the overflowing meter's color maprams are placed before
 *  any home row meter would be placed.  Similar to the RAMs, a mapram order could be
 *  determined, but I wanted to handle this separately.
 */
void Memories::color_mapram_candidates(swbox_fill candidates[SWBOX_TYPES], RAM_side_t side) {
    if (side != RIGHT)
        return;
    unsigned avail_maprams = side_mask(side);
    for (int i = 0; i < SWBOX_TYPES; i++) {
        if (!candidates[i]) continue;
        avail_maprams &= ~candidates[i].mapram_mask;
    }

    if (candidates[OFLOW] && candidates[OFLOW].group->type == SRAM_group::METER) {
        if (!candidates[OFLOW].group->cm.all_placed())
            set_color_maprams(candidates[OFLOW], avail_maprams);
        BUG_CHECK(candidates[OFLOW].mapram_mask != 0,
                  "Oflow candidate does not have any maprams placed");
    }

    if (candidates[SYNTH] && !candidates[SYNTH].group->cm.all_placed()) {
        set_color_maprams(candidates[SYNTH], avail_maprams);
        // FIXME: Could have a similar algorithm to set_up_RAM_counts for color mapram,
        // instead of having separate color mapram information known throughout function.
        // Currently unnecessary because the cm_order never changes.  I think that a function
        // before this should clear all unused candidates rather than this
        if (candidates[SYNTH].mapram_mask == 0)
            candidates[SYNTH].clear();
    }
}

/** This converts the swbox_fill masks to allocations within the Memories::Use object.  Also
 *  links wide action tables underneath the same Use objects
 */
void Memories::fill_swbox_side(swbox_fill candidates[SWBOX_TYPES], int row, RAM_side_t side) {
    for (int i = 0; i < SWBOX_TYPES; i++) {
        auto sb_type = static_cast<switchbox_t>(i);
        auto &candidate = candidates[i];
        if (!candidate) continue;
        if (bitcount(candidate.mask) == 0 && bitcount(candidate.mapram_mask) == 0)
            BUG("Trying to fill in a use object with nothing to allocate");
        fill_RAM_use(candidates[i], row, side, sb_type);
        if (candidate.group->type == SRAM_group::METER)
            fill_color_mapram_use(candidate, row, side);
        remove_placed_group(candidate, side);
    }

    // FIXME: Potentially need to set up the difference between wide action tables within
    // the assembly output
    if (candidates[ACTION] && candidates[OFLOW]
        && candidates[ACTION].group->same_wide_action(*candidates[OFLOW].group)) {
        if (candidates[ACTION].group == candidates[OFLOW].group) {
            BUG("Shouldn't be the same for action and oflow");
        }
    }
}

/** Fill out the Memories::Use object with the RAMs reserved by the candidate, as well as any
 *  other useful data structures.  If the table is synth2port, the algorithm also reserves
 *  maprams as well.
 */
void Memories::fill_RAM_use(swbox_fill &candidate, int row, RAM_side_t side, switchbox_t type) {
    if (candidate.mask == 0)
        return;

    auto unique_id = candidate.group->build_unique_id();
    auto name = unique_id.build_name();
    auto &alloc = (*candidate.group->ta->memuse)[unique_id];
    if (type == OFLOW) {
        overflow_bus[row][side] = name;
        alloc.row.emplace_back(row);
        if (candidate.group->type == SRAM_group::ACTION)
            alloc.row.back().word = candidate.group->number;
    } else if (type == SYNTH) {
        BUG_CHECK(side == RIGHT, "Allocating Synth2Port table on left side of RAM array");
        twoport_bus[row] = name;
        alloc.row.emplace_back(row);
    } else if (type == ACTION) {
        action_data_bus[row][side] = name;
        alloc.row.emplace_back(row, side, candidate.group->number);
        alloc.home_row.emplace_back(2*row + side, candidate.group->number);
        candidate.group->recent_home_row = row;
    }

    for (int k = 0; k < SRAM_COLUMNS; k++) {
        if (((1 << k) & side_mask(side)) == 0)
            continue;

        if ((1 << k) & candidate.mask) {
            sram_use[row][k] = name;
            alloc.row.back().col.push_back(k);
            alloc.row.back().vpn.push_back(candidate.group->calculate_next_vpn());
            candidate.group->placed++;
            if (candidate.group->is_synth_type()) {
                mapram_use[row][k - LEFT_SIDE_COLUMNS] = name;
                alloc.row.back().mapcol.push_back(k - LEFT_SIDE_COLUMNS);
            }
        }
    }

    sram_inuse[row] |= candidate.mask;
    if (type == SYNTH) {
        if (candidate.group->type == SRAM_group::STATS)
            stats_alus[row/2] = name;
        else
            meter_alus[row/2] = name;
    }
}

/** The algorithm operates under the assumption that anything left within the action_bus_users and
 *  synth_bus_users still has allocation requirements.  This function therefore removes any
 *  group that has been completely placed by the algorithm.
 */
void Memories::remove_placed_group(swbox_fill &candidate, RAM_side_t side) {
    bool removed = false;
    if (candidate.group->all_placed() && candidate.group->cm.all_placed()) {
        if (candidate.group->is_synth_type()) {
            BUG_CHECK(side == RIGHT, "Allocating Synth2Port table on left side of RAM array");
            auto synth_table_loc = synth_bus_users.find(candidate.group);
            BUG_CHECK(synth_table_loc != synth_bus_users.end(),
                      "Removing a synth2port table that isn't in the list of potential tables");
            synth_bus_users.erase(synth_table_loc);
        } else {
            auto action_table_loc = action_bus_users.find(candidate.group);
            BUG_CHECK(action_table_loc != action_bus_users.end(),
                      "Removing an action table that isn't in the list of potential tables");
            action_bus_users.erase(action_table_loc);
        }
        removed = true;
    }

#ifdef HAVE_JBAY
    if (Device::currentDevice() == "JBay") {
        if (removed) {
            if (must_be_placed_in_half.count(candidate.group))
                must_be_placed_in_half.erase(candidate.group);
        } else {
            if (candidate.group->is_synth_type()) {
                must_be_placed_in_half.insert(candidate.group);
            }

            if (candidate.group->type == SRAM_group::SELECTOR) {
                for (auto ag : candidate.group->sel.action_groups) {
                    if (!ag->all_placed())
                        must_be_placed_in_half.insert(ag);
                }
            }
        }
    }
#endif
}

/** This ensures that no collision exists within the action selector overflow switchbox, and
 *  will update the information for the next row.
 */
void Memories::calculate_sel_oflow(swbox_fill candidates[SWBOX_TYPES], swbox_fill &sel_oflow) {
    bool sel_oflow_needed = false;
    if (sel_oflow && !sel_oflow.group->sel.action_all_placed()) {
        sel_oflow_needed = true;
    }

    if (candidates[SYNTH] && candidates[SYNTH].group->type == SRAM_group::SELECTOR
        && !candidates[SYNTH].group->sel.action_all_placed()) {
        BUG_CHECK(!sel_oflow_needed, "Collision on selector oflow");
        sel_oflow_needed = true;
        sel_oflow = candidates[SYNTH];
    }

    if (!sel_oflow_needed)
        sel_oflow.clear();
    else
        sel_oflow.clear_masks();
}

/** Calculates the group that will be using the overflow switchbox.  Between rows, the switchbox
 *  is used to calculate a right to left overflow.  A synth2port table cannot overflow to the left
 *  side of the RAM array, but an action can potentially overflow from right to left.  Because an
 *  action table can have multiple home rows, it is fine to break an overflowing action.  However,
 *  a synth2port table cannot have a broken overflow.
 */
void Memories::calculate_curr_oflow(swbox_fill candidates[SWBOX_TYPES],
                                    swbox_fill &curr_oflow, swbox_fill &synth_oflow,
                                    RAM_side_t side) {
    bool synth_oflow_needed = false;
    bool curr_oflow_needed = false;
    if (side == RIGHT) {
        if (candidates[SYNTH] && !(candidates[SYNTH].group->all_placed()
                                   && candidates[SYNTH].group->cm.all_placed())) {
            synth_oflow = candidates[SYNTH];
            synth_oflow_needed = true;
        }
        if (candidates[OFLOW] && candidates[OFLOW].group->is_synth_type()
            && !(candidates[OFLOW].group->all_placed()
                 && candidates[OFLOW].group->cm.all_placed())) {
            BUG_CHECK(!synth_oflow_needed, "Multiple synth2port require overflow");
            synth_oflow = candidates[OFLOW];
            synth_oflow_needed = true;
        } else if (curr_oflow && curr_oflow.group->is_synth_type()
             && !(curr_oflow.group->all_placed()
                  && curr_oflow.group->cm.all_placed())) {
             // This check exists in case nothing could be placed within a row, and the synth2port
             // table needs to just overflow across this row
             BUG_CHECK(!synth_oflow_needed, "Multiple synth2port require overflow");
             synth_oflow = curr_oflow;
             synth_oflow_needed = true;
        }

        if (!synth_oflow_needed)
            synth_oflow.clear();
        else
            synth_oflow.clear_masks();
    }

    if (candidates[OFLOW] && !candidates[OFLOW].group->is_synth_type()
        && !candidates[OFLOW].group->all_placed()) {
        curr_oflow = candidates[OFLOW];
        curr_oflow_needed = true;
    } else if (curr_oflow && !curr_oflow.group->is_synth_type()
               && !curr_oflow.group->all_placed()) {
        // Again, this will overflow curr_oflow if no RAMs were allocated in this logical row
        curr_oflow_needed = true;
    } else if (candidates[ACTION] && !candidates[ACTION].group->all_placed()) {
        curr_oflow = candidates[ACTION];
        curr_oflow_needed = true;
    }

    if (!curr_oflow_needed)
        curr_oflow.clear();
    else
        curr_oflow.clear_masks();
}

/** Fills the Use object for meters specifically for color maprams. */
void Memories::fill_color_mapram_use(swbox_fill &candidate, int row, RAM_side_t side) {
    BUG_CHECK(candidate.group->type == SRAM_group::METER && side == RIGHT,
              "Can only allocate color maprams for Meters");
    if (candidate.mapram_mask == candidate.mask)
        return;

    auto unique_id = candidate.group->build_unique_id();
    auto &alloc = (*candidate.group->ta->memuse)[unique_id];
    auto name = unique_id.build_name();

    int bus = -1;
    int half = row / (SRAM_ROWS / 2);
    // FIXME: This is the simple solution for color mapram.  There are cases when the
    // color mapram cannot use the idletime bus, i.e. when the information comes through
    // hash distribution or if the table requires meter and idletime
    for (int i = 0; i < NUM_IDLETIME_BUS; i++) {
        if (idletime_bus[half][i] == name) {
            bus = i;
            break;
        }
    }

    for (int i = 0; i < NUM_IDLETIME_BUS && bus < 0; i++) {
        if (!idletime_bus[half][i])
            bus = i;
    }


    BUG_CHECK(bus >= 0, "Cannot have a negative color mapram bus.  Should always have a free "
                        "choice at this point");

    alloc.color_mapram.emplace_back(row, bus);
    unsigned color_mapram_mask = candidate.mapram_mask & ~candidate.mask;

    idletime_bus[half][bus] = name;
    for (int k = 0; k < SRAM_COLUMNS; k++) {
        if (((1 << k) & side_mask(side)) == 0)
            continue;
        if ((1 << k) & color_mapram_mask) {
            alloc.color_mapram.back().col.push_back(k - LEFT_SIDE_COLUMNS);
        }
    }
    candidate.group->cm.placed += bitcount(color_mapram_mask);
}

/* Logging information for each individual action/twoport table information */
void Memories::action_bus_users_log() {
    for (auto *ta : action_tables) {
        if (ta->table->layout.atcam)
            continue;
        auto unique_id = ta->build_unique_id(nullptr, false, -1, UniqueAttachedId::ADATA_PP);
        auto name = unique_id.build_name();
        auto alloc = (*ta->memuse)[unique_id];
        LOG4("Action allocation for " << name);
        for (auto row : alloc.row) {
            LOG4("Row is " << row.row << " and bus is " << row.bus);
            LOG4("Col is " << row.col);
        }
    }

    for (auto *ta : action_tables) {
        if (!ta->table->layout.atcam)
            continue;
        for (int lt = 0; lt < ta->layout_option->logical_tables(); lt++) {
             auto unique_id = ta->build_unique_id(nullptr, false, lt, UniqueAttachedId::ADATA_PP);
             auto name = unique_id.build_name();
             auto alloc = (*ta->memuse)[unique_id];
             LOG4("Action allocation for " << name);
             for (auto row : alloc.row) {
                 LOG4("Row is " << row.row << " and bus is " << row.bus);
                 LOG4("Col is " << row.col);
             }
        }
    }

    for (auto *ta : stats_tables) {
        for (auto at : ta->table->attached) {
            const IR::MAU::Counter *stats = nullptr;
            if ((stats = at->to<IR::MAU::Counter>()) == nullptr)
                continue;
            auto unique_id = ta->build_unique_id(stats);
            auto name = unique_id.build_name();
            LOG4("Stats table for " << name);
            auto alloc = (*ta->memuse)[unique_id];
            for (auto row : alloc.row) {
                LOG4("Row is " << row.row << " and bus is " << row.bus);
                LOG4("Col is " << row.col);
                LOG4("Map col is " << row.mapcol);
            }
        }
    }
    for (auto *ta : meter_tables) {
        for (auto at : ta->table->attached) {
            const IR::MAU::Meter *meter = nullptr;
            if ((meter = at->to<IR::MAU::Meter>()) == nullptr)
                continue;
            auto unique_id = ta->build_unique_id(meter);
            LOG4("Meter table for " << unique_id.build_name());
            auto alloc = (*ta->memuse)[unique_id];
            for (auto row : alloc.row) {
                LOG4("Row is " << row.row << " and bus is " << row.bus);
                LOG4("Col is " << row.col);
                LOG4("Map col is " << row.mapcol);
            }
        }
    }
    for (auto *ta : stateful_tables) {
        for (auto at : ta->table->attached) {
            const IR::MAU::StatefulAlu *salu = nullptr;
            if ((salu = at->to<IR::MAU::StatefulAlu>()) == nullptr)
                continue;
            auto unique_id = ta->build_unique_id(salu);
            LOG4("Stateful table for " << unique_id.build_name());
            auto alloc = (*ta->memuse)[unique_id];
            for (auto row : alloc.row) {
                LOG4("Row is " << row.row << " and bus is " << row.bus);
                LOG4("Col is " << row.col);
                LOG4("Map col is " << row.mapcol);
            }
        }
    }

    for (auto *ta : selector_tables) {
        for (auto at : ta->table->attached) {
            const IR::MAU::Selector *as = nullptr;
            if ((as = at->to<IR::MAU::Selector>()) == nullptr)
                continue;
            auto unique_id = ta->build_unique_id(as);
            LOG4("Selector table for " << unique_id.build_name());
            auto alloc = (*ta->memuse)[unique_id];
            for (auto row : alloc.row) {
                LOG4("Row is " << row.row << " and bus is " << row.bus);
                LOG4("Col is " << row.col);
                LOG4("Map col is " << row.mapcol);
            }
        }
    }

    for (auto *ta : indirect_action_tables) {
        for (auto at : ta->table->attached) {
            const IR::MAU::ActionData *ad = nullptr;
            if ((ad = at->to<IR::MAU::ActionData>()) == nullptr)
                continue;
            auto unique_id = ta->build_unique_id(ad);
            LOG4("Action profile allocation for " << unique_id.build_name());
            auto alloc = (*ta->memuse)[unique_id];
            for (auto row : alloc.row) {
                LOG4("Row is " << row.row << " and bus is " << row.bus);
                LOG4("Col is " << row.col);
            }
        }
    }
}

void Memories::swbox_logical_row(int row, RAM_side_t side, swbox_fill candidates[SWBOX_TYPES],
                                 swbox_fill &curr_oflow, swbox_fill &sel_oflow) {
    for (int k = 0; k < SWBOX_TYPES; k++)
        candidates[k].clear();

    if (bitcount(side_mask(side) & ~sram_inuse[row]) == 0)
        return;

    bool stats_available = true; bool meter_available = true;

    // FIXME: A stats alu is available on even rows while a meter alu is available on odd rows.
    // Now this could be loosened through a check to see if one could overflow up to a higher
    // ALU, but that is unimplemented
    if ((row % 2) == 1 || stats_alus[(row+1)/2]) {
        stats_available = false;
    }

    if (meter_alus[row/2] || (row % 2) == 0) {
        meter_available = false;
    }

    // Determine the candidates to place as well as what RAMs each candidate will have
    find_swbox_candidates(row, side, candidates, stats_available, meter_available, curr_oflow,
                          sel_oflow);

    bool candidate_found = false;
    for (int k = 0; k < SWBOX_TYPES; k++) {
        if (candidates[k]) {
            candidate_found = true;
        }
    }

    if (!candidate_found)
        return;
    // Fill out the Use structures based on the candidates
    fill_swbox_side(candidates, row, side);
}

/** The purpose of this section of code is to allocate all data HV (Horizontal/Vertical) switchbox
 *  users.  This particular switchbox is shown in section 6.2.4.4 (RAM Data Bus Horizontal/Vertical
 *  (HV) Switchbox.  The possible tables that can use this switch box are action data tables,
 *  as well as all synthetic twoport tables, (Stats, Meter, StatefulAlu, and Selector) tables.
 *
 *  The RAM array is 8 rows x 10 columns.  These columns are divided into 2 sides, a left and a
 *  right side.  The left side has 4 RAMs per row while the right side has 6 RAMs per row.  Each
 *  individual row and side has a bus from which action data can flow from  a RAM to the action
 *  data bus headed to the ALUs.
 *
 *  The right side of the RAM array is where all synth2port tables must go.  This is for a couple
 *  of reasons.  First, each synth2port RAM uses a corresponding map RAM, which is an 11 bit x
 *  1024 row RAM.  These are used to hold addressing information to perform simultaneous reads
 *  and writes.  There is a one-to-one correspondence with map RAMs and the RAM array table,
 *  but only on the right side of the RAM array.  Thus at most 6 * 8 = 48 possible locations
 *  for a synth2port table to go.
 *
 *  Also on the right side of the RAM array are ALUs to perform stateful operations.  Every odd
 *  row has a meter ALU, which can perform meter, selector, or stateful operations.  Every even
 *  row has a stats ALU, which can perform stats operations.  Each of these ALUs has a
 *  corrsponding meter/stats bus, depending on ALU on that particular row.
 *
 *  Lastly, every single row, both left and right, has an overflow bus.  This bus can be used
 *  on a row below the original home row of that attached table.  Using the switchbox, the data
 *  can then flow either horizontally or vertically to the home row location of that particular
 *  action data/synth2port table.  This is extremely useful if for instance the table cannot fit
 *  on a particular row.
 *
 *  The switchbox itself has limitations.  Only one bus can vertically overflow between rows.
 *  Thus, the bus can either come from that row, or the previously overflowed bus.  Also,
 *  a left side bus can overflow to a right side home row, but not the other way.  A bus through
 *  the vertical switchbox bus can either go to the left or right side.  In the uArch, you might
 *  see the word overflow2.  That bus no longer exists.  Fake news!
 *
 *  This algorithm is to navigate all of these constraints.  The general algorithm follows the
 *  algorithm generally specified in section 6.2.4.1.  The algorithm occurs after exact match
 *  and ternary indirect have already taken place.  The algorithm selects row by row which
 *  candidates belong on that row, and then assign a corresponding number of RAMs and map RAMs
 *  to those candidates.
 *
 *  Two other things have separate overflow constraints, specifically selectors and color mapram.
 *  Selectors provide an address offset to an action table, and have a separate overflow switchbox
 *  in order to provide this address.  The overflow switchbox, similar to the data overflow,
 *  can only overflow one address at a time.  Also, this means that an action data table attached
 *  to a selector must be at or below the row the selector is in.  This is specified in uArch
 *  section 6.2.8.4.7 Selector RAM Addressing, and is handled by the sel_oflow structure.
 *
 *  The other overflow is color maprams.  Color maprams are attached to meters and save the color
 *  information, and have a separate overflow structure.  The details of how color maprams are
 *  currently allocated are summarized above the color_mapram_candidates section.
 *
 *  Two other things have separate overflow constraints, specifically selectors and color mapram.
 *  Selectors provide an address offset to an action table, and have a separate overflow switchbox
 *  in order to provide this address.  The overflow switchbox, similar to the data overflow,
 *  can only overflow one address at a time.  Also, this means that an action data table attached
 *  to a selector must be at or below the row the selector is in.  This is specified in uArch
 *  section 6.2.8.4.7 Selector RAM Addressing, and is handled by the sel_oflow structure.
 *
 *  The other overflow is color maprams.  Color maprams are attached to meters and save the color
 *  information, and have a separate overflow structure.  The details of how color maprams are
 *  currently allocated are summarized above the color_mapram_candidates section.
 *
 *  Also please note that there are two buses to consider, the buses to address the RAMs and
 *  the buses to move data to the correct place.  Unless specified directly, the constraints
 *  generally come directly from the data bus, as overflow for addresses is a little simpler.
 *  If the constraint is directly address bus related, this should be specified in the comments,
 *  (i.e. the selector oflow is a constraint related to address buses).
 */
bool Memories::allocate_all_swbox_users() {
    find_swbox_bus_users();
    swbox_fill curr_oflow, synth_oflow;
    swbox_fill candidates[SWBOX_TYPES];
    swbox_fill sel_oflow;

    for (int i = SRAM_ROWS - 1; i >= 0; i--) {
        synth_oflow.clear();
        for (int j = RAM_SIDES - 1; j >= 0; j--) {
            auto side = static_cast<RAM_side_t>(j);
            swbox_logical_row(i, side, candidates, curr_oflow, sel_oflow);
            calculate_curr_oflow(candidates, curr_oflow, synth_oflow, side);
            calculate_sel_oflow(candidates, sel_oflow);
        }

        // Always overflow the synth2port table between rows
        if (synth_oflow)
            curr_oflow = synth_oflow;

        if (i != SRAM_ROWS - 1 && curr_oflow.group)
            vert_overflow_bus[i] = std::make_pair(curr_oflow.group->build_unique_id().build_name(),
                                                  curr_oflow.group->number);

        // Due to a timing constraint not yet even described in the uArch, the maximum number
        // of rows a particular table can overflow is 6.
        // FIXME: Need to cause this to fail specifically on twoport tables that can't use more
        // than 1 ALU
        if (curr_oflow.group && curr_oflow.group->recent_home_row - i >= MAX_DATA_SWBOX_ROWS - 1) {
            if (curr_oflow.group->type != SRAM_group::ACTION)
                curr_oflow.group->depth++;
            curr_oflow.clear();
        }

#ifdef HAVE_JBAY
        // JBay has no overflow bus between logical row 7 and 8
        if ((Device::currentDevice() == "JBay") && i == LOGICAL_ROW_MISSING_OFLOW / 2) {
            curr_oflow.clear();
        }
#endif /* HAVE_JBAY */
    }

    if (!action_bus_users.empty() || !synth_bus_users.empty()) {
        int act_unused = 0;
        for (auto abu : action_bus_users)
            act_unused += abu->left_to_place();

        int sup_unused = 0;
        for (auto sbu : synth_bus_users)
            sup_unused += sbu->left_to_place();

        return false;
    }
    action_bus_users_log();
    return true;
}

Memories::table_alloc *Memories::find_corresponding_exact_match(cstring name) {
    for (auto *ta : exact_tables) {
        auto check_name = ta->build_unique_id().build_name();
        if (check_name == name)
            return ta;
    }
    return nullptr;
}

bool Memories::gw_search_bus_fit(table_alloc *ta, table_alloc *exact_ta, int row, int col) {
    auto search_bus = sram_search_bus[row][col];
    BUG_CHECK(exact_ta->table_format->ixbar_group_per_width.count(search_bus.hash_group) > 0,
              "Miscoordination of what hash groups are on the search bus vs. what hash "
              "groups are in the table format");

    auto ixbar_groups = exact_ta->table_format->ixbar_group_per_width.at(search_bus.hash_group);
    int ixbar_group = ixbar_groups[search_bus.width_section];

    if (ixbar_group != ta->match_ixbar->gateway_group())
        return false;

    int lo = TableFormat::SINGLE_RAM_BYTES * search_bus.width_section;

    auto avail_bytes = exact_ta->table_format->avail_sb_bytes;
    if (avail_bytes.getslice(lo, ta->match_ixbar->gw_search_bus_bytes).popcount()
        != ta->match_ixbar->gw_search_bus_bytes)
        return false;
    return true;
}

/** This algorithm looks for the first free available gateway.  The gateway may need a search
 *  bus as well, so the algorithm looks for that too.
 */
bool Memories::find_unit_gw(Memories::Use &alloc, cstring name, bool requires_search_bus) {
    for (int i = 0; i < SRAM_ROWS; i++) {
        for (int j = 0; j < GATEWAYS_PER_ROW; j++) {
            if (gateway_use[i][j]) continue;
            for (int k = 0; k < BUS_COUNT; k++) {
                if (requires_search_bus && sram_search_bus[i][k].name) continue;
                alloc.row.emplace_back(i, k);
                alloc.gateway.unit = j;
                gateway_use[i][j] = name;
                if (requires_search_bus)
                    sram_search_bus[i][k] = search_bus_info(name, 0, 0, 0);
                return true;
            }
        }
    }
    return false;
}

/** Finds a search bus for the gateway.  The alogrithm first looks at all used search buses,
 *  to see if it can reuse a search bus on the table.  If it cannot find a search bus to
 *  share, then it finds the first free search bus to use
 */
bool Memories::find_search_bus_gw(table_alloc *ta, Memories::Use &alloc, cstring name) {
    for (int i = 0; i < SRAM_ROWS; i++) {
        for (int j = 0; j < GATEWAYS_PER_ROW; j++) {
            if (gateway_use[i][j]) continue;
            for (int k = 0; k < BUS_COUNT; k++) {
                auto search = sram_search_bus[i][k];
                if (search.free()) continue;
                table_alloc *exact_ta = find_corresponding_exact_match(search.name);
                if (exact_ta == nullptr) continue;
                // FIXME: currently we have to fold in the table format to this equation
                // in order to share a format
                if (ta->match_ixbar->gw_search_bus) {
                    if (gw_bytes_reserved[i][k])
                        continue;
                    if (!gw_search_bus_fit(ta, exact_ta, i, k))
                        continue;
                }
                // Because multiple ways could have different hash groups, this check is no
                // longer valid
                if (ta->match_ixbar->gw_hash_group) {
                    auto sbi = sram_search_bus[i][k];
                    if (sbi.hash_group != ta->match_ixbar->bit_use[0].group)
                        continue;
                    // FIXME: Currently all ways do not share the same hash_group
                    // if (ta->match_ixbar->bit_use[0].group
                       //  != exact_ta->match_ixbar->way_use[0].group)
                         // continue;
                }
                exact_ta->attached_gw_bytes += ta->match_ixbar->gw_search_bus_bytes;
                gw_bytes_reserved[i][k] = true;
                alloc.row.emplace_back(i, k);
                alloc.gateway.unit = j;
                gateway_use[i][j] = name;
                return true;
            }
        }
    }

    return find_unit_gw(alloc, name, true);
}

/** Finding a result bus for the gateway.  Will save associated information, such as payload
 *  row, bus, and value, as well as link no match tables if necessary
 */
bool Memories::find_match_bus_gw(Memories::Use &alloc, int payload, cstring name,
                                 table_alloc *ta_no_match, int logical_table) {
    for (int i = 0; i < SRAM_ROWS; i++) {
        for (int j = 0; j < BUS_COUNT; j++) {
            if (payload_use[i][j]) continue;
            if (payload == 0) {
               // FIXME: Add ability to handle tind outputs from payload
               if (sram_match_bus[i][j]) continue;
            } else {
                if (sram_match_bus[i][j] || tind_bus[i][j]) continue;
            }
            alloc.gateway.payload_row = i;
            alloc.gateway.payload_bus = j;
            alloc.gateway.payload_value = payload;
            // FIXME: again allow tind busses to potentially be used
            alloc.gateway.bus_type = Use::EXACT;
            if (payload != 0)
                payload_use[i][j] = name;
            if (ta_no_match) {
                auto no_match_id = ta_no_match->build_unique_id(nullptr, false, logical_table);
                auto &no_match_alloc = (*ta_no_match->memuse)[no_match_id];
                no_match_alloc.row.emplace_back(i, j);
                no_match_alloc.type = Use::EXACT;
                sram_match_bus[i][j] = no_match_id.build_name();
            } else {
                sram_match_bus[i][j] = name;
            }
            return true;
        }
    }
    return false;
}


/** Allocates all gateways with a payload, which is a conditional linked to a no match table.
 *  Thus it needs a payload, result bus, and search bus.
 */
bool Memories::allocate_all_payload_gw() {
    for (auto *ta : payload_gws) {
        UniqueId unique_id;
        if (ta->table_link) {
            unique_id = ta->table_link->build_unique_id(nullptr, true);
        } else {
            BUG("Payload requiring gw has no linked table");
        }
        auto &alloc = (*ta->memuse)[unique_id];
        alloc.type = Use::GATEWAY;
        bool search_bus_found = find_search_bus_gw(ta, alloc, unique_id.build_name());
        bool match_bus_found = find_match_bus_gw(alloc, 1, unique_id.build_name(), ta->table_link);
        if (!(search_bus_found && match_bus_found))
            return false;
    }
    return true;
}

/** Allocation of a conditional gateway that does not map to a no match hit path table.
 * Conditional gateways require a search bus and result bus.  If the table is linked to another
 * table, then the result bus will be the same as the result bus of the linked table.
 */
bool Memories::allocate_all_normal_gw() {
    for (auto *ta : normal_gws) {
        // auto name = ta->table->get_use_name(nullptr, true);
        UniqueId unique_id = ta->build_unique_id(nullptr, true);
        if (ta->table_link != nullptr)
            unique_id = ta->table_link->build_unique_id(nullptr, true);
        auto &alloc = (*ta->memuse)[unique_id];
        alloc.type = Use::GATEWAY;
        bool search_bus_found = find_search_bus_gw(ta, alloc, unique_id.build_name());
        bool match_bus_found;
        if (ta->table_link) {
            // FIXME: Must use table format in order to instantiate payload bus location properly.
            // However, the payload buses can be inferred from the location of the table
            alloc.gateway.payload_value = -1;
            alloc.gateway.payload_bus = -1;
            alloc.gateway.payload_row = -1;
            if (ta->table_link->table->layout.ternary)
                alloc.gateway.bus_type = Use::TERNARY;
            else
                alloc.gateway.bus_type = Use::EXACT;
            match_bus_found = true;
        } else {
            match_bus_found = find_match_bus_gw(alloc, 0, unique_id.build_name(), nullptr);
        }
        if (!(search_bus_found && match_bus_found))
            return false;
    }

    return true;
}

/** This function call allocates no match hit tables that don't require a payload.  This means
 *  only a result bus is needed
 */
bool Memories::allocate_all_no_match_gw() {
    for (auto *ta : no_match_gws) {
        if (ta->table->for_dleft())
            continue;
        auto unique_id = ta->build_unique_id(nullptr, true);
        auto &alloc = (*ta->memuse)[unique_id];
        alloc.type = Use::GATEWAY;
        bool unit_found = find_unit_gw(alloc, unique_id.build_name(), false);
        bool match_bus_found = find_match_bus_gw(alloc, 0, unique_id.build_name(), ta);
        if (!(unit_found && match_bus_found))
            return false;
    }

    // Initializing gateways for dleft hash tables
    for (auto *ta : no_match_gws) {
        if (!ta->table->for_dleft())
            continue;
        for (int lt = 0; lt < ta->layout_option->logical_tables(); lt++) {
            auto unique_id = ta->build_unique_id(nullptr, true, lt);
            auto &alloc = (*ta->memuse)[unique_id];
            alloc.type = Use::GATEWAY;
            bool unit_found = find_unit_gw(alloc, unique_id.build_name(), false);
            bool match_bus_found = find_match_bus_gw(alloc, 0, unique_id.build_name(), ta, lt);
            if (!(unit_found && match_bus_found))
                return false;
        }
    }
    return true;
}

/** The two allocation schemes allocate_all_gw and allocate_all_no_match_miss are responsible for
 *  the allocation of both all gateways and all no match tables.  Keyless tables can go through
 *  two pathways within match central, through the hit path or the miss path.
 *
 *  There are two types of standard no match tables.  Currently keyless tables that can have
 *  no action data, and only one action are allocated to go through the hit path, which is what
 *  glass does.  The tables that require action data or have multiple potential actions have
 *  to go through the miss path, as those values are configurable by the driver, and currently
 *  the driver can only rewrite the miss registers, even though these registers are completely
 *  configurable through the hit path.  Lastly, all keyless tables that require hash distribution
 *  require the hit path, as anything needed with hash distribution goes through the format
 *  and merge block.
 *
 *  A gateway is the hardware block for handling a conditional block.  There are 16 gateways per
 *  stage, two per rows.  Gateways are 4 row, 44 bit TCAMs, and can bring there comparison data
 *  in two ways.  The lower 32 bits are brought in through the lower 32 bits of an 128 bit
 *  search bus, while the upper 12 bits come from the upper 12 bits of a 52 bit hash.  The
 *  necessary gateway resources are known at this point, so it's a matter of reserving either
 *  a search bus, a hash bus or both.
 *
 *  Keyless table that go through the hit path must initialize a gateway to always hit, and thus
 *  must find a gateway.  However, if the no match table through the hit path has a gateway
 *  attached to it, this must use a payload in order for the gateway to be configured correctly.
 *  The details of why this is necessary are contained within the asm_output, which talks about
 *  the initialization of gateways.
 *
 *  Out of this comes three reservations of gateways.
 *  1. Gateways that require payloads, which are conditionals linked to no match hit path tables.
 *     In this case, a payload is required be resereved.
 *  2. Gateways that are conditionals.  These conditionals can be paired with a match table or
 *     exist by themselves.
 *  3. Gateways that are no match tables alone.  Due to the nature of the hit path, the gateway
 *     is an always true gateway that always hits, and does not need to search
 *
 *  This list goes from least to most complex, specifically:
 *  1.  Reserve gateway unit, search bus, result bus, payload
 *  2.  Reserve gateway unit, search bus, result bus
 *  3.  Reserve gateway unit, result bus
 */
bool Memories::allocate_all_gw() {
    payload_gws.clear();
    normal_gws.clear();
    no_match_gws.clear();

    for (auto *ta_gw : gw_tables) {
        bool pushed_back = false;
        for (auto *ta_nm : no_match_hit_tables) {
            if (ta_gw->table_link == ta_nm) {
                payload_gws.push_back(ta_gw);
                pushed_back = true;
                break;
            }
        }

        if (!pushed_back)
            normal_gws.push_back(ta_gw);
    }

    for (auto *ta_nm : no_match_hit_tables) {
        bool linked = false;
        for (auto &ta_gw : gw_tables) {
            if (ta_gw->table_link == ta_nm) {
                linked = true;
                break;
            }
        }
        if (!linked) {
            no_match_gws.push_back(ta_nm);
        }
    }

    int search_bus_free = 0;
    for (int i = 0; i < SRAM_ROWS; i++) {
        for (int j = 0; j < 2; j++) {
            if (sram_search_bus[i][j].free())
                search_bus_free++;
        }
    }

    if (!allocate_all_payload_gw()) return false;
    if (!allocate_all_normal_gw()) return false;
    if (!allocate_all_no_match_gw()) return false;
    return true;
}

/** This allocates all tables that currently take the miss path information.  The miss path
 *  is how action data information can be configured by runtime.  This would be necessary
 *  if multiple actions are needed/action data is changeable.  Just reserved a result bus
 *  for the time being.
 */
bool Memories::allocate_all_no_match_miss() {
    // FIXME: Currently the assembler supports exact match to make calls to immediate here,
    // so this is essentially what I'm doing.  More discussion is needed with the driver
    // team in order to determine if this is correct, or if this has to go through ternary and
    // tind tables
    size_t no_match_tables_allocated = 0;
    for (auto *ta : no_match_miss_tables) {
        auto unique_id = ta->build_unique_id(nullptr, false, -1, UniqueAttachedId::TIND_PP);
        auto &alloc = (*ta->memuse)[unique_id];
        alloc.type = Use::TIND;
        bool found = false;

        found = false;
        for (int i = 0; i < SRAM_ROWS; i++) {
            for (int j = 0; j < BUS_COUNT; j++) {
                if (payload_use[i][j]) continue;
                if (tind_bus[i][j]) continue;
                alloc.row.emplace_back(i, j);
                tind_bus[i][j] = unique_id.build_name();
                found = true;
                break;
            }
            if (found) break;
        }

        if (!found)
            break;
        else
            no_match_tables_allocated++;
    }

    if (no_match_tables_allocated != no_match_miss_tables.size())
        return false;

    return true;
}

bool Memories::find_mem_and_bus_for_idletime(
        std::vector<std::pair<int, std::vector<int>>>& mem_locs,
        int& bus, int total_mem_required, bool top_half) {
    // find mapram locs
    int total_requested = 0;

    int mem_start_row = (top_half) ? SRAM_ROWS/2 : 0;
    int mem_end_row = (top_half) ? SRAM_ROWS : SRAM_ROWS/2;

    mem_locs.clear();

    for (int i = mem_start_row; i < mem_end_row; i++) {
        if (total_requested == total_mem_required)
            break;

        std::vector<int> cols;
        for (int j = 0; j < MAPRAM_COLUMNS; j++) {
            if (!mapram_use[i][j]) {
                cols.push_back(j);

                total_requested++;
                if (total_requested == total_mem_required)
                    break;
            }
        }
        mem_locs.emplace_back(i, cols);
    }

    const char* which_half = top_half ? "top" : "bottom";

    // find a bus
    bool found_bus = false;
    for (int i = 0; i < NUM_IDLETIME_BUS; i++) {
        if (!idletime_bus[(unsigned)top_half][i]) {
            bus = i;
            found_bus = true;
            break;
        }
    }

    if (!found_bus) {
        LOG3("Ran out of idletime bus in " << which_half << "half");
        return false;
    }

    return true;
}

bool Memories::allocate_idletime_in_top_or_bottom_half(SRAM_group* idletime_group,
                                                       bool in_top_half) {
    auto unique_id = idletime_group->build_unique_id();

    int total_required = idletime_group->left_to_place();

    std::vector<std::pair<int, std::vector<int>>> mem_locs;
    int bus = -1;

    // find mem and bus in top and bottom half of mapram
    bool resource_available = find_mem_and_bus_for_idletime(mem_locs, bus, total_required,
                                                            in_top_half);

    if (!resource_available)
        return false;

    // update memuse and bus use
    auto &alloc = (*idletime_group->ta->memuse)[unique_id];

    for (auto& loc : mem_locs) {
        Memories::Use::Row row(loc.first, bus);
        for (auto col : loc.second) {
            mapram_use[loc.first][col] = unique_id.build_name();
            mapram_inuse[loc.first] |= (1 << col);
            row.col.push_back(col);  // XXX(zma) use col as bfas expects "column" for idletime
            idletime_group->placed++;
        }
        alloc.row.push_back(row);
    }

    idletime_bus[(unsigned)in_top_half][bus] = unique_id.build_name();
    return idletime_group->all_placed();
}


bool Memories::allocate_idletime(SRAM_group* idletime_group) {
    // Pick the most available section of the map RAM array to try to fit in an idletime
    // resource allocation
    int top_half_maprams = half_map_RAMs_available(SRAM_ROWS - 1);
    int bottom_half_maprams = half_map_RAMs_available((SRAM_ROWS / 2) - 1);

    bool in_top_half = top_half_maprams >= bottom_half_maprams;
    if (allocate_idletime_in_top_or_bottom_half(idletime_group, in_top_half))
        return true;
    if (allocate_idletime_in_top_or_bottom_half(idletime_group, !in_top_half))
        return true;
    return false;
}

bool Memories::allocate_all_idletime() {
    idletime_groups.clear();
    for (auto *ta : idletime_tables) {
        for (auto back_at : ta->table->attached) {
            auto at = back_at->attached;
            const IR::MAU::IdleTime *id = nullptr;
            if ((id = at->to<IR::MAU::IdleTime>()) == nullptr)
                continue;

            int per_row = IdleTimePerWord(id);
            int depth = mems_needed(ta->calculated_entries, SRAM_DEPTH, per_row, false);
            auto idletime_group = new SRAM_group(ta, depth, 1, SRAM_group::IDLETIME);
            idletime_group->attached = id;
            idletime_groups.push_back(idletime_group);
        }
    }

    std::sort(idletime_groups.begin(), idletime_groups.end(),
        [](const SRAM_group *a, const SRAM_group *b){
        int t;
        if ((t = a->left_to_place() - b->left_to_place()) != 0)
            return t > 0;
        return a->ta->table->name < b->ta->table->name;
    });

    for (auto* idletime_group : idletime_groups) {
        if (!allocate_idletime(idletime_group))
            return false;
    }

    return true;
}

void Memories::Use::visit(Memories &mem, std::function<void(cstring &)> fn) const {
    Alloc2Dbase<cstring> *use = 0, *mapuse = 0, *bus = 0;
    switch (type) {
    case EXACT:
    case ATCAM:
        use = &mem.sram_use;
        bus = &mem.sram_print_search_bus;
        break;
    case TERNARY:
        use = &mem.tcam_use;
        break;
    case GATEWAY:
        use = &mem.gateway_use;
        //  bus = &mem.sram_print_match_bus;
        break;
    case TIND:
        use = &mem.sram_use;
        bus = &mem.tind_bus;
        break;
    case COUNTER:
    case METER:
    case STATEFUL:
    case SELECTOR:
        use = &mem.sram_use;
        mapuse = &mem.mapram_use;
        break;
    case ACTIONDATA:
        use = &mem.sram_use;
        bus = &mem.action_data_bus;
        break;
    case IDLETIME:
        mapuse = &mem.mapram_use;
        break;
    default:
        BUG("Unhandled memory use type %d in Memories::Use::visit", type); }
    for (auto &r : row) {
        if (bus && r.bus != -1) {
            fn((*bus)[r.row][r.bus]); }
        /*if (type == TWOPORT)
            fn(mem.stateful_bus[r.row]);*/
        if (use)
            for (auto col : r.col) {
                fn((*use)[r.row][col]); }
        if (mapuse) {
            for (auto col : r.mapcol) {
                fn((*mapuse)[r.row][col]); } } }
    if (mapuse) {
        for (auto &r : color_mapram) {
             for (auto col : r.col) {
                 fn((*mapuse)[r.row][col]); } } }
}

void Memories::update(cstring name, const Memories::Use &alloc) {
    alloc.visit(*this, [name](cstring &use) {
        if (use)
            BUG("conflicting memory use between %s and %s", use, name);
        use = name; });
}

void Memories::update(const std::map<UniqueId, Use> &alloc) {
    for (auto &a : alloc) update(a.first.build_name(), a.second);
}

void Memories::remove(cstring name, const Memories::Use &alloc) {
    alloc.visit(*this, [name](cstring &use) {
        if (use != name)
            BUG("Undo failure for %s", name);
        use = nullptr; });
}
void Memories::remove(const std::map<UniqueId, Use> &alloc) {
    for (auto &a : alloc) remove(a.first.build_name(), a.second);
}

std::ostream &operator<<(std::ostream &out, const Memories::search_bus_info &sbi) {
    out << "search bus " << sbi.name << " width: " << sbi.width_section << " hash_group: "
        << sbi.hash_group << " lt: " << sbi.logical_table;
    return out;
}

/* MemoriesPrinter in .gdbinit should match this */
std::ostream &operator<<(std::ostream &out, const Memories &mem) {
    const Alloc2Dbase<cstring> *arrays[] = { &mem.tcam_use, &mem.sram_print_search_bus,
                   &mem.tind_bus, &mem.action_data_bus, &mem.sram_use, &mem.mapram_use,
                   &mem.gateway_use };
    std::map<cstring, char>     tables;
    out << "tc  eb  tib ab  srams       mapram  gw" << std::endl;
    for (int r = 0; r < Memories::TCAM_ROWS; r++) {
        for (auto arr : arrays) {
            for (int c = 0; c < arr->cols(); c++) {
                if (r >= arr->rows()) {
                    out << ' ';
                } else {
                    auto tbl = (*arr)[r][c];
                    if (tbl) {
                        if (!tables.count(tbl))
                            tables.emplace(tbl, 'A' + tables.size());
                        out << tables.at(tbl);
                    } else {
                        out << '.'; } } }
            out << "  "; }
        if (r < Memories::SRAM_ROWS) {
            auto tbl = mem.stateful_bus[r];
            if (tbl) {
                if (!tables.count(tbl))
                    tables.emplace(tbl, 'A' + tables.size());
                out << tables.at(tbl);
            } else {
                out << '.'; } }
        out << std::endl; }
    for (auto &tbl : tables)
        out << "   " << tbl.second << " " << tbl.first << std::endl;
    return out;
}

void dump(const Memories *mem) {
    std::cout << *mem;
}

template<int R, int C>
std::ostream &operator<<(std::ostream& out, const Alloc2D<cstring, R, C>& alloc2d) {
    for (int i = 0; i < R; i++) {
        for (int j = 0; j < C; j++) {
            cstring val = alloc2d[i][j];
            if (!val) val = "-";
            out << std::setw(10) << val << " ";
        }
        out << std::endl;
    }
    return out;
}

std::ostream & operator<<(std::ostream &out, const Memories::table_alloc &ta) {
    out << "table_alloc[" << ta.table->match_table->externalName() << ": ";
    for (auto &u : *ta.memuse)
        out << "(" << u.first.build_name() << ", " << use_type_to_str[u.second.type] << ") ";
    out << "]";
    return out;
}
