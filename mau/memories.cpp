#include "lib/bitops.h"
#include "lib/range.h"
#include "memories.h"
#include "resource_estimate.h"
#include "mau_visitor.h"


void Memories::clear_uses() {
    sram_use.clear();
    tcam_use.clear();
    mapram_use.clear();
    sram_match_bus.clear();
    sram_print_match_bus.clear();
    tind_bus.clear();
    action_data_bus.clear();
    stateful_bus.clear();
    overflow_bus.clear();
    vert_overflow_bus.clear();
    memset(sram_inuse, 0, sizeof(sram_inuse));
    memset(gw_bytes_per_sb, 0, sizeof(gw_bytes_per_sb));
    memset(mapram_inuse, 0, sizeof(mapram_inuse));
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
    action_profiles.clear();
    selector_tables.clear();
    action_bus_users.clear();
    gw_tables.clear();
    stats_tables.clear();
    meter_tables.clear();
    suppl_bus_users.clear();
}

/* Creates a new table_alloc object for each of the taibles within the memory allocation */
void Memories::add_table(const IR::MAU::Table *t, const IR::MAU::Table *gw,
                         TableResourceAlloc *resources, const IR::MAU::Table::LayoutOption *lo,
                         int entries) {
    table_alloc *ta;
    if (t->match_table)
        ta = new table_alloc(t, &resources->match_ixbar, &resources->memuse, lo, entries);
    else
        ta = new table_alloc(t, &resources->gateway_ixbar, &resources->memuse, lo, entries);
    tables.push_back(ta);
    if (gw != nullptr)  {
        auto *ta_gw = new table_alloc(gw, &resources->gateway_ixbar, &resources->memuse, lo, -1);
        ta_gw->link_table(ta);
        tables.push_back(ta_gw);
    }
}

/* Function that tests whether all added tables can be allocated to the stage */
bool Memories::allocate_all() {
    mem_info mi;

    LOG3("Analyzing tables");
    if (!analyze_tables(mi)) {
        return false;
    }
    unsigned row = 0;
    bool finished = false;

    do {
        clear_uses();
        calculate_column_balance(mi, row);
        LOG3("Allocating all exact tables");
        if (allocate_all_exact(row)) {
           finished = true;
        }
        LOG3("Row size " << __builtin_popcount(row));
    } while (__builtin_popcount(row) < 10 && !finished);

    if (!finished) {
        return false;
    }

    LOG3("Allocating all ternary tables");
    if (!allocate_all_ternary()) {
        return false;
    }

    LOG3("Allocating all ternary indirect tables");
    if (!allocate_all_tind()) {
        return false;
    }

    LOG3("Allocating all action tables");
    if (!allocate_all_action()) {
        return false;
    }

    LOG3("Allocating all gateway tables");
    if (!allocate_all_gw()) {
        return false;
    }

    LOG3("Memory allocation fits");
    return true;
}

/* This class is responsible for filling in all of the particular lists with the corresponding
   twoport tables, as well as getting the sharing of indirect action tables and selectors correct
*/
class SetupAttachedTables : public MauInspector {
    Memories &mem; Memories::table_alloc *ta; int entries; Memories::mem_info &mi;
    bool stats_pushed = false; bool meter_pushed = false;

    profile_t init_apply(const IR::Node *root) {
        profile_t rv = MauInspector::init_apply(root);
        if (ta->layout_option == nullptr) return rv;

        if (ta->layout_option->layout->ternary_indirect_required()) {
            auto name = ta->table->get_use_name(nullptr, false, IR::MAU::Table::TIND_NAME);
            (*ta->memuse)[name].type = Memories::Use::TIND;
            mem.tind_tables.push_back(ta);
            mi.tind_tables++;
            mi.tind_RAMs += (entries + 1023U) / 1024U;
        }

        if (ta->layout_option->layout->action_data_required()) {
            auto name = ta->table->get_use_name(nullptr, false, IR::MAU::Table::AD_NAME);
            (*ta->memuse)[name].type = Memories::Use::ACTIONDATA;
            mem.action_tables.push_back(ta);
            mi.action_tables++;
            int width = 1;
            int per_row = ActionDataPerWord(ta->layout_option->layout, &width);
            int depth = (entries + per_row * 1024 - 1) / (per_row * 1024);
            mi.action_bus_min += width; mi.action_RAMs += depth * width;
        }
        return rv;
    }

    /* In order to only visit the attached tables of the current table */
    bool preorder(const IR::MAU::TableSeq *) { return false; }
    bool preorder(const IR::ActionFunction *) { return false; }

    bool preorder(const IR::MAU::ActionData *) {
        BUG("Shouldn't have an action data table before table placement");
    }

    bool preorder(const IR::ActionProfile *ap) {
        auto name = ta->table->get_use_name(ap);
        auto table_name = ta->table->get_use_name();
        LOG4("Action profile for table " << table_name);
        bool selector_first = false;
        /* This is a check to see if the table has already been placed due to it being in
           the profile of a separate table */
        Memories::profile_info *linked_pi = nullptr;
        for (auto *pi : mem.action_profiles) {
            if (pi->ap == ap) {
                linked_pi = pi;
                break;
            }
            if (pi->linked_ta == ta) {
                if (ap->selector.name != pi->as->name)
                    BUG("Alignment of selector and action profile in memory allocation");
                selector_first = true;
                linked_pi = pi;
                break;
            }
        }
        if (selector_first) {
            linked_pi->ap = ap;
            (*ta->memuse)[name].type = Memories::Use::ACTIONDATA;
            mem.indirect_action_tables.push_back(ta);
        } else if (linked_pi == nullptr) {
            mem.indirect_action_tables.push_back(ta);
            mem.action_profiles.push_back(new Memories::profile_info(ap, ta));
            (*ta->memuse)[name].type = Memories::Use::ACTIONDATA;
        } else {
            auto linked_name = linked_pi->linked_ta->table->get_use_name();
            (*ta->memuse)[table_name].unattached_profile = true;
            (*ta->memuse)[table_name].profile_name = linked_name;
            return false;
        }
        mi.action_tables++;
        int width = 1;
        int per_row = ActionDataPerWord(&ta->table->layout, &width);
        int depth = (ap->size + per_row * 1024 - 1) / (per_row * 1024);
        mi.action_bus_min += width; mi.action_RAMs += depth * width;
        return false;
    }

    bool preorder(const IR::Meter *mtr) {
        auto name = ta->table->get_use_name(mtr);
        (*ta->memuse)[name].type = Memories::Use::TWOPORT;
        if (!meter_pushed) {
            mem.meter_tables.push_back(ta);
            meter_pushed = true;
        }
        mi.meter_tables++;
        if (mtr->direct)
            mi.meter_RAMs += (entries + 1023)/1024 + 1;
        else
            mi.meter_RAMs += (mtr->instance_count + 1023)/1024 + 1;
        return false;
    }

    bool preorder(const IR::Counter *cnt) {
        auto name = ta->table->get_use_name(cnt);
        (*ta->memuse)[name].type = Memories::Use::TWOPORT;
        if (!stats_pushed) {
            mem.stats_tables.push_back(ta);
            stats_pushed = true;
        }
        mi.stats_tables++;
        int per_row = CounterPerWord(cnt);
        if (cnt->direct)
            mi.stats_RAMs += (entries + per_row * 1024 - 1) / (per_row * 1024) + 1;
        else
            mi.stats_RAMs += (cnt->instance_count + per_row * 1024 - 1) / (per_row * 1024) + 1;
        return false;
    }

    bool preorder(const IR::MAU::TernaryIndirect *) {
        BUG("Should be no Ternary Indirect before table placement is complete");
    }


    bool preorder(const IR::ActionSelector *as) {
        auto name = ta->table->get_use_name(as);
        auto table_name = ta->table->get_use_name();
        bool profile_first = false;
        Memories::profile_info *linked_pi = nullptr;
        /* This checks to see if the selector is being shared between separate tables in the
           same stage.  Only needs to be allocated once if shared between two logical tables */
        for (auto *pi : mem.action_profiles) {
            if (pi->as == as) {
                linked_pi = pi;
                break;
            }
            if (pi->linked_ta == ta) {
                if (pi->ap->selector.name != as->name)
                    BUG("Alignment of selector and action profile in memory allocation");
                profile_first = true;
                linked_pi = pi;
                break;
            }
        }
        if (profile_first) {
            linked_pi->as = as;
            (*ta->memuse)[name].type = Memories::Use::TWOPORT;
            mem.selector_tables.push_back(ta);
        } else if (linked_pi == nullptr) {
            auto name = ta->table->name + "$selector";
            (*ta->memuse)[name].type = Memories::Use::TWOPORT;
            mem.selector_tables.push_back(ta);
            mem.action_profiles.push_back(new Memories::profile_info(as, ta));
        } else {
            auto linked_name = linked_pi->linked_ta->table->get_use_name();
            (*ta->memuse)[table_name].unattached_profile = true;
            (*ta->memuse)[table_name].profile_name = linked_name;
        }
        mi.selector_RAMs += 2;
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
            auto name = ta->table->get_use_name(nullptr, true);
            if (ta->table_link != nullptr)
                name = ta->table_link->table->get_use_name(nullptr, true);
            (*ta->memuse)[name].type = Use::GATEWAY;
            gw_tables.push_back(ta);
            LOG4("Gateway table for " << ta->table->name);
            continue;
        }
        auto table = ta->table;
        int entries = ta->provided_entries;
        if (!table->layout.ternary) {
            auto name = ta->table->get_use_name();
            LOG4("Exact match table " << name);
            (*ta->memuse)[name].type = Use::EXACT;
            exact_tables.push_back(ta);
            mi.match_tables++;
            int width = ta->layout_option->way->width;
            int groups = ta->layout_option->way->match_groups;
            int depth = ((entries + groups - 1U)/groups + 1023)/1024U;
            mi.match_bus_min += width;
            mi.match_RAMs += depth;
        } else {
           auto name = ta->table->get_use_name();
           LOG4("Ternary match table " << name);
           (*ta->memuse)[name].type = Use::TERNARY;
           ternary_tables.push_back(ta);
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

           int depth = (entries + 511)/512U;
           mi.ternary_TCAMs += TCAMs_needed * depth;
           ta->calculated_entries = depth * 512;
        }
        SetupAttachedTables setup(*this, ta, entries, mi);
        ta->table->apply(setup);
    }
    if (mi.match_tables > EXACT_TABLES_MAX
        || mi.match_bus_min > SRAM_ROWS * BUS_COUNT
        || mi.tind_tables > TERNARY_TABLES_MAX
        || mi.action_tables > ACTION_TABLES_MAX
        || mi.action_bus_min > SRAM_ROWS * BUS_COUNT
        || mi.match_RAMs + mi.action_RAMs + mi.tind_RAMs > SRAM_ROWS * SRAM_COLUMNS
        || mi.ternary_tables > TERNARY_TABLES_MAX
        || mi.ternary_TCAMs > TCAM_ROWS * TCAM_COLUMNS
        || mi.stats_tables > STATS_ALUS
        || mi.meter_tables + mi.selector_tables > METER_ALUS
        || mi.meter_RAMs + mi.stats_RAMs + mi.selector_RAMs > MAPRAM_COLUMNS * SRAM_ROWS) {
        return false;
    }
    return true;
}

/* Calculate the size of the ways given the number of RAMs necessary */
vector<int> Memories::way_size_calculator(int ways, int RAMs_needed) {
    vector<int> vec;
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
vector<std::pair<int, int>> Memories::available_SRAMs_per_row(unsigned mask, table_alloc *ta,
                                                                int width_sect) {
    vector<std::pair<int, int>> available_rams;
    auto name = ta->table->get_use_name();
    for (int i = 0; i < SRAM_ROWS; i++) {
        auto bus = sram_match_bus[i];
        // if the first bus or the second bus match up to what is
        if (!(!bus[0].first || !bus[1].first ||
            (bus[0].first == name && bus[0].second == width_sect) ||
            (bus[1].first == name && bus[1].second == width_sect)))
            continue;
        available_rams.push_back(std::make_pair(i,
                                 __builtin_popcount((mask ^ sram_inuse[i]) & mask)));
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
vector<int> Memories::available_match_SRAMs_per_row(unsigned row_mask, unsigned total_mask,
                                                    int row, table_alloc *ta, int width_sect) {
    vector<int> matching_rows;
    auto name = ta->table->get_use_name();
    for (int i = 0; i < SRAM_ROWS; i++) {
        auto bus = sram_match_bus[i];
        if (row == i) continue;
        if (!(!bus[0].first || !bus[1].second ||
            (bus[0].first == name && bus[0].second == width_sect) ||
            (bus[1].first == name && bus[1].second == width_sect))) continue;

        if (__builtin_popcount(row_mask & ~sram_inuse[i]) == __builtin_popcount(row_mask))
            matching_rows.push_back(i);
    }

    std::sort(matching_rows.begin(), matching_rows.end(),
              [=] (const int a, const int b) {
        int t;
        if ((t = __builtin_popcount(~sram_inuse[a] & total_mask) -
                 __builtin_popcount(~sram_inuse[b] & total_mask)) != 0)
            return t < 0;

        auto bus = sram_match_bus[a];

        if ((bus[0].first && bus[0].first == name && bus[0].second == width_sect) ||
            (bus[1].first && bus[1].first == name && bus[1].second == width_sect))
            return true;

        bus = sram_match_bus[b];

        if ((bus[0].first && bus[0].first == name && bus[0].second == width_sect) ||
            (bus[1].first && bus[1].first == name && bus[1].second == width_sect))
            return false;
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
        auto name = ta->table->get_use_name();
        (*ta->memuse)[name].ways.clear();
        (*ta->memuse)[name].row.clear();
        int index = 0;
        ta->calculated_entries = ta->layout_option->entries;
        index = 0;
        assert(ta->match_ixbar->way_use.size() == ta->layout_option->way_sizes.size());
        for (auto &way : ta->match_ixbar->way_use) {
            SRAM_group *wa = new SRAM_group(ta, ta->layout_option->way_sizes[index],
                                             ta->layout_option->way->width, index,
                                             way.group, SRAM_group::EXACT);
            exact_match_ways.push_back(wa);
            (*ta->memuse)[name].ways.emplace_back(ta->layout_option->way_sizes[index],
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
   within this row
*/
Memories::SRAM_group * Memories::find_best_candidate(SRAM_group *placed_wa, int row, int &loc) {
    if (exact_match_ways.empty()) return nullptr;
    auto bus = sram_match_bus[row];

    loc = 0;
    for (auto emw : exact_match_ways) {
        if (placed_wa->ta == emw->ta) {
            return emw;
        }
        loc++;
    }

    loc = 0;
    for (auto emw : exact_match_ways) {
        auto name = emw->ta->table->get_use_name();
        if ((bus[0].first && bus[0].first == name) || (bus[1].first && bus[1].first == name))
            return emw;
        loc++;
    }

    if (bus[0].first && bus[1].first) {
        return nullptr;
    }

    // FIXME: Perhaps do a best fit algorithm here
    loc = 0;
    return exact_match_ways[0];
}

/* Fill out the remainder of the row with other ways! */
bool Memories::fill_out_row(SRAM_group *placed_wa, int row, unsigned column_mask) {
    int loc = 0;
    vector<std::pair<int, int>> buses;
    // FIXME: Need to adjust to the proper mask provided by earlier function
    while (__builtin_popcount(column_mask) - __builtin_popcount(sram_inuse[row]) > 0) {
        buses.clear();
        SRAM_group *wa = find_best_candidate(placed_wa, row, loc);
        if (wa == nullptr)
            return true;
        int cols = 0;
        if (!pack_way_into_RAMs(wa, row, cols, column_mask))
            return false;
        if (cols >= wa->depth - wa->placed) {
            exact_match_ways.erase(exact_match_ways.begin() + loc);
        } else {
            wa->placed += cols;
        }
    }
    return true;
}

/* Returns the match bus that we are selecting on this row */
int Memories::match_bus_available(table_alloc *ta, int width, int row) {
     auto name = ta->table->get_use_name();
     if (!sram_match_bus[row][0].first
         || (sram_match_bus[row][0].first == name && sram_match_bus[row][0].second == width))
         return 0;
     else
         return 1;
}

/* Put the selected way group into the RAM row as much as possible */
bool Memories::pack_way_into_RAMs(SRAM_group *wa, int row, int &cols, unsigned column_mask) {
    vector<std::pair<int, int>> buses;
    buses.emplace_back(row, match_bus_available(wa->ta, wa->unique_bus(0), row));
    unsigned row_mask = 0;
    vector<int> selected_cols;

    for (int i = 0; i < SRAM_COLUMNS && cols < wa->depth - wa->placed; i++) {
        // FIXME: Path change
        if (!sram_use[row][i]  && ((1 << i) & column_mask)) {
            row_mask |= (1 << i);
            selected_cols.push_back(i);
            cols++;
        }
    }

    vector<int> selected_rows;
    selected_rows.push_back(row);
    // Fairly simple stuff
    for (int i = 1; i < wa->width; i++) {
        vector<int> matching_rows = available_match_SRAMs_per_row(row_mask, column_mask, row,
                                                                  wa->ta, wa->unique_bus(i));
        size_t j = 0;
        while (j < matching_rows.size()) {
            int test_row = matching_rows[j];
            if (std::find(selected_rows.begin(), selected_rows.end(), test_row)
                == selected_rows.end()) {
                selected_rows.push_back(test_row);
                buses.emplace_back(test_row, match_bus_available(wa->ta, i, test_row));
                break;
            }
            j++;
        }
        // This needs to be better checked
        if (j == matching_rows.size()) {
            return false;
        }
    }

    auto name = wa->ta->table->get_use_name();
    Memories::Use &alloc = (*wa->ta->memuse)[name];

    for (size_t i = 0; i < selected_rows.size(); i++) {
        int bus = -1;
        int width = -1;
        for (size_t j = 0; j < buses.size(); j++) {
            if (buses[j].first == selected_rows[i]) {
                bus = buses[j].second;
                width = j;
            }
        }

        alloc.row.emplace_back(selected_rows[i], bus);
        auto &alloc_row = alloc.row.back();
        for (size_t j = 0; j < selected_cols.size(); j++) {
            sram_use[selected_rows[i]][selected_cols[j]] = name;
            alloc_row.col.push_back(selected_cols[j]);
        }

        sram_inuse[selected_rows[i]] |= row_mask;
        if (!sram_match_bus[selected_rows[i]][bus].first) {
            sram_match_bus[selected_rows[i]][bus]
                = std::make_pair(name, wa->unique_bus(width));
            sram_print_match_bus[selected_rows[i]][bus] = name;
        }
    }
    for (size_t j = 0; j < selected_cols.size(); j++) {
        for (size_t i = 0; i < selected_rows.size(); i++) {
             alloc.ways[wa->number].rams.emplace_back(selected_rows[i], selected_cols[j]);
        }
    }
    return true;
}

/* Picks an empty/most open row, and begins to fill it in within a way */
bool Memories::find_best_row_and_fill_out(unsigned column_mask) {
    SRAM_group *wa = exact_match_ways[0];
    // FIXME: Obviously the mask has to change
    vector<std::pair<int, int>> available_rams
        = available_SRAMs_per_row(column_mask, wa->ta, wa->unique_bus(0));
    // No memories left to place anything
    if (available_rams.size() == 0) {
        return false;
    }

    int row = available_rams[0].first;
    int cols = 0;
    if (available_rams[0].second == 0)
        return false;

    if (!pack_way_into_RAMs(wa, row, cols, column_mask))
        return false;

    if (cols >= wa->depth - wa->placed) {
        exact_match_ways.erase(exact_match_ways.begin());
        if (cols == wa->depth - wa->placed)
           return fill_out_row (wa, row, column_mask);
        else
           return true;
    } else {
        wa->placed += cols;
        return true;
    }
}

/* Determining if the side from which we want to give extra columns to the exact match
   allocation, potentially cutting room from either tind tables or twoport tables */
bool Memories::cut_from_left_side(mem_info &mi, int left_given_columns,
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
    return false;
}

/* Calculates the number of columns and the distribution of columns on the left and
   right side of the SRAM array in order to place all exact match tables */
void Memories::calculate_column_balance(mem_info &mi, unsigned &row) {
    int min_columns_required = (mi.match_RAMs + SRAM_COLUMNS - 1) / SRAM_COLUMNS;
    int left_given_columns = 0;
    int right_given_columns = 0;

    if (__builtin_popcount(row) == 0) {
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
        left_given_columns = __builtin_popcount(~row & 0xf);
        right_given_columns = __builtin_popcount(~row & 0x3f0);
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
    break_exact_tables_into_ways();
    while (exact_match_ways.size() > 0) {
        if (find_best_row_and_fill_out(column_mask) == false) {
            return false;
        }
    }
    compress_ways();
    for (auto *ta : exact_tables) {
        auto name = ta->table->get_use_name();
        LOG4("Exact match table " << name);
        auto alloc = (*ta->memuse)[name];
        for (auto row : alloc.row) {
            LOG4("Row is " << row.row << " and bus is " << row.bus);
            LOG4("Col is " << row.col);
        }
    }
    return true;
}

/* For assembly generation, ways from the same table that are on the same row need
   to be adjusted in the Memories::Use, as multiple entries appear o/w  */
void Memories::compress_ways() {
    for (auto *ta : exact_tables) {
        auto name = ta->table->get_use_name();
        auto &alloc = (*ta->memuse)[name];
        std::stable_sort(alloc.row.begin(), alloc.row.end(),
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


/* Number of continuous TCAMs needed for table width */
int Memories::ternary_TCAMs_necessary(table_alloc *ta, int &mid_bytes_needed) {
    int groups = ta->match_ixbar->groups();
    if (groups == 0)
        groups++;
    mid_bytes_needed = groups/2;
    return groups;
}

/* Finds the stretch on the ternary array that can hold entries */
bool Memories::find_ternary_stretch(int TCAMs_necessary, int mid_bytes_needed,
                                    int &row, int &col) {
    for (int j = 0; j < TCAM_COLUMNS; j++) {
        int clear_cols = 0;
        for (int i = 0; i < TCAM_ROWS; i++) {
            if (tcam_use[i][j]) {
                clear_cols = 0;
                continue;
            }

            if (clear_cols == 0 && mid_bytes_needed == TCAMs_necessary / 2
                && TCAMs_necessary % 2 == 0 && i % 2 == 1)
                 continue;
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
    std::sort(ternary_tables.begin(), ternary_tables.end(),
        [=](const table_alloc *a, table_alloc *b) {
        int t;
        if ((t = a->table->layout.match_bytes - b->table->layout.match_bytes) != 0) return t > 0;
        if ((t = a->calculated_entries - b->calculated_entries) != 0) return t > 0;
        return true;
    });

    // FIXME: All of this needs to be changed on this to match up with xbar
    for (auto *ta : ternary_tables) {
        int mid_bytes_needed = 0;
        int TCAMs_necessary = ternary_TCAMs_necessary(ta, mid_bytes_needed);
        // FIXME: If the table is just a default action table, essentially a hack
        if (TCAMs_necessary == 0)
            continue;

        int row = 0; int col = 0;
        auto name = ta->table->get_use_name();
        Memories::Use &alloc = (*ta->memuse)[name];
        for (int i = 0; i < ta->calculated_entries / 512; i++) {
            if (!find_ternary_stretch(TCAMs_necessary, mid_bytes_needed, row, col))
                return false;
            for (int i = row; i < row + TCAMs_necessary; i++) {
                 tcam_use[i][col] = name;
                 alloc.row.emplace_back(i, col);
                 alloc.row.back().col.push_back(col);
            }
        }
    }
    for (auto *ta : ternary_tables) {
        auto name = ta->table->get_use_name();
        auto &alloc = (*ta->memuse)[name];
        LOG4("Allocation of " << name);
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
    for (auto *ta : tind_tables) {
        int depth = (ta->calculated_entries + 2047) / 2048;
        tind_groups.push_back(new SRAM_group(ta, depth, 0, SRAM_group::TIND));
    }
}

/* Finds the best row in which to put the tind table */
int Memories::find_best_tind_row(SRAM_group *tg, int &bus) {
    int open_space = 0;
    unsigned left_mask = 0xf;
    vector<int> available_rows;
    auto name = tg->ta->table->get_use_name(nullptr, false, IR::MAU::Table::TIND_NAME);
    for (int i = 0; i < SRAM_ROWS; i++) {
        open_space += __builtin_popcount(~sram_inuse[i] & left_mask);
        auto tbus = tind_bus[i];
        if (!tbus[0] || tbus[0] == name || !tbus[1] || tbus[1] == name)
            available_rows.push_back(i);
    }

    if (open_space == 0)
        return -1;

    std::sort(available_rows.begin(), available_rows.end(),
        [=] (const int a, const int b) {
        int t;
        if ((t = __builtin_popcount(~sram_inuse[a] & left_mask)
               - __builtin_popcount(~sram_inuse[b] & left_mask)) != 0) return t > 0;

        auto tbus = tind_bus[a];
        if (tbus[0] == name || tbus[1] == name)
            return true;
        tbus = tind_bus[b];
        if (tbus[0] == name || tbus[1] == name)
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
        auto name = ta->table->get_use_name(nullptr, false, IR::MAU::Table::TIND_NAME);
        auto &alloc = (*ta->memuse)[name];
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
                auto name = tg->ta->table->get_use_name(nullptr, false, IR::MAU::Table::TIND_NAME);
                sram_inuse[best_row] |= (1 << i);
                sram_use[best_row][i] = name;
                tg->placed++;
                if (tg->all_placed()) {
                    tind_groups.erase(tind_groups.begin());
                }
                tind_bus[best_row][best_bus] = name;

                auto &alloc = (*tg->ta->memuse)[name];
                alloc.row.emplace_back(best_row, best_bus);
                alloc.row.back().col.push_back(i);
                break;
            }
        }
    }
    compress_tind_groups();
    for (auto *ta : tind_tables) {
        auto name = ta->table->get_use_name(nullptr, false, IR::MAU::Table::TIND_NAME);
        auto &alloc = (*ta->memuse)[name];
        LOG4("Allocation of " << name);
        for (auto row : alloc.row) {
            LOG4("Row is " << row.row << " and bus is " << row.bus);
            LOG4("Col is " << row.col);
        }
    }
    return true;
}

/* Calculates the necessary size and requirements for any and all indirect actions and selectors.
   Selectors must be done before indirect actions */
void Memories::action_bus_selectors_indirects() {
    for (auto *ta : selector_tables) {
        for (auto at : ta->table->attached) {
            // FIXME: need to adjust if the action selector is larger than 2 RAMs, based
            // on the pragmas provided to the compiler
            const IR::ActionSelector *as = nullptr;
            if ((as = at->to<IR::ActionSelector>()) == nullptr)
                continue;
            suppl_bus_users.push_back(new SRAM_group(ta, 2, 0, SRAM_group::SELECTOR));
            suppl_bus_users.back()->attached = as;
        }
    }

    for (auto *ta : indirect_action_tables) {
        for (auto at : ta->table->attached) {
            const IR::ActionProfile *ap = nullptr;
            if ((ap = at->to<IR::ActionProfile>()) == nullptr)
                continue;
            int width = 1;
            int per_row = ActionDataPerWord(&ta->table->layout, &width);
            int depth = (ap->size + per_row * 1024 - 1) / (per_row * 1024);
            SRAM_group *selector = nullptr;

            for (auto grp : suppl_bus_users) {
                if (grp->ta == ta && grp->type == SRAM_group::SELECTOR) {
                    selector = grp;
                    break;
                }
            }
            for (int i = 0; i < width; i++) {
                action_bus_users.push_back(new SRAM_group(ta, depth, i, SRAM_group::ACTION));
                action_bus_users.back()->attached = ap;
                if (selector != nullptr) {
                    action_bus_users.back()->sel.sel_group = selector;
                    selector->sel.action_groups.insert(action_bus_users.back());
                }
            }
        }
    }
}

/* Calculates the necessary size and requirements for any meter and counter tables within
   the stage */
void Memories::action_bus_meters_counters() {
    for (auto *ta : stats_tables) {
        for (auto at : ta->table->attached) {
            const IR::Counter *stats = nullptr;
            if ((stats = at->to<IR::Counter>()) == nullptr)
                continue;
            int per_row = CounterPerWord(stats);
            int depth;
            if (stats->direct) {
                depth = (ta->calculated_entries + per_row * 1024 - 1)/(per_row * 1024) + 1;
            } else {
                depth = (stats->instance_count + per_row * 1024 + 1023)/(per_row * 1024) + 1;
            }
            suppl_bus_users.push_back(new SRAM_group(ta, depth, 0, SRAM_group::STATS));
            suppl_bus_users.back()->attached = stats;
            auto name = ta->table->get_use_name(stats);
            // FIXME: This can go away
            (*ta->memuse)[name].per_row = per_row;
        }
    }

    for (auto *ta : meter_tables) {
        const IR::Meter *meter = nullptr;
        for (auto at : ta->table->attached) {
            if ((meter = at->to<IR::Meter>()) == nullptr)
                continue;
            int depth;
            if (meter->direct)
                depth = (ta->calculated_entries + 1023) / 1024 + 1;
            else
                depth = (meter->instance_count + 1023)/1024 + 1;

            suppl_bus_users.push_back(new SRAM_group(ta, depth, 0, SRAM_group::METER));
            suppl_bus_users.back()->attached = meter;
            if (meter->direct)
                suppl_bus_users.back()->cm.needed = (ta->calculated_entries + 4095)/4096;
            else
                suppl_bus_users.back()->cm.needed = (meter->instance_count + 4095)/4096;
            if (meter->implementation.name == "lpf" || meter->implementation.name == "wred") {
                suppl_bus_users.back()->requires_ab = true;
            }
        }
    }
}

/* Breaks up all tables requiring an action to be parsed into SRAM_group, a structure
   designed for adding to SRAM array  */
void Memories::find_action_bus_users() {
    for (auto *ta : action_tables) {
        int width = 1;
        int per_row = ActionDataPerWord(ta->layout_option->layout, &width);
        int depth = (ta->calculated_entries + per_row * 1024 - 1) / (per_row * 1024);
        for (int i = 0; i < width; i++) {
            action_bus_users.push_back(new SRAM_group(ta, depth, i, SRAM_group::ACTION));
        }
    }
    action_bus_selectors_indirects();
    action_bus_meters_counters();
}

/* Due to color maprams, the number of RAMs available to the suppl vs. the action
   groups could be wildly different */
void Memories::adjust_RAMs_available(action_fill &curr_oflow, int &suppl_RAMs_available,
                                     int action_RAMs_available, int row, bool left_side) {
    if (left_side)
        return;
    int open_maprams = __builtin_popcount(sram_inuse[row] & 0x3f0);

    if (!curr_oflow.group || curr_oflow.group->type != SRAM_group::METER)
        return;

    if (open_maprams > curr_oflow.group->cm.left_to_place()) {
        return;
    }

    if (curr_oflow.group && curr_oflow.group->cm.required) {
        suppl_RAMs_available -= curr_oflow.group->cm.left_to_place() - open_maprams;
    } else if (curr_oflow.group && !curr_oflow.group->cm.all_placed()) {
        if (curr_oflow.group->left_to_place() < action_RAMs_available) {
           suppl_RAMs_available -= curr_oflow.group->cm.left_to_place() - open_maprams;
        }
    }
}

/* This is a massive conditional to determine which action and supplemental tables should
   fill in the current row.  On the right side, the supplemental tables are favored.  If
   someone is on the left side or if no tables are able to be placed, then the choice of
   best action is made */
void Memories::action_row_trip(action_fill &action, action_fill &suppl, action_fill &oflow,
                               action_fill &best_fit_action, action_fill &best_fit_suppl,
                               action_fill &curr_oflow, action_fill &next_action,
                               action_fill &next_suppl, int action_RAMs_available,
                               int suppl_RAMs_available, bool left_side, int order[3]) {
    if (!left_side) {
        if (curr_oflow.group && curr_oflow.group->type != SRAM_group::ACTION) {
            if (best_fit_suppl.group
                && best_fit_suppl.group->left_to_place() == suppl_RAMs_available
                && best_fit_suppl.group->cm.needed == 0) {
                suppl = best_fit_suppl;
                order[SUPPL_IND] = 0;
            } else if (curr_oflow.group->left_to_place() >= suppl_RAMs_available) {
                oflow = curr_oflow;
                order[OFLOW_IND] = 0;
                if (suppl_RAMs_available < action_RAMs_available && next_action.group) {
                    action = next_action;
                    order[ACTION_IND] = 1;
                }
            /* There is space left for the suppl, based on the 2nd check */
            } else if (next_suppl.group && (!curr_oflow.group->needs_ab() ||
                      (curr_oflow.group->needs_ab() && !next_suppl.group->needs_ab()))) {
                suppl = next_suppl;
                oflow = curr_oflow;
                order[OFLOW_IND] = 0; order[SUPPL_IND] = 1;
                if (!next_suppl.group->needs_ab() &&
                    (next_suppl.group->left_to_place() +
                    curr_oflow.group->left_to_place() < action_RAMs_available)
                    && next_action.group) {
                    action = next_action;
                    order[ACTION_IND] = 2;
                }
            /* There is space left for the action, based on 2nd check */
            } else if (next_action.group && !curr_oflow.group->needs_ab()) {
                oflow = curr_oflow;
                action = next_action;
                order[OFLOW_IND] = 0; order[ACTION_IND] = 1;
            } else {
                oflow = curr_oflow;
                order[OFLOW_IND] = 0;
            }
        } else if (next_suppl.group) {
            suppl = next_suppl;
            order[SUPPL_IND] = 0;
            // FIXME: Perhaps port the correct function
            if (next_suppl.group->left_to_place() < action_RAMs_available
                && !next_suppl.group->needs_ab()) {
                if (curr_oflow.group) {
                    oflow = curr_oflow;
                    order[OFLOW_IND] = 1;
                } else if (next_action.group) {
                    action = next_action;
                    order[ACTION_IND] = 1;
                }
            }
        } else {
            action_oflow_only(action, oflow, best_fit_action, next_action, curr_oflow,
                              action_RAMs_available, order);
        }
    } else {
        action_fill curr_oflow_temp = curr_oflow;
        if (!curr_oflow.group || curr_oflow.group->type != SRAM_group::ACTION) {
            curr_oflow_temp.group = nullptr;
        }
        action_oflow_only(action, oflow, best_fit_action, next_action, curr_oflow_temp,
                          action_RAMs_available, order);
    }
}

/* When no supplementary tables were available, the best action and overflow groups are
   determined, as was the original algorithm before the supplementar7 tables were added */
void Memories::action_oflow_only(action_fill &action, action_fill &oflow,
                                 action_fill &best_fit_action, action_fill &next_action,
                                 action_fill &curr_oflow, int RAMs_available, int order[3]) {
    if (curr_oflow.group == nullptr) {
        if (!best_fit_action.group) {
            action = next_action;
        } else if (best_fit_action.group->left_to_place() == RAMs_available) {
            action = best_fit_action;
        } else {
            action = next_action;
        }
        order[ACTION_IND] = 0;
    } else {
        if (!best_fit_action.group) {
            oflow = curr_oflow;
            if (next_action.group && curr_oflow.group->left_to_place() < RAMs_available) {
                action = next_action;
                order[ACTION_IND] = 1;
            }
            order[OFLOW_IND] = 0;
        } else if (curr_oflow.group->left_to_place() + best_fit_action.group->left_to_place()
            >= RAMs_available) {
            oflow = curr_oflow;
            if (curr_oflow.group->left_to_place() < RAMs_available) {
                action = next_action;
                order[OFLOW_IND] = 0; order[ACTION_IND] = 1;
            } else {
                if (best_fit_action.group->left_to_place() <= RAMs_available) {
                    action = best_fit_action;
                    if (best_fit_action.group->left_to_place() == RAMs_available) {
                        oflow.group = nullptr;
                        order[ACTION_IND] = 0;
                    } else {
                        order[ACTION_IND] = 0; order[OFLOW_IND] = 1;
                    }
                } else {
                    order[OFLOW_IND] = 0;
                }
            }
        } else {
            oflow = curr_oflow;
            if (next_action.group
                && curr_oflow.group->left_to_place() < RAMs_available) {
                action = next_action;
                order[ACTION_IND] = 1;
            }
            order[OFLOW_IND] = 0;
        }
    }
}

/* Is a test within best candidates to see if even though sel unplaced is not yet finished,
   its action can be placed within this next row so that a new selector can be placed as well */
bool Memories::can_place_selector(action_fill &curr_oflow, SRAM_group *curr_check,
                                  int suppl_RAMs_available, int action_RAMs_available,
                                  action_fill &sel_unplaced) {
    // Need to fit the selector on this row, as the oflow group is a twoport table
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

/* This function called is used in the particular scenario where a previous selector's action
   can be placed within the same row as a new selector.  This has the possibility to use
   up potentially some RAMs in a particular row */
void Memories::selector_candidate_setup(action_fill &action, action_fill &suppl,
                                        action_fill &oflow, action_fill &curr_oflow,
                                        action_fill &sel_unplaced, action_fill &next_suppl,
                                        int order[3], int action_RAMs_available,
                                        int suppl_RAMs_available) {
    /* Should be guaranteed that the selector has enough space to fit onto the row
       if another two port table is on overflow */

    // FIXME: Potentially could save room if the action group that is overflowing is the
    // sel_unplaced group
    if (curr_oflow.group && curr_oflow.group->type != SRAM_group::ACTION) {
        suppl = next_suppl;
        order[SUPPL_IND] = 0;
        if (suppl.group->left_to_place() < action_RAMs_available) {
            action.group = sel_unplaced.group->sel.action_group_left();
            order[ACTION_IND] = 1;
            if (suppl.group->left_to_place() + action.group->left_to_place()
                < suppl_RAMs_available) {
                oflow.group = curr_oflow.group;
                order[OFLOW_IND] = 2;
            }
        }
    } else {
        action.group = sel_unplaced.group->sel.action_group_left();
        order[ACTION_IND] = 0;
        suppl = next_suppl;
        order[SUPPL_IND] = 1;
        // FIXME: Double check fo putting the correct information
        if (action.group->left_to_place() + suppl.group->left_to_place()
            > action_RAMs_available) {
            if (action.group->left_to_place() + 1 != action_RAMs_available)
                BUG("We have an issue in the double selector algorithm");
        } else if (action.group->left_to_place() + suppl.group->left_to_place()
                   < action_RAMs_available && curr_oflow.group
                   && curr_oflow.group != action.group && suppl.group != curr_oflow.group) {
            order[OFLOW_IND] = 2;
            oflow.group = curr_oflow.group;
        }
    }
}

/* Calculates the RAMs available to give to a particular action fill group based on the ordering
   which was dteremined by action_row_trip or selector_candidate_setup */
void Memories::set_up_RAM_counts(action_fill &action, action_fill &suppl, action_fill &oflow,
                                 int order[3], int RAMs[3], bool is_suppl[3],
                                 int suppl_RAMs_available) {
    if (order[ACTION_IND] >= 0) {
        RAMs[order[ACTION_IND]] = action.group->left_to_place();
    }
    if (order[SUPPL_IND] >= 0) {
        RAMs[order[SUPPL_IND]] = suppl.group->left_to_place();
        is_suppl[order[SUPPL_IND]] = true;
    }
    if (order[OFLOW_IND] >= 0) {
        if (suppl_RAMs_available > 0)
            RAMs[order[OFLOW_IND]] = oflow.group->left_to_place();
        if (oflow.group->type != SRAM_group::ACTION)
            is_suppl[order[OFLOW_IND]] = true;
    }
}
/* Calculate the best candidates for fitting onto the individual rows.  This
   finds the next candidates for the row */
void Memories::best_candidates(action_fill &best_fit_action, action_fill &best_fit_suppl,
                               action_fill &next_action, action_fill &next_suppl,
                               action_fill &curr_oflow, int action_RAMs_available,
                               int suppl_RAMs_available, bool stats_available,
                               bool meter_available, unsigned mask, action_fill &sel_unplaced) {
    int min_left;
    if (mask == 0x3f0) {
        /* Determine the best fit supplementary table on the row */
        for (size_t i = 0; i < suppl_bus_users.size(); i++) {
            if (curr_oflow.group == suppl_bus_users[i])
                continue;
            if (!stats_available && suppl_bus_users[i]->type == SRAM_group::STATS)
                continue;
            if (!meter_available && suppl_bus_users[i]->type != SRAM_group::STATS)
                continue;
            if (sel_unplaced.group && suppl_bus_users[i]->type == SRAM_group::SELECTOR)
                continue;
            if (suppl_bus_users[i]->left_to_place() <= suppl_RAMs_available) {
                best_fit_suppl.group = suppl_bus_users[i];
                best_fit_suppl.index = i;
                break;
            }
        }
        min_left = 0;
        /* Determine the supplementary table with the most left to place */
        for (size_t i = 0; i < suppl_bus_users.size(); i++) {
            if (curr_oflow.group == suppl_bus_users[i])
                continue;
            if (!stats_available && suppl_bus_users[i]->type == SRAM_group::STATS)
                continue;
            if (!meter_available && suppl_bus_users[i]->type != SRAM_group::STATS)
                continue;
            if (curr_oflow.group && curr_oflow.group->needs_ab()
                && suppl_bus_users[i]->needs_ab())
                continue;
            if (sel_unplaced.group && suppl_bus_users[i]->type == SRAM_group::SELECTOR
                && !can_place_selector(curr_oflow, suppl_bus_users[i],
                               suppl_RAMs_available, action_RAMs_available, sel_unplaced)) {
                continue;
            }
            if (suppl_bus_users[i]->total_left_to_place() > min_left) {
                next_suppl.group = suppl_bus_users[i];
                next_suppl.index = i;
                min_left = suppl_bus_users[i]->total_left_to_place();
            }
        }
    }


    if (sel_unplaced.group && next_suppl.group && next_suppl.group->type == SRAM_group::SELECTOR) {
        return;
    }

    /* Determine the best fit action on the current row.  Cannot be current oflow group */
    for (size_t i = 0; i < action_bus_users.size(); i++) {
        if (curr_oflow.group == action_bus_users[i])
            continue;
        if (action_bus_users[i]->sel.sel_linked() && !action_bus_users[i]->sel.sel_any_placed()) {
            if (!(next_suppl.group && next_suppl.group == action_bus_users[i]->sel.sel_group)) {
                continue;
            }
        }
        if (action_bus_users[i]->left_to_place() <= action_RAMs_available) {
            best_fit_action.group = action_bus_users[i];
            best_fit_action.index = i;
            break;
        }
    }

    min_left = 0;
    /* Determine the action with the most left to place */
    for (size_t i = 0; i < action_bus_users.size(); i++) {
        if (curr_oflow.group == action_bus_users[i]) {
            continue;
        }
        if (action_bus_users[i]->sel.sel_linked() && !action_bus_users[i]->sel.sel_any_placed()) {
            if (!(next_suppl.group && next_suppl.group == action_bus_users[i]->sel.sel_group)) {
                continue;
            }
        }
        if (action_bus_users[i]->left_to_place() > min_left) {
            next_action.group = action_bus_users[i];
            next_action.index = i;
            min_left = action_bus_users[i]->left_to_place();
        }
    }
}

/* Fills out the masks for the suppl and the action groups in each of the orders */
void Memories::fill_out_masks(unsigned suppl_masks[3], unsigned action_masks[3], int RAMs[3],
                              int RAMs_filled[3], bool is_suppl[3], int row, unsigned mask,
                              int suppl_RAMs_available, int action_RAMs_available) {
    int total_RAMs_filled = 0;

    /* Separate passes as the considered RAMs available for supplementary tables and
       action tables might be different */
    unsigned all_suppl_masks = 0;
    for (int i = 0; i < SRAM_COLUMNS && total_RAMs_filled < RAMs[0] + RAMs[1] + RAMs[2] &&
                                        total_RAMs_filled < suppl_RAMs_available; i++) {
        if (((1 << i) & mask) == 0)
            continue;
        if ((1 << i) & ~sram_inuse[row]) {
            if (RAMs_filled[0] < RAMs[0]) {
                suppl_masks[0] |= (1 << i);
                RAMs_filled[0]++;
            } else if (RAMs_filled[1] < RAMs[1]) {
                suppl_masks[1] |= (1 << i);
                RAMs_filled[1]++;
            } else if (RAMs_filled[2] < RAMs[2]) {
                suppl_masks[2] |= (1 << i);
                RAMs_filled[2]++;
            } else {
                break;
            }
            total_RAMs_filled++;
        }
    }

    all_suppl_masks = suppl_masks[0] | suppl_masks[1] | suppl_masks[2];

    /* Separate action masks due to color mapram usage */
    for (int i = 0; i < SRAM_COLUMNS && total_RAMs_filled < RAMs[0] + RAMs[1] + RAMs[2] &&
                                        total_RAMs_filled < action_RAMs_available; i++) {
        if (((1 << i) & mask) == 0 || ((1 << i) & ~all_suppl_masks) == 0)
            continue;
        if ((1 << i) & ~sram_inuse[row]) {
            if (RAMs_filled[0] < RAMs[0] && !is_suppl[0]) {
                action_masks[0] |= (1 << i);
                RAMs_filled[0]++;
            } else if (RAMs_filled[1] < RAMs[1] && !is_suppl[1]) {
                action_masks[1] |= (1 << i);
                RAMs_filled[1]++;
            } else if (RAMs_filled[2] < RAMs[2] && !is_suppl[2]) {
                action_masks[2] |= (1 << i);
                RAMs_filled[2]++;
            } else {
               break;
            }
            total_RAMs_filled++;
        }
    }
}

/* Selects the best two candidates for the potential use in the particular action row,
   and calculate the corresponding masks and indices within the list */
void Memories::find_action_candidates(int row, int mask, action_fill &action, action_fill &suppl,
                                      action_fill &oflow, bool stats_available,
                                      bool meter_available, action_fill &curr_oflow,
                                      action_fill &sel_unplaced) {
    if (action_bus_users.empty() && suppl_bus_users.empty()) {
        return;
    }

    int action_RAMs_available = __builtin_popcount(mask & ~sram_inuse[row]);
    int suppl_RAMs_available = action_RAMs_available;
    adjust_RAMs_available(curr_oflow, suppl_RAMs_available, action_RAMs_available, row,
                          mask == 0xf);
    action_fill best_fit_action, best_fit_suppl;
    action_fill next_action, next_suppl;

    best_candidates(best_fit_action, best_fit_suppl, next_action, next_suppl, curr_oflow,
                    suppl_RAMs_available, action_RAMs_available, stats_available,
                    meter_available, mask, sel_unplaced);

    if (best_fit_action.group == nullptr && best_fit_suppl.group == nullptr
        && curr_oflow.group == nullptr && next_action.group == nullptr
        && next_suppl.group == nullptr) {
        // FIXME: Calculate the color mapram stuff
        if (curr_oflow.group && !curr_oflow.group->cm.all_placed()) {
            oflow = curr_oflow;
            color_mapram_candidates(suppl, oflow, mask);
        }
        bool actions_available = false;
        for (size_t i = 0; i < action_bus_users.size(); i++) {
            if (!action_bus_users[i]->sel.sel_linked() ||
                (action_bus_users[i]->sel.sel_linked()
                 && action_bus_users[i]->sel.sel_all_placed())) {
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

    unsigned suppl_masks[3] = {0, 0, 0};
    unsigned action_masks[3] = {0, 0, 0};
    int RAMs[3] = {0, 0, 0};
    int order[3] = {-1, -1, -1};  // order is action, suppl, oflow
    int RAMs_filled[3] = {0, 0, 0};
    bool is_suppl[3] = {false, false, false};

    if (sel_unplaced.group && next_suppl.group && next_suppl.group->type == SRAM_group::SELECTOR)
        selector_candidate_setup(action, suppl, oflow, curr_oflow, sel_unplaced, next_suppl,
                                 order, action_RAMs_available, suppl_RAMs_available);
    else
        action_row_trip(action, suppl, oflow, best_fit_action, best_fit_suppl, curr_oflow,
                        next_action, next_suppl, action_RAMs_available, suppl_RAMs_available,
                        (mask == 0xf), order);

    set_up_RAM_counts(action, suppl, oflow, order, RAMs, is_suppl, suppl_RAMs_available);
    fill_out_masks(suppl_masks, action_masks, RAMs, RAMs_filled, is_suppl, row, mask,
                   suppl_RAMs_available, action_RAMs_available);

    if (order[ACTION_IND] >= 0) {
        action.mask = suppl_masks[order[ACTION_IND]] | action_masks[order[ACTION_IND]];
    }
    if (order[SUPPL_IND] >= 0) {
        suppl.mask = suppl_masks[order[SUPPL_IND]];
        suppl.mapram_mask = suppl_masks[order[SUPPL_IND]];
    }
    if (order[OFLOW_IND] >= 0) {
        oflow.mask = suppl_masks[order[OFLOW_IND]];
        if (oflow.group->type != SRAM_group::ACTION)
            oflow.mapram_mask = suppl_masks[order[OFLOW_IND]];
        else
            oflow.mask |= action_masks[order[OFLOW_IND]];
    }
    color_mapram_candidates(suppl, oflow, mask);
}

/* All calculations for the color mapram usage if necessary */
void Memories::color_mapram_candidates(action_fill &suppl, action_fill &oflow, unsigned mask) {
    int maprams[2] = {0, 0};
    int maprams_filled[2] = {0, 0};
    bool curr_oflow_mapram = false;

    if (oflow.group && !oflow.group->cm.all_placed()) {
        maprams[0] = oflow.group->cm.left_to_place();
        curr_oflow_mapram = true;
    }

    if (suppl.group && !suppl.group->cm.all_placed()) {
        int suppl_mapram_index = 0;
        if (curr_oflow_mapram)
            suppl_mapram_index = 1;
        maprams[suppl_mapram_index] = suppl.group->cm.left_to_place();
    }

    unsigned mapram_masks[2] = {0, 0};
    unsigned mapram_row_use = suppl.mask;
    if (oflow.group && oflow.group->type != SRAM_group::ACTION)
        mapram_row_use |= oflow.mask;

    int total_maprams_filled = 0;
    for (int i = 0; i < SRAM_COLUMNS && total_maprams_filled < maprams[0] + maprams[1]; i++) {
        if (((1 << i) & mask) == 0)
            continue;
        if ((1 << i) & mapram_row_use)
            continue;
        if (maprams_filled[0] < maprams[0]) {
            mapram_masks[0] |= (1 << i);
            maprams_filled[0]++;
        } else if (maprams_filled[1] < maprams[1]) {
            mapram_masks[1] |= (1 << i);
            maprams_filled[1]++;
        }
        total_maprams_filled++;
    }

    curr_oflow_mapram = false;
    if (oflow.group && !oflow.group->cm.all_placed()) {
        if (oflow.group->cm.required && mapram_masks[0] == 0)
            BUG("Oflow required color map ram and none available");
        oflow.mapram_mask |= mapram_masks[0];
        curr_oflow_mapram = true;
    }

    if (suppl.group && !suppl.group->cm.all_placed()) {
        int suppl_mapram_index = 0;
        if (curr_oflow_mapram)
            suppl_mapram_index = 1;
        suppl.mapram_mask |= mapram_masks[suppl_mapram_index];
    }
}

/*  Fills out a row with all three of the group */
void Memories::action_side(action_fill &action, action_fill &suppl, action_fill &oflow,
                           bool removed[3], int row, int side, unsigned mask) {
    if (action.group != nullptr) {
        removed[ACTION_IND] = fill_out_action_row(action, row, side, mask, false, false);
    }

    if (suppl.group != nullptr) {
        removed[SUPPL_IND] = fill_out_action_row(suppl, row, side, mask, false, true);
        fill_out_color_mapram(suppl, row, mask, false);
    }

    if (oflow.group != nullptr) {
        if (removed[ACTION_IND] && action.index < oflow.index
            && oflow.group->type == SRAM_group::ACTION)
            oflow.index--;
        if (removed[SUPPL_IND] && suppl.index < oflow.index
            && oflow.group->type != SRAM_group::ACTION)
            oflow.index--;

        removed[OFLOW_IND] = fill_out_action_row(oflow, row, side, mask, true,
                                            oflow.group->type != SRAM_group::ACTION);
        fill_out_color_mapram(oflow, row, mask, true);
    }
    // FIXME: Potentially need to set up the difference between wide action tables within
    // the assembly output
    if (action.group && oflow.group && action.group->ta == oflow.group->ta
        && action.group->type == SRAM_group::ACTION && oflow.group->type == SRAM_group::ACTION) {
        if (action.group == oflow.group) {
            BUG("Shouldn't be the same for action and oflow");
        } else {
            auto name = action.group->get_name();
            auto &alloc = (*action.group->ta->memuse)[name];
            size_t size = alloc.row.size();
            auto &row2 = alloc.row[size - 1]; auto &row1 = alloc.row[size - 2];
            row1.col.insert(row1.col.end(), row2.col.begin(), row2.col.end());
            alloc.row.erase(alloc.row.begin() + size - 1);
        }
    }

    if (suppl.group && oflow.group && oflow.group->type != SRAM_group::ACTION &&
        oflow.index < suppl.index && removed[OFLOW_IND])
        suppl.index--;


    if (action.group && oflow.group && oflow.group->type == SRAM_group::ACTION &&
        oflow.index < action.index && removed[OFLOW_IND])
        action.index--;
}

/* Fills out the action RAMs and bus on an individual action data bus and potential
   removes completely packed action groups from the action group array */
bool Memories::fill_out_action_row(action_fill &action, int row, int side, unsigned mask,
                                   bool is_oflow, bool is_twoport) {
    if (__builtin_popcount(action.mask) == 0 && __builtin_popcount(action.mapram_mask) == 0) {
        BUG("Somehow action group allocated without anything to place");
    }
    if (__builtin_popcount(action.mask) == 0)
        return false;

    auto a_name = action.group->get_name();
    auto &a_alloc = (*action.group->ta->memuse)[a_name];
    if (is_oflow) {
        overflow_bus[row][side] = a_name;
        a_alloc.row.emplace_back(row);
    } else if (is_twoport) {
        twoport_bus[row] = a_name;
        a_alloc.row.emplace_back(row, side);
    } else {
        action_data_bus[row][side] = a_name;
        a_alloc.row.emplace_back(row, side);
        a_alloc.home_row.emplace_back(2*row + 1-side, action.group->number);
        action.group->recent_home_row = row;
    }

    for (int k = 0; k < 10; k++) {
        if (((1 << k) & mask) == 0)
            continue;

        if ((1 << k) & action.mask) {
            sram_use[row][k] = a_name;
            a_alloc.row.back().col.push_back(k);
            if (is_twoport) {
                mapram_use[row][k - LEFT_SIDE_COLUMNS] = a_name;
                a_alloc.row.back().mapcol.push_back(k - LEFT_SIDE_COLUMNS);
            }
        }
    }

    sram_inuse[row] |= action.mask;
    if (is_twoport && !is_oflow) {
        if (action.group->type == SRAM_group::STATS)
            stats_alus[row/2] = a_name;
        else
            meter_alus[row/2] = a_name;
    }
    bool action_group_removed = false;
    action.group->placed += __builtin_popcount(action.mask);
    if (action.group->all_placed()) {
        if (is_twoport)
            suppl_bus_users.erase(suppl_bus_users.begin() + action.index);
        else
            action_bus_users.erase(action_bus_users.begin() + action.index);
        action_group_removed = true;
    }
    return action_group_removed;
}

/* Calculates if a placed selector's action has been entirely placed.  If the action
   is not yet fully placed, another selector cannot yet be placed */
void Memories::calculate_sel_unplaced(action_fill &action, action_fill &suppl,
                                      action_fill &oflow, action_fill &sel_unplaced) {
    if (sel_unplaced.group) {
        if ((action.group && action.group->sel_act_placed(sel_unplaced.group)) ||
            (oflow.group && oflow.group->sel_act_placed(sel_unplaced.group))) {
           sel_unplaced.clear();
        }
    }

    bool curr_sel_oflow = sel_unplaced.group != nullptr;
    if (suppl.group && suppl.group->type == SRAM_group::SELECTOR) {
        if ((action.group == nullptr || !action.group->sel.is_sel_corr_group(suppl.group) ||
            !action.group->all_placed()) && (oflow.group == nullptr ||
            !oflow.group->sel.is_sel_corr_group(suppl.group) || oflow.group->all_placed())) {
            if (curr_sel_oflow)
                BUG("Error: Two selector tables are colliding on overflow");
            else
                sel_unplaced = suppl;
        }
    }

    if (oflow.group && oflow.group->type == SRAM_group::SELECTOR) {
        if (oflow.group == sel_unplaced.group)
            return;
        if (action.group == nullptr || action.group->sel.is_sel_corr_group(oflow.group) ||
            !action.group->all_placed()) {
            if (curr_sel_oflow)
                BUG("Error: Two selector tables are colliding on overflow");
            else
                sel_unplaced = oflow;
        }
    }
}

/* Finds the twoport oflow group and finds the curr oflow group */
void Memories::calculate_curr_oflow(action_fill &action, action_fill &suppl, action_fill &oflow,
                                    bool removed[3], action_fill &curr_oflow,
                                    action_fill &twoport_oflow, bool right_side) {
    bool twoport_oflow_selected = false;
    if (right_side) {
        if (suppl.group) {
            if (!suppl.group->all_placed() || !suppl.group->cm.all_placed()) {
                twoport_oflow = suppl;
                twoport_oflow_selected = true;
            }
        }
        if (oflow.group && oflow.group->type != SRAM_group::ACTION) {
            if (!oflow.group->all_placed() || !oflow.group->cm.all_placed()) {
                twoport_oflow = oflow;
                if (twoport_oflow_selected) {
                    BUG("Compiler selected multiple overflow groups");
                }
            }
        }
    }


    if (!removed[OFLOW_IND] && oflow.group && oflow.group->type == SRAM_group::ACTION) {
        curr_oflow = oflow;
    } else if (!removed[ACTION_IND] && action.group) {
        curr_oflow = action;
    } else {
        curr_oflow.clear();
    }
}

/* Fills out the color mapram information within the Use for the particular table */
void Memories::fill_out_color_mapram(action_fill &action, int row, unsigned mask, bool is_oflow) {
    if (action.mapram_mask == action.mask || action.group->type == SRAM_group::ACTION)
        return;

    auto a_name = action.group->get_name();
    auto &a_alloc = (*action.group->ta->memuse)[a_name];

    if (is_oflow)
        a_alloc.color_mapram.emplace_back(row, 1);
    else
        a_alloc.color_mapram.emplace_back(row, 0);
    unsigned color_mapram_mask = action.mapram_mask & ~action.mask;

    for (int k = 0; k < 10; k++) {
        if (((1 << k) & mask) == 0)
            continue;
        if ((1 << k) & color_mapram_mask) {
            a_alloc.color_mapram.back().col.push_back(k - LEFT_SIDE_COLUMNS);
        }
    }
    action.group->cm.placed += __builtin_popcount(color_mapram_mask);
}

/* Logging information for each individual action/twoport table information */
void Memories::action_bus_users_log() {
    for (auto *ta : action_tables) {
        auto name = ta->table->get_use_name(nullptr, false, IR::MAU::Table::AD_NAME);
        auto alloc = (*ta->memuse)[name];
        LOG4("Action allocation for " << name);
        for (auto row : alloc.row) {
            LOG4("Row is " << row.row << " and bus is " << row.bus);
            LOG4("Col is " << row.col);
        }
    }

    // FIXME: Add extra meter pre-color maprams
    for (auto *ta : stats_tables) {
        for (auto at : ta->table->attached) {
            const IR::Counter *stats = nullptr;
            if ((stats = at->to<IR::Counter>()) == nullptr)
                continue;
            auto name = ta->table->get_use_name(stats);
            LOG4("Stats table for " << name);
            auto alloc = (*ta->memuse)[name];
            for (auto row : alloc.row) {
                LOG4("Row is " << row.row << " and bus is " << row.bus);
                LOG4("Col is " << row.col);
                LOG4("Map col is " << row.mapcol);
            }
        }
    }
    for (auto *ta : meter_tables) {
        for (auto at : ta->table->attached) {
            const IR::Meter *meter = nullptr;
            if ((meter = at->to<IR::Meter>()) == nullptr)
                continue;
            auto name = ta->table->get_use_name(meter);
            LOG4("Meter table for " << name);
            auto alloc = (*ta->memuse)[name];
            for (auto row : alloc.row) {
                LOG4("Row is " << row.row << " and bus is " << row.bus);
                LOG4("Col is " << row.col);
                LOG4("Map col is " << row.mapcol);
            }
        }
    }

    for (auto *ta : selector_tables) {
        for (auto at : ta->table->attached) {
            const IR::ActionSelector *as = nullptr;
            if ((as = at->to<IR::ActionSelector>()) == nullptr)
                continue;
            auto name = ta->table->get_use_name(as);
            LOG4("Selector table for " << name);
            auto alloc = (*ta->memuse)[name];
            for (auto row : alloc.row) {
                LOG4("Row is " << row.row << " and bus is " << row.bus);
                LOG4("Col is " << row.col);
                LOG4("Map col is " << row.mapcol);
            }
        }
    }

    for (auto *ta : indirect_action_tables) {
        for (auto at : ta->table->attached) {
            const IR::ActionProfile *ap = nullptr;
            if ((ap = at->to<IR::ActionProfile>()) == nullptr)
                continue;
            auto name = ta->table->get_use_name(ap);
            LOG4("Action profile allocation for " << name);
            auto alloc = (*ta->memuse)[name];
            for (auto row : alloc.row) {
                LOG4("Row is " << row.row << " and bus is " << row.bus);
                LOG4("Col is " << row.col);
            }
        }
    }
}

/* Goes through action bus by action bus, and finds the best candidates for each row,
   then allocates them.  */
bool Memories::allocate_all_action() {
    find_action_bus_users();
    action_fill curr_oflow, twoport_oflow;
    action_fill action; action_fill oflow; action_fill suppl;
    action_fill sel_unplaced;
    std::sort(action_bus_users.begin(), action_bus_users.end(),
        [=](const SRAM_group *a, SRAM_group *b) {
        int t;
        if ((t = a->RAMs_required() - b->RAMs_required()) != 0) return t > 0;
        return a->number < b->number;
    });

    std::sort(suppl_bus_users.begin(), suppl_bus_users.end(),
        [=](const SRAM_group *a, SRAM_group *b) {
        int t;
        if ((t = a->RAMs_required() - b->RAMs_required()) != 0) return t > 0;
        return a->number < b->number;
    });

    for (int i = SRAM_ROWS - 1; i >= 0; i--) {
        twoport_oflow.clear();
        for (int j = 0; j < 2; j++) {
            int mask = 0;
            if (j == 0)
                mask = 0x3f0;
            else
                mask = 0xf;

            if (__builtin_popcount(mask & ~sram_inuse[i]) == 0) continue;
            action.clear(); oflow.clear(); suppl.clear();
            bool stats_available = true; bool meter_available = true;

            if (i == 7 || stats_alus[(i+1)/2]) {
                stats_available = false;
            }

            if (meter_alus[i/2]) {
                meter_available = false;
            }
            find_action_candidates(i, mask, action, suppl, oflow, stats_available, meter_available,
                                   curr_oflow, sel_unplaced);

            if (action.group == nullptr && oflow.group == nullptr && suppl.group == nullptr) {
                continue;
            }
            bool removed[3];
            for (int k = 0; k < 3; k++)
                 removed[k] = false;
            action_side(action, suppl, oflow, removed, i, j, mask);
            calculate_curr_oflow(action, suppl, oflow, removed, curr_oflow,
                                 twoport_oflow, j == 0);
            calculate_sel_unplaced(action, suppl, oflow, sel_unplaced);
        }
        if (twoport_oflow.group) {
            curr_oflow = twoport_oflow;
        }
        if (i != SRAM_ROWS - 1 && curr_oflow.group)
            vert_overflow_bus[i] = std::make_pair(curr_oflow.group->get_name(),
                                                  curr_oflow.group->number);

        if (curr_oflow.group && curr_oflow.group->recent_home_row - i >= 4) {
            if (curr_oflow.group->type != SRAM_group::ACTION)
                curr_oflow.group->depth++;
            curr_oflow.clear();
        }
    }

    if (!action_bus_users.empty() || !suppl_bus_users.empty()) {
        int act_unused = 0;
        for (auto abu : action_bus_users)
            act_unused += abu->left_to_place();

        int sup_unused = 0;
        for (auto sbu : suppl_bus_users)
            sup_unused += sbu->left_to_place();

        return false;
    }
    action_bus_users_log();
    return true;
}

Memories::table_alloc *Memories::find_corresponding_exact_match(cstring name) {
    for (auto *ta : exact_tables) {
        auto check_name = ta->table->get_use_name();
        if (check_name == name)
            return ta;
    }
    return nullptr;
}

bool Memories::gw_search_bus_fit(table_alloc *ta, table_alloc *exact_ta, int width_sect,
                                 int row, int col) {
    if (!ta->match_ixbar->exact_comp(exact_ta->match_ixbar, width_sect)) return false;
    // FIXME: Needs to better orient with the layout
    int bytes_needed = exact_ta->table->layout.match_bytes;
    bytes_needed = (exact_ta->table->layout.overhead_bits + 7) / 8;
    int groups = exact_ta->layout_option->way->match_groups;
    int width = exact_ta->layout_option->way->width;
    bytes_needed *= groups * width;
    // FIXME: For version bits
    bytes_needed += groups / 2 * width;
    int total_bytes = 16 * width;
    int remaining_bytes = total_bytes - bytes_needed - exact_ta->attached_gw_bytes;
    if (remaining_bytes < ta->match_ixbar->gw_search_bus_bytes) {
        return false;
    }
    if (gw_bytes_per_sb[row][col] + ta->match_ixbar->gw_search_bus_bytes > 4)
        return false;
    return true;
}

/* Allocates all gateways */
bool Memories::allocate_all_gw() {
    size_t index = 0;
    for (auto *ta : gw_tables) {
        auto name = ta->table->get_use_name(nullptr, true);
        if (ta->table_link != nullptr)
            name = ta->table_link->table->get_use_name(nullptr, true);
        auto &alloc = (*ta->memuse)[name];
        bool found = false;
        // Tries to find a bus to share with the current table
        for (int i = 0; i < SRAM_ROWS; i++) {
            if (gateway_use[i][0] && gateway_use[i][1]) continue;
            int current_gw = 0;
            if (gateway_use[i][0])
                current_gw = 1;
            for (int j = 0; j < BUS_COUNT; j++) {
                auto bus = sram_match_bus[i][j];
                // FIXME: This is the punt based on the layout issues, later remove
                // the gateway_use[i][j]
                if (!bus.first || gateway_use[i][j]) continue;
                table_alloc *exact_ta = find_corresponding_exact_match(bus.first);
                // FIXME: this is just a temporary patch
                if (ta->match_ixbar->gw_search_bus) {
                    continue;
                    // if (!gw_search_bus_fit(ta, exact_ta, bus.second, i, j)) continue;
                }
                if (ta->match_ixbar->gw_hash_group) {
                    // FIXME: Currently all ways shared the same hash_group
                    if (ta->match_ixbar->bit_use[0].group
                        != exact_ta->match_ixbar->way_use[0].group)
                         continue;
                }
                exact_ta->attached_gw_bytes += ta->match_ixbar->gw_search_bus_bytes;
                gw_bytes_per_sb[i][j] += ta->match_ixbar->gw_search_bus_bytes;
                gateway_use[i][current_gw] = name;
                alloc.row.emplace_back(i, j);
                alloc.row.back().col.push_back(current_gw);
                found = true;
                index++;
                break;
            }
            if (found) break;
        }
        if (found) continue;
        // No bus could be shared, just look for an open bus!
        for (int i = 0; i < SRAM_ROWS; i++) {
            if (gateway_use[i][0] && gateway_use[i][1]) continue;
            int current_gw = 0;
            if (gateway_use[i][0])
                current_gw = 1;
            // FIXME: When layout info is added, we can potentially change this
            for (int j = 0; j < BUS_COUNT; j++) {
                if (!gateway_use[i][j]) {
                    alloc.row.emplace_back(i, j);
                    gateway_use[i][current_gw] = name;
                    alloc.row.back().col.push_back(current_gw);
                    index++;
                    found = true;
                    break;
                }
            }
            if (found) break;
        }
        if (!found) break;
    }
    if (gw_tables.size() != index)
        return false;
    return true;
}

void Memories::Use::visit(Memories &mem, std::function<void(cstring &)> fn) const {
    Alloc2Dbase<cstring> *use = 0, *mapuse = 0, *bus = 0;
    switch (type) {
    case EXACT:
        use = &mem.sram_use;
        bus = &mem.sram_print_match_bus;
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
    case TWOPORT:
        use = &mem.sram_use;
        mapuse = &mem.mapram_use;
        break;
    case ACTIONDATA:
        use = &mem.sram_use;
        bus = &mem.action_data_bus;
        break;
    default:
        BUG("Unhandled memory use type %d in Memories::Use::visit", type); }
    for (auto &r : row) {
        if (bus && r.bus != -1) {
            fn((*bus)[r.row][r.bus]);
        }
        /*if (type == TWOPORT)
            fn(mem.stateful_bus[r.row]);*/
        for (auto col : r.col) {
            fn((*use)[r.row][col]);
        }
        for (auto col : r.mapcol) {
            fn((*mapuse)[r.row][col]);
        }
    }
    for (auto &r : color_mapram) {
         for (auto col : r.col) {
             fn((*mapuse)[r.row][col]);
         }
    }
}

void Memories::update(cstring name, const Memories::Use &alloc) {
    alloc.visit(*this, [name](cstring &use) {
        if (use)
            BUG("conflicting memory use between %s and %s", use, name);
        use = name; });
}
void Memories::update(const map<cstring, Use> &alloc) {
    for (auto &a : alloc) update(a.first, a.second);
}

void Memories::remove(cstring name, const Memories::Use &alloc) {
    alloc.visit(*this, [name](cstring &use) {
        if (use != name)
            BUG("Undo failure for %s", name);
        use = nullptr; });
}
void Memories::remove(const map<cstring, Use> &alloc) {
    for (auto &a : alloc) remove(a.first, a.second);
}

/* MemoriesPrinter in .gdbinit should match this */
std::ostream &operator<<(std::ostream &out, const Memories &mem) {
    const Alloc2Dbase<cstring> *arrays[] = { &mem.tcam_use, &mem.sram_print_match_bus,
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
