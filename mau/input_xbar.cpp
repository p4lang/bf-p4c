#include "gateway.h"
#include "input_xbar.h"
#include "resource.h"
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


void IXBar::Use::compute_hash_tables() {
    hash_table_input = 0;
    for (auto &b : use) {
        assert(b.loc.group >= 0 && b.loc.group < HASH_TABLES/2);
        unsigned grp = 1U << (b.loc.group * 2);
        if (b.loc.byte >= 8) grp <<= 1;
        hash_table_input |= grp; }
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
    int group;
    bitvec found;
    bitvec free;
    bool first_hash_open;
    bool second_hash_open;
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
   extra 12 hash bits */
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
        if (first_ways_available < hash_groups_needed)
            big_grp.first.first_hash_open = false;
        if (second_ways_available < hash_groups_needed)
            big_grp.first.second_hash_open = false;
    }
}

/* Calculates the bytes per each group that match any currently unallocated */
void IXBar::calculate_found(vector<IXBar::Use::Byte *> unalloced, vector<big_grp_use> &order,
                            bool ternary) {
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
                if (!ternary) {
                    if (p.byte / 8 == 0 && !order[p.group].first.first_hash_open)
                        continue;
                    if (p.byte / 8 == 1 && !order[p.group].first.second_hash_open)
                        continue;
                    order[p.group].first.found[p.byte] = true;
                    continue;
                }


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
                                 int bytes_per_big_group) {
    auto &use = this->use(false);
    for (int grp = 0; grp < big_groups; grp++) {
        for (int byte = 0; byte < bytes_per_big_group; byte++) {
            if (byte < 8 && !order[grp].first.first_hash_open)
                continue;
            if (byte > 8 && !order[grp].first.second_hash_open)
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
                      vector<IXBar::Use::Byte *> &alloced, bool ternary) {
    int bytes_placed = 0;
    int free_bytes = grp->free.popcount();
    for (int i = 0; i < static_cast<int>(unalloced.size()); i++) {
        if (free_bytes == 0)
            break;
        auto &need = *(unalloced[i]);
        int align = ternary ? ((grp->group * 11 + 1)/2) & 3 : 0;
        for (auto byte : grp->free) {
            if (align_flags[(byte+align) & 3] & need.flags) {
                 continue;
            }
            allocate_free_byte(grp, unalloced, alloced, need, grp->group, byte,
                               i, free_bytes, bytes_placed);
            break;
        }
    }
    LOG4("Total free bytes placed was " << bytes_placed);
    return bytes_placed;
}

/* Fills out all currently unoccupied xbar bytes within a group with bytes from the current table
   following alignment constraints.  Specifically designed to handle the allocation of a large
   ternary group */
int IXBar::free_bytes_big_group(big_grp_use *grp, vector<IXBar::Use::Byte*> &unalloced,
                                vector<IXBar::Use::Byte *> &alloced) {
    int bytes_placed = 0;
    int free_bytes = grp->total_free();

    for (int i = 0; i < static_cast<int>(unalloced.size()); i++) {
        bool found = false;
        if (free_bytes == 0)
            break;

        auto &need = *(unalloced[i]);
        int align = (grp->big_group * (2 * TERNARY_BYTES_PER_GROUP + 1)) & 3;

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
    LOG4("Total free bytes placed was " << bytes_placed);
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
                          int big_groups_needed, int &total_bytes_needed, int bytes_per_big_group) {
    while (big_groups_needed > 1) {
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
            bytes_placed += free_bytes_big_group(&order[0], unalloced, alloced);
        } else {
            LOG4("SRAM group selected was " << order[0].first.group);
            bytes_placed += found_bytes(&order[0].first, unalloced, ternary);
            bytes_placed += free_bytes(&order[0].first, unalloced, alloced, ternary);
        }

        /* No bytes placed in the xbar.  You're finished */
        if (bytes_placed == 0) {
            return false;
        }
        total_bytes_needed -= bytes_placed;
        /* FIXME: Need some calculations for 88 bit multiples */
        big_groups_needed = (total_bytes_needed + bytes_per_big_group - 1)/bytes_per_big_group;
        calculate_found(unalloced, order, ternary);
    }
    return true;
}

/* This allocation scheme is used when only one SRAM xbar or 2 TCAM xbars are needed, as the middle
   byte is no longer available to be used by the TCAM xbar due to version restrictions. */
bool IXBar::small_grp_alloc(bool ternary, bool second_try, vector<IXBar::Use::Byte *> &unalloced,
                            vector<IXBar::Use::Byte *> &alloced, vector<grp_use *> &small_order,
                            vector<big_grp_use> &order, int &total_bytes_needed) {
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
        bytes_placed += free_bytes(small_order[0], unalloced, alloced, ternary);
        /* No bytes placed in the xbar.  You're finished */
        if (bytes_placed == 0) {
            return false;
        }
        total_bytes_needed -= bytes_placed;
        calculate_found(unalloced, order, ternary);
    }
    return true;
}

/* The algorithm for allocation of bytes from the table on to the input xbar.  Both for
   TCAM and SRAM xbar.  Overall algorithm looks at the size of the allocation.  If the allocation
   spans a group, tries to minimize total number of groups while finding the best groups to fill.
   If the allocation is less than a group, tries to find the best fit  */
bool IXBar::find_alloc(IXBar::Use &alloc, bool ternary, bool second_try,
                       vector<IXBar::Use::Byte *> &alloced, int hash_groups_needed) {
    /* Initial sizing calculations*/
    int groups = ternary ? TERNARY_GROUPS : EXACT_GROUPS;
    int big_groups = ternary ? TERNARY_GROUPS/2 : EXACT_GROUPS;
    int bytes_per_big_group = ternary ? 11 : EXACT_BYTES_PER_GROUP;

    int total_bytes_needed = alloc.use.size();
    LOG4("Total Bytes needed to allocate is " << total_bytes_needed);
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
    for (auto &need : alloc.use) {
        unalloced.push_back(&need);
    }
    if (!ternary) {
        calculate_available_groups(order, hash_groups_needed);
    }

    /* Initial found and free calculations */
    calculate_found(unalloced, order, ternary);

    if (ternary) {
        calculate_ternary_free(order, big_groups, bytes_per_big_group);
    } else {
        calculate_exact_free(order, big_groups, bytes_per_big_group);
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
                       total_bytes_needed, bytes_per_big_group)) {
        return false; }

    // Only one large group at most is necessary
    if (!small_grp_alloc(ternary, second_try, unalloced, alloced, small_order, order,
                         total_bytes_needed)) {
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

static void add_use(IXBar::Use &alloc, const PhvInfo::Field *field,
                    const PhvInfo::Field::bitrange *bits = nullptr, int flags = 0) {
    bool ok = false;
    field->foreach_byte(bits, [&](const PhvInfo::Field::alloc_slice &sl) {
        ok = true;  // FIXME -- better sanity check?
        alloc.use.emplace_back(field->name, sl.field_bit, sl.field_hi());
        alloc.use.back().flags |=
            flags | need_align_flags[sl.container.log2sz()][(sl.container_bit/8U) & 3]; });
    if (!ok)
        BUG("field %s allocated to tagalong but used in MAU pipe", field->name);
}

bool IXBar::allocMatch(bool ternary, const IR::V1Table *tbl, const PhvInfo &phv, Use &alloc,
                       vector<IXBar::Use::Byte *> &alloced, bool second_try, int hash_groups) {
    alloc.ternary = ternary;
    if (!tbl->reads) return true;
    set<cstring>                        fields_needed;
    bool                                rv;
    for (auto r : *tbl->reads) {
        auto *field = r;
        if (auto mask = r->to<IR::Mask>()) {
            field = mask->left;
        } else if (auto prim = r->to<IR::Primitive>()) {
            if (prim->name != "valid")
                BUG("unexpected reads expression %s", r);
            // FIXME -- for now just assuming we can fit the valid bit reads in as needed
            continue; }
        const PhvInfo::Field *finfo;
        PhvInfo::Field::bitrange bits;
        if (!field || !(finfo = phv.field(field, &bits)))
            BUG("unexpected reads expression %s", r);
        if (fields_needed.count(finfo->name))
            throw Util::CompilationError("field %s read twice by table %s", finfo->name, tbl->name);
        fields_needed.insert(finfo->name);
        add_use(alloc, finfo, &bits); }
    LOG3("need " << alloc.use.size() << " bytes for table " << tbl->name);
    LOG3("need fields " << fields_needed);

    rv = find_alloc(alloc, ternary, second_try, alloced, hash_groups);
    if (!ternary && rv)
        alloc.compute_hash_tables();
    if (!rv) alloc.clear();
    LOG1("Done");
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
             hash_group_use[i] = hash_table_input;
             return i;
         }
    }
    for (int i = 0; i < HASH_GROUPS; i++) {
         if (hash_group_use[i] == 0) {
             hash_group_use[i] = hash_table_input;
             return i;
         }
    }

    LOG2("failed to allocate hash group");
    return -1;
}


// FIXME: This is a very temporary patch to solve the hashing issue.  Hashing
// needs a much greater analysis
bool IXBar::allocAllHashWays(bool ternary, const IR::MAU::Table *tbl, Use &alloc) {
    if (ternary)
        return true;
    int hash_group = getHashGroup(alloc.hash_table_input);
    if (hash_group < 0) return false;
    int free_groups = 0;
    int group;
    for (group = 0; group < HASH_INDEX_GROUPS; group++) {
        if (!(hash_index_inuse[group] & alloc.hash_table_input)) {
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
        if (!(hash_single_bit_inuse[bit] & alloc.hash_table_input)) {
            way_bits++;
        }
    }
    if (way_bits == 0 && way_bits_needed > 0) {
        alloc.clear();
        return false;
    }
    // Currently should  never return false
    for (auto &way : tbl->ways) {
        if (!allocHashWay(tbl, way, alloc)) {
            alloc.clear();
            return false; } }

    for (int bit = 0; bit < HASH_SINGLE_BITS; bit++) {
        LOG3("Hash bit at bit " << bit << " is " << hash_single_bit_inuse[bit]);
    }
    return true;
}


bool IXBar::allocHashWay(const IR::MAU::Table *tbl, const IR::MAU::Table::Way &way, Use &alloc) {
    int hash_group = getHashGroup(alloc.hash_table_input);
    if (hash_group < 0) return false;
    int way_bits = ceil_log2(way.entries/1024U/way.match_groups);
    int group;
    LOG3("Hash group is " << hash_group);
    unsigned way_mask = 0;
    LOG3("Need " << way_bits << " mask bits for way " << alloc.way_use.size() <<
         " in table " << tbl->name);
    for (group = 0; group < HASH_INDEX_GROUPS; group++) {
        if (!(hash_index_inuse[group] & alloc.hash_table_input)) {
            break; } }
    if (group >= HASH_INDEX_GROUPS) {
        if (alloc.way_use.empty())
            group = 0;  // share with another table?
        else
            group = alloc.way_use[alloc.way_use.size() % way_groups_allocated(alloc)].slice;
        LOG3("all hash slices in use, reusing " << group); }
    for (int bit = 0; bit < HASH_SINGLE_BITS; bit++) {
        if (way_bits <= 0) break;
        if (!(hash_single_bit_inuse[bit] & alloc.hash_table_input)) {
            way_mask |= 1U << bit;
            way_bits--; } }
    if (way_bits > 0)
        LOG3("failed to allocate enough way mask bits, will need to reuse some");
    alloc.way_use.emplace_back(Use::Way{ hash_group, group, way_mask });
    hash_index_inuse[group] |= alloc.hash_table_input;
    LOG3("The way_mask is " << way_mask);
    for (auto bit : bitvec(way_mask))
        hash_single_bit_inuse[bit] |= alloc.hash_table_input;
    for (auto ht : bitvec(alloc.hash_table_input)) {
        hash_index_use[ht][group] = tbl->name;
        for (auto bit : bitvec(way_mask))
            hash_single_bit_use[ht][bit] = tbl->name; }
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
    LOG1("Total bytes out is " << alloc.gw_search_bus_bytes);
    vector<IXBar::Use::Byte *> xbar_alloced;
    if (!find_alloc(alloc, false, second_try, xbar_alloced, 0)) {
        alloc.clear();
        return false; }
    if (!collect.compute_offsets()) {
        alloc.clear();
        LOG3("collect.compute_offsets failed?");
        return false; }
    LOG3("Collect bits is " << collect.bits);
    if (collect.bits > 0) {
        alloc.compute_hash_tables();
        int hash_group = getHashGroup(alloc.hash_table_input);
        if (hash_group < 0) {
            alloc.clear();
            return false; }
        /* FIXME -- don't need use all hash tables that we're using the ixbar for -- just those
         * tables for bytes we want to put through the hash table to get into the upper gw bits */
        unsigned avail = 0;
        unsigned need = (1U << collect.bits) - 1;
        for (auto i : Range(0, HASH_SINGLE_BITS-1)) {
            if ((hash_single_bit_inuse[i] & alloc.hash_table_input) == 0)
                avail |= (1U << i); }
        int shift = 0;
        LOG3("Avail is " << avail);
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
                alloc.bit_use.emplace_back(info.first->name, hash_group, 0,
                                           offset.first - 32, offset.second.size()); } }
        for (auto &valid : collect.valid_offsets) {
            LOG3("Valid.second " << valid.second);
            if (valid.second < 32) continue;
            valid.second += shift;
            alloc.bit_use.emplace_back(valid.first + ".$valid", hash_group, 0,
                                       valid.second - 32, 1); }
        LOG3("Before bit_use size is " << alloc.bit_use.size());
        for (auto ht : bitvec(alloc.hash_table_input))
            for (int i = 0; i < collect.bits; ++i)
                hash_single_bit_use[ht][shift + i] = tbl->name + "$gw";
        for (int i = 0; i < collect.bits; ++i)
            hash_single_bit_inuse[shift + i] |= alloc.hash_table_input; }
    LOG1("Totally allocated");
    fill_out_use(xbar_alloced, false);
    for (int bit = 0; bit < HASH_SINGLE_BITS; bit++) {
        LOG3("Hash bit at bit " << bit << " is " << hash_single_bit_inuse[bit]);
    }
    return true;
}

bool IXBar::allocTable(const IR::MAU::Table *tbl, const PhvInfo &phv,
                       Use &tbl_alloc, Use &gw_alloc) {
    if (!tbl) return true;
    LOG1("IXBar::allocTable(" << tbl->name << ")");
    if (tbl->match_table) {
        int hash_groups = tbl->ways.size() > 4 ? 4 : tbl->ways.size();
        bool ternary = tbl->layout.ternary;
        vector <IXBar::Use::Byte *> alloced;
        if (!(allocMatch(ternary, tbl->match_table, phv, tbl_alloc, alloced, false, hash_groups)
              && allocAllHashWays(ternary, tbl, tbl_alloc))
            && !(allocMatch(ternary, tbl->match_table, phv, tbl_alloc, alloced, true, hash_groups)
               && allocAllHashWays(ternary, tbl, tbl_alloc))) {
            tbl_alloc.clear();
            return false;
        } else {
            fill_out_use(alloced, ternary);
        }
    }
    if (!allocGateway(tbl, phv, gw_alloc, false) && !allocGateway(tbl, phv, gw_alloc, true)) {
        gw_alloc.clear();
        tbl_alloc.clear();
        return false; }
    return true;
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
    LOG3("Bit_use size is " << alloc.bit_use.size());
    for (auto &bits : alloc.bit_use) {
        const Loc *loc = nullptr;
        for (int b = 0; b < bits.width; b++) {
            if ((!loc || loc->byte != (b + bits.lo)/8) &&
                !(loc = findExactByte(bits.field, (b + bits.lo)/8)))
                BUG("ixbar hashing bits from %s, but they're not on the bus", bits.field);
            for (auto ht : bitvec(alloc.hash_table_input)) {
                if (hash_single_bit_use.at(ht, b + bits.bit))
                    BUG("conflicting ixbar hash bit allocation");
                hash_single_bit_use.at(ht, b + bits.bit) = name; }
            hash_single_bit_inuse[b + bits.bit] |= alloc.hash_table_input; }
        if (hash_group_use[bits.group] == 0) {
            hash_group_use[bits.group] = alloc.hash_table_input;
            hash_group_print_use[bits.group] = name;
        } else if (hash_group_use[bits.group] != alloc.hash_table_input) {
            BUG("conflicting hash group use between %s and %s", name, hash_group_use[bits.group]);
        }
    }
    for (auto &way : alloc.way_use) {
        if (hash_group_use[way.group] == 0) {
            hash_group_use[way.group] = alloc.hash_table_input;
            hash_group_print_use[way.group] = name;
        }
        hash_index_inuse[way.slice] |= alloc.hash_table_input;
        for (int hash : bitvec(alloc.hash_table_input)) {
            if (!hash_index_use[hash][way.slice])
                hash_index_use[hash][way.slice] = name;
            for (auto bit : bitvec(way.mask)) {
                hash_single_bit_inuse[bit] |= alloc.hash_table_input;
                if (!hash_single_bit_use[hash][bit])
                    hash_single_bit_use[hash][bit] = name; } } }
}

void IXBar::update(cstring name, const TableResourceAlloc *rsrc) {
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
