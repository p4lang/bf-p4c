#include "lib/bitops.h"
#include "lib/range.h"
#include "memories.h"
#include "resource_estimate.h"

void Memories::clear() {
    sram_use.clear();
    tcam_use.clear();
    mapram_use.clear();
    sram_match_bus.clear();
    tind_bus.clear();
    action_data_bus.clear();
    stateful_bus.clear();
}

void Memories::add_table(const IR::MAU::Table *t, const IXBar::Use &mi, 
                         map<cstring, Memories::Use> *mu, int entries) {
    if (t != nullptr) {
        LOG3("Adding a table " << t->name);
        auto *ta = new table_alloc(t, mi, mu, entries);
        tables.push_back(ta);
    }
}

bool Memories::analyze_tables(mem_info &mi) {

    mi.clear();
    for (auto *ta : tables) {
        LOG3 ("Entries is " << ta->provided_entries);
        //TODO: Ask Chris about this?
        if (ta->provided_entries == -1 || ta->provided_entries == 0) {
            auto name = ta->table->name + "$gw";
            (*ta->memuse)[name].type = Use::GATEWAY;
            gw_tables.push_back(ta);
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
            int groups = table->ways[0].match_groups;
            int depth = ((entries + groups - 1U)/groups + 1023)/1024U;
            LOG3("depth is " << depth);
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

    if (mi.match_tables > 16 || mi.match_bus_min > 16 || mi.tind_tables > 8 
        || mi.action_tables > 16 || mi.action_bus_min > 16 
        || mi.match_RAMs + mi.action_RAMs + mi.tind_RAMs > 80
        || mi.ternary_tables > 8 || mi.ternary_TCAMs > 24) {
        return false;
    }
    return true;    
}

vector<int> Memories::way_size_calculator (int ways, int RAMs_needed) {
    vector<int> vec;
    if (ways == -1) {
    //FIXME: If the number of ways are not provided, not yet considered


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

vector<std::pair<int, int>> Memories::available_SRAMs_per_row(unsigned mask, table_alloc *ta,
                                                                int width_sect) {
    vector<std::pair<int, int>> available_rams;
    for (int i = 0; i < SRAM_ROWS; i++) {
        std::pair<table_alloc *, int> *first_bus, *second_bus;
        first_bus = sram_match_bus2[i][0];  second_bus = sram_match_bus2[i][1];
        //if the first bus or the second bus match up to what is 
        if (!(first_bus == nullptr || second_bus == nullptr ||
            (first_bus->first == ta && first_bus->second == width_sect) ||
            (second_bus->first == ta && second_bus->second == width_sect))) continue; 
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
        std::pair<table_alloc *, int> *first_bus, *second_bus;
        first_bus = sram_match_bus2[i][0];  second_bus = sram_match_bus2[i][1];
        if (row == i) continue;
        if (!(first_bus == nullptr || second_bus == nullptr ||
            (first_bus->first == ta && first_bus->second == width_sect) ||
            (second_bus->first == ta && second_bus->second == width_sect))) continue;

        if (__builtin_popcount(row_mask & ~sram_inuse[i]) == __builtin_popcount(row_mask))
            matching_rows.push_back(i); 
    }
 
    std::sort(matching_rows.begin(), matching_rows.end(),
              [=] (const int a, const int b) {

        int t;
        if ((t = __builtin_popcount(~sram_inuse[a] & total_mask) - 
                 __builtin_popcount(~sram_inuse[b] & total_mask)) != 0)
            return t < 0;
        
        std::pair<table_alloc *, int> *first_bus, *second_bus;
        first_bus = sram_match_bus2[a][0]; second_bus = sram_match_bus2[a][1];

        if ((first_bus != nullptr && first_bus->first == ta && first_bus->second == width_sect) ||
            (second_bus != nullptr && second_bus->first == ta && second_bus->second == width_sect)) 
            return true;
      
        first_bus = sram_match_bus2[b][0]; second_bus = sram_match_bus2[b][1];
        
        if ((first_bus != nullptr && first_bus->first == ta && first_bus->second == width_sect) ||
            (second_bus != nullptr && second_bus->first == ta && second_bus->second == width_sect)) 
            return false;

        return a < b;
    });
    return matching_rows;
}

void Memories::break_exact_tables_into_ways() {
    LOG3("Breaking the tables into ways");

    for (auto *ta : exact_tables) { 
        int number_of_ways = ta->table->ways.size();
        int width = ta->table->ways[0].width;
        int groups = ta->table->ways[0].match_groups;
	int RAMs_needed = width * ((ta->provided_entries + groups - 1U)/groups + 1023)/1024U;
        int total_depth = (RAMs_needed + width - 1) / width;
        LOG3("number of ways " << number_of_ways);
        LOG3("RAMs_needed " << RAMs_needed);
        LOG3("total_depth " << total_depth);
        vector<int> way_sizes = way_size_calculator(number_of_ways, total_depth);
        for (size_t i = 0; i < way_sizes.size(); i++) {
            exact_match_ways.push_back(new way_group(ta, way_sizes[i], width, i));
            ta->calculated_entries += way_sizes[i] * 1024U * groups;
        }
        
        struct waybits {
            bitvec bits;
            decltype(bits.end()) next;
            waybits() : next(bits.end()) {}
        };
        std::map<int, waybits> alloc_bits;
        for (auto &way : ta->match_ixbar.way_use) {
            alloc_bits[way.group].bits |= way.mask; 
        }
        for (size_t i = 0; i < way_sizes.size(); i++) {
            int log2sz = ceil_log2(way_sizes[i]);
            auto &bits = alloc_bits[ta->match_ixbar.way_use[i].group];
            unsigned mask = 0;
            for (int bit = 0; bit < log2sz; bit++) {
               if(!++bits.next) ++bits.next;
               if(!bits.next || (mask & (1 << *bits.next))) {
                   WARNING("Not enough way bits");
                   break;
               }
               mask |= 1 << *bits.next;      
            }
           (*ta->memuse)[ta->table->name].ways.emplace_back(way_sizes[i], mask);
        }
        
    }

    std::sort(exact_match_ways.begin(), exact_match_ways.end(),
              [=](const way_group *a, const way_group *b) {
         
         int t;
         if ((t = a->width - b->width) != 0) return t > 0;
         if ((t = (a->depth - a->placed) - (b->depth - b->placed)) != 0) return t > 0;
         if ((t = a->ta->calculated_entries - b->ta->calculated_entries) != 0) return t < 0;
         return a->number < b->number;
    });

}

Memories::way_group * Memories::find_best_candidate (way_group *placed_wa, int row, int &loc) {
    if (exact_match_ways.empty()) return nullptr;
    
    std::pair<table_alloc *, int> *first_bus, *second_bus;
    first_bus = sram_match_bus2[row][0];  second_bus = sram_match_bus2[row][1];

    loc = 0;
    for (auto emw : exact_match_ways) {
        if (placed_wa->ta == emw->ta) {
            return emw;
        }
        loc++;    
    }

    loc = 0;
    for (auto emw : exact_match_ways) {
        if ((first_bus != nullptr && first_bus->first == emw->ta) ||
            (second_bus != nullptr && second_bus->first == emw->ta)) 
            return emw;
        loc++;
    }

    if (first_bus != nullptr && second_bus != nullptr) {
        return nullptr;
    }

    //FIXME: Perhaps do a best fit algorithm here
    loc = 0;
    return exact_match_ways[0];
}

bool Memories::fill_out_row(way_group *placed_wa, int row) {

    int loc = 0;
    vector<std::pair<int, int>> buses;
    //FIXME: Need to adjust to the proper mask provided by earlier function
    while (SRAM_COLUMNS - __builtin_popcount(sram_inuse[row]) > 0) {
        buses.clear();
        way_group *wa = find_best_candidate(placed_wa, row, loc);
	if (wa == nullptr)
            return true;
        buses.emplace_back(row, match_bus_available(wa->ta, 0, row));
        int cols = 0;
        unsigned row_mask = 0;
        vector<int> selected_cols;
        for (int i = 0; i < SRAM_COLUMNS && cols < wa->depth - wa->placed; i++) {        
            if (sram_use2[row][i] == nullptr && ((1 << i) & 0x3ff)) {
                row_mask |= (1 << i);
                selected_cols.push_back(i);
                cols++;
            }
        }

        vector<int> selected_rows;
        selected_rows.push_back(row);
        //Fairly simple stuff
        for (int i = 1; i < wa->width; i++) {
            vector<int> matching_rows = available_match_SRAMs_per_row(row_mask, 0x3ff, 
								      row, wa->ta, i);
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
            //This needs to be better checked
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
                sram_use2[selected_rows[i]][selected_cols[j]] = wa->ta;
                alloc_row.col.push_back(selected_cols[j]);
            }
            sram_inuse[selected_rows[i]] |= row_mask;
            if (sram_match_bus2[selected_rows[i]][bus] == nullptr) {
                sram_match_bus2[selected_rows[i]][bus] 
                    = new std::pair<table_alloc *, int>(wa->ta, width);
            }
        }

        if (cols >= wa->depth - wa->placed) {
            exact_match_ways.erase(exact_match_ways.begin() + loc);
        } else {
            wa->placed += cols;
        }
    }
    return true;
}

int Memories::match_bus_available(table_alloc *ta, int width, int row) {
     if (sram_match_bus2[row][0] == nullptr 
         || (sram_match_bus2[row][0]->first == ta && sram_match_bus2[row][0]->second == width))
         return 0;
     else
         return 1;
}

bool Memories::find_best_row_and_fill_out() {
    way_group *wa = exact_match_ways[0];
    //FIXME: Obviously the mask has to change
    vector<std::pair<int, int>> buses;
    vector<std::pair<int, int>> available_rams = available_SRAMs_per_row(0x3ff, wa->ta, 0);
    //No memories left to place anything
    if (available_rams.size() == 0) {
        return false;
    }

    int row = available_rams[0].first;
    buses.emplace_back(row, match_bus_available(wa->ta, 0, row));
    if (available_rams[0].second == 0)
        return false;
    unsigned row_mask = 0;
    vector<int> selected_cols;
    int cols = 0;
    for (int i = 0; i < SRAM_COLUMNS && cols < wa->depth - wa->placed; i++) {
        //FIXME: Path change
        if (sram_use2[row][i] == nullptr && ((1 << i) & 0x3ff)) {
            row_mask |= (1 << i);
            selected_cols.push_back(i);
            cols++;
        }
    }

    vector<int> selected_rows;
    selected_rows.push_back(row);
    //Fairly simple stuff
    for (int i = 1; i < wa->width; i++) {
        vector<int> matching_rows = available_match_SRAMs_per_row(row_mask, 0x3ff, row, wa->ta, i);
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
        //This needs to be better checked
        if (j == matching_rows.size()) {
            return false;
        }
    }

    auto name = wa->ta->table->name;
    //assert(!wa->ta->memuse->count(name));
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
            sram_use2[selected_rows[i]][selected_cols[j]] = wa->ta;
            alloc_row.col.push_back(selected_cols[j]);
        }
        sram_inuse[selected_rows[i]] |= row_mask;
        if (sram_match_bus2[selected_rows[i]][bus] == nullptr) {
            sram_match_bus2[selected_rows[i]][bus] 
                = new std::pair<table_alloc *, int>(wa->ta, width);
        }
    }

    if (cols >= wa->depth - wa->placed) {
        exact_match_ways.erase(exact_match_ways.begin());
        if (cols == wa->depth - wa->placed)
           return fill_out_row (wa, row);
        else
           return true;
    } else {
        wa->placed += cols;
        return true;
    }
}

void Memories::calculate_column_balance(mem_info &mi) {
    return;
}


bool Memories::allocate_all_exact(Memories::mem_info &mi) {
    break_exact_tables_into_ways();
    while (exact_match_ways.size() > 0) {
        if (find_best_row_and_fill_out() == false) {
            return false;
        }
    }
    return true;
}

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

    for (auto *ta : exact_tables) {
        auto name = ta->table->name;
        auto &alloc = (*ta->memuse)[name];
        for (size_t i = 0; (int) i < alloc.row.size(); i++) {
             LOG3("Table " << name << " on row " << alloc.row[i].row << " has " 
                  << alloc.row[i].col.size() << " columns");
        }
    }
}

bool Memories::allocate_all() { 
    mem_info mi;
    if (!analyze_tables(mi)) {
        return false;
    }

    calculate_column_balance(mi);


    if (!allocate_all_exact(mi)) {
        return false;
    }
    compress_ways();
    
    LOG3("SRAM inuse");
    for (int i = 0; i < SRAM_ROWS; i++) {
        LOG3(sram_inuse[i]);
    } 

    if (!allocate_all_ternary()) {
        return false;
    }

    if (!allocate_all_tind()) {
        return false;
    }

    if (!allocate_all_action()) {
        return false;
    }
   
    for (auto *ta : action_tables) {
        auto name = ta->table->name + "$action";
        auto &alloc = (*ta->memuse)[name];
        for (int i = 0; (int) i < alloc.row.size(); i++) {
             LOG3("Table " << name << " on row " << alloc.row[i].row << " has " 
                  << alloc.row[i].col.size() << " columns");
        }
    } 


    if (!allocate_all_gw()) {
        return false;
    }
    return true;
}

//FIXME: Have to at some point coordinate this with the actual XBAR lol
int Memories::ternary_TCAMs_necessary(table_alloc *ta, int &mid_bytes_needed) {
    int bytes = ta->table->layout.match_bytes;
    int TCAMs_necessary = 0;
    while (bytes > 11) {
        bytes -= 11;
        mid_bytes_needed++;
        TCAMs_necessary += 2;
    }

    if (bytes == 11)
        TCAMs_necessary += 3;
    else if (bytes > 5)
        TCAMs_necessary += 2;
    else
        TCAMs_necessary += 1;   
    return TCAMs_necessary;
}

bool Memories::find_ternary_stretch(int TCAMs_necessary, int mid_bytes_needed,
                                    int &row, int &col) {

    for (int j = 0; j < SRAM_COLUMNS; j++) {
        int clear_cols = 0;
        for (int i = 0; i < SRAM_ROWS; i++) {
            if (tcam_use2[i][j] != nullptr) {
                clear_cols = 0;
                continue;
            }

            if (clear_cols == 0 && mid_bytes_needed == TCAMs_necessary / 2 
                && TCAMs_necessary % 2 == 0 && i % 2 == 0)
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

//Allocate all ternary entries
bool Memories::allocate_all_ternary() {
    std::sort(ternary_tables.begin(), ternary_tables.end(),
        [=](const table_alloc *a, table_alloc *b) {
        int t;
        if ((t = a->table->layout.match_bytes - b->table->layout.match_bytes) != 0) return t > 0;
        if ((t = a->calculated_entries - b->calculated_entries) != 0) return t > 0;
        return true;
    });

    //All of this needs to be changed on this to match up with xbar
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
                 tcam_use2[i][col] = ta;
                 alloc.row.emplace_back(i, col);
                 alloc.row.back().col.push_back(col);
            }
        }
    }
    return true;
}

void Memories::find_tind_groups() {
    for (auto *ta : tind_tables) {
        int depth = (ta->calculated_entries + 2047) / 2048;
        tind_groups.push_back(new action_group(ta, depth, 0));
    }
}

//This is extremely basic for right now
bool Memories::allocate_all_tind() {
   
    std::sort(tind_tables.begin(), tind_tables.end(),
        [=] (const table_alloc *a, const table_alloc *b) {
        int t;
        if ((t = a->calculated_entries - b->calculated_entries) != 0) return t > 0;
        return true;
    });
  
    find_tind_groups();
     
    //Keep it really simple for first iteration, just reserve the 1st column and then fill it out
    int left_mask = 0xf;
    for (int i = 0; i < SRAM_ROWS; i++) {
        if (tind_groups.empty())
            return true;
        action_group *next_tind = tind_groups[0];


        if (sram_use2[i][0] == nullptr) {
            sram_use2[i][0] = next_tind->ta;
            tind_bus2[i][0] = next_tind->ta;
            next_tind->placed++;
            if (next_tind->all_placed()) { 
                tind_groups.erase(tind_groups.begin()); 
            }
            auto name = next_tind->ta->table->name + "$tind";
            auto &alloc = (*next_tind->ta->memuse)[name];
            alloc.row.emplace_back(i, 0);
            alloc.row.back().col.push_back(0);
        } 
          
    }
    LOG3("Allocated tind");
    return true;
}

void Memories::find_action_bus_users() {
    for (auto *ta : action_tables) {
        int sz = ceil_log2(ta->table->layout.action_data_bytes) + 3;
        int width = sz > 7 ? 1 << (sz - 7) : 1;

        int per_ram = sz > 7 ? 10 : 17 - sz;
        int depth = ((ta->calculated_entries - 1) >> per_ram) + 1;

        for (int i = 0; i < width; i++) {
            action_bus_users.push_back(new action_group(ta, depth, i));
        }
    }
}

void Memories::find_action_candidates(int row, int mask, action_group **a_group, unsigned &a_mask,
                                      int &a_index, action_group **oflow_group,
                                      unsigned &oflow_mask, int &oflow_index) {
    LOG3("Finding action candidates");
    if (action_bus_users.empty()) {
        LOG3("Empty");
        return;
    }

    int RAMs_available = __builtin_popcount(mask & ~sram_inuse[row]);

    bool on_right_side = false;
    if (mask == 0x3f0)
        on_right_side = true;

    action_group *best_fit = nullptr;
    int best_fit_index = -1;
    action_group *over_fit = nullptr;
    int over_fit_index = -1;

    int i = 0;
    int max = 0;
    for (auto *ag : action_bus_users) {
        if (ag->left_to_place() <= RAMs_available && ag->left_to_place() > max) {
            best_fit = ag;
            best_fit_index = i;
            max = ag->left_to_place();
        }
        i++;
    }


    i = 0;
    for (auto *ag : action_bus_users) {
        if (ag->left_to_place() > RAMs_available) {
            over_fit = ag;
            over_fit_index = i;
            break;
        }
        i++;
    }

    //FIXME: Ignoring overflow for the time being
    //vector <action_group *> overflow_candidates = candidates_for_overflow(row, on_right_side);
    //if (overflow_candidates.empty()) {
        if (best_fit != nullptr && best_fit->left_to_place() == RAMs_available) {
            LOG3("Best fit first");
            a_index = best_fit_index;
            a_mask = mask & ~sram_inuse[row];
            *a_group = best_fit;
            return;
        }
        if (over_fit != nullptr) {
            LOG3("Over fit first");
            a_index = over_fit_index;
            a_mask = mask & ~sram_inuse[row];
            *a_group = over_fit;
            return;
        }
        LOG3("Best fit last");
        int RAMs_filled = 0;
        for (int i = 0; i < 10 && RAMs_filled < RAMs_available; i++) {
            if (((1 << i) & mask) == 0)
                continue;
            if ((1 << i) & ~sram_inuse[row]) {
                a_mask |= (1 << i);
                RAMs_filled++;
            }
        }
        a_index = best_fit_index;
        *a_group = best_fit;
   /* } else {

    }*/

}

vector<Memories::action_group *> Memories::candidates_for_overflow(int row, bool on_right_side) {
    vector<action_group *> overflow_candidates;

    for (int i = row - 1; i > 0 && i > row - 5;  i--) {
        for (int j = 0; j < 2; j++) {
            if (action_data_bus2[i][j] != nullptr && !action_data_bus2[i][j]->all_placed()) {
                overflow_candidates.push_back(action_data_bus2[i][j]);
            }
            
            if (vert_overflow_bus2[i - 1] != nullptr 
                && !vert_overflow_bus2[i - 1]->all_placed()) {
                if (i != row - 5) {
                    overflow_candidates.push_back(vert_overflow_bus2[i - 1]);
                }
                break;
            }
        }
    }

    if (!on_right_side && action_data_bus2[row][1] != nullptr 
                       && !action_data_bus2[row][1]->all_placed()) {
        overflow_candidates.push_back(action_data_bus2[row][1]);
    }

    return overflow_candidates; 
}


bool Memories::allocate_all_action() {
    find_action_bus_users();
    std::sort(action_bus_users.begin(), action_bus_users.end(),
        [=](const action_group *a, action_group *b) {
        int t;
        if ((t = a->depth - b->depth) != 0) return t > 0;
        return a->number < b->number;
    });


  
    
    for (int i = 0; i < SRAM_ROWS; i++) {
        for (int j = 0; j < 2; j++) {
            int mask = 0;
            if (j == 0) 
                mask = 0x3f0;
            else
                mask = 0xf;

            if (__builtin_popcount(mask & ~sram_inuse[i]) == 0) continue;

            LOG3("Action now on " << i << " " << j << " with " <<
                 __builtin_popcount(mask & ~sram_inuse[i]) << " RAMs");
            action_group *a_group = nullptr;
            action_group *oflow_group = nullptr;
            unsigned a_mask = 0; unsigned oflow_mask = 0;
            int a_index = 0; int oflow_index = 0;
 
            find_action_candidates(i, mask, &a_group, a_mask, a_index,
                                   &oflow_group, oflow_mask, oflow_index);

            Memories::Use::Row *a_row, *oflow_row = nullptr;

            if (a_group == nullptr && oflow_group == nullptr) {
                LOG3("Help");
                return true;
            }            
            if (a_group != nullptr) {
                LOG3("Before");
                auto a_name = a_group->ta->table->name + "$action";
                auto &a_alloc = (*a_group->ta->memuse)[a_name];
                a_alloc.row.emplace_back(i, j);
                a_row = &(a_alloc.row.back());
                action_data_bus2[i][j] = a_group;
                LOG3("After");
            }

            if (oflow_group != nullptr) {
                auto oflow_name = oflow_group->ta->table->name + "$action";
                auto &oflow_alloc = (*oflow_group->ta->memuse)[oflow_name];
                oflow_alloc.row.emplace_back(i, j);
                oflow_row = &oflow_alloc.row.back();
                overflow_bus2[i][j] = oflow_group;
            }

            bool action_group_removed = false;
            for (int k = 0; k < 10; k++) {
                if (((1 << k) & mask) == 0)
                    continue;

                if ((1 << k) & a_mask) {
                    sram_use2[i][k] = a_group->ta;
                   
                    a_row->col.push_back(k);   
                }
                else if ((1 << k) & oflow_mask) {
                    sram_use2[i][k] = oflow_group->ta;
                    oflow_row->col.push_back(k);
                }
            }
            sram_inuse[i] |= a_mask | oflow_mask;
            if (a_group != nullptr) {
                a_group->placed += __builtin_popcount(a_mask);
                if (a_group->all_placed()) {
                    action_bus_users.erase(action_bus_users.begin() + a_index);
                    action_group_removed = true;
                }
            }

            if (oflow_group != nullptr) {
                oflow_group->placed += __builtin_popcount(oflow_mask);
                if (action_group_removed && a_index < oflow_index) {
                    oflow_index--;
                }
                action_bus_users.erase(action_bus_users.begin() + oflow_index);
            }
        }
    }

    if (!action_bus_users.empty())
        return false; 
    return true;
}

bool Memories::allocate_all_gw() {

    int row = 0; int column = 0;    
    for (auto *ta : gw_tables) {
        for (int i = row; i < SRAM_ROWS; i++) {
            for (int j = column; j < 2; j++) {
                if (sram_match_bus2[i][j] == nullptr) {
                    sram_match_bus2[i][j] = new std::pair<table_alloc *, int>(ta, 0);
                    auto name = ta->table->name + "$gw";
                    auto &alloc = (*ta->memuse)[name];
                    alloc.row.emplace_back(i, j);
                    row = i;
                    column = j+1;
                }
            }
        }
    }
    if (!gw_tables.empty())
        return false;
    return true;
}

bool Memories::alloc2Port(cstring name, int entries, int entries_per_word, Use &alloc) {
    //LOG3("alloc2Port(" << name << ", " << entries << ", " << entries_per_word << ")");
    int rams = (entries + 1024*entries_per_word - 1) / (1024*entries_per_word);
    alloc.type = Use::TWOPORT;
    for (int row = 0; row < SRAM_ROWS; row++) {
        if (stateful_bus[row]) continue;
        Use::Row *alloc_row = 0;
        for (int col = MAPRAM_COLUMNS-1; col >= 0; col--) {
            if (mapram_use[row][col]) continue;
            if (sram_use[row][col + SRAM_COLUMNS - MAPRAM_COLUMNS]) continue;
            stateful_bus[row] = mapram_use[row][col] =
            sram_use[row][col + SRAM_COLUMNS - MAPRAM_COLUMNS] = name;
            if (!alloc_row) {
                alloc.row.emplace_back(row);
                alloc_row = &alloc.row.back(); }
            alloc_row->col.push_back(col + SRAM_COLUMNS - MAPRAM_COLUMNS);
            alloc_row->mapcol.push_back(col);
            if (!--rams) return true; } }
    remove(name, alloc);
    alloc.row.clear();
    //LOG3("failed");
    return false;
}

bool Memories::allocActionRams(cstring name, int width, int depth, Use &alloc) {
    //LOG3("allocActionRams(" << name << ", " << width << 'x' << depth << ")");
    int count = 0;
    auto left = Range(0, LEFT_SIDE_COLUMNS-1);
    auto right = Range(LEFT_SIDE_COLUMNS, SRAM_COLUMNS-1);
    for (int row : Range(sram_use.rows()-1, 0)) {
        for (int side : Range(1, 0)) {
            Use::Row *current = nullptr;
            if (action_data_bus[row][side]) continue;
            action_data_bus[row][side] = name;
            for (int col : side ? right : left) {
                if (sram_use[row][col]) continue;
                if (!current) {
                    alloc.row.emplace_back(row, side);
                    current = &alloc.row.back(); }
                current->col.push_back(col);
                sram_use[row][col] = name;
                if (++count == depth) {
                    count = 0;
                    if (!--width) return true; } } } }
    remove(name, alloc);
    alloc.row.clear();
    //LOG3("failed");
    return false;
}

bool Memories::allocBus(cstring name, Alloc2Dbase<cstring> &bus_use, Use &alloc) {
    for  (int row : Range(0, bus_use.rows()-1)) {
        for (int bus : Range(0, bus_use.cols()-1)) {
            if (bus_use[row][bus]) continue;
            bus_use[row][bus] = name;
            alloc.row.emplace_back(row, bus);
            return true; } }
    return false;
}

bool Memories::allocRams(cstring name, int width, int depth, Alloc2Dbase<cstring> &use,
                         Alloc2Dbase<cstring> *bus, Use &alloc) {
    //LOG3("allocRams(" << name << ", " << width << 'x' << depth << ")");
    vector<int> free(use.rows()), free_bus(use.rows());
    for (int row = 0; row < use.rows(); row++) {
        for (auto col : use[row]) if (!col) free[row]++;
        if (bus) {
            free_bus[row] = -1;
            for (int col = 0; col < bus->cols(); col++)
                if (!(*bus)[row][col]) {
                    free_bus[row] = col;
                    break; } } }
    for (int row = 0; row + width <= use.rows(); row++) {
        if (free_bus[row] < 0) continue;
        int max = free[row];
        for (int i = 1; i < width; i++) {
            if (free_bus[row+i] < 0) max = 0;
            if (free[row+i] < max) max = free[row+i]; }
        if (!max) continue;
        //LOG3("The max rows available " << max);
        if (max > depth) max = depth;
        for (int i = 0; i < width; i++) {
            alloc.row.emplace_back(row+i);
            auto &alloc_row = alloc.row.back();
            if (bus) {
                (*bus)[row+i][free_bus[row+i]] = name;
                alloc_row.bus = free_bus[row+i]; }
            int cnt = 0;
            int col_idx = -1;
            for (auto &col : use[row+i]) {
                ++col_idx;
                if (!col) {
                    col = name;
                    //LOG3("Allocating the RAM at " << row << "," << col_idx);
                    alloc_row.col.push_back(col_idx);
                    if (++cnt == max)
                        break; } } }
        row += width-1;
        if (!(depth -= max)) return true; }
    remove(name, alloc);
    alloc.row.clear();
    //LOG3("failed");
    return false;
}

namespace {
class AllocAttached : public Inspector {
    const IR::MAU::Table        *tbl;
    Memories                    &mem;
    bool                        &ok;
    int                         entries;
    map<cstring, Memories::Use> &alloc;
    bool preorder(const IR::Counter *ctr) override {
        cstring name = ctr->name + "$ctr";
        assert(!alloc.count(name));
        if (!mem.alloc2Port(name, ctr->direct ? entries : ctr->instance_count,
                            CounterPerWord(ctr), alloc[name]))
            ok = false;
        return false; }
    bool preorder(const IR::Meter *mtr) override {
        cstring name = mtr->name + "$mtr";
        assert(!alloc.count(name));
        if (!mem.alloc2Port(name, mtr->direct ? entries : mtr->instance_count, 1, alloc[name]))
            ok = false;
        return false; }
    bool preorder(const IR::Register *reg) override {
        cstring name = reg->name + "$reg";
        assert(!alloc.count(name));
        if (!mem.alloc2Port(name, reg->direct ? entries : reg->instance_count,
                            RegisterPerWord(reg), alloc[name]))
            ok = false;
        return false; }
    bool preorder(const IR::MAU::TernaryIndirect *ti) override {
        assert(!alloc.count(ti->name));
        int sz = ceil_log2(tbl->layout.overhead_bits);
        if (sz < 3) sz = 3;  // min 8 bits
        if (sz > 6)
            throw new Util::CompilationError("%1%: more than 64 bits of overhead for ternary "
                                             "table", tbl->match_table);
        alloc[ti->name].type = Memories::Use::TIND;
        if (!mem.allocRams(ti->name, 1, ((entries - 1) >> (17 - sz)) + 1, mem.sram_use,
                           &mem.tind_bus, alloc[ti->name]))
            ok = false;
        return false; }
    bool preorder(const IR::MAU::ActionData *ad) override {
        assert(!alloc.count(ad->name));
        int sz = ceil_log2(tbl->layout.action_data_bytes) + 3;
        if (sz > 10)
            throw new Util::CompilationError("%1%: more than 1024 bits wide for action data "
                                             "table", tbl->match_table);
        alloc[ad->name].type = Memories::Use::ACTIONDATA;
        int width = sz > 7 ? 1 << (sz - 7) : 1;
        int per_ram = sz > 7 ? 10 : 17 - sz;
        if (!mem.allocActionRams(ad->name, width, ((entries - 1) >> per_ram) + 1, alloc[ad->name]))
            ok = false;
        return false; }
    bool preorder(const IR::ActionProfile *ap) override {
        assert(!alloc.count(ap->name));
        return false; }
    bool preorder(const IR::ActionSelector *as) override {
        cstring name = as->name + "$sel";
        assert(!alloc.count(name));
        return false; }
    bool preorder(const IR::Attached *att) override {
        BUG("Unknown attached table type %s", att->kind()); }

 public:
    AllocAttached(Memories *m, const IR::MAU::Table *t, bool *o, int e,
                  map<cstring, Memories::Use> &a)
    : tbl(t), mem(*m), ok(*o), entries(e) , alloc(a) {}
};
}  // namespace

bool Memories::allocTable(cstring name, const IR::MAU::Table *table, int &entries,
                          map<cstring, Use> &alloc, const IXBar::Use &match_ixbar) {
    if (!table) return true;
    //LOG2("Memories::allocTable(" << name << ", &" << entries << ")");
    bool ok = true;
    int width, depth, groups = 1;
    if (table->layout.ternary) {
        depth = (entries + 511U)/512U;
        width = (table->layout.match_width_bits + 47)/44;  // +4 bits for v/v, round up
        if (width < 12)
            width = std::max(width, match_ixbar.groups());
        entries = depth * 512;
    } else if (!table->ways.empty()) {
        /* Assuming all ways have the same format and width (only differ in depth) */
        width = table->ways[0].width;
        groups = table->ways[0].match_groups;
        depth = ((entries + groups - 1U)/groups + 1023)/1024U;
        if (depth < static_cast<int>(table->ways.size()))
            depth = table->ways.size();
        entries = depth * groups * 1024U;
    } else {
        width = depth = entries = 0; }
    //LOG3("   " << width << 'x' << depth << " entries=" << entries);
    if (table->layout.ternary) {
        assert(!alloc.count(name));
        alloc[name].type = Use::TERNARY;
        ok &= allocRams(name, width, depth, tcam_use, 0, alloc[name]);
    } else if (!table->ways.empty()) {
        assert(match_ixbar.way_use.size() == table->ways.size());
        struct waybits {
            bitvec              bits;
            decltype(bits.end()) next;
            waybits() : next(bits.end()) {} };
        std::map<int, waybits> alloc_bits;
        for (auto &way : match_ixbar.way_use) {
            //LOG3("The way is m|s|g " << way.mask << " " << way.slice << " " << way.group);
            alloc_bits[way.group].bits |= way.mask;
        }
        assert(!alloc.count(name));
        alloc[name].type = Use::EXACT;
        int alloc_depth = 0;
        auto ixbar_way = match_ixbar.way_use.begin();
        for (int i = table->ways.size(); i > 0; --i, ++ixbar_way) {
            int log2size = std::max(ceil_log2((depth+i-1)/i), 0);
            int sz = 1 << log2size;
            ok &= allocRams(name, width, sz, sram_use, &sram_match_bus, alloc[name]);
            alloc_depth += sz;
            unsigned mask = 0;
            auto &bits = alloc_bits[ixbar_way->group];
            for (int bit = 0; bit < log2size; bit++) {
                if (!++bits.next) ++bits.next;
                if (!bits.next || (mask & (1 << *bits.next))) {
                    ok = false;
                    WARNING("Not enough way select bits allocated in group " <<
                            ixbar_way->group << " for table " << name);
                    break; }
                mask |= 1 << *bits.next; }
            alloc[name].ways.emplace_back(sz, mask);
            if ((depth -= sz) < 1) depth = 1; }
        entries = alloc_depth * groups * 1024U; }
    if (ok) {
        for (auto at : table->attached)
            at->apply(AllocAttached(this, table, &ok, entries, alloc));
        if (table->uses_gateway()) {
            auto gwname = name + "$gw";
            alloc[gwname].type = Use::GATEWAY;
            ok &= allocBus(gwname, sram_match_bus, alloc[gwname]); } }
    return ok;
}

void Memories::Use::visit(Memories &mem, std::function<void(cstring &)> fn) const {
    Alloc2Dbase<cstring> *use = 0, *mapuse = 0, *bus = 0;
    switch (type) {
    case EXACT:
        use = &mem.sram_use;
        bus = &mem.sram_match_bus;
        break;
    case TERNARY:
        use = &mem.tcam_use;
        break;
    case GATEWAY:
        bus = &mem.sram_match_bus;
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
        if (bus)
            fn((*bus)[r.row][r.bus]);
        if (type == TWOPORT)
            fn(mem.stateful_bus[r.row]);
        for (auto col : r.col)
            fn((*use)[r.row][col]);
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
    const Alloc2Dbase<cstring> *arrays[] = { &mem.tcam_use, &mem.sram_match_bus, &mem.tind_bus,
        &mem.action_data_bus, &mem.sram_use, &mem.mapram_use };
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
