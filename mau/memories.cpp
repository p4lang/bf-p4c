#include "lib/bitops.h"
#include "lib/range.h"
#include "memories.h"
#include "resource_estimate.h"

void Memories::clear() {
    sram_use.clear();
    tcam_use.clear();
    mapram_use.clear();
    sram_match_bus.clear();
    sram_search_bus.clear();
    sram_print_match_bus.clear();
    tind_bus.clear();
    action_data_bus.clear();
    stateful_bus.clear();
    overflow_bus.clear();
    vert_overflow_bus.clear();
    tables.clear();
    clear_table_vectors();
}

void Memories::clear_table_vectors() {
    exact_tables.clear();
    exact_match_ways.clear();
    ternary_tables.clear();
    tind_tables.clear();
    tind_groups.clear();
    action_tables.clear();
    action_bus_users.clear();
    gw_tables.clear();
}

/* Creates a new table_alloc object for each of the tables within the memory allocation */
void Memories::add_table(const IR::MAU::Table *t, const IXBar::Use *mi,
                         map<cstring, Memories::Use> *mu, int entries) {
    if (t != nullptr) {
        auto *ta = new table_alloc(t, mi, mu, entries);
        tables.push_back(ta);
        LOG3("Adding table " << t->name << " with " << entries << " entries.");
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
        calculate_column_balance(mi, row);
        LOG3("Allocating all exact tables");
        if (allocate_all_exact(row)) {
           finished = true;
        }
        LOG3("Row size " << __builtin_popcount(row));

    } while (__builtin_popcount(row) < 10 && !finished);

    if (!finished)
        return false;

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

/* Run a quick analysis on all tables added by the table placement algorithm, 
   and add the tables to their corresponding lists */
bool Memories::analyze_tables(mem_info &mi) {
    mi.clear();
    clear_table_vectors();
    for (auto *ta : tables) {
        if (ta->provided_entries == -1 || ta->provided_entries == 0) {
            auto name = ta->table->name + "$gw";
            (*ta->memuse)[name].type = Use::GATEWAY;
            gw_tables.push_back(ta);
            LOG4("Gateway table for " << ta->table->name);
            continue;
        }
        auto table = ta->table;
        int entries = ta->provided_entries;
        if (!table->layout.ternary) {
            LOG4("Exact match table " << table->name);
            auto name = ta->table->name;
            (*ta->memuse)[name].type = Use::EXACT;
            exact_tables.push_back(ta);
            mi.match_tables++;
            int width = table->ways[0].width;
            LOG3("Width/groups " << width << "/" << ta->match_ixbar->groups());
            //FIXME: Non-working valid bits
            assert(width == ta->match_ixbar->groups() || ta->match_ixbar->groups() == 0);
            int groups = table->ways[0].match_groups;
            int depth = ((entries + groups - 1U)/groups + 1023)/1024U;
            mi.match_bus_min += width;
            mi.match_RAMs += depth;
        } else {
           LOG4("Ternary match table " << table->name);
           auto name = ta->table->name;
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
        for (auto at : table->attached) {
            if (at->is<IR::MAU::ActionData>()) {
                LOG4("Action table for table " << table->name);
                auto name = ta->table->name + "$action";
                (*ta->memuse)[name].type = Use::ACTIONDATA;
                action_tables.push_back(ta);
                mi.action_tables++;
                int sz = ceil_log2(table->layout.action_data_bytes) + 3;
                int width = sz > 7 ? 1 << (sz - 7) : 1;
                mi.action_bus_min += width;
                int per_ram = sz > 7 ? 10 : 17 - sz;
                int depth = ((entries - 1) >> per_ram) + 1;
                mi.action_RAMs += depth;
            } else if (at->is<IR::MAU::TernaryIndirect>()) {
                auto name = ta->table->name + "$tind";
                (*ta->memuse)[name].type = Use::TIND;
                tind_tables.push_back(ta);
                mi.tind_tables++;
                mi.tind_RAMs += (entries + 1023U) / 1024U;
            }
        }
    }

    if (mi.match_tables > EXACT_TABLES_MAX
        || mi.match_bus_min > SRAM_ROWS * BUS_COUNT
        || mi.tind_tables > TERNARY_TABLES_MAX
        || mi.action_tables > ACTION_TABLES_MAX
        || mi.action_bus_min > SRAM_ROWS * BUS_COUNT
        || mi.match_RAMs + mi.action_RAMs + mi.tind_RAMs > SRAM_ROWS * SRAM_COLUMNS
        || mi.ternary_tables > TERNARY_TABLES_MAX
        || mi.ternary_TCAMs > TCAM_ROWS * TCAM_COLUMNS) {
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
    for (int i = 0; i < SRAM_ROWS; i++) {
        auto bus = sram_match_bus[i];
        // if the first bus or the second bus match up to what is
        if (!(!bus[0].first || !bus[1].first ||
            (bus[0].first == ta->table->name && bus[0].second == width_sect) ||
            (bus[1].first == ta->table->name && bus[1].second == width_sect)))
            continue;
        available_rams.push_back(std::make_pair(i,
                                 __builtin_popcount((mask ^ sram_inuse[i]) & mask)));
    }

    std::sort(available_rams.begin(), available_rams.end(),
             [=](const std::pair<int, int> a, const std::pair<int, int> b) {
         int t;
         if ((t = a.second - b.second) != 0) return t > 0;
         return a < b;
    });
    return available_rams;
}

/* Simple now.  Just find rows with the available RAMs that it is asking for */
vector<int> Memories::available_match_SRAMs_per_row(unsigned row_mask, unsigned total_mask,
                                                    int row, table_alloc *ta, int width_sect) {
    vector<int> matching_rows;
    for (int i = 0; i < SRAM_ROWS; i++) {
        auto bus = sram_match_bus[i];
        if (row == i) continue;
        if (!(!bus[0].first || !bus[1].second ||
            (bus[0].first == ta->table->name && bus[0].second == width_sect) ||
            (bus[1].first == ta->table->name && bus[1].second == width_sect))) continue;

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

        if ((bus[0].first && bus[0].first == ta->table->name && bus[0].second == width_sect) ||
            (bus[1].first && bus[1].first == ta->table->name && bus[1].second == width_sect))
            return true;

        bus = sram_match_bus[b];

        if ((bus[0].first && bus[0].first == ta->table->name && bus[0].second == width_sect) ||
            (bus[1].first && bus[1].first == ta->table->name && bus[1].second == width_sect))
            return false;

        return a < b;
    });
    return matching_rows;
}

/* Based on the number of ways provided to the table, this function calculates the
   way sizes based on the number of entries desired by the table, and recalculates
   the same number of entries */
void Memories::break_exact_tables_into_ways() {
    exact_match_ways.clear();
    for (auto *ta : exact_tables) {
        int number_of_ways = ta->table->ways.size();
        int width = ta->table->ways[0].width;
        int groups = ta->table->ways[0].match_groups;
        int RAMs_needed = width * (((ta->provided_entries + groups - 1U)/groups + 1023)/1024U);
        int total_depth = (RAMs_needed + width - 1) / width;
        vector<int> way_sizes = way_size_calculator(number_of_ways, total_depth);
        for (size_t i = 0; i < way_sizes.size(); i++) {
            exact_match_ways.push_back(new SRAM_group(ta, way_sizes[i], width, i));
            ta->calculated_entries += way_sizes[i] * 1024U * groups;
        }

        struct waybits {
            bitvec bits;
            decltype(bits.end()) next;
            waybits() : next(bits.end()) {}
        };
        std::map<int, waybits> alloc_bits;
        for (auto &way : ta->match_ixbar->way_use) {
            alloc_bits[way.group].bits |= way.mask;
        }
        for (size_t i = 0; i < way_sizes.size(); i++) {
            int log2sz = ceil_log2(way_sizes[i]);
            auto &bits = alloc_bits[ta->match_ixbar->way_use[i].group];
            unsigned mask = 0;
            for (int bit = 0; bit < log2sz; bit++) {
               if (!++bits.next) ++bits.next;
               if (!bits.next || (mask & (1 << *bits.next))) {
                   WARNING("Not enough way bits");
                   break;
               }
               mask |= 1 << *bits.next;
            }
           (*ta->memuse)[ta->table->name].ways.emplace_back(way_sizes[i], mask);
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
        if ((bus[0].first && bus[0].first == emw->ta->table->name) ||
            (bus[1].first && bus[1].first == emw->ta->table->name))
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
     if (!sram_match_bus[row][0].first
         || (sram_match_bus[row][0].first == ta->table->name
         && sram_match_bus[row][0].second == width))
         return 0;
     else
         return 1;
}

/* Put the selected way group into the RAM row as much as possible */
bool Memories::pack_way_into_RAMs(SRAM_group *wa, int row, int &cols, unsigned column_mask) {
    vector<std::pair<int, int>> buses;
    buses.emplace_back(row, match_bus_available(wa->ta, 0, row));
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
                                                                  wa->ta, i);
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

    auto name = wa->ta->table->name;
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
            sram_use[selected_rows[i]][selected_cols[j]] = wa->ta->table->name;
            alloc_row.col.push_back(selected_cols[j]);
        }
        sram_inuse[selected_rows[i]] |= row_mask;
        if (!sram_match_bus[selected_rows[i]][bus].first) {
            sram_match_bus[selected_rows[i]][bus]
                = std::make_pair(wa->ta->table->name, width);
            sram_print_match_bus[selected_rows[i]][bus] = wa->ta->table->name;
        }
    }
    return true;
}

/* Picks an empty/most open row, and begins to fill it in within a way */
bool Memories::find_best_row_and_fill_out(unsigned column_mask) {
    SRAM_group *wa = exact_match_ways[0];
    // FIXME: Obviously the mask has to change
    vector<std::pair<int, int>> available_rams
        = available_SRAMs_per_row(column_mask, wa->ta, 0);
    LOG3("Past available");
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
    LOG3("Past pack way into RAMs");

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

// FIXME: Needs to actually be calculated for exact match row placement
void Memories::calculate_column_balance(mem_info &mi, unsigned &row) {
    int min_columns_required = (mi.match_RAMs + SRAM_ROWS - 1) / SRAM_ROWS; 
    int total_RAMs = mi.match_RAMs + mi.tind_RAMs + mi.action_RAMs; 
    int total_columns_required = (total_RAMs + SRAM_ROWS - 1) / SRAM_ROWS; 
    int mask_columns = 0; 
    if (__builtin_popcount(row) == 0) { 
        // FIXME: Making things up. Need good statistics  
        if (total_columns_required < 7 || min_columns_required < 5) { 
            mask_columns = 8; 
        } else { 
            mask_columns = min_columns_required; 
        } 
    } else { 
        mask_columns = __builtin_popcount(row) + 1; 
    } 
 
    switch (mask_columns) { 
        case 5 : row = 0x0f8; break; 
        case 6 : row = 0x0fc; break; 
        case 7 : row = 0x1fc; break; 
        case 8 : row = 0x1fe; break; 
        case 9 : row = 0x1ff; break; 
        default : row = 0x3ff; break; 
    }
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
    return true;
}

/* For assembly generation, ways from the same table that are on the same row need
   to be adjusted in the Memories::Use, as multiple entries appear o/w  */
void Memories::compress_ways() {
    for (auto *ta : exact_tables) {
        auto name = ta->table->name;
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


/* Number of continuous TCAMs needed for table width */
int Memories::ternary_TCAMs_necessary(table_alloc *ta, int &mid_bytes_needed) {
    int groups = ta->match_ixbar->groups();
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
        int row = 0; int col = 0;
        auto name = ta->table->name;
        Memories::Use &alloc = (*ta->memuse)[name];
        for (int i = 0; i < ta->calculated_entries / 512; i++) {
            if (!find_ternary_stretch(TCAMs_necessary, mid_bytes_needed, row, col))
                return false;
            for (int i = row; i < row + TCAMs_necessary; i++) {
                 tcam_use[i][col] = ta->table->name;
                 alloc.row.emplace_back(i, col);
                 alloc.row.back().col.push_back(col);
            }
        }
    }
    return true;
}

/* Breaks up the tables requiring tinds into groups that can be allocated within the 
   SRAM array */
void Memories::find_tind_groups() {
    for (auto *ta : tind_tables) {
        int depth = (ta->calculated_entries + 2047) / 2048;
        tind_groups.push_back(new SRAM_group(ta, depth, 0));
    }
}


int Memories::find_best_tind_row(SRAM_group *tg, int &bus) {
    int open_space = 0;
    unsigned left_mask = 0xf;
    for (int i = 0; i < SRAM_ROWS; i++) {
        open_space += __builtin_popcount(sram_inuse[i] & left_mask);
    }
    if (open_space == 0)
        return -1;

    int avg_open = open_space / SRAM_ROWS;

    int best_row = 0;
    for (int i = 1; i < SRAM_ROWS; i++) {
        auto t_bus = tind_bus[i];
        if (!t_bus[0] || !t_bus[1]) {

        } 
    }
    return 0;
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

    // Keep it really simple for first iteration, just reserve the 1st column and then fill it out

    while (!tind_groups.empty()) {
        auto *tg = tind_groups[0];
        int best_bus = 0;
        int best_row = find_best_tind_row(tg, best_bus);
        if (best_row == -1) return false;
        for (int i = 0; i < LEFT_SIDE_COLUMNS; i++) {
            if (~(sram_inuse[best_row] & (1 << i))) {
                auto name = tg->ta->table->name + "$tind";
                sram_inuse[best_row] |= (1 << i);
                sram_use[best_row][i] = name;
                tg->placed++;
                if (tg->all_placed()) {
                    tind_groups.erase(tind_groups.begin());
                }

                auto &alloc = (*tg->ta->memuse)[name];
                alloc.row.emplace_back(best_row, best_bus);
                alloc.row.back().col.push_back(i);
                break;
            }
        }
    }

    return true;
    /*
    for (int i = 0; i < SRAM_ROWS; i++) {
        if (tind_groups.empty())
            break;
        SRAM_group *next_tind = tind_groups[0];
        if (!sram_use[i][0]) {
            auto name = next_tind->ta->table->name + "$tind";
            sram_use[i][0] = name;
            sram_inuse[i] |= 1;
            tind_bus[i][0] = name;
            next_tind->placed++;
            if (next_tind->all_placed()) {
                tind_groups.erase(tind_groups.begin());
            }
            auto &alloc = (*next_tind->ta->memuse)[name];
            alloc.row.emplace_back(i, 0);
            alloc.row.back().col.push_back(0);
        }
    }

    if (!tind_groups.empty())
        return false;

    return true;
    */
}

/* Breaks up all tables requiring an action to be parsed into SRAM_group, a structure
   designed for adding to SRAM array  */
void Memories::find_action_bus_users() {
    for (auto *ta : action_tables) {
        int sz = ceil_log2(ta->table->layout.action_data_bytes) + 3;
        int width = sz > 7 ? 1 << (sz - 7) : 1;

        int per_ram = sz > 7 ? 10 : 17 - sz;
        int depth = ((ta->calculated_entries - 1) >> per_ram) + 1;

        for (int i = 0; i < width; i++) {
            action_bus_users.push_back(new SRAM_group(ta, depth, i));
        }
    }
}

/* This is a large if-else to determine the best two groups to fit within in the
   particular action row, based on previous oflows.
*/
bool Memories::best_a_oflow_pair(SRAM_group **best_a_group, SRAM_group **best_oflow_group,
                                 int &a_index, int &oflow_index, int RAMs_available,
                                 SRAM_group *best_fit_group, int best_fit_index,
                                 SRAM_group *curr_oflow_group) {
    bool oflow_first = false;

    if (curr_oflow_group == nullptr) {
        if (!best_fit_group) {
            *best_a_group = action_bus_users[0];
            a_index = 0;
        } else if (best_fit_group->left_to_place() == RAMs_available) {
            *best_a_group = best_fit_group;
            a_index = best_fit_index;
        } else {
            *best_a_group = action_bus_users[0];
            a_index = 0;
        }

    } else {
        if (!best_fit_group) {
            *best_oflow_group = curr_oflow_group;
            oflow_index = 0;
            if (action_bus_users.size() > 1
                && curr_oflow_group->left_to_place() < RAMs_available) {
                *best_a_group = action_bus_users[1];
                a_index = 1;
            }
            oflow_first = true;
        } else if (curr_oflow_group->left_to_place() + best_fit_group->left_to_place()
            >= RAMs_available) {
            *best_oflow_group = curr_oflow_group;
            oflow_index = 0;
            if (curr_oflow_group->left_to_place() < RAMs_available) {
                oflow_first = true;
                *best_a_group = best_fit_group;
                a_index = best_fit_index;
            } else {
                if (best_fit_group->left_to_place() <= RAMs_available) {
                    *best_a_group = best_fit_group;
                    a_index = best_fit_index;
                    if (best_fit_group->left_to_place() == RAMs_available)
                        *best_oflow_group = nullptr;
                } else {
                    oflow_first = true;
                }
            }
        } else {
            *best_oflow_group = curr_oflow_group;
            oflow_index = 0;
            if (action_bus_users.size() > 1
                && curr_oflow_group->left_to_place() < RAMs_available) {
                *best_a_group = action_bus_users[1];
                a_index = 1;
            }
            oflow_first = true;
        }
    }
    return oflow_first;
}

/* Selects the best two candidates for the potential use in the particular action row, 
   and calculate the corresponding masks and indices within the list */
void Memories::find_action_candidates(int row, int mask, SRAM_group **a_group, unsigned &a_mask,
                                      int &a_index, SRAM_group **oflow_group,
                                      unsigned &oflow_mask, int &oflow_index) {
    if (action_bus_users.empty()) {
        return;
    }

    int RAMs_available = __builtin_popcount(mask & ~sram_inuse[row]);

    int best_fit_index = 0;

    SRAM_group *best_a_group = nullptr;
    SRAM_group *best_oflow_group = nullptr;

    SRAM_group *curr_oflow_group = (action_bus_users[0]->placed == 0) ?
                                         nullptr : action_bus_users[0];
    SRAM_group *best_fit_group = nullptr;
    for (size_t i = 1; i < action_bus_users.size(); i++) {
        if (action_bus_users[i]->depth <= RAMs_available) {
            best_fit_group = action_bus_users[i];
            best_fit_index = i;
            break;
        }
    }

    bool oflow_first = best_a_oflow_pair(&best_a_group, &best_oflow_group, a_index, oflow_index,
                                         RAMs_available, best_fit_group, best_fit_index,
                                         curr_oflow_group);

    unsigned first_mask = 0; unsigned second_mask = 0;
    int first_RAMs = 0;
    int second_RAMs = 0;
    if (oflow_first) {
        first_RAMs = best_oflow_group->left_to_place();
        if (best_a_group)
            second_RAMs = best_a_group->left_to_place();
    } else {
        first_RAMs = best_a_group->left_to_place();
        if (best_oflow_group)
            second_RAMs = best_oflow_group->left_to_place();
    }

    int RAMs_filled = 0;
    for (int i = 0; i < SRAM_COLUMNS && RAMs_filled < first_RAMs + second_RAMs; i++) {
        if (((1 << i) & mask) == 0)
            continue;
        if ((1 << i) & ~sram_inuse[row]) {
            if (RAMs_filled < first_RAMs)
                first_mask |= (1 << i);
            else
                second_mask |= (1 << i);
            RAMs_filled++;
        }
    }

    if (oflow_first) {
        oflow_mask = first_mask;
        a_mask = second_mask;
    } else {
        oflow_mask = second_mask;
        a_mask = first_mask;
    }

    if (best_a_group) {
        *a_group = best_a_group;
    }
    if (best_oflow_group) {
        *oflow_group = best_oflow_group;
    }
}

/* Fills out the action RAMs and bus on an individual action data bus and potential
   removes completely packed action groups from the action group array */
bool Memories::fill_out_action_row(SRAM_group *a_group, unsigned a_mask, int a_index,
                                   int row, int side, unsigned mask, bool is_oflow) {
    auto a_name = a_group->ta->table->name + "$action";
    auto &a_alloc = (*a_group->ta->memuse)[a_name];
    if (is_oflow) {
        overflow_bus[row][side] = a_name;
        a_alloc.row.emplace_back(row);
    } else {
        action_data_bus[row][side] = a_name;
        a_alloc.row.emplace_back(row, side);
    }
    for (int k = 0; k < 10; k++) {
        if (((1 << k) & mask) == 0)
            continue;

        if ((1 << k) & a_mask) {
            sram_use[row][k] = a_name;
            a_alloc.row.back().col.push_back(k);
        }
    }

    sram_inuse[row] |= a_mask;
    bool action_group_removed = false;
    if (a_group != nullptr) {
        a_group->placed += __builtin_popcount(a_mask);
        if (a_group->all_placed()) {
            action_bus_users.erase(action_bus_users.begin() + a_index);
            action_group_removed = true;
        }
    }
    return action_group_removed;
}
/* Goes through action bus by action bus, and finds the best candidates for each row,
   then allocates them.  */
bool Memories::allocate_all_action() {
    find_action_bus_users();
    std::sort(action_bus_users.begin(), action_bus_users.end(),
        [=](const SRAM_group *a, SRAM_group *b) {
        int t;
        if ((t = a->depth - b->depth) != 0) return t > 0;
        return a->number < b->number;
    });

    bool completed = false;
    for (int i = 0; i < SRAM_ROWS; i++) {
        for (int j = 0; j < 2; j++) {
            int mask = 0;
            if (j == 0)
                mask = 0x3f0;
            else
                mask = 0xf;

            if (__builtin_popcount(mask & ~sram_inuse[i]) == 0) continue;

            SRAM_group *a_group = nullptr;
            SRAM_group *oflow_group = nullptr;
            unsigned a_mask = 0; unsigned oflow_mask = 0;
            int a_index = 0; int oflow_index = 0;
            find_action_candidates(i, mask, &a_group, a_mask, a_index,
                                   &oflow_group, oflow_mask, oflow_index);

            if (a_group == nullptr && oflow_group == nullptr) {
                completed = true;
                break;
            }

            bool a_group_removed = false;
            if (a_group != nullptr) {
                a_group_removed = fill_out_action_row(a_group, a_mask, a_index,
                                                      i, j, mask, false);
            }

            if (oflow_group != nullptr) {
                if (a_group_removed && a_index < oflow_index)
                    oflow_index--;
                fill_out_action_row(oflow_group, oflow_mask, oflow_index, i, j, mask, true);
            }
        }
        if (completed) break;
    }

    if (!action_bus_users.empty())
        return false;
    return true;
}

/* Allocates all gateways */
bool Memories::allocate_all_gw() {
/*
    for (auto *ta : gw_tables) {
        for (int i = 0; i < SRAM_ROWS; i++) {
            for (int j = 0; j < BUS_COUNT; j++) {
                if (gateway_use[i][j]) continue;
                auto bus = sram_match_bus[i][j];
                if (!bus.first) continue;
                table_alloc *exact_ta = find_corresponding_exact_match(bus.first);
                if (!ta->match_ixbar->exact_comp(exact_ta->match_ixbar, bus.second)) continue;

                //FIXME: Needs to better orient with the layout
                int bytes_needed = exact_ta->table->layout.match_bytes;
                bytes_needed = (exact_ta->table->layout.overhead_bits + 7) / 8;
                int groups = exact_ta->table->ways[0].groups;
                int width = exact_ta->table->ways[0].width;
                bytes_needed *= groups * width;
                //FIXME: For version bits
                bytes_needed += groups / 2 * width; 
                int total_bytes = 16 * width;
                int remaining_bytes = total_bytes - bytes_needed - exact_ta->gw_bytes;
                if (remaining_bytes){
                }
                
            }
        }
    }
*/

    int row = 0; int column = 0;
    size_t index = 0;
    for (auto *ta : gw_tables) {
        bool found = false;
        for (int i = row; i < SRAM_ROWS; i++) {
            for (int j = column; j < 2; j++) {
                if (!sram_match_bus[i][j].first) {
                    auto name = ta->table->name + "$gw";
                    sram_match_bus[i][j] = std::make_pair(name, 0);
                    auto &alloc = (*ta->memuse)[name];
                    alloc.row.emplace_back(i, j);
                    row = i;
                    column = j+1;
                    index++;
                    found = true;
                    break;
                }
            }
            if (found) break;
            column = 0;
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
        bus = &mem.sram_print_match_bus;
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
        if (bus && r.bus != -1)
            fn((*bus)[r.row][r.bus]);
        if (type == TWOPORT)
            fn(mem.stateful_bus[r.row]);
        for (auto col : r.col) {
            fn((*use)[r.row][col]);
        }
        for (auto col : r.mapcol)
            fn((*mapuse)[r.row][col]); }
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
                   &mem.tind_bus, &mem.action_data_bus, &mem.sram_use, &mem.mapram_use };
    std::map<cstring, char>     tables;
    out << "tc  eb  tib ab  srams       mapram  sb" << std::endl;
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
