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
    hash_group_use.clear();
    memset(hash_single_bit_inuse, 0, sizeof(hash_single_bit_inuse));
}

int IXBar::Use::groups() const {
    int rv = 0;
    unsigned counted = 0;
    for (auto &b : use) {
        //LOG1("Before assert " << b);
        assert(b.loc.group >= 0 && b.loc.group < 16);
        if (!(1 & (counted >> b.loc.group))) {
            ++rv;
            counted |= 1U << b.loc.group; } }
    return rv;
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

struct grp_use {
    int group;
    bitvec found;
    bitvec free;
    void dbprint(std::ostream &out) const {
        out << group << " found: " << found << " free: " << free;
    };
};
struct big_grp_use {
    int big_group;
    grp_use first;
    grp_use second;
    bool mid_byte_found;
    bool mid_byte_free;
    void dbprint(std::ostream &out) const {
        out << big_group << " : found=" << first.found << " " << mid_byte_found << " " << second.found 
                       << " : free= " << first.free  << " " << mid_byte_free  << " " << second.free; }
    int total_found() const { return first.found.popcount() + second.found.popcount() + mid_byte_found; }
    int total_free() const { return first.free.popcount() + second.free.popcount() + mid_byte_free; }
    int total_used() const { return total_found() + total_free(); }
    int better_group() const {
        int first_open = first.free.popcount() + first.found.popcount();
        int second_open = second.free.popcount() + second.found.popcount();
        if (first_open >= second_open)
             return first_open;
        return second_open;
    }
};

void IXBar::calculate_found(vector<IXBar::Use::Byte *> unalloced, vector<big_grp_use> &order, bool ternary) { 
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
                    order[p.group].first.found[p.byte] = true;
                    continue;
                }


                if (p.group % 2) {
                    order[p.group/2].second.found[p.byte] = true;
                } else {
                                                 //&need - unalloced.data()
                    order[p.group/2].first.found[p.byte] = true;
                }
            }
        }
    }
}

void IXBar::calculate_ternary_free(vector<big_grp_use> &order, int big_groups, int bytes_per_big_group) {
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

void IXBar::calculate_exact_free(vector<big_grp_use> &order, int big_groups, int bytes_per_big_group) {
    auto &use = this->use(false);
    for (int grp = 0; grp < big_groups; grp++) {
        for (int byte = 0; byte < bytes_per_big_group; byte++) {
            if (!use[grp][byte].first)
                order[grp].first.free[byte] = true;
        }
    }
}

void IXBar::delete_placement(IXBar::Use &alloc, vector<IXBar::Use::Byte *> &alloced) {
    LOG1("We deleting this sucka");
    for (auto &need : alloc.use) {
        need.loc.byte = -1;
        need.loc.group = -1;
    }
    alloced.clear();
}

int IXBar::found_bytes(grp_use *grp, vector<IXBar::Use::Byte *> &unalloced, bool ternary) {
    auto &use = this->use(ternary);
    auto &fields = this->fields(ternary);
    int found_bytes = grp->found.popcount();
    int bytes_placed = 0;

    for (size_t i = 0; i < unalloced.size(); i++)
    {
        auto &need = *(unalloced[i]);
        if (found_bytes == 0)
            break;
        for (auto &p : Values(fields.equal_range(need.field))) {
            

            if ((grp->group == p.group) && (use[p.group][p.byte].second == need.lo)) {
                unalloced[i]->loc = p;
                found_bytes--; bytes_placed++;
                unalloced.erase(unalloced.begin() + i);
                i--;
            }
        }
    }
    LOG1("Found bytes allocated is " << bytes_placed);
    return bytes_placed;
}

int IXBar::found_bytes_big_group(big_grp_use *grp, vector<IXBar::Use::Byte *> &unalloced) {

    auto &use = this->use(true);
    auto &fields = this->fields(true);
    int found_bytes = grp->total_found();
    int bytes_placed = 0;
    for (int i = 0; i < (int) unalloced.size(); i++)
    {
        auto &need = *(unalloced[i]);
        if (found_bytes == 0)
            break;
        for (auto &p : Values(fields.equal_range(need.field))) {
            if (p.byte == 5) {
                if ((grp->big_group == p.group/2) && (byte_group_use[p.group].second == need.lo)) {
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
    return bytes_placed;
}

void IXBar::allocate_free_byte(grp_use *grp, vector<IXBar::Use::Byte *> &unalloced,
                               vector<IXBar::Use::Byte *> &alloced, IXBar::Use::Byte &need,
                               int group, int byte, int &index, int &free_bytes, int &bytes_placed)
{
    need.loc.group = group;
    need.loc.byte = byte;
    //FIXME: Necessary for non-ternary change
    if (grp != nullptr)
        grp->free[byte] = false;
   
    alloced.push_back(unalloced[index]);
    unalloced.erase(unalloced.begin() + index);
    index--;
    free_bytes--;
    bytes_placed++;
}

int IXBar::free_bytes(grp_use *grp, vector<IXBar::Use::Byte *> &unalloced,
                      vector<IXBar::Use::Byte *> &alloced, bool ternary) {

    int bytes_placed = 0;
    int free_bytes = grp->free.popcount();
    for (int i = 0; i < (int) unalloced.size(); i++) {
        if (free_bytes == 0)
            break;
        auto &need = *(unalloced[i]);
        int align = ternary ? ((grp->group * 11 + 1)/2) & 3 : 0;
        for (auto byte : grp->free) {
            if (align_flags[(byte+align) & 3] & need.flags) continue;
            allocate_free_byte(grp, unalloced, alloced, need,
                               grp->group, byte, i, free_bytes, bytes_placed);
            break;
        }
    }
    LOG1("Free bytes allocated is " << bytes_placed);
    return bytes_placed;
}

int IXBar::free_bytes_big_group(big_grp_use *grp, vector<IXBar::Use::Byte*> &unalloced,
                                vector<IXBar::Use::Byte *> &alloced) {
    int bytes_placed = 0;
    int free_bytes = grp->total_free();

    for (int i = 0; i < (int) unalloced.size(); i++) {
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
            if (align_flags[(byte + TERNARY_BYTES_PER_GROUP + 1 + align) & 3] & need.flags) continue;
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


void IXBar::fill_out_use(vector<IXBar::Use::Byte *> &alloced, bool ternary) {
    auto &use = this->use(ternary);
    auto &fields = this->fields(ternary);
    for (auto &need : alloced) {
        LOG1("Allocating new space for need " << need);
        fields.emplace(need->field, need->loc);
        if (ternary && need->loc.byte == 5)
            byte_group_use[need->loc.group/2] = *(need);
        else
            use[need->loc] = *(need);
    }
}

bool IXBar::find_alloc(IXBar::Use &alloc, bool ternary, bool second_try, vector<IXBar::Use::Byte *> alloced) {
    int groups = ternary ? TERNARY_GROUPS : EXACT_GROUPS;
    int big_groups = ternary ? TERNARY_GROUPS/2 : EXACT_GROUPS;
    int bytes_per_big_group = ternary ? 11 : EXACT_BYTES_PER_GROUP;
    auto &use = this->use(ternary);
    auto &fields = this->fields(ternary);
    
    int total_bytes_needed = alloc.use.size();
    LOG1("Total Bytes needed to allocate is " << total_bytes_needed);
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

    /* Initialize all required information */
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
    //vector<IXBar::Use::Byte *> alloced;
    for (auto &need : alloc.use) {
        unalloced.push_back(&need);
    }


    /* figure out how many needed bytes have already been allocated to each group the xbar */
    calculate_found(unalloced, order, ternary);

    /* and how many (and which) bytes are still free in each group */
    if (ternary) {
        calculate_ternary_free(order, big_groups, bytes_per_big_group);
    } else {
        calculate_exact_free(order, big_groups, bytes_per_big_group);
    }
    LOG1("Before Allocation Check");
  
    if (ternary) {
        for (int grp = 0; grp < big_groups; grp++)
            LOG1("Big Group " << order[grp]);
    } else { 
        for (int grp = 0; grp < groups; grp++)
            LOG1("Small Group " << *(small_order[grp]));
    }
    /* While a middle byte in a ternary group is definitely necessary */ 
    while (big_groups_needed > 1) {
        int reduced_bytes_needed = total_bytes_needed % bytes_per_big_group;
        if (reduced_bytes_needed == 0)
            reduced_bytes_needed += bytes_per_big_group;

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
            bytes_placed += found_bytes_big_group(&order[0], unalloced);
            bytes_placed += free_bytes_big_group(&order[0], unalloced, alloced);       
        } else {
            bytes_placed += found_bytes(&order[0].first, unalloced, ternary);
            bytes_placed += free_bytes(&order[0].first, unalloced, alloced, ternary);
        }

        /* No bytes placed in the xbar.  You're finished */
        if (bytes_placed == 0) {
            delete_placement(alloc, alloced);
            return false;
        }

        total_bytes_needed -= bytes_placed;
        /* FIXME: Need some calculations for 88 bit multiples */
        big_groups_needed = (total_bytes_needed + bytes_per_big_group - 1)/bytes_per_big_group;
        
        calculate_found(unalloced, order, ternary);
    }


    

    int bytes_needed = total_bytes_needed;
    if (ternary && bytes_needed > 5) {
        bytes_needed /= 2;
    }
  
    while (total_bytes_needed != 0) {

        std::sort(small_order.begin(), small_order.end(), [=](const grp_use *ap, const grp_use *bp) {
       
            if (!second_try && (ap->free.popcount() + ap->found.popcount() < bytes_needed))
                return false;
            if (!second_try && (bp->free.popcount() + bp->found.popcount() < bytes_needed))
                return true;
            int t;
            if (!second_try && (t = ap->found.popcount() - bp->found.popcount()) != 0)
                return t > 0;
       
            int r = total_bytes_needed - ap->found.popcount();
            int s = total_bytes_needed - bp->found.popcount();
        
            //Best fit in terms of free bits left
            if (!second_try && (t = (bp->free.popcount() - s) - (ap->free.popcount() - r)) != 0)
                return t > 0;
        
            if ((t = ap->free.popcount() - bp->free.popcount()) != 0) return t > 0;
            return (ap->group < bp->group); 
        });

        
        int bytes_placed = 0;
        /* Remove all bytes previously found */
        bytes_placed += found_bytes(small_order[0], unalloced, ternary);
        /* Place all free locations */
        bytes_placed += free_bytes(small_order[0], unalloced, alloced, ternary);
 
        /* No bytes placed in the xbar.  You're finished */
        if (bytes_placed == 0) {
            delete_placement(alloc, alloced);
            return false;
        }

        total_bytes_needed -= bytes_placed;
        calculate_found(unalloced, order, ternary);
    }

    /* Place all of the newly allocated fields into their new spot */
    //fill_out_use(alloced, ternary);

    LOG1("The thing is done");
    if (ternary) {
        for (int grp = 0; grp < big_groups; grp++)
            LOG1("Big Group " << order[grp]);
    } else { 
        for (int grp = 0; grp < groups; grp++)
            LOG1("Small Group " << *(small_order[grp]));
    }
    return true;
}

/*
bool IXBar::find_original_alloc(IXBar::Use &alloc, bool ternary, bool second_try) {
    int groups = ternary ? TERNARY_GROUPS : EXACT_GROUPS;
    int bytes_per_group = ternary ? TERNARY_BYTES_PER_GROUP : EXACT_BYTES_PER_GROUP;
    auto &use = this->use(ternary);
    auto &fields = this->fields(ternary);
    int groups_needed = (alloc.use.size() + bytes_per_group - 1)/bytes_per_group;

    
 
    if (!ternary)
        LOG3("Groups Needed is " << groups_needed << " with the allocated size at " << alloc.use.size());

    if (groups_needed > groups)
        return false;
    struct original_grp_use {
        int     group;
        bitvec  found,  // bytes from alloc found already allocated in this group
                free;   // bytes in this group available for use
        void dbprint(std::ostream &out) const {
            out << group << ": found=" << found << " free=" << free; }
    };
    vector<original_grp_use> order(groups);
    for (int i = 0; i < groups; i++) order[i].group = i;
    // figure out how many needed bytes have already been allocated to each group the xbar
    for (auto &need : alloc.use)
        for (auto &p : Values(fields.equal_range(need.field)))
            if (use[p.group][p.byte].second == need.lo)
                order[p.group].found[&need - alloc.use.data()] = true;
    // and how many (and which) bytes are still free in each group
    for (int grp = 0; grp < groups; grp++)
        for (int byte = 0; byte < bytes_per_group; byte++)
            if (!use[grp][byte].first)
                order[grp].free[byte] = true;

    if (ternary) {
       LOG3("Ternary Check 2");
       for (int grp = 0; grp < groups; grp++)
           LOG3("Group " << order[grp]);

    }
    // sort group pref order: prefer groups with most bytes already in, then most free
    std::sort(order.begin(), order.end(), [=](const original_grp_use &a, const original_grp_use &b) {
        int t;
        if (!second_try && (t = a.found.popcount() - b.found.popcount()) != 0) return t > 0;
        if ((t = a.free.popcount() - b.free.popcount()) != 0) return t > 0;
        return a.group < b.group; });
    LOG3("Order: " << order);
    // figure out which group(s) to use 
    bitvec groups_to_use, found_bytes;
    unsigned space_free = 0;
    for (int i = 0; i < groups && found_bytes.popcount() + space_free < alloc.use.size(); i++) {
        groups_to_use[order[i].group] = true;
        found_bytes |= order[i].found;
        space_free += order[i].free.popcount(); }
    // now try to allocate all bytes to those groups
    if (found_bytes.popcount() + space_free < alloc.use.size()) return false;
    LOG4("Found bytes is " << found_bytes);

    if (!ternary && groups_needed > 1) {
        if (groups_to_use.popcount() != groups_needed)
            LOG3("WE GOT PROBLEMS"); 
        LOG3("Groups to use is " << groups_to_use.popcount() << " and groups needed is " << groups_needed);
    }
    bitvec need_alloc;
    for (auto &need : alloc.use) {

        bool found = false;
        LOG4("Test " << alloc.use << " " << &need - alloc.use.data() << " " << found_bytes[&need - alloc.use.data()]);
        if (found_bytes[&need - alloc.use.data()]) {
            for (auto &p : Values(fields.equal_range(need.field)))
                if (groups_to_use[p.group] && use[p.group][p.byte].second == need.lo) {
                    need.loc = p;
                    found = true;
                    break; }
            assert(found);
            continue; }
        for (auto &grp : order) {
            if (!groups_to_use[grp.group] && !second_try) break;

            if (!ternary && groups_needed > 1 && groups_to_use.popcount() != groups_needed) {
                LOG3("Group is " << grp);
            }
  
            int align = (ternary ? (grp.group * 11 + 1)/2 : 0) & 3;
            for (auto byte : grp.free) {
                if (align_flags[(byte+align)&3] & need.flags) continue;
                need_alloc[&need - &alloc.use[0]] = true;
                need.loc.group = grp.group;
                need.loc.byte = byte;
                grp.free[byte] = false;
                found = true;
                break; }
            if (found) break; }
        if (!found) {
            LOG3("failed to fit");
            return false; } }
    // succeded -- update the use info
    for (int i : need_alloc) {
        fields.emplace(alloc.use[i].field, alloc.use[i].loc);
        use[alloc.use[i].loc] = alloc.use[i]; }
    for (int grp = 0; grp < groups; grp++)
         LOG1("Small Group " << order[grp]);
    return  true;
}*/

int need_align_flags[3][4] = { { 0, 0, 0, 0 },  // 8bit -- no alignment needed
    { IXBar::Use::Align16lo, IXBar::Use::Align16hi, IXBar::Use::Align16lo, IXBar::Use::Align16hi },
    { IXBar::Use::Align16lo | IXBar::Use::Align32lo,
      IXBar::Use::Align16hi | IXBar::Use::Align32lo,
      IXBar::Use::Align16lo | IXBar::Use::Align32hi,
      IXBar::Use::Align16hi | IXBar::Use::Align32hi } };

static void add_use(IXBar::Use &alloc, const PhvInfo::Field *field, int flags) {
    if (field->alloc.empty()) {
        for (int i = 0; i < field->size; i += 8) {
            alloc.use.emplace_back(field->name, i, std::min(i + 7, field->size - 1));
            alloc.use.back().flags = flags; }
    } else {
        bool ok = false;
        PHV::Container prev_container;
        unsigned prev_cbyte;
        /* DANGER: field->alloc is sort msb to lsb and we want lsb to msb */
        for (auto it = field->alloc.rbegin(); it != field->alloc.rend(); ++it) {
            if (it->container.tagalong()) continue;
            ok = true;  // FIXME -- better sanity check?
            unsigned lo = it->container_bit, hi = it->container_hi(), sz = it->container.log2sz();
            for (unsigned cbyte = lo/8U; cbyte <= hi/8U; ++cbyte) {
                if (it->container != prev_container || cbyte != prev_cbyte) {
                    int flo = it->field_bit;
                    if (cbyte*8 > lo) flo += cbyte*8 - lo;
                    int fhi = it->field_hi();
                    if (cbyte*8+7 < hi) fhi -= hi - (cbyte*8+7);
                    alloc.use.emplace_back(field->name, flo, fhi);
                    alloc.use.back().flags |=  flags | need_align_flags[sz][cbyte & 3];
                    prev_container = it->container;
                    prev_cbyte = cbyte;
                } else {
                    int fhi = it->field_hi();
                    if (cbyte*8+7 < hi) fhi -= hi - (cbyte*8+7);
                    alloc.use.back().hi = fhi; } } }
        if (!ok)
            BUG("field %s allocated to tagalong but used in MAU pipe", field->name); }
}

bool IXBar::allocMatch(bool ternary, const IR::V1Table *tbl, const PhvInfo &phv, Use &alloc) {
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
        if (!field || !(finfo = phv.field(field)))
            BUG("unexpected reads expression %s", r);
        if (fields_needed.count(finfo->name))
            throw Util::CompilationError("field %s read twice by table %s", finfo->name, tbl->name);
        fields_needed.insert(finfo->name);
        add_use(alloc, finfo, 0); }
    LOG1("need " << alloc.use.size() << " bytes for table " << tbl->name);
    LOG3("need fields " << fields_needed);
    rv = find_alloc(alloc, ternary, false) || find_alloc(alloc, ternary, true);
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

int IXBar::getHashGroup(cstring name) {
    int hash_group = find(hash_group_use, name) - hash_group_use.begin();
    if (hash_group >= HASH_GROUPS)
        hash_group = find(hash_group_use, cstring()) - hash_group_use.begin();
    if (hash_group >= HASH_GROUPS) {
        LOG2("failed to allocate hash group");
        return -1; }
    hash_group_use[hash_group] = name;
    return hash_group;
}

bool IXBar::allocHashWay(const IR::MAU::Table *tbl, const IR::MAU::Table::Way &way, Use &alloc) {
    int hash_group = getHashGroup(tbl->name);
    if (hash_group < 0) return false;
    int way_bits = ceil_log2(way.entries/1024U/way.match_groups);
    int group;
    unsigned way_mask = 0;
    LOG3("Need " << way_bits << " mask bits for way " << alloc.way_use.size() <<
         " in table " << tbl->name);
    for (group = 0; group < HASH_INDEX_GROUPS; group++) {
        if (!(hash_index_inuse[group] & alloc.hash_table_input))
            break; }
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

bool IXBar::allocGateway(const IR::MAU::Table *tbl, const PhvInfo &phv, Use &alloc, bool second_try) {
    CollectGatewayFields collect(phv);
    tbl->apply(collect);
    if (collect.info.empty() && collect.valid_offsets.empty()) return true;
    for (auto &info : collect.info) {
        int flags = 0;
        if (info.second.xor_with)
            flags |= IXBar::Use::NeedXor;
        if (info.second.need_range)
            flags |= IXBar::Use::NeedRange;
        add_use(alloc, info.first, flags); }
    for (auto &valid : collect.valid_offsets) {
        alloc.use.emplace_back(valid.first + ".$valid", 0, 0); }
    LOG3("gw needs alloc: " << alloc.use);
    vector<IXBar::Use::Byte *> xbar_alloced;
    if (!find_alloc(alloc, false, second_try, xbar_alloced) && !find_alloc(alloc, false, true, xbar_alloced)) {
        alloc.clear();
        return false; }
    if (!collect.compute_offsets()) {
        alloc.clear();
        LOG3("collect.compute_offsets failed?");
        return false; }
    if (collect.bits > 0) {
        int hash_group = getHashGroup(tbl->name + "$gw");
        if (hash_group < 0) {
            delete_placement(alloc, xbar_alloced);
            return false; }
        /* FIXME -- don't need use all hash tables that we're using the ixbar for -- just those
         * tables for bytes we want to put through the hash table to get into the upper gw bits */
        alloc.compute_hash_tables();
        unsigned avail = 0;
        unsigned need = (1U << collect.bits) - 1;
        for (auto i : Range(0, HASH_SINGLE_BITS-1)) {
            if ((hash_single_bit_inuse[i] & alloc.hash_table_input) == 0)
                avail |= (1U << i); }
        int shift = 0;
        while (((avail >> shift) & need) != need && shift < 12) {
            shift += 4;
            LOG3("Still looping");
        }
        if (((avail >> shift) & need) != need) {
            delete_placement(alloc, xbar_alloced);
            LOG3("failed to find " << collect.bits << " continuous nibble aligend bits in 0x" <<
                 hex(avail));
            return false; }
        for (auto &info : collect.info) {
            if (info.second.offset < 32) continue;
            info.second.offset += shift;
            alloc.bit_use.emplace_back(info.first->name, hash_group, 0,
                                       info.second.offset - 32, info.first->size); }
        for (auto &valid : collect.valid_offsets) {
            if (valid.second < 32) continue;
            valid.second += shift;
            alloc.bit_use.emplace_back(valid.first + ".$valid", hash_group, 0,
                                       valid.second - 32, 1); }
        for (auto ht : bitvec(alloc.hash_table_input))
            for (int i = 0; i < collect.bits; ++i)
                hash_single_bit_use[ht][shift + i] = tbl->name + "$gw";
        for (int i = 0; i < collect.bits; ++i)
            hash_single_bit_inuse[shift + i] |= alloc.hash_table_input; }
    LOG1("Totally allocated");
    return true;
}

bool IXBar::allocTable(const IR::MAU::Table *tbl, const PhvInfo &phv,
                       Use &tbl_alloc, Use &gw_alloc) {
    if (!tbl) return true;
    LOG2("IXBar::allocTable(" << tbl->name << ")");
    if (tbl->match_table && !allocMatch(tbl->layout.ternary, tbl->match_table, phv, tbl_alloc))
        return false;
    for (auto &way : tbl->ways) {
        if (!allocHashWay(tbl, way, tbl_alloc)) {
            tbl_alloc.clear();
            return false; } }
    if (!allocGateway(tbl, phv, gw_alloc)) {
        
        gw_alloc.clear();
        tbl_alloc.clear();
        return false; }

    return true;
}

void IXBar::update(cstring name, const Use &alloc) {
    LOG1("Calling update");
    auto &use = alloc.ternary ? ternary_use.base() : exact_use.base();
    auto &fields = alloc.ternary ? ternary_fields : exact_fields;
    for (auto &byte : alloc.use) {
        if (!byte.loc) continue;
        //LOG3("Test " << byte);
        if (byte.loc.byte == 5 && alloc.ternary) {
            /* the sixth byte in a ternary group is actually half a byte group it shares with
             * the adjacent ternary group */
            int byte_group = byte.loc.group/2;
            if (byte == byte_group_use[byte_group]) continue;
            if (byte_group_use[byte_group].first)
                BUG("conflicting ixbar allocation");
            byte_group_use[byte_group] = byte;
        } else {
            LOG1("Alloc.use " << byte << " location " << byte.loc << " ternary " << alloc.ternary);
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
            for (auto ht : bitvec(alloc.hash_table_input)) {
                if (hash_single_bit_use.at(ht, b + bits.bit))
                    BUG("conflicting ixbar hash bit allocation");
                hash_single_bit_use.at(ht, b + bits.bit) = name; }
            hash_single_bit_inuse[b + bits.bit] |= alloc.hash_table_input; }
        if (!hash_group_use[bits.group])
            hash_group_use[bits.group] = name;
        else if (hash_group_use[bits.group] != name)
            BUG("conflicting hash group use between %s and %s", name, hash_group_use[bits.group]); }
    for (auto &way : alloc.way_use) {
        if (!hash_group_use[way.group])
            hash_group_use[way.group] = name;
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
            if (fields.size() >= 26)
                fields.emplace(f.first, 'a' + fields.size() - 26);
            else
                fields.emplace(f.first, 'A' + fields.size()); }
        out << fields[f.first] << hex(f.second);
    } else {
        out << ".."; }
}
static void write_one(std::ostream &out, cstring n, std::map<cstring, char> &names) {
    if (n) {
        if (!names.count(n)) {
            if (names.size() >= 26)
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
            write_one(out, ixbar.hash_group_use[h], tables); }
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
