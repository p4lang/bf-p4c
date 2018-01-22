#include "bf-p4c/mau/input_xbar.h"

#include <set>
#include "bf-p4c/mau/gateway.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/mau/resource_estimate.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/algorithm.h"
#include "lib/bitvec.h"
#include "lib/bitops.h"
#include "lib/hex.h"
#include "lib/range.h"
#include "lib/log.h"

void IXBar::clear() {
    exact_use.clear();
    ternary_use.clear();
    byte_group_use.clear();
    exact_fields.clear();
    ternary_fields.clear();
    hash_index_use.clear();
    hash_single_bit_use.clear();
    hash_group_print_use.clear();
    hash_dist_use.clear();
    hash_dist_bit_use.clear();
    memset(hash_index_inuse, 0, sizeof(hash_index_inuse));
    memset(hash_single_bit_inuse, 0, sizeof(hash_single_bit_inuse));
    memset(hash_group_use, 0, sizeof(hash_group_use));
    memset(hash_dist_inuse, 0, sizeof(hash_dist_inuse));
    memset(hash_dist_bit_inuse, 0, sizeof(hash_dist_bit_inuse));
    memset(hash_dist_groups, -1, sizeof(hash_dist_groups));
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

safe_vector<IXBar::Use::Byte> IXBar::Use::match_hash_single() const {
    if (atcam)
        return atcam_match();
    safe_vector<IXBar::Use::Byte> single_match;
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

/** Do not count partition indexes within the match bytes and double count repeated bytes
 */
safe_vector<IXBar::Use::Byte> IXBar::Use::atcam_match() const {
    safe_vector<IXBar::Use::Byte> single_match;
    for (auto byte : use) {
        if (byte.atcam_index)
            continue;
        single_match.push_back(byte);
        if (byte.atcam_double) {
            auto repeat_byte = byte;
            repeat_byte.match_index = 1;
            single_match.push_back(repeat_byte);
        }
    }
    return single_match;
}

safe_vector<IXBar::Use::Byte> IXBar::Use::atcam_partition() const {
    safe_vector<IXBar::Use::Byte> partition;
    for (auto byte : use) {
        if (!byte.atcam_index)
            continue;
        partition.push_back(byte);
    }
    return partition;
}

/** Base matching on search buses rather than ixbar groups, as potentially an input xbar
 *  group for an ATCAM table has multiple matches in it. 
 */
int IXBar::Use::search_buses_single() const {
    unsigned counted = 0;
    int rv = 0;
    for (auto &b : match_hash_single()) {
        assert(b.loc.group >= 0 && b.loc.group < 16);
        assert(b.search_bus >= 0 && b.search_bus < 16);
        if (((1 << b.search_bus) & counted) == 0) {
            ++rv;
            counted |= 1U << b.search_bus;
        }
    }
    return rv;
}

safe_vector<std::pair<int, int>> IXBar::Use::bits_per_search_bus_single() const {
    int bits_per[IXBar::EXACT_GROUPS] = { 0 };
    auto single_match = match_hash_single();

    for (auto &b : match_hash_single()) {
        assert(b.loc.group >= 0 && b.loc.group < 8);
        assert(b.search_bus >= 0 && b.search_bus < 8);
        bits_per[b.search_bus] += b.bit_use.popcount();
    }

    safe_vector<std::pair<int, int>> sizes;
    for (int i = 0; i < IXBar::EXACT_GROUPS; i++) {
         if (bits_per[i] == 0) continue;
         sizes.emplace_back(i, bits_per[i]);
    }
    return sizes;
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

/** This is too constraining than the actual algorithm, but this ensures that the hash
 *  distribution group has available space for this particular hash distribution section.
 *  The granularity of this optimization is on 16 bit slices, which are as large as an
 *  individual hash distribution section, but potentially need to be refactored in order
 *  to include multiple wide addresses or 8 bit hash distribution sections.
 */
void IXBar::calculate_available_hash_dist_groups(safe_vector<big_grp_use> &order,
                                                 int hash_groups_needed) {
    for (int i = 0; i < HASH_DIST_UNITS; i++) {
        if (hash_dist_groups[i] == -1) continue;
        auto hash_tables = hash_group_use[hash_dist_groups[i]];
        bitvec slices_used;
        for (auto &big_grp : order) {
             for (int hash_slice = 0; hash_slice < HASH_DIST_SLICES; hash_slice++) {
                 if (!(hash_dist_inuse[hash_slice] & (1 << (2 * big_grp.big_group))))
                     slices_used.setbit(hash_slice);
                 if (!(hash_dist_inuse[hash_slice] & (1 << (2 * big_grp.big_group + 1))))
                     slices_used.setbit(hash_slice);
             }
        }
        if (HASH_DIST_SLICES - slices_used.popcount() >= hash_groups_needed)
            continue;
        for (auto bit : bitvec(hash_tables)) {
            if (bit % 1 == 0)
                order[bit / 2].first.first_hash_open = false;
            else
                order[bit / 2].first.second_hash_open = false;
        }
    }
}

/* Calculates the number of hash ways available in each group.  Currently not including the
   extra 12 hash bits.  Also now separates hash tables from being part of hash distribution
   vs. standard tables and gateways.  */
void IXBar::calculate_available_groups(safe_vector<big_grp_use> &order,
                                       int hash_groups_needed, bool hash_dist) {
    for (auto &big_grp : order) {
        big_grp.first.first_hash_open = true;
        big_grp.first.second_hash_open = true;
    }

    if (hash_dist) {
        calculate_available_hash_dist_groups(order, hash_groups_needed);
    } else {
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
bool IXBar::violates_hash_constraints(safe_vector<big_grp_use> &order,
                                      bool hash_dist, int group, int byte) {
    if (byte / 8 == 0) {
        if (!order[group].first.first_hash_open) return true;
        if (hash_dist) {
            if (!order[group].first.first_hash_dist_avail())
                return true;
        } else {
            if (order[group].first.first_hash_dist_only())
                return true;
        }
    }
    if (byte / 8 == 1) {
        if (!order[group].first.second_hash_open) return true;
        if (hash_dist) {
            if (!order[group].first.second_hash_dist_avail())
                return true;
        } else {
           if (order[group].first.second_hash_dist_only())
               return true;
        }
    }
    return false;
}

/* Calculates the bytes per each group that match any currently unallocated */
void IXBar::calculate_found(safe_vector<IXBar::Use::Byte *> unalloced,
                            safe_vector<big_grp_use> &order,
                            bool ternary, bool hash_dist, unsigned byte_mask) {
    if (byte_mask != ~0U)
        return;

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
                if (need->is_range())
                    continue;
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
void IXBar::calculate_ternary_free(safe_vector<big_grp_use> &order,
                                   int big_groups, int bytes_per_big_group) {
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
void IXBar::calculate_exact_free(safe_vector<big_grp_use> &order, int big_groups,
                                 int bytes_per_big_group, bool hash_dist, unsigned byte_mask) {
    auto &use = this->use(false);
    // FIXME: This is a way too tight constraint in order to get stful.p4 to correctly compile
    // There needs to be some coordination with what is actually needed vs. what is actually
    // available.  One doesn't need the whole byte_mask to be free, in order to allocate it.
    if (byte_mask != ~0U) {
        for (int grp = 0; grp < big_groups; grp++) {
            bool whole_section_free = true;
            for (int byte = 0; byte < bytes_per_big_group; byte++) {
                if (!(byte_mask & (1U << byte)))
                    continue;
                if (use[grp][byte].first)
                    whole_section_free = false;
            }
            for (int byte = 0; byte < bytes_per_big_group && whole_section_free; byte++) {
                if (!(byte_mask & (1U << byte)))
                    continue;
                order[grp].first.free[byte] = true;
            }
        }
        return;
    }

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
void IXBar::found_bytes(grp_use *grp, safe_vector<IXBar::Use::Byte *> &unalloced, bool ternary,
                       int &match_bytes_placed, int search_bus) {
    auto &use = this->use(ternary);
    auto &fields = this->fields(ternary);
    int found_bytes = grp->found.popcount();
    int ixbar_bytes_placed = 0;
    int total_match_bytes = ternary ? TERNARY_BYTES_PER_GROUP : EXACT_BYTES_PER_GROUP;
    for (size_t i = 0; i < unalloced.size(); i++) {
        auto &need = *(unalloced[i]);
        if (found_bytes == 0)
            break;
        if (match_bytes_placed >= total_match_bytes)
            break;
        int match_bytes_added = need.atcam_double ? 2 : 1;
        if (match_bytes_placed + match_bytes_added > match_bytes_placed)
            continue;

        for (auto &p : Values(fields.equal_range(need.field))) {
            if (ternary && p.byte == 5)
                continue;
            if ((grp->group == p.group) && (use[p.group][p.byte].second == need.lo)) {
                if (!ternary && (p.byte / 8 == 0) && !grp->first_hash_open)
                    continue;
                if (!ternary && (p.byte / 8 == 1) && !grp->second_hash_open)
                    continue;
                allocate_byte(nullptr, unalloced, nullptr, need, p.group, p.byte, i,
                              found_bytes, ixbar_bytes_placed, match_bytes_placed, search_bus);
                break;
            }
        }
    }
    LOG4("Total found bytes placed was " << ixbar_bytes_placed << " " << match_bytes_placed);
}

/* Find the unalloced bytes in the current table that are contained in the grp_use containing two
   ternary groups and shared these locations.  Currently designed only for the ternary groups */
void IXBar::found_bytes_big_group(big_grp_use *grp, safe_vector<IXBar::Use::Byte *> &unalloced,
                                 int &match_bytes_placed, int search_bus) {
    auto &use = this->use(true);
    auto &fields = this->fields(true);
    int found_bytes = grp->total_found();
    int ixbar_bytes_placed = 0;
    int total_match_bytes = TERNARY_BYTES_PER_BIG_GROUP;
    for (size_t i = 0; i < unalloced.size(); i++) {
        if (found_bytes == 0)
            break;
        if (match_bytes_placed >= total_match_bytes)
            break;
        auto &need = *(unalloced[i]);
        BUG_CHECK(!need.atcam_double, "Cannot place ATCAM resources on the ternary crossbar");
        for (auto &p : Values(fields.equal_range(need.field))) {
            if (p.byte == 5) {
                if (need.is_range())
                    continue;
                if ((grp->big_group == p.group/2)
                    && (byte_group_use[p.group/2].second == need.lo)) {
                    allocate_byte(nullptr, unalloced, nullptr, need, p.group, p.byte, i,
                                  found_bytes, ixbar_bytes_placed, match_bytes_placed, search_bus);
                    break;
                }
                continue;
            }
            if ((grp->big_group == p.group/2) && (use[p.group][p.byte].second == need.lo)) {
                allocate_byte(nullptr, unalloced, nullptr, need, p.group, p.byte, i,
                              found_bytes, ixbar_bytes_placed, match_bytes_placed, search_bus);
                break;
            }
        }
    }

    LOG4("Total found bytes placed was " << ixbar_bytes_placed << " " << match_bytes_placed);
}

/** Allocate all fields within a IXBar::Byte object given its selection throughout the
 *  algorithm.  If it is not shared, move the byte to the alloced list to be filled in
 *  to the IXBar local objects later
 */
void IXBar::allocate_byte(grp_use *grp, safe_vector<Use::Byte *> &unalloced,
                          safe_vector<Use::Byte *> *alloced, Use::Byte &need, int group, int byte,
                          size_t &index, int &avail_bytes, int &ixbar_bytes_placed,
                          int &match_bytes_placed, int search_bus) {
    need.loc.group = group;
    need.loc.byte = byte;
    need.search_bus = search_bus;
    if (grp != nullptr)
        grp->free[byte] = false;
    if (alloced)
        alloced->push_back(unalloced[index]);

    unalloced.erase(unalloced.begin() + index);
    index--;
    avail_bytes--;
    ixbar_bytes_placed++;
    if (need.atcam_double)
        match_bytes_placed += 2;
    else
        match_bytes_placed++;
}


/* Fills out all currently unoccupied xbar bytes within a group with bytes from the current table
   following alignment constraints.  Works for single TCAM groups or SRAM groups */
void IXBar::free_bytes(grp_use *grp, safe_vector<IXBar::Use::Byte *> &unalloced,
                      safe_vector<IXBar::Use::Byte *> &alloced,
                      bool ternary, bool hash_dist, int &match_bytes_placed, int search_bus) {
    int ixbar_bytes_placed = 0;
    int free_bytes = grp->free.popcount();
    int total_match_bytes = ternary ? TERNARY_BYTES_PER_GROUP : EXACT_BYTES_PER_GROUP;

    for (size_t i = 0; i < unalloced.size(); i++) {
        if (free_bytes == 0)
            break;
        if (match_bytes_placed >= total_match_bytes)
            break;
        auto &need = *(unalloced[i]);
        int match_bytes_added = need.atcam_double ? 2 : 1;
        if (match_bytes_placed + match_bytes_added > total_match_bytes)
            continue;

        int align = ternary ? ((grp->group * 11 + 1)/2) & 3 : 0;
        int chosen_byte = -1;
        bool found = false;
        for (auto byte : grp->free) {
            if (align_flags[(byte+align) & 3] & need.flags) {
                 continue;
            }
            allocate_byte(grp, unalloced, &alloced, need, grp->group, byte, i, free_bytes,
                          ixbar_bytes_placed, match_bytes_placed, search_bus);
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
    LOG4("Total free bytes placed was " << ixbar_bytes_placed << " " << match_bytes_placed);
}

/* Fills out all currently unoccupied xbar bytes within a group with bytes from the current table
   following alignment constraints.  Specifically designed to handle the allocation of a large
   ternary group */
void IXBar::free_bytes_big_group(big_grp_use *grp,
                                safe_vector<IXBar::Use::Byte*> &unalloced,
                                safe_vector<IXBar::Use::Byte *> &alloced,
                                bool &version_placed, int &match_bytes_placed, int search_bus) {
    int ixbar_bytes_placed = 0;
    int free_bytes = grp->total_free();
    int align = (grp->big_group * (2 * TERNARY_BYTES_PER_GROUP + 1)) & 3;
    int total_match_bytes = TERNARY_BYTES_PER_BIG_GROUP;

    /* Version bit information has to be at the midbyte boundary.  However, if there is a hole
       in the bits, then the code can go there. */
    if (!version_placed) {
        for (size_t i = 0; i < unalloced.size(); i++) {
            if (free_bytes == 0)
                break;
            auto &need = *(unalloced[i]);
            if (need.bit_use.getslice(4, 4).popcount() > 0 &&
                need.bit_use.getslice(0, 4).popcount() > 0) continue;
            if (align_flags[(TERNARY_BYTES_PER_GROUP + align) & 3] & need.flags) continue;
            allocate_byte(nullptr, unalloced, &alloced, need, grp->big_group * 2, 5, i,
                               free_bytes, ixbar_bytes_placed, match_bytes_placed, search_bus);
            grp->mid_byte_free = false;
            version_placed = true;
            break;
        }
    }


    for (size_t i = 0; i < unalloced.size(); i++) {
        bool found = false;
        if (free_bytes == 0)
            break;
        if (match_bytes_placed >= total_match_bytes)
            break;
        auto &need = *(unalloced[i]);
        BUG_CHECK(!need.atcam_double, "Should not be allocating algorithmic TCAM bytes to the "
                  "ternary crossbar");

        /* Allocate free bytes within the first ternary group */
        for (auto byte : grp->first.free) {
            if (align_flags[(byte + align) & 3] & need.flags) continue;
            allocate_byte(&(grp->first), unalloced, &alloced, need, grp->big_group * 2, byte, i,
                          free_bytes, ixbar_bytes_placed, match_bytes_placed, search_bus);
            found = true;
            break;
        }
        if (found)
            continue;

        /* Allocate free bytes within the second ternary group */
        for (auto byte : grp->second.free) {
            if (align_flags[(byte + TERNARY_BYTES_PER_GROUP + 1 + align) & 3] & need.flags)
                continue;
            allocate_byte(&(grp->second), unalloced, &alloced, need, grp->big_group * 2 + 1, byte,
                          i, free_bytes, ixbar_bytes_placed, match_bytes_placed, search_bus);
            found = true;
            break;
        }

        if (found)
            continue;

        /* Allocate middle bytes of the ternary big group */
        if (grp->mid_byte_free && !(need.is_range())) {
            if (align_flags[(TERNARY_BYTES_PER_GROUP + align) & 3] & need.flags) continue;
            allocate_byte(nullptr, unalloced, &alloced, need, grp->big_group * 2, 5, i, free_bytes,
                          ixbar_bytes_placed, match_bytes_placed, search_bus);
            grp->mid_byte_free = false;
        }
    }
}

/* When all bytes of the current table have been given a placement, this function fills out
   the xbars use for later record keeping and checks */
void IXBar::fill_out_use(safe_vector<IXBar::Use::Byte *> &alloced, bool ternary) {
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
bool IXBar::big_grp_alloc(bool ternary, bool second_try,
                          safe_vector<IXBar::Use::Byte *> &unalloced,
                          safe_vector<IXBar::Use::Byte *> &alloced,
                          safe_vector<big_grp_use> &order,
                          int big_groups_needed, int &total_bytes_needed,
                          int bytes_per_big_group, int &search_bus,
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

        int match_bytes_placed = 0;
        if (ternary) {
            LOG4("TCAM big group selected was " << order[0].big_group);
            found_bytes_big_group(&order[0], unalloced, match_bytes_placed, search_bus);
            free_bytes_big_group(&order[0], unalloced, alloced, version_placed,
                                 match_bytes_placed, search_bus);
        } else {
            LOG4("SRAM group selected was " << order[0].first.group);
            found_bytes(&order[0].first, unalloced, ternary, match_bytes_placed, search_bus);
            free_bytes(&order[0].first, unalloced, alloced, ternary, hash_dist,
                       match_bytes_placed, search_bus);
        }

        /* No bytes placed in the xbar.  You're finished */
        if (match_bytes_placed == 0) {
            return false;
        }
        total_bytes_needed -= match_bytes_placed;
        search_bus++;
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
bool IXBar::small_grp_alloc(bool ternary, bool second_try,
                            safe_vector<IXBar::Use::Byte *> &unalloced,
                            safe_vector<IXBar::Use::Byte *> &alloced,
                            safe_vector<grp_use *> &small_order,
                            safe_vector<big_grp_use> &order,
                            int &total_bytes_needed, int &search_bus, bool hash_dist,
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

        int match_bytes_placed = 0;
        if (ternary)
            LOG4("TCAM small group selected was " << small_order[0]->group);
        else
            LOG4("SRAM group selected was " << small_order[0]->group);

        found_bytes(small_order[0], unalloced, ternary, match_bytes_placed, search_bus);
        free_bytes(small_order[0], unalloced, alloced, ternary, hash_dist, match_bytes_placed,
                   search_bus);
        /* No bytes placed in the xbar.  You're finished */
        if (match_bytes_placed == 0) {
            return false;
        }
        total_bytes_needed -= match_bytes_placed;
        calculate_found(unalloced, order, ternary, hash_dist, byte_mask);
    }
    search_bus++;
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
bool IXBar::find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use,
                       bool ternary, bool second_try,
                       safe_vector<IXBar::Use::Byte *> &alloced,
                       int hash_groups_needed,
                       bool hash_dist, unsigned byte_mask) {
    /* Initial sizing calculations*/
    int groups = ternary ? TERNARY_GROUPS : EXACT_GROUPS;
    int big_groups = ternary ? TERNARY_GROUPS/2 : EXACT_GROUPS;
    int bytes_per_big_group = ternary ? 11 : EXACT_BYTES_PER_GROUP;

    int total_bytes_needed = 0;
    for (auto byte : alloc_use) {
        if (byte.atcam_double)
            total_bytes_needed += 2;
        else
            total_bytes_needed++;
    }
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
    safe_vector<big_grp_use> order(big_groups);
    safe_vector<grp_use *> small_order;
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
    safe_vector<IXBar::Use::Byte *> unalloced;

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
        calculate_available_groups(order, hash_groups_needed, hash_dist);
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

    int search_bus = 0;

    /* While more than one individual group is necessary for the number of unallocated bytes */
    if (!big_grp_alloc(ternary, second_try, unalloced, alloced, order, big_groups_needed,
                       total_bytes_needed, bytes_per_big_group, search_bus, hash_dist,
                       byte_mask)) {
        return false;
    }

    // Only one large group at most is necessary
    if (!small_grp_alloc(ternary, second_try, unalloced, alloced, small_order, order,
                         total_bytes_needed, search_bus, hash_dist, byte_mask)) {
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
static void add_use(IXBar::Use &alloc, const PHV::Field *field,
                    const bitrange *bits = nullptr, int flags = 0,
                    IXBar::byte_type_t byte_type = IXBar::NO_BYTE_TYPE,
                    unsigned extra_align = 0) {
    bool ok = false;
    int index = 0;
    field->foreach_byte(bits, [&](const PHV::Field::alloc_slice &sl) {
        ok = true;  // FIXME -- better sanity check?
        IXBar::Use::Byte byte(field->name, sl.field_bit, sl.field_hi());
        byte.bit_use.setrange(sl.container_bit % 8, sl.width);
        byte.flags =
            flags | need_align_flags[sl.container.log2sz()][(sl.container_bit/8U) & 3]
                  | need_align_flags[extra_align][index & 3];
        if (byte_type == IXBar::ATCAM) {
            byte.atcam_double = true;
        } else if (byte_type == IXBar::PARTITION_INDEX) {
            byte.atcam_index = true;
        }

        if (byte_type == IXBar::RANGE) {
            if (sl.container_bit < 4) {
                alloc.use.push_back(byte);
                alloc.use.back().range_lo = true;
            } else {
                alloc.use.push_back(byte);
                alloc.use.back().range_hi = true;
            }
        } else {
            alloc.use.push_back(byte);
        }
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
    if (start == 0 && layout_option && layout_option->select_bus_split != -1) {
        last = layout_option->select_bus_split;
    } else {
        last = layout_option->way_sizes.size();
    }
}

/* This is for adding fields to be allocated in the ixbar allocation scheme.  Used by
   match tables, selectors, and hash distribution */
void IXBar::field_management(const IR::Expression *field, IXBar::Use &alloc,
        std::map<cstring, bitvec> &fields_needed, bool hash_dist, cstring name,
        const PhvInfo &phv, bool is_atcam, bool partition) {
    const PHV::Field *finfo = nullptr;
    bitrange bits = { };
    if (auto list = field->to<IR::ListExpression>()) {
        if (!hash_dist)
            BUG("A field list is somehow contained within the reads in table %s", name);
        for (auto comp : list->components)
             field_management(comp, alloc, fields_needed, hash_dist, name, phv);
        return;
    }
    if (field->is<IR::Mask>())
        BUG("Masks should have been converted to Slices before input xbar allocation");

    byte_type_t byte_type = NO_BYTE_TYPE;
    if (auto read = field->to<IR::MAU::InputXBarRead>()) {
        if (is_atcam) {
            if (partition != read->partition_index)
                return;
            else if (read->partition_index)
                byte_type = PARTITION_INDEX;
            else if (read->match_type.name == "ternary" || read->match_type.name == "lpm")
                byte_type = ATCAM;
        }
        if (read->match_type.name == "range")
            byte_type = RANGE;
        field = read->expr;
    }

    finfo = phv.field(field, &bits);
    BUG_CHECK(finfo, "unexpected field %s", field);
    bitvec field_bits(bits.lo, bits.hi - bits.lo + 1);
    if (fields_needed.count(finfo->name)) {
        auto &allocated_bits = fields_needed.at(finfo->name);
        if (allocated_bits.intersects(field_bits))
            warning("a range of field %s read twice by table %s", finfo->name, name);
        if ((allocated_bits & field_bits).popcount() == field_bits.popcount())
            return;
        fields_needed[finfo->name] |= field_bits;
    } else {
         fields_needed[finfo->name] = field_bits;
    }
    add_use(alloc, finfo, &bits, 0, byte_type);
}

/* This visitor is used by stateful tables to find the fields needed and add them to the
 * use info */
class FindFieldsToAlloc : public Inspector {
    const PhvInfo       &phv;
    IXBar::Use          &alloc;
    std::set<cstring>   &fields_needed;
    unsigned            extra_align;  // log2 of the salu size in bytes (0 = 8 bits, etc)
    bool preorder(const IR::MAU::SaluAction *a) override {
        visit(a->action, "action");  // just visit the action instructions
        return false; }
    bool preorder(const IR::Expression *e) override {
        bitrange bits;
        if (auto *finfo = phv.field(e, &bits)) {
            if (!fields_needed.count(finfo->name)) {
                fields_needed.insert(finfo->name);
                add_use(alloc, finfo, &bits, 0, IXBar::NO_BYTE_TYPE, extra_align); }
            return false; }
        return true; }
    bool preorder(const IR::MAU::HashDist *) override {
        // Handled in a different section
        return false;
    }

 public:
    FindFieldsToAlloc(const PhvInfo &phv, IXBar::Use &alloc, std::set<cstring> &fn, unsigned ea)
    : phv(phv), alloc(alloc), fields_needed(fn), extra_align(ea) {}
};

bool IXBar::allocMatch(bool ternary, const IR::MAU::Table *tbl,
                       const PhvInfo &phv, Use &alloc,
                       safe_vector<IXBar::Use::Byte *> &alloced,
                       bool second_try, int hash_groups) {
    alloc.ternary = ternary;
    if (tbl->match_key.empty()) return true;
    std::map<cstring, bitvec> fields_needed;
    for (auto ixbar_read : tbl->match_key) {
        if (ixbar_read->match_type.name == "selector") continue;
        field_management(ixbar_read, alloc, fields_needed, false, tbl->name, phv,
                         tbl->layout.atcam);
    }
    LOG3("need " << alloc.use.size() << " bytes for table " << tbl->name);

    bool rv = find_alloc(alloc.use, ternary, second_try, alloced, hash_groups);
    if (!ternary && !tbl->layout.atcam && rv)
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

/** Allocate the partition index of an algorithmic TCAM table.  Unlike an exact match table
 *  in which every single bit needs to be in the hash matrix, only the partition index
 *  appears within the hash matrix.  Thus the algorithm only calculates the hash information
 *  for the partition, and once it is completed, only then will it append it to the rest
 *  of the match alloc.
 */
bool IXBar::allocPartition(const IR::MAU::Table *tbl, const PhvInfo &phv, Use &match_alloc,
                           bool second_try) {
    if (tbl->match_key.empty()) return true;
    Use alloc;
    std::map<cstring, bitvec> fields_needed;
    safe_vector<Use::Byte *> alloced;
    for (auto ixbar_read : tbl->match_key) {
        if (ixbar_read->match_type.name == "selector") continue;
        field_management(ixbar_read, alloc, fields_needed, false, tbl->name, phv,
                         tbl->layout.atcam, true);
    }
    BUG_CHECK(alloc.use.size() > 0, "No partition index found");

    bool rv = find_alloc(alloc.use, false, second_try, alloced, 1);
    unsigned hash_table_input = 0;
    if (!rv) {
        alloc.clear();
        return rv;
    } else {
        hash_table_input = alloc.compute_hash_tables();
    }

    int hash_group = getHashGroup(hash_table_input);
    if (hash_group < 0) {
        alloc.clear();
        return false;
    }

    int group = -1;
    for (int i = 0; i < HASH_INDEX_GROUPS; i++) {
        if ((hash_index_inuse[i] & hash_table_input) == 0) {
            group = i;
            break;
        }
    }

    if (group == -1) {
        alloc.clear();
        return false;
    }

    int bits_needed = std::max(tbl->layout.partition_bits - 10, 0);
    int bits_found = 0;
    unsigned way_mask = 0;
    for (int i = 0; i < HASH_SINGLE_BITS; i++) {
        if (bits_found >= bits_needed)
            break;
        if ((hash_single_bit_inuse[i] & hash_table_input) == 0) {
            way_mask |= (1 << i);
            bits_found++;
        }
    }

    if (bits_found < bits_needed) {
        alloc.clear();
        return false;
    }

    /** The partition fits.  Just update all of the values */
    match_alloc.use.insert(match_alloc.use.end(), alloc.use.begin(), alloc.use.end());
    match_alloc.atcam = true;
    match_alloc.hash_table_inputs[hash_group] = hash_table_input;
    hash_group_use[hash_group] |= hash_table_input;
    match_alloc.way_use.emplace_back(Use::Way{ hash_group, group, way_mask});
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
    fill_out_use(alloced, false);
    return true;
}

bool IXBar::allocGateway(const IR::MAU::Table *tbl, const PhvInfo &phv, Use &alloc,
                         bool second_try) {
    alloc.gw_search_bus = false; alloc.gw_hash_group = false;
    alloc.gw_search_bus_bytes = 0;
    CollectGatewayFields collect(phv);
    tbl->apply(collect);
    if (collect.info.empty()) return true;
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
        add_use(alloc, info.first, &info.second.bits, flags, NO_BYTE_TYPE); }
    safe_vector<IXBar::Use::Byte *> xbar_alloced;
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

/** Selector allocation algorithm.  Currently reserves an entire section of hash matrix,
 *  even if the selector is only on fair mode, rather than resilient
 */
bool IXBar::allocSelector(const IR::MAU::Selector *as, const IR::MAU::Table *tbl,
                          const PhvInfo &phv, Use &alloc, bool second_try, cstring name) {
    safe_vector<IXBar::Use::Byte *>  alloced;
    std::map<cstring, bitvec>        fields_needed;
    for (auto ixbar_read : tbl->match_key) {
        if (ixbar_read->match_type.name != "selector") continue;
        field_management(ixbar_read->expr, alloc, fields_needed, false, tbl->name, phv);
    }

    LOG3("need " << alloc.use.size() << " bytes for table " << tbl->name);
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
    for (int i = 0; i < HASH_TABLES; i++) {
        if ((1U << i) & hash_table_input) {
            for (int j = 0; j < HASH_INDEX_GROUPS; j++) {
                if (hash_index_use[i][j]) {
                    alloc.clear();
                    return false;
                }
            }
            for (int j = 0; j < HASH_SINGLE_BITS; j++) {
                if (hash_single_bit_use[i][j]) {
                    alloc.clear();
                    return false;
                }
            }
        }
    }

    alloc.select_use.emplace_back(hash_group);
    alloc.select_use.back().algorithm = as->algorithm.name;
    alloc.select_use.back().mode = as->mode.name;
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
    fill_out_use(alloced, false);
    hash_group_print_use[hash_group] = name + "$select";
    hash_group_use[hash_group] |= hash_table_input;
    alloc.hash_table_inputs[hash_group] = hash_table_input;
    hash_group_use[hash_group] |= hash_table_input;
    return rv;
}

bool IXBar::allocStateful(const IR::MAU::StatefulAlu *salu,
                          const PhvInfo &phv, Use &alloc, bool second_try) {
    std::set <cstring> fields_needed;
    unsigned extra_align = 0;
    if (!second_try && salu->width > 1) {
        /* To use the stateful_meter_alu_data path, any fields read must be aligned
         * properly on the ixbar for the size of the stateful alu.  We only do this
         * on the first try, since if it's not aligned, we can still make it work, we
         * just need to use a hash table to swizzle it properly, and use the Exact
         * Match Hash Address VH Xbar.  See 6.2.3(fig 6-18) and 6.2.8.4.1(fig 6-32)
         * in the Tofino uArch doc */
        extra_align = floor_log2(salu->width) - 3;
        if (salu->dual) extra_align--;
        BUG_CHECK(extra_align <= 2, "Bad SatefulAlu width"); }
    salu->apply(FindFieldsToAlloc(phv, alloc, fields_needed, extra_align));
    unsigned width = salu->width/8U;
    if (!salu->dual) width *= 2;
    unsigned byte_mask = ((1U << width) - 1) << 8;
    if (alloc.use.size() == 0) return true;
    if (alloc.use.size() > width) {
        // can't possibly fit
        return false; }
    safe_vector<IXBar::Use::Byte *> xbar_alloced;
    if (!find_alloc(alloc.use, false, second_try, xbar_alloced, 0, false, byte_mask)) {
        alloc.clear();
        return false; }
    // FIXME -- need to allocate hash table space if it turns out we need it
    fill_out_use(xbar_alloced, false);
    return true;
}

/** Allocating hash bits for an indirect address in the table.  Currently checks on a slice
 *  by slice granularity, unless upper bits are required in a longer address, and then will
 *  allocate those upper bits.
 */
bool IXBar::allocHashDistAddress(const IR::MAU::HashDist *hd, const unsigned used_hash_dist_slices,
    const unsigned long used_hash_dist_bits, const unsigned &hash_table_input, unsigned &slice,
    unsigned long &bit_mask, cstring name) {
    bool can_allocate = false;
    int address_group = -1;
    for (int i = 0; i < HASH_DIST_SLICES - 1; i++) {
        bool collision = false;
        if ((1 << i) & used_hash_dist_slices) continue;
        address_group = i;
        int extra_addr = hd->bit_width - HASH_DIST_BITS;
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
        int addr_size = (HASH_DIST_BITS < hd->bit_width) ? HASH_DIST_BITS : hd->bit_width;
        for (int j = 0; j < addr_size; j++) {
            int index = address_group * HASH_DIST_BITS + j;
            hash_dist_bit_use[i][index] = name;
            hash_dist_bit_inuse[i] |= (1ULL << index);
            bit_mask |= (1ULL << index);
        }
        int extra_addr = hd->bit_width - HASH_DIST_BITS;
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

/** Allocating hash bits for hash calculation.  Currently checks on a slice granularity.  Could
 *  be further optimized for a bit by bit granularity
 */
bool IXBar::allocHashDistImmediate(const IR::MAU::HashDist *hd,
    const unsigned used_hash_dist_slices, const unsigned &hash_table_input, unsigned &slice,
    unsigned long &bit_mask, cstring name) {
    bool can_allocate = false;

    int hash_dist_groups_needed = (hd->bit_width + HASH_DIST_BITS - 1) / HASH_DIST_BITS;
    unsigned avail_groups = ((1 << HASH_DIST_SLICES) - 1) & (~used_hash_dist_slices);
    int groups_left = __builtin_popcount(avail_groups);
    if (groups_left - hash_dist_groups_needed >= 0)
        can_allocate = true;
    for (int i = 0; i < HASH_DIST_SLICES; i++) {
        if ((groups_left - hash_dist_groups_needed) == 0) break;
        if (((1 << i) & avail_groups) == 0) continue;
        avail_groups &= ~(1 << i);
        groups_left--;
    }

    if (!can_allocate) return false;

    for (int i = 0; i < HASH_TABLES; i++) {
        int allocated_groups = 0;
        if ((hash_table_input & (1 << i)) == 0) continue;
        for (int j = 0; j < HASH_DIST_SLICES; j++) {
            if (((1 << j) & avail_groups) == 0) continue;
            hash_dist_use[i][j] = name;
            hash_dist_inuse[i] |= (1 << j);
            slice |= (1 << j);
            int bits_needed = hd->bit_width - allocated_groups * HASH_DIST_BITS;
            bits_needed = (bits_needed <= HASH_DIST_BITS) ? bits_needed : HASH_DIST_BITS;
            unsigned long bit_vector = (1ULL << bits_needed) - 1;
            bit_mask |= (bit_vector << (j * HASH_DIST_BITS));
            hash_dist_bit_inuse[i] |= bit_mask;
            allocated_groups++;
        }
    }
    return true;
}

/** Allocation for an individual hash distribution requirement.  Hash distribution is a piece of
 *  match central that can take PHV information through the hash matrix/input xbar, where this
 *  information can be used within the performatnce of the action.  The following uses are:
 *      - Using a PHV field as an address for address distribution for a counter, meter, or
 *        action data table
 *      - Calculating a hash to be used as immediate data for the table.
 *      - Providing a meter with a pre-color
 *      - Providing a hash to a selector table to calculate a RAM line hash.  This can be used for
 *        selector pools that require pool sizes > 120, as 120 is the max size for an individual
 *        RAM line in Tofino
 *      - Pulling in any PHV that can be used as immediate, in case the PHV field cannot fit
 *        in a cluster with other PHV fields
 *
 *   Specifically, the hash distribution is described in MicroArch section 6.4.3.5.3.  I'll
 *   outline the major constraints.  The hash distribution is broken into 2 units, of which
 *   each unit has access to an individual hash group output from the hash matrix.  These 2 units
 *   are 48 bits wide, and are broken into 3 16 bit slices, totalling to 96 bits of hash
 *   distribution per stage.  These 16 bit slices can be reformed into addresses, immediate, etc,
 *   through the hash distribution unit, but essentially it uses the same shift and mask procedures
 *   used by match central.
 *
 *   In the case where an address is larger than 16 bits, i.e. for a large stateful table, one
 *   has to use the expand block within hash distribution, which puts a weird restriction on the
 *   bits on the hash bus the address needs.  This constraint is specified in the following Tofino
 *   register: pipes.mau.rams.match.merge.mau_hash_group_expand.  Otherwise, the data can use
 *   the hash bits as one would expect
 *
 *   The last thing is that hash distribution must always be enabled on, as per_flow_enable cannot
 *   be brought through hash distribution.  The only place this doesn't apply is on a miss, where
 *   the miss can actually override the results from hash distribution.
 *
 *   Like every other allocation, it first finds the locations on the input xbar, and then
 *   tries to fit this into the hash matrix
 */
bool IXBar::allocHashDist(const IR::MAU::HashDist *hd, IXBar::HashDistUse::HashDistType hdt,
                          const PhvInfo &phv, IXBar::Use &alloc, bool second_try, cstring name) {
    std::map<cstring, bitvec>        fields_needed;
    safe_vector <IXBar::Use::Byte *> alloced;
    fields_needed.clear();

    field_management(hd->field_list, alloc, fields_needed, true, name, phv);
    int hash_slices_needed = (hd->bit_width + HASH_DIST_BITS - 1) / hd->bit_width;

    bool rv = find_alloc(alloc.use, false, second_try, alloced, hash_slices_needed, true);
    if (!rv) {
        alloc.use.clear();
        alloced.clear();
        return false;
    }
    unsigned hash_table_input = alloc.compute_hash_tables();
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
        // Determine which bits/slices are used on the hash group bus already
        unsigned long used_hash_dist_bits = 0;
        unsigned used_hash_dist_slices = 0;
        for (int j = 0; j < HASH_TABLES; j++) {
            if (((1 << j) & hash_group_use[hash_group_opts[i]]) == 0) continue;
            used_hash_dist_bits |= hash_dist_bit_inuse[j];
            used_hash_dist_slices |= hash_dist_inuse[j];
        }
        if (hdt == IXBar::HashDistUse::COUNTER_ADR || hdt == IXBar::HashDistUse::METER_ADR
            || hdt == IXBar::HashDistUse::ACTION_ADR)
            can_allocate = allocHashDistAddress(hd, used_hash_dist_slices,
                used_hash_dist_bits, hash_table_input, slice, bit_mask, name);
        else if (hdt == IXBar::HashDistUse::IMMEDIATE)
            can_allocate = allocHashDistImmediate(hd, used_hash_dist_slices,
                hash_table_input, slice, bit_mask, name);
        else
            BUG("Unknown hash dist requirement type for IXBar");

        if (can_allocate) break;
    }
    if (!can_allocate) {
        alloc.use.clear();
        alloced.clear();
        return false;
    }
    fill_out_use(alloced, false);
    alloc.hash_table_inputs[used_hash_group] = hash_table_input;
    hash_group_use[used_hash_group] |= hash_table_input;
    hash_dist_groups[unit] = used_hash_group;

    alloc.ternary = false;
    alloc.hash_dist_hash.allocated = true;
    alloc.hash_dist_hash.algorithm = hd->algorithm;
    alloc.hash_dist_hash.unit = unit;
    alloc.hash_dist_hash.slice = slice;
    alloc.hash_dist_hash.bit_mask = bit_mask;
    alloc.hash_dist_hash.group = used_hash_group;
    return rv;
}

class XBarHashDist : MauInspector {
    friend struct IXBar;
    IXBar &self;
    const PhvInfo &phv;
    TableResourceAlloc &alloc;
    bool allocation_passed = true;
    cstring name;

    /** Configuring the match central configuration of a hash distribution unit.  Unfortunately
     *  the hash distribution units set up the registers within the assembler on a register
     *  by register basis.  This should probably be moved more into the assembler, but in the
     *  meantime, the compiler is more responsible for these registers
     *
     *  Sets the values in the IXBar::HashDistUse struct, which describes what the individual
     *  registers are for
     */
    void initialize_hash_dist_unit(const IR::MAU::HashDist *hd, IXBar::HashDistUse &hd_use) {
        auto &hdh = hd_use.use.hash_dist_hash;
        auto hdt = hd_use.type;
        for (int i = 0; i < IXBar::HASH_DIST_SLICES; i++) {
            if (hdh.slice & (1 << i))
                hd_use.pre_slices.push_back(i + IXBar::HASH_DIST_SLICES * hdh.unit);
        }

        bool slices_set = false;

        // Preslices refer to before expand block, Slices are after expand block
        if (hdt == IXBar::HashDistUse::COUNTER_ADR || hdt == IXBar::HashDistUse::METER_ADR
            || hdt == IXBar::HashDistUse::ACTION_ADR) {
            if (hd_use.pre_slices.size() > 1) {
                if (!(hd_use.pre_slices.size() == 2
                    || (hd_use.pre_slices[1] % IXBar::HASH_DIST_SLICES) == 2))
                    BUG("Wide hash distribution address doesn't fit in the table");
                hd_use.expand.emplace(hd_use.pre_slices[0],
                                      (7 * (hd_use.pre_slices[0] % IXBar::HASH_DIST_SLICES)));
                hd_use.slices.push_back(hd_use.pre_slices[0]);
                slices_set = true;
            }
        }

        if (!slices_set) {
            for (auto pre_slice : hd_use.pre_slices) {
                hd_use.slices.push_back(pre_slice);
            }
        }

        /* Sets up the mask and shift portion of hash distribution.  Unlike every other part of
           match central, hash distribution is mask then shift, rather than shift then mask
           (of course it is) */

        auto *back_at = findContext<IR::MAU::BackendAttached>();
        if (hdt == IXBar::HashDistUse::COUNTER_ADR) {
            auto *counter = back_at->attached->to<IR::MAU::Counter>();
            int per_word = CounterPerWord(counter);
            int shift = 3 - ceil_log2(per_word);
            bitvec mask(0, hd->bit_width);
            hd_use.shifts[hd_use.slices[0]] = shift;
            hd_use.masks[hd_use.slices[0]] = mask;
        } else if (hdt == IXBar::HashDistUse::METER_ADR) {
            if (back_at->attached->is<IR::MAU::Meter>()) {
                int shift = 7;
                bitvec mask(0, hd->bit_width);
                hd_use.shifts[hd_use.slices[0]] = shift;
                hd_use.masks[hd_use.slices[0]] = mask;
            } else if (auto *salu = back_at->attached->to<IR::MAU::StatefulAlu>()) {
                int per_word = RegisterPerWord(salu);
                int shift = 7 - ceil_log2(per_word);
                bitvec mask(0, hd->bit_width);
                hd_use.shifts[hd_use.slices[0]] = shift;
                hd_use.masks[hd_use.slices[0]] = mask;
            }
        } else if (hdt == IXBar::HashDistUse::IMMEDIATE) {
            for (auto slice : hd_use.slices) {
                hd_use.shifts[slice] = 0;
                // FIXME: Can we just have a full mask for immediate here, or do we have to
                // adjust for the immediate size?
                bitvec mask(0, IXBar::HASH_DIST_BITS);
                hd_use.masks[slice] = mask;
            }
        }

        int group = hd_use.use.hash_dist_hash.group;
        for (auto slice : hd_use.slices)
            hd_use.groups[slice] = group;
    }

    /** Passes over all hash distribution uses within the IR and determines what their
     *  needs are.  Will allocate on the xbar, and setup the match central portion.
     */
    bool preorder(const IR::MAU::HashDist *hd) {
        if (!allocation_passed)
            return false;
        IXBar::HashDistUse::HashDistType hdt = IXBar::HashDistUse::UNKNOWN;
        if (findContext<IR::MAU::Instruction>()) {
            hdt = IXBar::HashDistUse::IMMEDIATE;
        } else if (auto back_at = findContext<IR::MAU::BackendAttached>()) {
            auto at_mem = back_at->attached;
            if (at_mem->is<IR::MAU::Counter>())
                hdt = IXBar::HashDistUse::COUNTER_ADR;
            else if (at_mem->is<IR::MAU::Meter>() || at_mem->is<IR::MAU::StatefulAlu>())
                hdt = IXBar::HashDistUse::METER_ADR;
        }

        IXBar::HashDistUse hd_use(hd->field_list);
        hd_use.type = hdt;
        if (!self.allocHashDist(hd, hdt, phv, hd_use.use, false, name) &&
            !self.allocHashDist(hd, hdt, phv, hd_use.use, true, name)) {
            allocation_passed = false;
            return false;
        }
        initialize_hash_dist_unit(hd, hd_use);
        alloc.hash_dists.push_back(hd_use);
        return false;
    }

    // In the IR::MAU::Action, there are two lists.  One is a list of instructions for
    // ALU operations, another is a list of counter/meter/stateful ALU externs saved
    // Because the hash distribution units are already saved on the BackendAttached objects,
    // we don't want to visit them in within the action in order to not double count
    bool preorder(const IR::Primitive *) {
        return false;
    }

    bool preorder(const IR::MAU::Instruction *) {
        return true;
    }

    void end_apply() {
        if (!allocation_passed) {
            alloc.hash_dists.clear();
        }
    }

    bool preorder(const IR::MAU::AttachedOutput *) {
        return false;
    }

    bool preorder(const IR::MAU::TableSeq *) {
        return false;
    }

 public:
    bool passed_allocation() { return allocation_passed; }

    XBarHashDist(IXBar &i, const PhvInfo &p, TableResourceAlloc &a, cstring n)
        : self(i), phv(p), alloc(a), name(n) {}
};

/** This is the general algorithm of the input xbar allocation.  This will allocate all
 *  needs for a table's input xbar, specifically xbar needs for the match, the gateway,
 *  selectors, stateful alu, and any hash distribution needs.  The allocation scheme is the
 *  following:
 *     - Find locations on the input xbar for bytes.
 *     - Once those locations are chosen, then make reservations within the hash matrix (if search
 *       data is on SRAM xbar) for these particular tables.
 *
 *  This occurs in two attempts.  First, attempt to share bytes on the ixbar wherever possible.
 *  If this doesn't work, due to hash matrix constraint, redo the allocation with input xbar
 *  locations that have no current hash matrix use
 */
bool IXBar::allocTable(const IR::MAU::Table *tbl, const PhvInfo &phv, TableResourceAlloc &alloc,
                       const LayoutOption *lo) {
    if (!tbl) return true;
    /* Determine number of groups needed.  Loop through them, alloc match will be the same
       for these.  Alloc All Hash Ways will required multiple groups, and may need to change  */
    LOG1("IXBar::allocTable(" << tbl->name << ")");
    if (!tbl->gateway_only() && !lo->layout.no_match_data() && !lo->layout.atcam) {
        bool ternary = tbl->layout.ternary;
        safe_vector<IXBar::Use::Byte *> alloced;
        safe_vector<Use> all_tbl_allocs;
        bool finished = false;
        size_t start = 0; size_t last = 0;
        while (!finished) {
            Use next_alloc;
            layout_option_calculation(lo, start, last);
            /* Essentially a calculation of how much space is potentially available */
            int hash_groups = (last - start > 4) ? 4 : last - start;
            if (!(allocMatch(ternary, tbl, phv, next_alloc, alloced, false, hash_groups)
                && allocAllHashWays(ternary, tbl, next_alloc, lo, start, last))
                && !(allocMatch(ternary, tbl, phv, next_alloc, alloced, true, hash_groups)
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
    } else if (tbl->layout.atcam) {
        safe_vector<IXBar::Use::Byte *> alloced;
        if (!allocMatch(false, tbl, phv, alloc.match_ixbar, alloced, false, 0)
            && !allocMatch(false, tbl, phv, alloc.match_ixbar, alloced, true, 0)) {
            alloc.match_ixbar.clear();
            alloced.clear();
            return false;
        } else {
            fill_out_use(alloced, false);
        }

        if (!allocPartition(tbl, phv, alloc.match_ixbar, false)
            && !allocPartition(tbl, phv, alloc.match_ixbar, true)) {
            alloc.match_ixbar.clear();
            return false;
        }
    }

    for (auto back_at : tbl->attached) {
        auto at_mem = back_at->attached;
        if (auto as = at_mem->to<IR::MAU::Selector>()) {
            if (!attached_tables.count(as) &&
                !allocSelector(as, tbl, phv, alloc.selector_ixbar, false, tbl->name) &&
                !allocSelector(as, tbl, phv, alloc.selector_ixbar, true, tbl->name)) {
                alloc.clear_ixbar();
                return false; } }
        if (auto salu = at_mem->to<IR::MAU::StatefulAlu>()) {
            if (!attached_tables.count(salu) &&
                !allocStateful(salu, phv, alloc.salu_ixbar, false) &&
                !allocStateful(salu, phv, alloc.salu_ixbar, true)) {
                alloc.clear_ixbar();
                return false; } } }

    if (!allocGateway(tbl, phv, alloc.gateway_ixbar, false) &&
        !allocGateway(tbl, phv, alloc.gateway_ixbar, true)) {
        alloc.clear_ixbar();
        return false; }

    XBarHashDist xbar_hash_dist(*this, phv, alloc, tbl->name);
    tbl->attached.apply(xbar_hash_dist);
    tbl->actions.apply(xbar_hash_dist);
    if (!xbar_hash_dist.passed_allocation()) {
        alloc.clear_ixbar();
        return false;
    }
    return true;
}

/** Fill in the information contained in the IXBar::Use object of a TableResourceAlloc into the
 *  IXBar structure, so that when a new table is allocated to the IXBar, the previous stage table
 *  resources are known
 */
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
            if (use[byte.loc].first) {
                BUG("conflicting ixbar allocation");
            }
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
    // If allocation uses hash distribution, update for hash distribution
    if (alloc.hash_dist_hash.allocated) {
        auto &hdh = alloc.hash_dist_hash;
        for (int i = 0; i < HASH_TABLES; i++) {
            if (((1U << i) & alloc.hash_table_inputs[hdh.group]) == 0) continue;

            // Save the bitmasks in the hash_dist_bit_(in)use
            for (auto bit : bitvec(hdh.bit_mask)) {
                 if (!hash_dist_bit_use[i][bit]) {
                     hash_dist_bit_use[i][bit] = name;
                 } else if (hash_dist_bit_use[i][bit] != name) {
                     BUG("Conflicting hash distribution bit allocation %s and %s",
                         name, hash_dist_bit_use[i][bit]);
                 }
            }
            hash_dist_bit_inuse[i] |= hdh.bit_mask;

            // Save the slice information inthe hash_dist_(in)use
            for (auto slice : bitvec(hdh.slice)) {
                if (!hash_dist_use[i][slice])
                    hash_dist_use[i][slice] = name;
            }
            hash_dist_inuse[i] |= hdh.slice;
        }

        hash_group_print_use[hdh.group] = name;
        hash_group_use[hdh.group] |= alloc.hash_table_inputs[hdh.group];
        if (hash_dist_groups[hdh.unit] != hdh.group && hash_dist_groups[hdh.unit] != -1)
            BUG("Conflicting hash distribution unit groups");
        hash_dist_groups[hdh.unit] = hdh.group;
    }
}

void IXBar::update(cstring name, const TableResourceAlloc *rsrc) {
    update(name + "$register", rsrc->salu_ixbar);
    update(name + "$select", rsrc->selector_ixbar);
    update(name + "$gw", rsrc->gateway_ixbar);
    update(name, rsrc->match_ixbar);
    int index = 0;
    for (auto hash_dist : rsrc->hash_dists)
        update(name + "$hash_dist" + std::to_string(index++), hash_dist.use);
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
