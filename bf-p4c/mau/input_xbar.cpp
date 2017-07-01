#include "gateway.h"
#include "input_xbar.h"
#include "resource.h"
#include "resource_estimate.h"
#include "lib/algorithm.h"
#include "lib/bitvec.h"
#include "lib/bitops.h"
#include "lib/hex.h"
#include "lib/range.h"
#include "lib/log.h"
#include "tofino/phv/phv_fields.h"

void IXBar::clear() {
    exact_use.clear();
    ternary_use.clear();
    byte_group_use.clear();
    exact_fields.clear();
    ternary_fields.clear();
    hash_index_use.clear();
    hash_single_bit_use.clear();
    memset(hash_index_inuse, 0, sizeof(hash_index_inuse));
    memset(hash_single_bit_inuse, 0, sizeof(hash_single_bit_inuse));
    memset(hash_group_use, 0, sizeof(hash_group_use));
}

int IXBar::Use::groups() const {
    int rv = 0;
    unsigned counted = 0;
    for (auto &b : use) {
        assert(b.loc.group >= 0 && b.loc.group < 16);
        if (!(1 & (counted >> b.loc.group))) {
            ++rv;
            counted |= 1U << b.loc.group; } }
    return rv;
}

int IXBar::Use::hash_groups() const {
    int rv = 0;
    unsigned counted = 0;
    for (auto way : way_use) {
        if (((1U << way.group) & counted) == 0) {
            rv++;
            counted |= 1U << way.group;
        }
    }
    return rv;
}

vector<std::pair<int, int>> IXBar::Use::bits_per_group_single() const {
    int bits_per[IXBar::EXACT_GROUPS] = { 0 };

    for (auto &b : match_hash_single()) {
        assert(b.loc.group >= 0 && b.loc.group < 8);
        int difference = b.hi - b.lo + 1;
        bits_per[b.loc.group] += difference;
    }

    vector<std::pair<int, int>> sizes;
    for (int i = 0; i < IXBar::EXACT_GROUPS; i++) {
         if (bits_per[i] == 0) continue;
         sizes.emplace_back(i, bits_per[i]);
    }
    return sizes;
}

vector<IXBar::Use::Byte> IXBar::Use::match_hash_single() const {
    vector<IXBar::Use::Byte> single_match;
    for (int i = 0; i < HASH_GROUPS; i++) {
        if (hash_table_inputs[i] == 0) continue;
        for (auto byte : use) {
            int hash_group = byte.loc.group * 2 + byte.loc.byte / 8;
            if ((1 << hash_group) & hash_table_inputs[i])
                single_match.push_back(byte);
        }
        break;
    }
    return single_match;
}

int IXBar::Use::groups_single() const {
    int rv = 0;
    unsigned counted = 0;
    for (auto &b : match_hash_single()) {
        assert(b.loc.group >= 0 && b.loc.group < 16);
        if (!(1 & (counted >> b.loc.group))) {
            ++rv;
            counted |= 1U << b.loc.group; } }
    return rv;
}

bool IXBar::Use::exact_comp(const IXBar::Use *exact_use, int width) const {
    unsigned gw_counted = 0, exact_counted = 0;
    for (auto &b : use) {
        assert(b.loc.group >= 0 && b.loc.group < 16);
        if (!(1 & (gw_counted >> b.loc.group))) {
            gw_counted |= 1U << b.loc.group; } }

    int exact_groups = 0;
    for (auto &b : exact_use->use) {
        if (!(1 & (exact_counted >> b.loc.group))) {
            ++exact_groups;
            exact_counted |= 1U << b.loc.group; } }

    if (width != 0) {
        int groups_found = 0, index = 0;
        while (groups_found < exact_groups) {
            if ((1 << index) & exact_counted) {
                if (groups_found == width) {
                    exact_counted &= ~(1 << index);
                }
                groups_found++;
            }
            index++;
        }
    }
    return exact_counted & gw_counted;
}

unsigned IXBar::Use::compute_hash_tables() {
    unsigned hash_table_input = 0;
    for (auto &b : use) {
        assert(b.loc.group >= 0 && b.loc.group < HASH_TABLES/2);
        unsigned grp = 1U << (b.loc.group * 2);
        if (b.loc.byte >= 8) grp <<= 1;
        hash_table_input |= grp; }
    return hash_table_input;
}

unsigned IXBar::Use::compute_hash_dist_tables(int i /*= -1*/) {
    unsigned hash_table_input = 0;
    vector<Byte> hash_dist;
    if (i == -1)
        hash_dist = hash_dist_use.back().use;
    else
        hash_dist = hash_dist_use[i].use;

    for (auto &b : hash_dist) {
        assert(b.loc.group >= 0 && b.loc.group < HASH_TABLES/2);
        unsigned grp = 1U << (b.loc.group * 2);
        if (b.loc.byte >= 8) grp <<= 1;
        hash_table_input |= grp; }
    return hash_table_input;
}

/* Combining the allocation of multiple separately allocated hash groups of the same
   table.  Done if the table requires two hash groups */
void IXBar::Use::add(const IXBar::Use &alloc) {
    ternary = alloc.ternary;
    gw_search_bus = alloc.gw_search_bus;
    gw_search_bus_bytes = alloc.gw_search_bus_bytes;
    gw_hash_group = alloc.gw_hash_group;
    for (auto old_byte : use) {
        for (auto new_byte : alloc.use) {
            if (old_byte.loc.group == new_byte.loc.group
                && old_byte.loc.byte == new_byte.loc.byte)
                BUG("Two combined input xbar groups are using the same byte location");
        }
    }
    for (auto old_way : way_use) {
        for (auto new_way : alloc.way_use) {
            if (old_way.group == new_way.group)
                BUG("Ways from supposedly different hash groups have same group?");
        }
    }
    for (auto old_bits : bit_use) {
        for (auto new_bits : alloc.bit_use) {
            if (old_bits.group == new_bits.group)
                BUG("Bit uses from separate hash groups are within same slice");
        }
    }
    use.insert(use.end(), alloc.use.begin(), alloc.use.end());
    bit_use.insert(bit_use.end(), alloc.bit_use.begin(), alloc.bit_use.end());
    way_use.insert(way_use.end(), alloc.way_use.begin(), alloc.way_use.end());
    select_use.insert(select_use.end(), alloc.select_use.begin(), alloc.select_use.end());
    for (int i = 0; i < HASH_GROUPS; i++) {
        if (hash_table_inputs[i] != 0 && alloc.hash_table_inputs[i] != 0)
            BUG("When adding allocs of ways, somehow ended up on the same hash group");
        hash_table_inputs[i] |= alloc.hash_table_inputs[i];
    }
}

static int align_flags[4] = {
    /* these flags are the alignment restrictions that FAIL for each byte in 4 */
    IXBar::Use::Align16hi | IXBar::Use::Align32hi,
    IXBar::Use::Align16lo | IXBar::Use::Align32hi,
    IXBar::Use::Align16hi | IXBar::Use::Align32lo,
    IXBar::Use::Align16lo | IXBar::Use::Align32lo,
};

/* An individual SRAM group or half of a TCAM group */
struct grp_use {
    enum type_t { MATCH, HASH_DIST, FREE };
    int group;
    bitvec found;
    bitvec free;
    bool first_hash_open = true;
    bool second_hash_open = true;
    type_t first_hash_dist = FREE;
    type_t second_hash_dist = FREE;

    bool first_hash_dist_avail() {
        return first_hash_dist == HASH_DIST || first_hash_dist == FREE;
    }

    bool second_hash_dist_avail() {
        return second_hash_dist == HASH_DIST || second_hash_dist == FREE;
    }

    bool first_hash_dist_only() {
        return first_hash_dist == HASH_DIST;
    }

    bool second_hash_dist_only() {
        return second_hash_dist == HASH_DIST;
    }
    void dbprint(std::ostream &out) const {
        out << group << " found: " << found << " free: " << free;
    }
};

/* A struct use for TCAM split between 2 groups.  Mid bytes are for the individual
   byte groups within the two ternary groups.  Only one grp_use is necessary for the
   calculation of the SRAM xbar */
struct big_grp_use {
    int big_group;
    grp_use first;
    grp_use second;
    bool mid_byte_found;
    bool mid_byte_free;
    void dbprint(std::ostream &out) const {
        out << big_group << " : found=" << first.found << " " << mid_byte_found << " "
            << second.found  << " : free= " << first.free  << " " << mid_byte_free
            << " " << second.free; }
    int total_found() const { return first.found.popcount() + second.found.popcount()
                                     + mid_byte_found; }
    int total_free() const { return first.free.popcount() + second.free.popcount()
                                    + mid_byte_free; }
    int total_used() const { return total_found() + total_free(); }
    int better_group() const {
        int first_open = first.free.popcount() + first.found.popcount();
        int second_open = second.free.popcount() + second.found.popcount();
        if (first_open >= second_open)
             return first_open;
        return second_open;
    }
};

/* Calculates the number of hash ways available in each group.  Currently not including the
   extra 12 hash bits.  Also now separates hash tables from being part of hash distribution
   vs. standard tables and gateways.  */
void IXBar::calculate_available_groups(vector<big_grp_use> &order, int hash_groups_needed) {
    for (auto &big_grp : order) {
        big_grp.first.first_hash_open = true;
        big_grp.first.second_hash_open = true;
    }

    for (auto &big_grp : order) {
        int first_ways_available = 0; int second_ways_available = 0;
        for (int hash_group = 0; hash_group < HASH_INDEX_GROUPS; hash_group++) {
            if (!(hash_index_inuse[hash_group] & (1 << (2 * big_grp.big_group))))
                first_ways_available++;
            if (!(hash_index_inuse[hash_group] & (1 << (2 * big_grp.big_group + 1))))
                second_ways_available++;
        }
        if (first_ways_available < hash_groups_needed) {
            big_grp.first.first_hash_open = false;
        }
        if (second_ways_available < hash_groups_needed) {
            big_grp.first.second_hash_open = false;
        }
    }
    for (auto &big_grp : order) {
        big_grp.first.first_hash_dist = is_group_for_hash_dist(2 * big_grp.big_group);
        big_grp.first.second_hash_dist = is_group_for_hash_dist(2 * big_grp.big_group + 1);
    }
}

IXBar::grp_use::type_t IXBar::is_group_for_hash_dist(int hash_table) {
    for (int i = 0; i < HASH_GROUPS; i++) {
        bool hash_dist = false;
        if (i == hash_dist_groups[0] || i == hash_dist_groups[1]) {
            hash_dist = true;
        }
        if (((1 << hash_table) | hash_group_use[i]) != hash_group_use[i]) continue;
        if (hash_dist)
            return grp_use::HASH_DIST;
        else
            return grp_use::MATCH;
    }
    return grp_use::FREE;
}

/* Determines if the byte within the crossbar has enough space within the hash table in 
   order to be placed in that spot */
bool IXBar::violates_hash_constraints(vector<big_grp_use> &order, bool hash_dist, int group,
                                      int byte) {
    if (byte / 8 == 0) {
        if (hash_dist) {
            if (!order[group].first.first_hash_dist_avail())
                return true;
        } else {
            if (order[group].first.first_hash_dist_only())
                return true;
            if (!order[group].first.first_hash_open) return true;
        }
    }
    if (byte / 8 == 1) {
        if (hash_dist) {
            if (!order[group].first.second_hash_dist_avail())
                return true;
        } else {
           if (order[group].first.second_hash_dist_only())
               return true;
           if (!order[group].first.second_hash_open) return true;
        }
    }
    return false;
}

/* Calculates the bytes per each group that match any currently unallocated */
void IXBar::calculate_found(vector<IXBar::Use::Byte *> unalloced, vector<big_grp_use> &order,
                            bool ternary, bool hash_dist, unsigned byte_mask) {
    auto &use = this->use(ternary);
    auto &fields = this->fields(ternary);
    for (size_t i = 0; i < order.size(); i++) {
        order[i].first.found.clear();
        order[i].second.found.clear();
        order[i].mid_byte_found = false;
    }
    for (auto &need : unalloced) {
        for (auto &p : Values(fields.equal_range(need->field))) {
            if (ternary && p.byte == 5) {
                if (byte_group_use[p.group/2].second == need->lo) {
                    order[p.group/2].mid_byte_found = true;
                }
                continue;
            }

            if (use[p.group][p.byte].second == need->lo) {
                if (!ternary && violates_hash_constraints(order, hash_dist, p.group, p.byte)) {
                    continue;
                }
                if (!(byte_mask & (1U << p.byte)))
                    continue;

                if (p.group % 2) {
                    order[p.group/2].second.found[p.byte] = true;
                } else {
                    order[p.group/2].first.found[p.byte] = true;
                }
            }
        }
    }
}

/* Calculates the bytes per each group that are currently not used, specifically for the ternary
   groups */
void IXBar::calculate_ternary_free(vector<big_grp_use> &order, int big_groups,
                                   int bytes_per_big_group) {
    auto &use = this->use(true);
    for (int grp = 0; grp < big_groups; grp++) {
        for (int byte = 0; byte < bytes_per_big_group/2; byte++) {
            if (!use[2*grp][byte].first)
                order[grp].first.free[byte] = true;
            if (!use[2*grp + 1][byte].first)
                order[grp].second.free[byte] = true;
            if (!byte_group_use[grp].first)
                order[grp].mid_byte_free = true;
        }
    }
}

/* Calculates the bytes in each group that are currently not used for the SRAM xbar */
void IXBar::calculate_exact_free(vector<big_grp_use> &order, int big_groups,
                                 int bytes_per_big_group, bool hash_dist, unsigned byte_mask) {
    auto &use = this->use(false);
    for (int grp = 0; grp < big_groups; grp++) {
        for (int byte = 0; byte < bytes_per_big_group; byte++) {
            if (violates_hash_constraints(order, hash_dist, grp, byte))
                continue;
            if (!(byte_mask & (1U << byte)))
                continue;
            if (!use[grp][byte].first)
                order[grp].first.free[byte] = true;
        }
    }
}

/* Find the unalloced bytes in the current table that are already contained within the xbar
   group and share those locations.  Works with grp_use only, used for a single TCAM group
   or an SRAM group */
int IXBar::found_bytes(grp_use *grp, vector<IXBar::Use::Byte *> &unalloced, bool ternary) {
    auto &use = this->use(ternary);
    auto &fields = this->fields(ternary);
    int found_bytes = grp->found.popcount();
    int bytes_placed = 0;

    for (size_t i = 0; i < unalloced.size(); i++) {
        auto &need = *(unalloced[i]);
        if (found_bytes == 0)
            break;
        for (auto &p : Values(fields.equal_range(need.field))) {
            if (ternary && p.byte == 5)
                continue;
            if ((grp->group == p.group) && (use[p.group][p.byte].second == need.lo)) {
                if (!ternary && (p.byte / 8 == 0) && !grp->first_hash_open)
                    continue;
                if (!ternary && (p.byte / 8 == 1) && !grp->second_hash_open)
                    continue;

                unalloced[i]->loc = p;
                found_bytes--; bytes_placed++;
                unalloced.erase(unalloced.begin() + i);
                i--;
                break;
            }
        }
    }
    LOG4("Total free bytes placed was " << bytes_placed);
    return bytes_placed;
}

/* Find the unalloced bytes in the current table that are contained in the grp_use containing two
   ternary groups and shared these locations.  Currently designed only for the ternary groups */
int IXBar::found_bytes_big_group(big_grp_use *grp, vector<IXBar::Use::Byte *> &unalloced) {
    auto &use = this->use(true);
    auto &fields = this->fields(true);
    int found_bytes = grp->total_found();
    int bytes_placed = 0;
    for (size_t i = 0; i < unalloced.size(); i++) {
        auto &need = *(unalloced[i]);
        if (found_bytes == 0)
            break;
        for (auto &p : Values(fields.equal_range(need.field))) {
            if (p.byte == 5) {
                if ((grp->big_group == p.group/2)
                    && (byte_group_use[p.group/2].second == need.lo)) {
                    need.loc = p;
                    found_bytes--; bytes_placed++;
                    unalloced.erase(unalloced.begin() + i);
                    i--;
                    break;
                }
                continue;
            }
            if ((grp->big_group == p.group/2) && (use[p.group][p.byte].second == need.lo)) {
                need.loc = p;
                found_bytes--; bytes_placed++;
                unalloced.erase(unalloced.begin() + i);
                i--;
                break;
            }
        }
    }
    LOG4("Total found bytes placed was " << bytes_placed);
    return bytes_placed;
}

/* Bookkeeping for the allocation of a free byte within a group. */
void IXBar::allocate_free_byte(grp_use *grp, vector<IXBar::Use::Byte *> &unalloced,
                               vector<IXBar::Use::Byte *> &alloced, IXBar::Use::Byte &need,
                               int group, int byte, int &index, int &free_bytes,
                               int &bytes_placed) {
    need.loc.group = group;
    need.loc.byte = byte;
    if (grp != nullptr)
        grp->free[byte] = false;

    alloced.push_back(unalloced[index]);
    unalloced.erase(unalloced.begin() + index);
    index--;
    free_bytes--;
    bytes_placed++;
}

/* Fills out all currently unoccupied xbar bytes within a group with bytes from the current table
   following alignment constraints.  Works for single TCAM groups or SRAM groups */
int IXBar::free_bytes(grp_use *grp, vector<IXBar::Use::Byte *> &unalloced,
                      vector<IXBar::Use::Byte *> &alloced, bool ternary, bool hash_dist) {
    int bytes_placed = 0;
    int free_bytes = grp->free.popcount();
    for (int i = 0; i < static_cast<int>(unalloced.size()); i++) {
        if (free_bytes == 0)
            break;
        auto &need = *(unalloced[i]);
        int align = ternary ? ((grp->group * 11 + 1)/2) & 3 : 0;
        int chosen_byte = -1;
        bool found = false;
        for (auto byte : grp->free) {
            if (align_flags[(byte+align) & 3] & need.flags) {
                 continue;
            }
            allocate_free_byte(grp, unalloced, alloced, need, grp->group, byte,
                               i, free_bytes, bytes_placed);
            chosen_byte = byte;
            found = true;
            break;
        }
        if (hash_dist && !ternary && found) {
            if (chosen_byte < 8) {
                grp->first_hash_dist = grp_use::HASH_DIST;
            } else {
                grp->second_hash_dist = grp_use::HASH_DIST;
            }
        }
    }
    LOG4("Total free bytes placed was " << bytes_placed);
    return bytes_placed;
}

/* Fills out all currently unoccupied xbar bytes within a group with bytes from the current table
   following alignment constraints.  Specifically designed to handle the allocation of a large
   ternary group */
int IXBar::free_bytes_big_group(big_grp_use *grp, vector<IXBar::Use::Byte*> &unalloced,
                                vector<IXBar::Use::Byte *> &alloced, bool &version_placed) {
    int bytes_placed = 0;
    int free_bytes = grp->total_free();
    int align = (grp->big_group * (2 * TERNARY_BYTES_PER_GROUP + 1)) & 3;

    /* Version bit information has to be at the midbyte boundary.  However, if there is a hole
       in the bits, then the code can go there. */
    if (!version_placed) {
        for (int i = 0; i < static_cast<int>(unalloced.size()); i++) {
            if (free_bytes == 0)
                break;
            auto &need = *(unalloced[i]);
            if (need.hi / 4 != need.lo / 4) continue;
            if (align_flags[(TERNARY_BYTES_PER_GROUP + align) & 3] & need.flags) continue;
            allocate_free_byte(nullptr, unalloced, alloced, need,
                               grp->big_group * 2, 5, i, free_bytes, bytes_placed);
            grp->mid_byte_free = false;
            version_placed = true;
            break;
        }
    }


    for (int i = 0; i < static_cast<int>(unalloced.size()); i++) {
        bool found = false;
        if (free_bytes == 0)
            break;

        auto &need = *(unalloced[i]);
        /* Allocate free bytes within the first ternary group */
        for (auto byte : grp->first.free) {
            if (align_flags[(byte + align) & 3] & need.flags) continue;
            allocate_free_byte(&(grp->first), unalloced, alloced, need,
                               grp->big_group * 2, byte, i, free_bytes, bytes_placed);
            found = true;
            break;
        }
        if (found)
            continue;

        /* Allocate free bytes within the second ternary group */
        for (auto byte : grp->second.free) {
            if (align_flags[(byte + TERNARY_BYTES_PER_GROUP + 1 + align) & 3] & need.flags)
                continue;
            allocate_free_byte(&(grp->second), unalloced, alloced, need,
                               grp->big_group * 2 + 1, byte, i, free_bytes, bytes_placed);
            found = true;
            break;
        }

        if (found)
            continue;

        /* Allocate middle bytes of the ternary big group */
        if (grp->mid_byte_free) {
            if (align_flags[(TERNARY_BYTES_PER_GROUP + align) & 3] & need.flags) continue;
            allocate_free_byte(nullptr, unalloced, alloced, need,
                               grp->big_group * 2, 5, i, free_bytes, bytes_placed);
            grp->mid_byte_free = false;
        }
    }
    return bytes_placed;
}

/* When all bytes of the current table have been given a placement, this function fills out
   the xbars use for later record keeping and checks */
void IXBar::fill_out_use(vector<IXBar::Use::Byte *> &alloced, bool ternary) {
    auto &use = this->use(ternary);
    auto &fields = this->fields(ternary);
    for (auto &need : alloced) {
        fields.emplace(need->field, need->loc);
        if (ternary && need->loc.byte == 5) {
            byte_group_use[need->loc.group/2] = *(need);
        } else {
            use[need->loc] = *(need);
        }
    }
}

/* This allocation scheme is used when more than one group on either the TCAM or SRAM xbar is
   required.  The sorting algorithm is a best fit while still shrinking the allocation so that one
   less xbar group was required.  */
bool IXBar::big_grp_alloc(bool ternary, bool second_try, vector<IXBar::Use::Byte *> &unalloced,
                          vector<IXBar::Use::Byte *> &alloced, vector<big_grp_use> &order,
                          int big_groups_needed, int &total_bytes_needed, int bytes_per_big_group,
                          bool hash_dist, unsigned byte_mask) {
    bool version_placed = false;
    int big_groups_max = 1;
    while (big_groups_needed > big_groups_max) {
        int reduced_bytes_needed = total_bytes_needed % bytes_per_big_group;
        if (reduced_bytes_needed == 0)
            reduced_bytes_needed += bytes_per_big_group;

        /* Find the best group that still lowers the total number of groups */
        std::sort(order.begin(), order.end(), [=](const big_grp_use &a, const big_grp_use &b) {
            if (!second_try && (a.total_found() + a.total_free() < reduced_bytes_needed))
                return false;
            if (!second_try && (b.total_found() + b.total_free() < reduced_bytes_needed))
                return true;

            int t;
            if (!second_try && (t = a.total_found() - b.total_found()) != 0) return t > 0;

            if ((t = a.total_free() - b.total_free()) != 0) return t > 0;
            return a.big_group < b.big_group; });

        int bytes_placed = 0;
        if (ternary) {
            LOG4("TCAM big group selected was " << order[0].big_group);
            bytes_placed += found_bytes_big_group(&order[0], unalloced);
            bytes_placed += free_bytes_big_group(&order[0], unalloced, alloced, version_placed);
        } else {
            LOG4("SRAM group selected was " << order[0].first.group);
            bytes_placed += found_bytes(&order[0].first, unalloced, ternary);
            bytes_placed += free_bytes(&order[0].first, unalloced, alloced, ternary, hash_dist);
        }

        /* No bytes placed in the xbar.  You're finished */
        if (bytes_placed == 0) {
            return false;
        }
        total_bytes_needed -= bytes_placed;
        /* FIXME: Need some calculations for 88 bit multiples */
        big_groups_needed = (total_bytes_needed + bytes_per_big_group - 1)/bytes_per_big_group;
        calculate_found(unalloced, order, ternary, hash_dist, byte_mask);
        if (ternary && version_placed)
            big_groups_max = 0;
    }


    return true;
}

/* This allocation scheme is used when only one SRAM xbar or 2 TCAM xbars are needed, as the middle
   byte is no longer available to be used by the TCAM xbar due to version restrictions. */
bool IXBar::small_grp_alloc(bool ternary, bool second_try, vector<IXBar::Use::Byte *> &unalloced,
                            vector<IXBar::Use::Byte *> &alloced, vector<grp_use *> &small_order,
                            vector<big_grp_use> &order, int &total_bytes_needed, bool hash_dist,
                            unsigned byte_mask) {
    while (total_bytes_needed != 0) {
        int bytes_needed = total_bytes_needed;
        if (ternary && bytes_needed > 5) {
            bytes_needed /= 2;
        }
        // Find the best fit for the group that still fits within only one group
        std::sort(small_order.begin(), small_order.end(), [=](const grp_use *ap,
                  const grp_use *bp) {
            if (!second_try && (ap->free.popcount() + ap->found.popcount() < bytes_needed))
                return false;
            if (!second_try && (bp->free.popcount() + bp->found.popcount() < bytes_needed))
                return true;
            int t;
            if (!second_try && (t = ap->found.popcount() - bp->found.popcount()) != 0)
                return t > 0;

            int r = total_bytes_needed - ap->found.popcount();
            int s = total_bytes_needed - bp->found.popcount();
            if (!second_try && (t = (bp->free.popcount() - s) - (ap->free.popcount() - r)) != 0)
                return t > 0;
            if ((t = ap->free.popcount() - bp->free.popcount()) != 0) return t > 0;
            return (ap->group < bp->group);
        });

        int bytes_placed = 0;
        if (ternary)
            LOG4("TCAM small group selected was " << small_order[0]->group);
        else
            LOG4("SRAM group selected was " << small_order[0]->group);

        bytes_placed += found_bytes(small_order[0], unalloced, ternary);
        bytes_placed += free_bytes(small_order[0], unalloced, alloced, ternary, hash_dist);
        /* No bytes placed in the xbar.  You're finished */
        if (bytes_placed == 0) {
            return false;
        }
        total_bytes_needed -= bytes_placed;
        calculate_found(unalloced, order, ternary, hash_dist, byte_mask);
    }
    return true;
}

/* The algorithm for allocation of bytes from the table on to the input xbar.  Both for
   TCAM and SRAM xbar.  Overall algorithm looks at the size of the allocation.  If the allocation
   spans a group, tries to minimize total number of groups while finding the best groups to fill.
   If the allocation is less than a group, tries to find the best fit

   ARGUMENTS:
     alloc_use  vector of Byte objects that need to be allocated on the ixbar
     ternary    true for ternary ixbar, false for exact
     second_try true for the second attempt, after a fist attempt minimizing the overhead failed
     alloced    output -- the Byte objects that were successfully allocated
     hash_groups_needed
                how many hash groups are needed for has tables
     hash_dist  true if this is for a hash_dist config
     byte_mask  which bytes in ixbar groups to use -- default mask of ~0 means use any bytes
*/
bool IXBar::find_alloc(vector<IXBar::Use::Byte> &alloc_use, bool ternary, bool second_try,
                       vector<IXBar::Use::Byte *> &alloced, int hash_groups_needed,
                       bool hash_dist, unsigned byte_mask) {
    /* Initial sizing calculations*/
    int groups = ternary ? TERNARY_GROUPS : EXACT_GROUPS;
    int big_groups = ternary ? TERNARY_GROUPS/2 : EXACT_GROUPS;
    int bytes_per_big_group = ternary ? 11 : EXACT_BYTES_PER_GROUP;

    int total_bytes_needed = alloc_use.size();
    int big_groups_needed = (total_bytes_needed + bytes_per_big_group - 1)/bytes_per_big_group;


    int groups_needed;
    if (ternary) {
        groups_needed = 2 * big_groups_needed;
        if (total_bytes_needed - big_groups_needed * bytes_per_big_group <= 5)
            groups_needed -= 1;
    } else {
        groups_needed = big_groups_needed;
    }
    if (big_groups_needed > big_groups || groups_needed > groups)
        return false;

    /* Initialize all required data structures */
    vector<big_grp_use> order(big_groups);
    vector<grp_use *> small_order;
    for (int i = 0; i < big_groups; i++) {
        order[i].big_group = i;
        if (ternary) {
            order[i].first.group = i*2;
            order[i].second.group = 2*i+1;
        } else {
            order[i].first.group = i;
           order[i].second.group = i;
        }
        order[i].mid_byte_found = false;
        order[i].mid_byte_free = false;
    }
    for (int i = 0; i < big_groups; i++) {
        small_order.push_back(&order[i].first);
        if (ternary)
            small_order.push_back(&order[i].second);
    }
    vector<IXBar::Use::Byte *> unalloced;

    /* Try to place most constrained to least constrained bytes */
    std::sort(alloc_use.begin(), alloc_use.end(), [=](const Use::Byte &a, const Use::Byte &b) {
        int t;
        if ((t = static_cast<size_t>(a.flags) - static_cast<size_t>(b.flags)) != 0)
            return t > 0;
        return a < b;
    });

    for (auto &need : alloc_use) {
        unalloced.push_back(&need);
    }
    if (!ternary) {
        calculate_available_groups(order, hash_groups_needed);
    }


    /* Initial found and free calculations */
    calculate_found(unalloced, order, ternary, hash_dist, byte_mask);

    if (ternary) {
        calculate_ternary_free(order, big_groups, bytes_per_big_group);
    } else {
        calculate_exact_free(order, big_groups, bytes_per_big_group, hash_dist, byte_mask);
    }

    if (ternary) {
        for (int grp = 0; grp < big_groups; grp++)
            LOG3("Big Group " << order[grp]);
    } else {
        for (int grp = 0; grp < groups; grp++)
            LOG3("Small Group " << *(small_order[grp]));
    }

    /* While more than one individual group is necessary for the number of unallocated bytes */
    if (!big_grp_alloc(ternary, second_try, unalloced, alloced, order, big_groups_needed,
                       total_bytes_needed, bytes_per_big_group, hash_dist, byte_mask)) {
        return false;
    }

    // Only one large group at most is necessary
    if (!small_grp_alloc(ternary, second_try, unalloced, alloced, small_order, order,
                         total_bytes_needed, hash_dist, byte_mask)) {
         return false; }

    if (ternary) {
        for (int grp = 0; grp < big_groups; grp++)
            LOG3("Big Group " << order[grp]);
    } else {
        for (int grp = 0; grp < groups; grp++)
            LOG3("Small Group " << *(small_order[grp]));
    }
    return true;
}


int need_align_flags[4][4] = { { 0, 0, 0, 0 },  // 8bit -- no alignment needed
    { IXBar::Use::Align16lo, IXBar::Use::Align16hi, IXBar::Use::Align16lo, IXBar::Use::Align16hi },
    { IXBar::Use::Align16lo | IXBar::Use::Align32lo,
      IXBar::Use::Align16hi | IXBar::Use::Align32lo,
      IXBar::Use::Align16lo | IXBar::Use::Align32hi,
      IXBar::Use::Align16hi | IXBar::Use::Align32hi },
    { 0, 0, 0, 0, },  // Not yet allocated -- assume no alignment required
};

/* Add the pre-allocated bytes to the Use structure */
static void add_use(IXBar::Use &alloc, const PhvInfo::Field *field,
                    const PhvInfo::Field::bitrange *bits = nullptr, int flags = 0,
                    bool hash_dist = false) {
    bool ok = false;
    int index = 0;
    field->foreach_byte(bits, [&](const PhvInfo::Field::alloc_slice &sl) {
        ok = true;  // FIXME -- better sanity check?
        IXBar::Use::Byte byte(field->name, sl.field_bit, sl.field_hi());
        byte.flags =
            flags | need_align_flags[sl.container.log2sz()][(sl.container_bit/8U) & 3];
        if (hash_dist)
            alloc.hash_dist_use.back().use.push_back(byte);
        else
            alloc.use.push_back(byte);
        index++;
    });
    if (!ok)
        ERROR("field " << field->name << " allocated to tagalong but used in MAU pipe");
}

/* Simple first step that aligns with the possible options for layout option way sizes.
   For example, the max a way size can currently be will be 16, and at most 3 16 deep ways
   can be within a single column.  Thus it may need a second hash group */
void IXBar::layout_option_calculation(const LayoutOption *layout_option,
                                      size_t &start, size_t &last) {
    if (layout_option->layout.ternary) {
        start = 0; last = 0; return;
    }
    start = last;
    if (start == 0 && layout_option && layout_option->way_sizes[0] == 16) {
        last = 3;
    } else {
        last = layout_option->way_sizes.size();
    }
}

/* This is for adding fields to be allocated in the ixbar allocation scheme.  Used by
   match tables, selectors, and hash distribution */
void IXBar::field_management(const IR::Expression *field, IXBar::Use &alloc,
    set<cstring> &fields_needed, bool hash_dist, cstring name, const PhvInfo &phv) {
    const PhvInfo::Field *finfo = nullptr;
    PhvInfo::Field::bitrange bits = { };
    if (auto list = field->to<IR::ListExpression>()) {
        if (!hash_dist)
            BUG("A field list is somehow contained within the reads in table %s", name);
        for (auto comp : list->components)
             field_management(comp, alloc, fields_needed, hash_dist, name, phv);
        return;
    }
    if (auto mask = field->to<IR::Mask>())
        field = mask->left;
    if (auto prim = field->to<IR::Primitive>()) {
        if (prim->name == "isValid") {
            auto hdr = prim->operands[0]->to<IR::HeaderRef>()->toString();
            finfo = phv.field(hdr + ".$valid");
        }
    } else {
        finfo = phv.field(field, &bits);
    }
    BUG_CHECK(finfo, "unexpected field %s", field);
    if (fields_needed.count(finfo->name)) {
        warning("field %s read twice by table %s", finfo->name, name);
        return;
    }
    fields_needed.insert(finfo->name);
    add_use(alloc, finfo, &bits, 0, hash_dist);
}

/* This visitor is used by stateful tables to find the fields needed and add them to the
 * use info */
class FindFieldsToAlloc : public Inspector {
    const PhvInfo       &phv;
    IXBar::Use          &alloc;
    set<cstring>        &fields_needed;
    bool preorder(const IR::MAU::SaluAction *a) override {
        visit(a->action, "action");  // just visit the action instructions
        return false; }
    bool preorder(const IR::Expression *e) override {
        PhvInfo::Field::bitrange bits;
        if (auto *finfo = phv.field(e, &bits)) {
            if (!fields_needed.count(finfo->name)) {
                fields_needed.insert(finfo->name);
                add_use(alloc, finfo, &bits, 0); }
            return false; }
        return true; }

 public:
    FindFieldsToAlloc(const PhvInfo &phv, IXBar::Use &alloc, set<cstring> &fn)
    : phv(phv), alloc(alloc), fields_needed(fn) {}
};

bool IXBar::allocMatch(bool ternary, const IR::P4Table *tbl, const PhvInfo &phv, Use &alloc,
                       vector<IXBar::Use::Byte *> &alloced, bool second_try, int hash_groups) {
    alloc.ternary = ternary;
    if (!tbl->getKey()) return true;
    set<cstring>                        fields_needed;
    bool                                rv;
    for (auto key : tbl->getKey()->keyElements) {
        if (key->matchType->path->name == "selector") continue;
        field_management(key->expression, alloc, fields_needed, false, tbl->name, phv);
    }
    LOG3("need " << alloc.use.size() << " bytes for table " << tbl->name);
    LOG3("need fields " << fields_needed);

    rv = find_alloc(alloc.use, ternary, second_try, alloced, hash_groups);
    if (!ternary && rv)
        alloc.compute_hash_tables();
    if (!rv) alloc.clear();
    return rv;
}

static int way_groups_allocated(const IXBar::Use &alloc) {
    for (unsigned i = 1; i < alloc.way_use.size(); ++i)
        if (alloc.way_use[i].slice == alloc.way_use[0].slice)
            return i;
    return alloc.way_use.size();
}

int IXBar::getHashGroup(unsigned hash_table_input) {
    for (int i = 0; i < HASH_GROUPS; i++) {
        if (hash_group_use[i] == hash_table_input) {
            return i;
        }
    }
    for (int i = 0; i < HASH_GROUPS; i++) {
        if (hash_group_use[i] == 0) {
            return i;
        }
    }

    LOG2("failed to allocate hash group");
    return -1;
}

void IXBar::getHashDistGroups(unsigned hash_table_input, int hash_group_opt[2]) {
    if (hash_dist_groups[0] >= 0) {
        int index = hash_dist_groups[0];
        if ((hash_table_input | hash_group_use[index]) == hash_group_use[index]) {
            hash_group_opt[0] = index; hash_group_opt[1] = -1;
            return;
        }
    }

    if (hash_dist_groups[1] >= 0) {
        int index = hash_dist_groups[1];
        if ((hash_table_input | hash_group_use[index]) == hash_group_use[index]) {
            hash_group_opt[0] = -1; hash_group_opt[1] = index;
            return;
        }
    }

    if (hash_dist_groups[0] == -1 && hash_dist_groups[1] == -1) {
        hash_group_opt[0] = getHashGroup(hash_table_input);
    } else if (hash_dist_groups[0] == -1) {
        if (hash_dist_groups[1] != -1)
            BUG("Hash Distribution Allocation Error");
    } else if (hash_dist_groups[1] == -1) {
       hash_group_opt[0] = hash_dist_groups[0];
       hash_group_opt[1] = getHashGroup(hash_table_input);
    } else {
       hash_group_opt[0] = hash_dist_groups[0];
       hash_group_opt[1] = hash_dist_groups[1];
    }
}

/* Allocate all hashes used within a hash group of a table. The number of hashes in the
   hash group are determined by the layout option */
bool IXBar::allocAllHashWays(bool ternary, const IR::MAU::Table *tbl, Use &alloc,
                             const LayoutOption *layout_option,
                             size_t start, size_t last) {
    if (ternary)
        return true;
    unsigned hash_table_input = alloc.compute_hash_tables();

    int hash_group = getHashGroup(hash_table_input);
    if (hash_group < 0) return false;
    int free_groups = 0;
    int group;
    for (group = 0; group < HASH_INDEX_GROUPS; group++) {
        if (!(hash_index_inuse[group] & hash_table_input)) {
            free_groups++;
        }
    }
    if (free_groups == 0) {
        alloc.clear();
        return false;
    }

    int way_bits_needed = 0;
    for (auto &way : tbl->ways) {
        way_bits_needed += ceil_log2(way.entries/1024U/way.match_groups);
    }
    int way_bits = 0;
    for (int bit = 0; bit < HASH_SINGLE_BITS; bit++) {
        if (!(hash_single_bit_inuse[bit] & hash_table_input)) {
            way_bits++;
        }
    }
    if (way_bits == 0 && way_bits_needed > 0) {
        alloc.clear();
        return false;
    }
    // Currently should  never return false
    for (size_t index = start; index < last; index++) {
        if (!allocHashWay(tbl, layout_option, index, start, alloc)) {
            alloc.clear();
            return false;
        }
    }
    /* No longer does a logical table have one hash_table_input, but a couple if the
       table requires multiple hash groups */
    alloc.hash_table_inputs[hash_group] = hash_table_input;
    hash_group_use[hash_group] |= hash_table_input;
    return true;
}

/* Individual Hash way allocated, called from allocAllHashWays.  Sets up the select bit
   mask provided by the layout option */
bool IXBar::allocHashWay(const IR::MAU::Table *tbl,
                         const LayoutOption *layout_option,
                         size_t index, size_t start, Use &alloc) {
    unsigned hash_table_input = alloc.compute_hash_tables();
    int hash_group = getHashGroup(hash_table_input);
    if (hash_group < 0) return false;
    int way_bits = ceil_log2(layout_option->way_sizes[index]);
    int group;
    unsigned way_mask = 0;
    bool shared = false;
    LOG3("Need " << way_bits << " mask bits for way " << alloc.way_use.size() <<
         " in table " << tbl->name);
    for (group = 0; group < HASH_INDEX_GROUPS; group++) {
        if (!(hash_index_inuse[group] & hash_table_input)) {
            break; } }
    if (group >= HASH_INDEX_GROUPS) {
        if (alloc.way_use.empty()) {
            group = 0;  // share with another table?
            BUG("Group was allocated with no available space to push hash ways");
        } else {
            group = alloc.way_use[alloc.way_use.size() % way_groups_allocated(alloc)].slice;
            shared = true;
        }
        LOG3("all hash slices in use, reusing " << group); }
    // Calculation of the separate select bits among many stages
    unsigned free_bits = 0; unsigned used_bits = 0;

    for (int bit = 0; bit < HASH_SINGLE_BITS; bit++) {
        if (!(hash_single_bit_inuse[bit] & hash_table_input)) {
            free_bits |= 1U << bit;
        }
    }
    for (auto &way_use : alloc.way_use) {
        used_bits |= way_use.mask;
    }

    if (way_bits == 0) {
        way_mask = 0;
    } else if (shared) {
        int used_count = __builtin_popcount(used_bits);
        int allocated_select_bits = 0;

        for (size_t i = start; i < index; i++) {
            allocated_select_bits += ceil_log2(layout_option->way_sizes[i]);
        }

        int starting_bit = allocated_select_bits % used_count;
        if (starting_bit + way_bits > used_count)
            BUG("Allocated bigger way before smaller way");

        int used_bit = -1;
        for (auto bit : bitvec(used_bits)) {
            used_bit++;
            if (starting_bit > used_bit) continue;
            if (starting_bit + way_bits == used_bit) break;
            way_mask |= (1U << bit);
        }
    } else if (__builtin_popcount(free_bits) < way_bits) {
        LOG3("Free bits available is too small");
        return false;
    } else {
        int bits_needed = way_bits;
        for (int bit = 0; bit < HASH_SINGLE_BITS; bit++) {
            if ((1U << bit) & free_bits) {
                way_mask |= 1U << bit;
                bits_needed--;
            }
            if (bits_needed == 0)
                break;
        }
    }

    alloc.way_use.emplace_back(Use::Way{ hash_group, group, way_mask });
    hash_index_inuse[group] |= hash_table_input;
    for (auto bit : bitvec(way_mask)) {
        hash_single_bit_inuse[bit] |= hash_table_input;
    }
    for (auto ht : bitvec(hash_table_input)) {
        hash_index_use[ht][group] = tbl->name;
        for (auto bit : bitvec(way_mask)) {
            hash_single_bit_use[ht][bit] = tbl->name;
        }
    }
    return true;
}

bool IXBar::allocGateway(const IR::MAU::Table *tbl, const PhvInfo &phv, Use &alloc,
                         bool second_try) {
    alloc.gw_search_bus = false; alloc.gw_hash_group = false;
    alloc.gw_search_bus_bytes = 0;
    CollectGatewayFields collect(phv);
    tbl->apply(collect);
    if (collect.info.empty() && collect.valid_offsets.empty()) return true;
    for (auto &info : collect.info) {
        int flags = 0;
        if (info.second.xor_with) {
            flags |= IXBar::Use::NeedXor;
            alloc.gw_search_bus = true;
            // FIXME: This need to be coordinated with the actual PHV!!!
            alloc.gw_search_bus_bytes += (info.first->size + 7)/8;
        } else if (info.second.need_range) {
            flags |= IXBar::Use::NeedRange;
            alloc.gw_hash_group = true;
        } else {
            alloc.gw_search_bus = true;
            alloc.gw_search_bus_bytes += (info.first->size + 7)/8;
        }
        add_use(alloc, info.first, &info.second.bits, flags); }
    for (auto &valid : collect.valid_offsets) {
        add_use(alloc, phv.field(valid.first + ".$valid"));
        alloc.gw_hash_group = true;
    }
    vector<IXBar::Use::Byte *> xbar_alloced;
    if (!find_alloc(alloc.use, false, second_try, xbar_alloced, 0)) {
        alloc.clear();
        return false; }
    if (!collect.compute_offsets()) {
        alloc.clear();
        LOG3("collect.compute_offsets failed?");
        return false; }
    if (collect.bits > 0) {
        int hash_table_input = alloc.compute_hash_tables();
        int hash_group = getHashGroup(hash_table_input);
        if (hash_group < 0) {
            alloc.clear();
            return false; }
        /* FIXME -- don't need use all hash tables that we're using the ixbar for -- just those
         * tables for bytes we want to put through the hash table to get into the upper gw bits */
        unsigned avail = 0;
        unsigned need = (1U << collect.bits) - 1;
        for (auto j : Range(0, HASH_SINGLE_BITS-1)) {
            if ((hash_single_bit_inuse[j] & hash_table_input) == 0) {
                avail |= (1U << j);
            }
        }
        int shift = 0;
        while (((avail >> shift) & need) != need && shift < 12) {
            shift += 4;
        }
        if (((avail >> shift) & need) != need) {
            alloc.clear();
            LOG3("failed to find " << collect.bits << " continuous nibble aligned bits in 0x" <<
                 hex(avail));
            return false; }
        for (auto &info : collect.info) {
            for (auto &offset : info.second.offsets) {
                if (offset.first < 32) continue;
                offset.first += shift;
                alloc.bit_use.emplace_back(info.first->name, hash_group, offset.second.lo,
                                           offset.first - 32, offset.second.size()); } }
        for (auto &valid : collect.valid_offsets) {
            if (valid.second < 32) continue;
            valid.second += shift;
            alloc.bit_use.emplace_back(valid.first + ".$valid", hash_group, 0,
                                       valid.second - 32, 1); }
        for (auto ht : bitvec(hash_table_input))
            for (int i = 0; i < collect.bits; ++i)
                hash_single_bit_use[ht][shift + i] = tbl->name + "$gw";
        for (int i = 0; i < collect.bits; ++i)
            hash_single_bit_inuse[shift + i] |= hash_table_input;
        alloc.hash_table_inputs[hash_group] = hash_table_input;
        hash_group_use[hash_group] |= hash_table_input;
    }
    fill_out_use(xbar_alloced, false);
    for (int bit = 0; bit < HASH_SINGLE_BITS; bit++) {
        LOG3("Hash bit at bit " << bit << " is " << hex(hash_single_bit_inuse[bit]));
    }
    return true;
}


bool IXBar::allocSelector(const IR::ActionSelector *, const IR::P4Table *match_table,
                          const PhvInfo &phv, Use &alloc, bool second_try, cstring name) {
    vector<IXBar::Use::Byte *>  alloced;
    set <cstring>               fields_needed;
    for (auto key : match_table->getKey()->keyElements) {
        // FIXME -- refactor this with the similar loop in allocMatch
        if (key->matchType->path->name != "selector") continue;
        auto *field = key->expression;
        field_management(field, alloc, fields_needed, false, name, phv);
    }

    LOG3("need " << alloc.use.size() << " bytes for table " << match_table->name);
    LOG3("need fields " << fields_needed);
    bool rv = find_alloc(alloc.use, false, second_try, alloced, HASH_INDEX_GROUPS);
    unsigned hash_table_input = 0;
    if (rv)
         hash_table_input = alloc.compute_hash_tables();
    if (!rv) alloc.clear();

    if (!rv) return false;
    int hash_group = getHashGroup(hash_table_input);
    if (hash_group < 0) {
        alloc.clear();
        return false;
    }
    alloc.select_use.emplace_back(hash_group);
    fill_out_use(alloced, false);
    for (int i = 0; i < HASH_TABLES; i++) {
        if ((1U << i) & hash_table_input) {
            for (int j = 0; j < HASH_INDEX_GROUPS; j++) {
                hash_index_use[i][j] = name + "$select";
                hash_index_inuse[j] |= (1 << i);
            }
            for (int j = 0; j < HASH_SINGLE_BITS; j++) {
                hash_single_bit_use[i][j] = name + "$select";
                hash_single_bit_inuse[j] |= (1 << i);
            }
        }
    }
    hash_group_print_use[hash_group] = name + "$select";
    hash_group_use[hash_group] |= hash_table_input;
    alloc.hash_table_inputs[hash_group] = hash_table_input;
    hash_group_use[hash_group] |= hash_table_input;
    return rv;
}

bool IXBar::allocStateful(const IR::MAU::StatefulAlu *salu,
                          const PhvInfo &phv, Use &alloc, bool second_try) {
    set <cstring> fields_needed;
    salu->apply(FindFieldsToAlloc(phv, alloc, fields_needed));
    unsigned width = salu->width/8U;
    if (!salu->dual) width *= 2;
    unsigned byte_mask = ((1U << width) - 1) << 8;
    LOG3("need " << alloc.use.size() << " bytes for stateful table " << salu->name);
    if (alloc.use.size() == 0) return true;
    LOG3("need fields " << fields_needed);
    if (alloc.use.size() > width) {
        // can't possibly fit
        return false; }
    vector<IXBar::Use::Byte *> xbar_alloced;
    if (!find_alloc(alloc.use, false, second_try, xbar_alloced, 0, false, byte_mask)) {
        alloc.clear();
        return false; }
    fill_out_use(xbar_alloced, false);
    return true;
}

/* Provide all necessary information to the IXBar::Use about this specific primitive */
void IXBar::initialize_hash_dist(const HashDistReq &hash_dist_req, Use &alloc,
                                 const PhvInfo &phv, set<cstring> &fields_needed,
                                 cstring name) {
    if (hash_dist_req.is_address()) {
        const IR::Expression *field = hash_dist_req.get_instr()->operands.at(1);
        auto sful = hash_dist_req.get_stateful();;
        if (auto ctr = sful->to<IR::Counter>()) {
            alloc.hash_dist_use.back().type = Use::CounterPtr;
            alloc.hash_dist_use.back().alg = Use::Identity;
            int per_word = CounterPerWord(ctr);
            if (per_word == 4)
                alloc.hash_dist_use.back().shift = 1;
            else if (per_word == 2)
                alloc.hash_dist_use.back().shift = 2;
            else
                alloc.hash_dist_use.back().shift = 3;
        } else if (sful->is<IR::Meter>()) {
            alloc.hash_dist_use.back().type = Use::MeterPtr;
            alloc.hash_dist_use.back().alg = Use::Identity;
            alloc.hash_dist_use.back().shift = 7;
        } else if (auto reg = sful->to<IR::Register>()) {
            alloc.hash_dist_use.back().type = Use::MeterPtr;
            alloc.hash_dist_use.back().alg = Use::Identity;
            alloc.hash_dist_use.back().shift = ceil_log2(reg->width);
        } else {
            BUG("Unrecognized stateful object %s", sful);
        }
        alloc.hash_dist_use.back().max_size = hash_dist_req.bits_required(phv);
        field_management(field, alloc, fields_needed, true, name, phv);
    } else if (hash_dist_req.is_immediate()) {
        alloc.hash_dist_use.back().type = Use::Immediate;
        cstring algorithm = hash_dist_req.algorithm();
        if (algorithm == "crc32" || algorithm == "crc32_custom")
            alloc.hash_dist_use.back().alg = Use::CRC32;
        else if (algorithm == "crc16" || "crc16_custom")
            alloc.hash_dist_use.back().alg = Use::CRC16;
        else if (algorithm == "random")
            alloc.hash_dist_use.back().alg = Use::Random;
        else if (algorithm == "identity")
            alloc.hash_dist_use.back().alg = Use::Identity;
        else
            BUG("Unrecognized hash algorithm %s", algorithm);

        long con = hash_dist_req.get_instr()->operands[4]->to<IR::Constant>()->asLong();
        alloc.hash_dist_use.back().max_size = __builtin_popcount(con - 1);
        auto *fl = hash_dist_req.get_instr()->operands[3]->to<IR::ListExpression>();
        for (auto comp : fl->components) {
            field_management(comp, alloc, fields_needed, true, name, phv);
        }
    }
}

/* For any hash action tables that have an indirect counter or meter */
bool IXBar::allocHashDistAddress(const HashDistReq &hash_dist_req,
    const unsigned used_hash_dist_groups, const unsigned long used_hash_dist_bits,
    const unsigned &hash_table_input, unsigned &slice, unsigned long &bit_mask, cstring name,
    const PhvInfo &phv) {
    bool can_allocate = false;
    int address_group = -1;
    for (int i = 0; i < HASH_DIST_GROUPS - 1; i++) {
        bool collision = false;
        if ((1 << i) & used_hash_dist_groups) continue;
        address_group = i;
        int extra_addr = hash_dist_req.bits_required(phv) - HASH_DIST_BITS;
        for (int j = 0; j < extra_addr; j++) {
            int index = j + 2 * HASH_DIST_BITS + address_group * 7;
            if (used_hash_dist_bits & (1ULL << index)) {
                collision = true;
                break;
            }
        }
        if (collision) continue;
        can_allocate = true;
        break;
    }

    if (!can_allocate) return false;

    for (int i = 0; i < HASH_TABLES; i++) {
        if ((hash_table_input & (1 << i)) == 0) continue;
        hash_dist_use[i][address_group] = name;
        hash_dist_inuse[i] |= (1 << address_group);
        slice |= (1 << address_group);
        int addr_size = (HASH_DIST_BITS < hash_dist_req.bits_required(phv))
                        ? HASH_DIST_BITS : hash_dist_req.bits_required(phv);
        for (int j = 0; j < addr_size; j++) {
            int index = address_group * HASH_DIST_BITS + j;
            hash_dist_bit_use[i][index] = name;
            hash_dist_bit_inuse[i] |= (1ULL << index);
            bit_mask |= (1ULL << index);
        }
        int extra_addr = hash_dist_req.bits_required(phv) - HASH_DIST_BITS;
        if (extra_addr > 0) {
            hash_dist_use[i][2] = name;
            hash_dist_inuse[i] |= (1 << 2);
            slice |= (1 << 2);
            for (int j = 0; j < extra_addr; j++) {
                int index = 2 * HASH_DIST_BITS + address_group * 7 + j;
                hash_dist_bit_use[i][index] = name;
                hash_dist_bit_inuse[i] |= (1ULL << index);
                bit_mask |= (1ULL << index);
            }
        }
    }
    return true;
}

/* Allocating hash bits for hash calculation */
bool IXBar::allocHashDistImmediate(const HashDistReq &hash_dist_req,
    const unsigned used_hash_dist_groups,
    const unsigned &hash_table_input, unsigned &slice, unsigned long &bit_mask, cstring name,
    const PhvInfo &phv) {
    bool can_allocate = false;
    int hash_dist_groups_needed =
        (hash_dist_req.bits_required(phv) + HASH_DIST_BITS - 1) / HASH_DIST_BITS;
    unsigned avail_groups = ((1 << HASH_DIST_GROUPS) - 1) & (~used_hash_dist_groups);
    int groups_left = __builtin_popcount(avail_groups);
    if (groups_left - hash_dist_groups_needed >= 0)
        can_allocate = true;
    for (int i = 0; i < HASH_DIST_GROUPS; i++) {
        if ((groups_left - hash_dist_groups_needed) == 0) break;
        if (((1 << i) & avail_groups) == 0) continue;
        avail_groups &= ~(1 << i);
        groups_left--;
    }

    if (!can_allocate) return false;

    for (int i = 0; i < HASH_TABLES; i++) {
        int allocated_groups = 0;
        if ((hash_table_input & (1 << i)) == 0) continue;
        for (int j = 0; j < HASH_DIST_GROUPS; j++) {
            if (((1 << j) & avail_groups) == 0) continue;
            hash_dist_use[i][j] = name;
            hash_dist_inuse[i] |= (1 << j);
            slice |= (1 << j);
            int bits_needed = hash_dist_req.bits_required(phv) - allocated_groups * HASH_DIST_BITS;
            bits_needed = (bits_needed <= HASH_DIST_BITS) ? bits_needed : HASH_DIST_BITS;
            unsigned long bit_vector = (1 << bits_needed) - 1;
            bit_mask |= (bit_vector << (j * HASH_DIST_BITS));
            allocated_groups++;
        }
    }
    return true;
}


/* Allocation for an individual hash distribution requirement, both within the match and
   hash crossbars. */
bool IXBar::allocHashDist(const HashDistReq &hash_dist_req, const PhvInfo &phv, Use &alloc,
                          bool second_try, cstring name) {
    set <cstring>                   fields_needed;
    vector <IXBar::Use::Byte *> alloced;
    fields_needed.clear();
    alloc.hash_dist_use.emplace_back();
    initialize_hash_dist(hash_dist_req, alloc, phv, fields_needed, name);
    bool rv = find_alloc(alloc.hash_dist_use.back().use, false, second_try, alloced,
                         HASH_INDEX_GROUPS, true);
    unsigned hash_table_input = 0;
    if (rv) {
        hash_table_input = alloc.compute_hash_dist_tables();
    } else {
        alloc.hash_dist_use.pop_back();
        return false;
    }
    int used_hash_group = -1;
    int hash_group_opts[HASH_DIST_UNITS] = {-1, -1};
    getHashDistGroups(hash_table_input, hash_group_opts);

    bool can_allocate = false;
    unsigned long bit_mask = 0; unsigned slice = 0;
    int unit = -1;
    for (int i = 0; i < HASH_DIST_UNITS; i++) {
        if (hash_group_opts[i] == -1) continue;
        unit = i;
        used_hash_group = hash_group_opts[i];
        unsigned long used_hash_dist_bits = 0;
        unsigned used_hash_dist_groups = 0;
        for (int j = 0; j < HASH_TABLES; j++) {
            if (((1 << j) & hash_group_use[hash_group_opts[i]]) == 0) continue;
            used_hash_dist_bits |= hash_dist_bit_inuse[j];
            used_hash_dist_groups |= hash_dist_inuse[j];
        }
        if (hash_dist_req.is_address())
            can_allocate = allocHashDistAddress(hash_dist_req, used_hash_dist_groups,
                used_hash_dist_bits, hash_table_input, slice, bit_mask, name, phv);
        else if (hash_dist_req.is_immediate())
            can_allocate = allocHashDistImmediate(hash_dist_req, used_hash_dist_groups,
                hash_table_input, slice, bit_mask, name, phv);
        else
            BUG("Unknown hash dist requirement type for IXBar");

        if (can_allocate) break;
    }
    if (!can_allocate) {
        alloc.hash_dist_use.pop_back();
        return false;
    }
    fill_out_use(alloced, false);
    alloc.hash_dist_use.back().hash_table_input = hash_table_input;
    hash_group_use[used_hash_group] |= hash_table_input;
    hash_dist_groups[unit] = used_hash_group;
    alloc.hash_dist_use.back().unit = unit;
    alloc.hash_dist_use.back().slice = slice;
    alloc.hash_dist_use.back().bit_mask = bit_mask;
    alloc.hash_dist_use.back().group = used_hash_group;
    return rv;
}

bool IXBar::allocTable(const IR::MAU::Table *tbl, const PhvInfo &phv, TableResourceAlloc &alloc,
                       const LayoutOption *lo, const vector<HashDistReq> &hash_dist_reqs) {
    if (!tbl) return true;
    /* Determine number of groups needed.  Loop through them, alloc match will be the same
       for these.  Alloc All Hash Ways will required multiple groups, and may need to change  */
    LOG1("IXBar::allocTable(" << tbl->name << ")");
    if (tbl->match_table && !lo->layout.no_match_data()) {
        bool ternary = tbl->layout.ternary;
        vector<IXBar::Use::Byte *> alloced;
        vector<Use> all_tbl_allocs;
        bool finished = false;
        size_t start = 0; size_t last = 0;
        while (!finished) {
            Use next_alloc;
            layout_option_calculation(lo, start, last);
            /* Essentially a calculation of how much space is potentially available */
            int hash_groups = (last - start > 4) ? 4 : last - start;
            if (!(allocMatch(ternary, tbl->match_table, phv, next_alloc,
                             alloced, false, hash_groups)
                && allocAllHashWays(ternary, tbl, next_alloc, lo, start, last))
                && !(allocMatch(ternary, tbl->match_table, phv, next_alloc,
                     alloced, true, hash_groups)
                && allocAllHashWays(ternary, tbl, next_alloc, lo, start, last))) {
                next_alloc.clear();
                alloc.match_ixbar.clear();
                return false;
            } else {
               fill_out_use(alloced, ternary);
            }
            alloced.clear();
            all_tbl_allocs.push_back(next_alloc);
            if (last == lo->way_sizes.size())
                finished = true;
        }
        for (auto a : all_tbl_allocs) {
            alloc.match_ixbar.add(a);
        }
    }

    for (auto at : tbl->attached) {
        if (auto as = at->to<IR::ActionSelector>()) {
            if (!attached_tables.count(as) &&
                !allocSelector(as, tbl->match_table, phv, alloc.selector_ixbar, false, tbl->name) &&
                !allocSelector(as, tbl->match_table, phv, alloc.selector_ixbar, true, tbl->name)) {
                alloc.clear_ixbar();
                return false; } }
        if (auto salu = at->to<IR::MAU::StatefulAlu>()) {
            if (!attached_tables.count(salu) &&
                !allocStateful(salu, phv, alloc.salu_ixbar, false) &&
                !allocStateful(salu, phv, alloc.salu_ixbar, true)) {
                alloc.clear_ixbar();
                return false; } } }

    if (!allocGateway(tbl, phv, alloc.gateway_ixbar, false) &&
        !allocGateway(tbl, phv, alloc.gateway_ixbar, true)) {
        alloc.clear_ixbar();
        return false; }

    for (auto &hash_dist_req : hash_dist_reqs) {
        if (!allocHashDist(hash_dist_req, phv, alloc.match_ixbar, false, tbl->name) &&
            !allocHashDist(hash_dist_req, phv, alloc.match_ixbar, true, tbl->name)) {
            alloc.clear_ixbar();
            return false;
        }
    }
    return true;
}

/* Specifically for the update of hash distribution information for each individual
   table.  Updates the exact match xbar and the hash xbar with the information.  */
void IXBar::update_hash_dist(cstring name, const Use &alloc) {
    auto &hd_use = exact_use.base();
    auto &hd_fields = exact_fields;
    for (auto &hash_dist : alloc.hash_dist_use) {
        for (auto &byte : hash_dist.use) {
            if (!byte.loc) continue;
            if (byte == hd_use[byte.loc]) continue;
            if (hd_use[byte.loc].first)
                BUG("Conflicting hash dist ixbar allocation");
            hd_use[byte.loc] = byte;
            hd_fields.emplace(byte.field, byte.loc);
        }
        for (int i = 0; i < HASH_TABLES; i++) {
            if (((1U << i) & hash_dist.hash_table_input) == 0) continue;
            for (auto bit : bitvec(hash_dist.bit_mask)) {
                 if (!hash_dist_bit_use[i][bit]) {
                     hash_dist_bit_use[i][bit] = name;
                 } else {
                     BUG("Conflicting hash distribution bit allocation");
                 }
            }
            hash_dist_bit_inuse[i] |= hash_dist.bit_mask;
            for (auto slice : bitvec(hash_dist.slice)) {
                if (!hash_dist_use[i][slice])
                    hash_dist_use[i][slice] = name;
            }
            hash_dist_inuse[i] |= hash_dist.slice;
        }
        hash_group_print_use[hash_dist.group] = name;
        hash_group_use[hash_dist.group] |= hash_dist.hash_table_input;
        if (hash_dist_groups[hash_dist.unit] != hash_dist.group &&
            hash_dist_groups[hash_dist.unit] != -1)
            BUG("Conflicting hash distribution unit groups");
        hash_dist_groups[hash_dist.unit] = hash_dist.group;
    }
}

void IXBar::update(cstring name, const Use &alloc) {
    auto &use = alloc.ternary ? ternary_use.base() : exact_use.base();
    auto &fields = alloc.ternary ? ternary_fields : exact_fields;
    for (auto &byte : alloc.use) {
        if (!byte.loc) continue;
        if (byte.loc.byte == 5 && alloc.ternary) {
            /* the sixth byte in a ternary group is actually half a byte group it shares with
             * the adjacent ternary group */
            int byte_group = byte.loc.group/2;
            if (byte == byte_group_use[byte_group]) continue;
            if (byte_group_use[byte_group].first)
                BUG("conflicting ixbar allocation");
            byte_group_use[byte_group] = byte;
        } else {
            if (byte == use[byte.loc]) continue;
            if (use[byte.loc].first)
                BUG("conflicting ixbar allocation");
            use[byte.loc] = byte; }
        fields.emplace(byte.field, byte.loc); }
    for (auto &bits : alloc.bit_use) {
        const Loc *loc = nullptr;
        for (int b = 0; b < bits.width; b++) {
            if ((!loc || loc->byte != (b + bits.lo)/8) &&
                !(loc = findExactByte(bits.field, (b + bits.lo)/8)))
                BUG("ixbar hashing bits from %s, but they're not on the bus", bits.field);
            for (auto ht : bitvec(alloc.hash_table_inputs[bits.group])) {
                if (hash_single_bit_use.at(ht, b + bits.bit)) {
                    BUG("conflicting ixbar hash bit allocation");
                }
                hash_single_bit_use.at(ht, b + bits.bit) = name; }
            hash_single_bit_inuse[b + bits.bit] |= alloc.hash_table_inputs[bits.group]; }
        if (hash_group_use[bits.group] == 0) {
            hash_group_use[bits.group] = alloc.hash_table_inputs[bits.group];
            hash_group_print_use[bits.group] = name;
        } else if (hash_group_use[bits.group] != alloc.hash_table_inputs[bits.group]) {
            BUG("conflicting hash group use between %s and %s", name, hash_group_use[bits.group]);
        }
    }
    for (auto &way : alloc.way_use) {
        if (hash_group_use[way.group] == 0) {
            hash_group_use[way.group] = alloc.hash_table_inputs[way.group];
            hash_group_print_use[way.group] = name;
        }
        hash_index_inuse[way.slice] |= alloc.hash_table_inputs[way.group];
        for (int hash : bitvec(alloc.hash_table_inputs[way.group])) {
            if (!hash_index_use[hash][way.slice])
                hash_index_use[hash][way.slice] = name;
            for (auto bit : bitvec(way.mask)) {
                hash_single_bit_inuse[bit] |= alloc.hash_table_inputs[way.group];
                if (!hash_single_bit_use[hash][bit])
                    hash_single_bit_use[hash][bit] = name; } } }
    for (auto &select : alloc.select_use) {
        for (int i = 0; i < HASH_TABLES; i++) {
            if ((1U << i) & alloc.hash_table_inputs[select.group]) {
                for (int j = 0; j < HASH_INDEX_GROUPS; j++) {
                    hash_index_use[i][j] = name;
                    hash_index_inuse[j] |= (1 << i);
                }
                for (int j = 0; j < HASH_SINGLE_BITS; j++) {
                    hash_single_bit_use[i][j] = name;
                    hash_single_bit_inuse[j] |= (1 << i);
                }
            }
        }
        hash_group_print_use[select.group] = name;
        hash_group_use[select.group] |= alloc.hash_table_inputs[select.group];
    }
    update_hash_dist(name, alloc);
}

void IXBar::update(cstring name, const TableResourceAlloc *rsrc) {
    update(name + "$register", rsrc->salu_ixbar);
    update(name + "$select", rsrc->selector_ixbar);
    update(name + "$gw", rsrc->gateway_ixbar);
    update(name, rsrc->match_ixbar);
}

static void write_one(std::ostream &out, const std::pair<cstring, int> &f,
                      std::map<cstring, char> &fields) {
    if (f.first) {
        if (!fields.count(f.first)) {
            if (fields.size() >= 52)
                fields.emplace(f.first, '?');
            else if (fields.size() >= 26)
                fields.emplace(f.first, 'a' + fields.size() - 26);
            else
                fields.emplace(f.first, 'A' + fields.size()); }
        out << fields[f.first] << hex(f.second/8);
    } else {
        out << ".."; }
}
static void write_one(std::ostream &out, cstring n, std::map<cstring, char> &names) {
    if (n) {
        if (!names.count(n)) {
            if (names.size() >= 52)
                names.emplace(n, '?');
            else if (names.size() >= 26)
                names.emplace(n, 'a' + names.size() - 26);
            else
                names.emplace(n, 'A' + names.size()); }
        out << names[n];
    } else {
        out << '.'; }
}

template<class T>
static void write_group(std::ostream &out, const T &grp, std::map<cstring, char> &fields) {
    for (auto &a : grp) write_one(out, a, fields);
}

/* IXBarPrinter in .gdbinit should match this */
std::ostream &operator<<(std::ostream &out, const IXBar &ixbar) {
    std::map<cstring, char>     fields;
    out << "Input Xbar:" << std::endl;
    for (int r = 0; r < IXBar::EXACT_GROUPS; r++) {
        write_group(out, ixbar.exact_use[r], fields);
        if (r < IXBar::BYTE_GROUPS) {
            out << "  ";
            write_group(out, ixbar.ternary_use[2*r], fields);
            out << " ";
            write_one(out, ixbar.byte_group_use[r], fields);
            out << " ";
            write_group(out, ixbar.ternary_use[2*r+1], fields); }
        out << std::endl; }
    for (auto &f : fields)
        out << "   " << f.second << " " << f.first << std::endl;
    std::map<cstring, char>     tables;
    out << "Hash:" << std::endl;
    for (int h = 0; h < IXBar::HASH_TABLES; ++h) {
        write_group(out, ixbar.hash_index_use[h], tables);
        out << " ";
        write_group(out, ixbar.hash_single_bit_use[h], tables);
        if (h < IXBar::HASH_GROUPS) {
            out << "   ";
            write_one(out, ixbar.hash_group_print_use[h], tables); }
        out << std::endl; }
    for (auto &t : tables)
        out << "   " << t.second << " " << t.first << std::endl;
    return out;
}

void dump(const IXBar *ixbar) {
    std::cout << *ixbar;
}
void dump(const IXBar &ixbar) {
    std::cout << ixbar;
}

std::ostream &operator<<(std::ostream &out, const IXBar::Use &use) {
    for (auto &b : use.use)
        out << b << std::endl;
    for (auto &w : use.way_use)
        out << "[ " << w.group << ", " << w.slice << ", 0x" << hex(w.mask) << " ]" << std::endl;
    return out;
}

void dump(const IXBar::Use *use) {
    std::cout << *use;
}
void dump(const IXBar::Use &use) {
    std::cout << use;
}
