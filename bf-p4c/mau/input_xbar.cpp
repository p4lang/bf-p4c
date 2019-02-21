#include "bf-p4c/device.h"
#include "bf-p4c/mau/gateway.h"
#include "bf-p4c/mau/ixbar_expr.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/mau/resource_estimate.h"
#include "bf-p4c/phv/phv_fields.h"
#include "dynamic_hash/dynamic_hash.h"
#include "lib/algorithm.h"
#include "lib/bitvec.h"
#include "lib/bitops.h"
#include "lib/hex.h"
#include "lib/range.h"
#include "lib/log.h"

constexpr int IXBar::HASH_INDEX_GROUPS;
constexpr int IXBar::HASH_SINGLE_BITS;
constexpr int IXBar::METER_ALU_HASH_BITS;
constexpr int IXBar::TOFINO_METER_ALU_BYTE_OFFSET;

unsigned IXBarRandom::seed = 0x0572f1fa;
std::uniform_int_distribution<unsigned> IXBarRandom::distribution10(0, 1023);
std::uniform_int_distribution<unsigned> IXBarRandom::distribution1(0, 1);
std::mt19937 IXBarRandom::mersenne_generator(IXBarRandom::seed);

unsigned IXBarRandom::nextRandomNumber(unsigned numBits) {
    if (numBits == 10)
        return distribution10(mersenne_generator);
    else
        return distribution1(mersenne_generator);
}

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

/** Returns each vector of match data.  If multiple hash groups are used, then the allocation,
 *  per hash group is provided
 */
IXBar::Use::TotalBytes IXBar::Use::match_hash(safe_vector<int> *hash_groups) const {
    TotalBytes rv;
    if (atcam) {
        rv = atcam_match();
        if (hash_groups) {
            int atcam_partition_group = -1;
            atcam_partition(&atcam_partition_group);
            hash_groups->push_back(atcam_partition_group);
        }
        return rv;
    }

    for (int i = 0; i < HASH_GROUPS; i++) {
        if (hash_table_inputs[i] == 0) continue;
        auto rv_index = new safe_vector<Byte>();
        for (auto byte : use) {
            int hash_group = byte.loc.group * 2 + byte.loc.byte / 8;
            if ((1 << hash_group) & hash_table_inputs[i]) {
                rv_index->push_back(byte);
            }
        }

        rv.push_back(rv_index);
        if (hash_groups)
            hash_groups->push_back(i);
    }
    return rv;
}

/** Do not count partition indexes within the match bytes and double count repeated bytes
 */
IXBar::Use::TotalBytes IXBar::Use::atcam_match() const {
    TotalBytes single_match;
    single_match.emplace_back(new safe_vector<Byte>());
    for (auto byte : use) {
        if (byte.is_spec(ATCAM_INDEX))
            continue;
        single_match[0]->push_back(byte);
        if (byte.is_spec(ATCAM_DOUBLE)) {
            auto repeat_byte = byte;
            repeat_byte.match_index = 1;
            single_match[0]->push_back(repeat_byte);
        }
    }
    return single_match;
}

/** Provides the bytes and hash group location of the partition index of an atcam table
 */
safe_vector<IXBar::Use::Byte> IXBar::Use::atcam_partition(int *hash_group) const {
    safe_vector<IXBar::Use::Byte> partition;
    for (auto byte : use) {
        if (!byte.is_spec(ATCAM_INDEX))
            continue;
        partition.push_back(byte);
    }
    if (hash_group) {
        for (int i = 0; i < HASH_GROUPS; i++) {
            if (hash_table_inputs[i] == 0) continue;
            *hash_group = i;
            break;
        }
    }
    return partition;
}

/** Base matching on search buses rather than ixbar groups, as potentially an input xbar
 *  group for an ATCAM table has multiple matches in it.
 */
int IXBar::Use::search_buses_single() const {
    unsigned counted = 0;
    int rv = 0;

    for (auto &b : *match_hash()[0]) {
        assert(b.loc.group >= 0 && b.loc.group < 16);
        assert(b.search_bus >= 0 && b.search_bus < 16);
        if (((1 << b.search_bus) & counted) == 0) {
            ++rv;
            counted |= 1U << b.search_bus;
        }
    }
    return rv;
}

/** Returns the ixbar group that the gateway is allocated to */
int IXBar::Use::gateway_group() const {
    int rv = -1;
    bool unset = true;
    for (auto &b : use) {
        if (unset)
            rv = b.loc.group;
        else if (rv != b.loc.group)
            BUG("Gateway can only currently be allocated to one ixbar group");
    }
    return rv;
}

/** Provides information per search bus of how many bytes/bits a particular section of
 *  table uses in order to determine what section is the best candidate to ghost off
 */
safe_vector<IXBar::Use::TotalInfo> IXBar::Use::bits_per_search_bus() const {
    safe_vector<TotalInfo> rv;
    safe_vector<int> hash_groups;
    auto match_bytes = match_hash(&hash_groups);
    int hash_index = 0;

    for (auto &single_match : match_bytes) {
        int bits_per[IXBar::EXACT_GROUPS] = { 0 };
        int bytes_per[IXBar::EXACT_GROUPS] = { 0 };
        int group_per[IXBar::EXACT_GROUPS];
        std::fill(group_per, group_per + IXBar::EXACT_GROUPS, -1);

        for (auto &b : *single_match) {
            assert(b.loc.group >= 0 && b.loc.group < 8);
            assert(b.search_bus >= 0 && b.search_bus < 8);
            bits_per[b.search_bus] += b.bit_use.popcount();
            bytes_per[b.search_bus]++;
            if (group_per[b.search_bus] != -1)
                BUG_CHECK(group_per[b.search_bus] == b.loc.group, "Bytes on same search bus are "
                          "not contained within the same ixbar group");
            group_per[b.search_bus] = b.loc.group;
        }

        safe_vector<GroupInfo> sizes;
        int search_bus_index = 0;
        for (int i = 0; i < IXBar::EXACT_GROUPS; i++) {
             if (bits_per[i] == 0) continue;
             sizes.emplace_back(search_bus_index, group_per[i], bytes_per[i], bits_per[i]);
             search_bus_index++;
        }

        std::sort(sizes.begin(), sizes.end(),
            [=](const GroupInfo &a, const GroupInfo &b) {
            return a.search_bus < b.search_bus;
        });
        rv.emplace_back(hash_groups[hash_index], sizes);
        hash_index++;
    }
    return rv;
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
    atcam = alloc.atcam;
    gw_search_bus = alloc.gw_search_bus;
    gw_search_bus_bytes = alloc.gw_search_bus_bytes;
    gw_hash_group = alloc.gw_hash_group;
    type = alloc.type;
    used_by = alloc.used_by;

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
    for (int i = 0; i < HASH_GROUPS; i++) {
        if (hash_table_inputs[i] != 0 && alloc.hash_table_inputs[i] != 0)
            BUG("When adding allocs of ways, somehow ended up on the same hash group");
        hash_table_inputs[i] |= alloc.hash_table_inputs[i];
        BUG_CHECK(hash_seed[i].popcount() == 0 || alloc.hash_seed[i].popcount() == 0,
                  "Hash seed already present for group %1%", i);
        hash_seed[i] |= alloc.hash_seed[i];
    }
}

/** Visualization Information of Bytes and their corresponding Hash Matrix Bits
 */
std::string IXBar::Use::used_for() const {
    if (type == MATCH) {
        if (ternary)
            return "ternary_match";
        else if (atcam)
            return "atcam_match";
        else
            return "exact_match";
    } else if (type == GATEWAY) {
        return "gateway";
    } else if (type == SELECTOR) {
        return "selection";
    } else if (type == METER) {
        return "meter";
    } else if (type == STATEFUL_ALU) {
        return "stateful_alu";
    } else if (type == HASH_DIST) {
        return hash_dist_used_for();
    }
    BUG("Invalid type of input xbar: %d", type);
    return "";
}

/** Visualization Information on Hash Distribution Units
 */
std::string IXBar::Use::hash_dist_used_for() const {
    switch (hash_dist_type) {
        case COUNTER_ADR:
            return "Counter Address";
        case METER_ADR:
            return "Meter Address";
        case METER_ADR_AND_IMMEDIATE:
            return "Meter Address and Immediate";
        case ACTION_ADR:
            return "Action Data Address";
        case IMMEDIATE:
            return "Hash Calculation";
        case PRECOLOR:
            return "Meter Pre Color";
        case HASHMOD:
            return "Multi-RAM-line Selection";
        default:
            BUG("Invalid type for a hash distribution unit: %d", type);
            return "";
    }
}

static int align_flags[4] = {
    /* these flags are the alignment restrictions that FAIL for each byte in 4 */
    IXBar::Use::Align16hi | IXBar::Use::Align32hi,
    IXBar::Use::Align16lo | IXBar::Use::Align32hi,
    IXBar::Use::Align16hi | IXBar::Use::Align32lo,
    IXBar::Use::Align16lo | IXBar::Use::Align32lo,
};

int inline IXBar::groups(bool ternary) const {
    return ternary ? TERNARY_GROUPS : EXACT_GROUPS;
}

int inline IXBar::mid_bytes(bool ternary) const {
    return ternary ? BYTE_GROUPS : 0;
}

int inline IXBar::bytes_per_group(bool ternary) const {
    return ternary ? TERNARY_BYTES_PER_GROUP : EXACT_BYTES_PER_GROUP;
}

bool IXBar::calculate_sizes(safe_vector<Use::Byte> &alloc_use, bool ternary,
        int &total_bytes_needed, int &groups_needed, int &mid_bytes_needed) {
    if (groups_needed == 0) {
        for (auto byte : alloc_use) {
            if (byte.is_spec(ATCAM_DOUBLE))
                total_bytes_needed += 2;
            else
                total_bytes_needed++;
        }

        if (ternary) {
            int big_groups_needed = (total_bytes_needed + TERNARY_BYTES_PER_BIG_GROUP - 1)
                                    / TERNARY_BYTES_PER_BIG_GROUP;
            groups_needed = big_groups_needed * 2;
            mid_bytes_needed = big_groups_needed - 1;
            if (total_bytes_needed % TERNARY_BYTES_PER_BIG_GROUP == 0)
                mid_bytes_needed++;
        } else {
            groups_needed = (total_bytes_needed + bytes_per_group(false) - 1)
                            / bytes_per_group(false);
            mid_bytes_needed = 0;
        }
    } else {
        if ((groups_needed % 2) == 0 && ternary)
            if (mid_bytes_needed * 2 != groups_needed)
                mid_bytes_needed++;
        groups_needed++;
    }

    if (groups_needed > groups(ternary))
        return false;
    return true;
}

/** This is too constraining than the actual algorithm, but this ensures that the hash
 *  distribution group has available space for this particular hash distribution section.
 *  The granularity of this optimization is on 16 bit slices, which are as large as an
 *  individual hash distribution section, but potentially need to be refactored in order
 *  to include multiple wide addresses or 8 bit hash distribution sections.
 */
void IXBar::calculate_available_hash_dist_groups(safe_vector<grp_use> &order,
        hash_matrix_reqs &hm_reqs) {
    for (int i = 0; i < HASH_DIST_UNITS; i++) {
        if (hash_dist_groups[i] == -1) continue;
        auto hash_tables = hash_group_use[hash_dist_groups[i]];
        bitvec slices_used;
        for (auto &grp : order) {
            for (int i = 0; i < 2; i++) {
                for (int hash_slice = 0; hash_slice < HASH_DIST_SLICES; hash_slice++) {
                    if (!(hash_dist_inuse[hash_slice].getbit(2 * grp.group + 1)))
                        slices_used.setbit(hash_slice);
                }
            }
        }
        if (HASH_DIST_SLICES - slices_used.popcount() >= hm_reqs.index_groups)
            continue;
        for (auto bit : bitvec(hash_tables)) {
            order[bit / 2].hash_open[bit % 2] = false;
        }
    }
}

/** The hash matrix, described in section 6.1.9 Hash Generation of the uArch, is a further
 *  constraint on where bytes can be placed within the input xbar.  The hash matrix is tied
 *  specifically to the exact match, and is not used for ternary.  The hash matrix is used
 *  for the following reasons:
 *     - Generating a lookup address for an exact table
 *     - Generating a hash for a selector to use
 *     - Generating any kind of hash to use through hash distribution.
 *
 *  The hash matrix itself is an 1024b * 52b matrix, broken into 16 64b by 52b matrix.  In order
 *  to generate a hash, the input xbar itself is broken into 16 64 bit sections.  Each 64 bit
 *  section performs a matrix multiply with its corresponding 64bx52b matrix to come up with
 *  a 16 separate 52b words.  Then any of the 52b words can be XORed together.  This is useful,
 *  for example, if a tables match data is larger than 64 bits, and thus requires the combination
 *  of multiple 64 bit sections.
 *
 *  Thus in order to successfully allocate a byte within a 64 bit section, that byte cannot use
 *  hash bits used by any other byte not part of the hash generation in this section.  For
 *  example, say a P4 program had two exact match tables with 32 bit keys, and each key needed
 *  30 bits of hash data.  Now because the hash matrix is only 52 bits, it is impossible for
 *  each of these tables data to be within the same 64 section of the input xbar, and have
 *  an independent hash calculation.
 *
 *  Futhermore, the algorithm currently restricts hash distribution and everything else to
 *  never be within the same 64 bit hash table.  This is just because it would be fairly tedious
 *  to check, and may limit hash distribution much later, especially for a greedy algorithm.
 */
void IXBar::calculate_available_groups(safe_vector<grp_use> &order,
                                       hash_matrix_reqs &hm_reqs) {
    for (auto &grp : order) {
        for (int i = 0; i < 2; i++) {
            grp.hash_open[i] = true;
        }
    }

    if (hm_reqs.hash_dist) {
        calculate_available_hash_dist_groups(order, hm_reqs);
    } else {
        for (auto &grp : order) {
            for (int i = 0; i < 2; i++) {
                int ways_available = 0;
                int select_bits_available = 0;
                for (int hg = 0; hg < HASH_INDEX_GROUPS; hg++) {
                     if (!(hash_index_inuse[hg] & (1 << (2 * grp.group + i))))
                         ways_available++;
                }
                for (int sb = 0; sb < HASH_SINGLE_BITS; sb++) {
                    if (!(hash_single_bit_inuse[sb] & (1 << (2 * grp.group + i))))
                        select_bits_available++;
                }

                if (ways_available < hm_reqs.index_groups ||
                    select_bits_available < hm_reqs.select_bits) {
                    grp.hash_open[i] = false;
                }
            }
        }
    }

    for (auto &grp : order) {
        for (int i = 0; i < 2; i++) {
            grp.hash_table_type[i] = is_group_for_hash_dist(2 * grp.group + i);
        }
    }
}

/** Determine if a group is either for hash distribution or match only */
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

/** Due to the earlier calculations on what 64 bit hash matrices are available, determine
 *  whether a byte within the input xbar is available.
 */
bool IXBar::violates_hash_constraints(safe_vector<grp_use> &order, bool hash_dist, int group,
        int byte) {
    if (!order[group].hash_open[byte / 8]) {
        return true;
    }
    if (hash_dist) {
        if (!order[group].hash_dist_avail(byte / 8)) {
            return true;
        }
    } else {
        if (order[group].hash_dist_only(byte / 8)) {
            return true;
        }
    }
    return false;
}

/** Put the grp_use and mid_byte_use vectors in group order */
void IXBar::reset_orders(safe_vector<grp_use> &order, safe_vector<mid_byte_use> &mid_byte_order) {
    std::sort(order.begin(), order.end(), [=](const grp_use &a, const grp_use &b) {
        return a.group < b.group;
    });

    std::sort(mid_byte_order.begin(), mid_byte_order.end(),
              [=](const mid_byte_use &a, const mid_byte_use &b) {
        return a.group < b.group;
    });
}

/** Calculates the bytes per each group/midbyte that have previously been allocated by a table,
 *  and can also be used by this table.
 */
void IXBar::calculate_found(safe_vector<IXBar::Use::Byte *> &unalloced,
                            safe_vector<grp_use> &order,
                            safe_vector<mid_byte_use> &mid_byte_order,
                            bool ternary, bool hash_dist, unsigned byte_mask) {
    if (byte_mask != ~0U)
        return;

    auto &use = this->use(ternary);
    auto &fields = this->fields(ternary);
    reset_orders(order, mid_byte_order);
    for (int i = 0; i < groups(ternary); i++) {
        order[i].found.clear();
    }

    for (int i = 0; i < mid_bytes(ternary); i++) {
        mid_byte_order[i].found = false;
    }

    for (auto &need : unalloced) {
        for (auto &p : Values(fields.equal_range(need->name))) {
            if (ternary && p.byte == 5) {
                if (need->is_range())
                    continue;
                if (byte_group_use[p.group/2].second == need->lo) {
                    mid_byte_order[p.group/2].found = true;
                }
                continue;
            }

            if (use[p.group][p.byte].second == need->lo) {
                if (!ternary && violates_hash_constraints(order, hash_dist, p.group, p.byte)) {
                    continue;
                }
                if (need->is_range() && order[p.group].range_set()
                    && order[p.group].range_index != need->range_index)
                    continue;

                if (!(byte_mask & (1U << p.byte)))
                    continue;
                order[p.group].found[p.byte] = true;
            }
        }
    }
}

/** Calculate the empty locations within the groups and midbytes
 */
void IXBar::calculate_free(safe_vector<grp_use> &order,
        safe_vector<mid_byte_use> &mid_byte_order, bool ternary, bool hash_dist,
        unsigned byte_mask)  {
    auto &use = this->use(ternary);
    reset_orders(order, mid_byte_order);
    // FIXME: This is a way too tight constraint in order to get stful.p4 to correctly compile
    // There needs to be some coordination with what is actually needed vs. what is actually
    // available.  One doesn't need the whole byte_mask to be free, in order to allocate it.
    if (byte_mask != ~0U) {
        for (int grp = 0; grp < groups(ternary); grp++) {
            bool whole_section_free = true;
            for (int byte = 0; byte < bytes_per_group(ternary); byte++) {
                if (!(byte_mask & (1U << byte)))
                    continue;
                if (use[grp][byte].first)
                    whole_section_free = false;
            }
            for (int byte = 0; byte < bytes_per_group(ternary) && whole_section_free; byte++) {
                if (!(byte_mask & (1U << byte)))
                    continue;
                order[grp].free[byte] = true;
            }
        }
        return;
    }

    for (int grp = 0; grp < groups(ternary); grp++) {
        for (int byte = 0; byte < bytes_per_group(ternary); byte++) {
            if (!ternary && violates_hash_constraints(order, hash_dist, grp, byte))
                continue;
            if (!use[grp][byte].first)
                order[grp].free[byte] = true;
        }
    }

    for (int mid_byte = 0; mid_byte < mid_bytes(ternary); mid_byte++) {
        if (!byte_group_use[mid_byte].first)
            mid_byte_order[mid_byte].free = true;
    }
}

/** Find the unalloced bytes in the current table that are already contained within the xbar
 *  group and share those locations.
 */
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
        int match_bytes_added = need.is_spec(ATCAM_DOUBLE) ? 2 : 1;
        if (match_bytes_placed + match_bytes_added > total_match_bytes)
            continue;
        if (need.is_range() && grp->range_set() && need.range_index != grp->range_index)
            continue;

        for (auto &p : Values(fields.equal_range(need.name))) {
            if (ternary && p.byte == TERNARY_BYTES_PER_GROUP)
                continue;


            if ((grp->group == p.group) && (use[p.group][p.byte].second == need.lo)) {
                if (!grp->found.getbit(p.byte))
                    continue;
                if (!ternary && !grp->hash_open[p.byte / 8])
                    continue;

                allocate_byte(&grp->found, unalloced, nullptr, need, p.group, p.byte, i,
                              found_bytes, ixbar_bytes_placed, match_bytes_placed, search_bus,
                              &grp->range_index);
                break;
            }
        }
    }
    LOG4("Total found bytes placed was " << ixbar_bytes_placed << " " << match_bytes_placed);
}

/** Find the unalloced bytes in the current table that are already contained within the xbar
 *  midbyte for ternary and share those locations.
 */
void IXBar::found_mid_bytes(mid_byte_use *mb_grp, safe_vector<IXBar::Use::Byte *> &unalloced,
    bool ternary, int &match_bytes_placed, int search_bus, bool &version_placed) {
    auto &fields = this->fields(ternary);
    if (mb_grp->found == false)
        return;
    int found_bytes = 1;
    int ixbar_bytes_placed = 0;
    int total_match_bytes = 1;

    for (size_t i = 0; i < unalloced.size(); i++) {
        auto &need = *(unalloced[i]);
        if (found_bytes == 0)
            break;
        if (match_bytes_placed >= total_match_bytes)
            break;
        for (auto &p : Values(fields.equal_range(need.name))) {
            if (!(ternary && p.byte == TERNARY_BYTES_PER_GROUP))
                continue;
            if ((mb_grp->group == p.group/2) && (byte_group_use[p.group/2].second == need.lo)) {
                allocate_byte(nullptr, unalloced, nullptr, need, p.group, p.byte, i,
                              found_bytes, ixbar_bytes_placed, match_bytes_placed, search_bus,
                              nullptr);
                mb_grp->found = false;
                if (need.bit_use.getslice(4, 4).popcount() == 0 ||
                    need.bit_use.getslice(0, 4).popcount() > 0)
                    version_placed = true;
                break;
            }
        }
    }
    LOG4("Total found mid bytes placed was " << ixbar_bytes_placed << " " << match_bytes_placed);
}

/** Fills out all currently unoccupied xbar bytes within a group with bytes from the current table
 *  following alignment constraints.
 */
void IXBar::free_bytes(grp_use *grp, safe_vector<IXBar::Use::Byte *> &unalloced,
                      safe_vector<IXBar::Use::Byte *> &alloced,
                      bool ternary, bool hash_dist, int &match_bytes_placed, int search_bus) {
    int ixbar_bytes_placed = 0;
    int free_bytes = grp->free.popcount();
    int total_match_bytes = ternary ? TERNARY_BYTES_PER_GROUP : EXACT_BYTES_PER_GROUP;
    int ternary_offset = (grp->group / 2) * TERNARY_BYTES_PER_BIG_GROUP;
    ternary_offset += (grp->group % 2) * (TERNARY_BYTES_PER_GROUP + 1);
    int align_offset = ternary ? ternary_offset : 0;
    int align = align_offset & 3;

    for (size_t i = 0; i < unalloced.size(); i++) {
        if (free_bytes == 0)
            break;
        if (match_bytes_placed >= total_match_bytes)
            break;
        auto &need = *(unalloced[i]);
        int match_bytes_added = need.is_spec(ATCAM_DOUBLE) ? 2 : 1;
        if (match_bytes_placed + match_bytes_added > total_match_bytes)
            continue;
        if (need.is_range() && grp->range_set() && need.range_index != grp->range_index)
            continue;

        int chosen_byte = -1;
        bool found = false;
        for (auto byte : grp->free) {
            if (align_flags[(byte+align) & 3] & need.flags) {
                 continue;
            }

            allocate_byte(&grp->free, unalloced, &alloced, need, grp->group, byte, i, free_bytes,
                          ixbar_bytes_placed, match_bytes_placed, search_bus, &grp->range_index);
            chosen_byte = byte;
            found = true;
            break;
        }

        if (hash_dist && !ternary && found) {
            grp->hash_table_type[chosen_byte / 8] = grp_use::HASH_DIST;
        }
    }
    LOG4("Total free bytes placed was " << ixbar_bytes_placed << " " << match_bytes_placed);
}

/** Fills out a currently unoccupied midbyte from the current table, following PHV alignment
 *  constraints
 */
void IXBar::free_mid_bytes(mid_byte_use *mb_grp, safe_vector<IXBar::Use::Byte *> &unalloced,
        safe_vector<Use::Byte *> &alloced, int &match_bytes_placed, int search_bus,
        bool &version_placed) {
    if (!mb_grp->free)
        return;

    int ixbar_bytes_placed = 0;
    int free_bytes = 1;
    int align_offset = (mb_grp->group * TERNARY_BYTES_PER_BIG_GROUP)
                        + TERNARY_BYTES_PER_GROUP;
    int align = align_offset & 3;
    int total_match_bytes = 1;

    if (!version_placed) {
        for (size_t i = 0; i < unalloced.size(); i++) {
            if (free_bytes == 0)
                break;
            if (match_bytes_placed >= total_match_bytes)
                break;
            auto &need = *(unalloced[i]);
            if (need.is_range())
                continue;
            if (need.bit_use.getslice(4, 4).popcount() > 0 &&
                need.bit_use.getslice(0, 4).popcount() > 0) continue;
            if (align_flags[align & 3] & need.flags) continue;
            allocate_byte(nullptr, unalloced, &alloced, need, mb_grp->group * 2, 5, i,
                          free_bytes, ixbar_bytes_placed, match_bytes_placed, search_bus,
                          nullptr);
            mb_grp->free = false;
            version_placed = true;
        }
    }

    for (size_t i = 0; i < unalloced.size(); i++) {
        if (free_bytes == 0)
            break;
        if (match_bytes_placed >= total_match_bytes)
            break;
        auto &need = *(unalloced[i]);
        if (need.is_range())
            continue;
        if (align_flags[align & 3] & need.flags) continue;
        allocate_byte(nullptr, unalloced, &alloced, need, mb_grp->group * 2,
                      bytes_per_group(true), i, free_bytes, ixbar_bytes_placed,
                      match_bytes_placed, search_bus, nullptr);
        mb_grp->free = false;
        if (need.bit_use.getslice(4, 4).popcount() == 0 ||
            need.bit_use.getslice(0, 4).popcount() > 0)
            version_placed = true;
    }
    LOG4("Total free bytes placed was " << ixbar_bytes_placed << " " << match_bytes_placed);
}


/** Allocate all fields within a IXBar::Byte object given its selection throughout the
 *  algorithm.  If it is not shared, move the byte to the alloced list to be filled in
 *  to the IXBar local objects later
 */
void IXBar::allocate_byte(bitvec *bv, safe_vector<Use::Byte *> &unalloced,
                          safe_vector<Use::Byte *> *alloced, Use::Byte &need, int group, int byte,
                          size_t &index, int &avail_bytes, int &ixbar_bytes_placed,
                          int &match_bytes_placed, int search_bus, int *range_index) {
    need.loc.group = group;
    need.loc.byte = byte;
    need.search_bus = search_bus;
    if (bv != nullptr)
        (*bv)[byte] = false;
    if (alloced)
        alloced->push_back(unalloced[index]);

    unalloced.erase(unalloced.begin() + index);
    index--;
    avail_bytes--;
    ixbar_bytes_placed++;
    if (need.is_spec(ATCAM_DOUBLE))
        match_bytes_placed += 2;
    else
        match_bytes_placed++;

    if (need.is_range() && range_index) {
        *range_index = need.range_index;
    }
}

/* When all bytes of the current table have been given a placement, this function fills out
   the xbars use for later record keeping and checks */
void IXBar::fill_out_use(safe_vector<IXBar::Use::Byte *> &alloced, bool ternary) {
    auto &use = this->use(ternary);
    auto &fields = this->fields(ternary);
    for (auto &need : alloced) {
        fields.emplace(need->name, need->loc);
        if (ternary && need->loc.byte == 5) {
            byte_group_use[need->loc.group/2] = *(need);
        } else {
            use[need->loc] = *(need);
        }
    }
}

/** Given whether the input xbar is either for the TCAM or the SRAM, create and size the order
 *  and midbyte order accordingly
 */
void IXBar::initialize_orders(safe_vector<grp_use> &order,
        safe_vector<mid_byte_use> &mid_byte_order, bool ternary) {
    order.clear();
    mid_byte_order.clear();
    for (int group = 0; group < groups(ternary); group++) {
        order.emplace_back(group);
    }

    for (int mid_byte = 0; mid_byte < mid_bytes(ternary); mid_byte++) {
        mid_byte_order.emplace_back(mid_byte);
    }
}

/** Clear the alloced vector, reinitialize all bytes to unallocated, and reset unalloced
 */
void IXBar::setup_byte_vectors(safe_vector<IXBar::Use::Byte> &alloc_use, bool ternary,
        safe_vector<IXBar::Use::Byte *> &unalloced, safe_vector<IXBar::Use::Byte *> &alloced,
        safe_vector<grp_use> &order, safe_vector<mid_byte_use> &mid_byte_order,
        hash_matrix_reqs &hm_reqs, unsigned byte_mask) {
    unalloced.clear();
    alloced.clear();
    for (auto byte : alloc_use) {
        byte.unallocate();
    }

    if (byte_mask == ~0U) {
        std::sort(alloc_use.begin(), alloc_use.end(),
                  [=](const Use::Byte &a, const Use::Byte &b) {
            int t;
            if (a.is_range() && !b.is_range())
                return true;
            if (!a.is_range() && b.is_range())
                return false;
            if ((t = a.range_index - b.range_index) != 0)
                return t < 0;
            if ((t = static_cast<size_t>(a.flags) - static_cast<size_t>(b.flags)) != 0)
                return t > 0;
            return a < b;
        });
    }

    for (auto &need : alloc_use) {
        unalloced.push_back(&need);
    }
    if (!ternary) {
        calculate_available_groups(order, hm_reqs);
    }

    /* Initial found and free calculations */
    calculate_found(unalloced, order, mid_byte_order, ternary, hm_reqs.hash_dist, byte_mask);
    calculate_free(order, mid_byte_order, ternary, hm_reqs.hash_dist, byte_mask);
}

void IXBar::print_groups(safe_vector<grp_use> &order, safe_vector<mid_byte_use> &mid_byte_order,
        bool ternary) {
    for (int grp = 0; grp < groups(ternary); grp++) {
        LOG6("  Group " << order[grp]);
        if (ternary && (grp % 2) == 0)
            LOG6("  Mid byte " << mid_byte_order[grp / 2]);
    }
}

void IXBar::allocate_mid_bytes(safe_vector<IXBar::Use::Byte *> &unalloced,
        safe_vector<IXBar::Use::Byte *> &alloced, bool ternary, bool prefer_found,
        safe_vector<grp_use> &order, safe_vector<mid_byte_use> &mid_byte_order,
        int mid_bytes_needed, int &bytes_to_allocate, bool &version_placed) {
    for (int search_bus = 0; search_bus < mid_bytes_needed; search_bus++) {
        if (unalloced.size() == 0)
            return;
        std::sort(mid_byte_order.begin(), mid_byte_order.end(),
                  [=](const mid_byte_use &a, const mid_byte_use &b) {
            if (!a.attempted && b.attempted)
                return true;
            if (b.attempted && !a.attempted)
                return false;

            if (prefer_found) {
               if (a.found && !b.found)
                   return true;
               if (b.found && !a.found)
                   return false;
            }

            if (a.free && !b.free)
                return true;
            if (b.free && !a.free)
                return false;

            return a.group < b.group;
        });

        int match_bytes_placed = 0;
        LOG4("TCAM mid byte selected was " << mid_byte_order[0].group);
        found_mid_bytes(&mid_byte_order[0], unalloced, ternary, match_bytes_placed, search_bus,
                        version_placed);
        free_mid_bytes(&mid_byte_order[0], unalloced, alloced, match_bytes_placed, search_bus,
                       version_placed);
        mid_byte_order[0].attempted = true;
        bytes_to_allocate -= match_bytes_placed;
        calculate_found(unalloced, order, mid_byte_order, ternary, false, ~0U);
    }
}

void IXBar::allocate_groups(safe_vector<IXBar::Use::Byte *> &unalloced,
        safe_vector<IXBar::Use::Byte *> &alloced, bool ternary, bool prefer_found,
        safe_vector<grp_use> &order, safe_vector<mid_byte_use> &mid_byte_order,
        int &bytes_to_allocate, int groups_needed, bool hash_dist, unsigned byte_mask) {
    for (int search_bus = 0; search_bus < groups_needed; search_bus++) {
        if (unalloced.size() == 0)
            return;

        int match_bytes_placed = 0;
        int max_possible_bytes = (groups_needed - search_bus) * bytes_per_group(ternary);
        int leeway = std::max(max_possible_bytes - bytes_to_allocate, 0);
        int required_allocation_bytes = std::max(bytes_per_group(ternary) - leeway, 0);

        std::sort(order.begin(), order.end(),
                 [required_allocation_bytes, prefer_found](const grp_use &a, const grp_use &b) {
            if (!a.attempted && b.attempted)
                return true;
            if (b.attempted && !a.attempted)
                return false;

            bool a_candidate = a.total_avail() > required_allocation_bytes;
            bool b_candidate = b.total_avail() > required_allocation_bytes;

            if (a_candidate && !b_candidate)
                return true;
            if (b_candidate && !a_candidate)
                return false;

            int t;
            if (prefer_found) {
               if ((t = a.found.popcount() - b.found.popcount()) != 0)
                   return t > 0;
               if ((t = a.total_avail() - b.total_avail()) != 0)
                   return t < 0;
            }

            if ((t = a.total_avail() - b.total_avail()) != 0)
                return t > 0;
            return a.group < b.group;
        });

        LOG4("Group selected was " << order[0].group << " bytes left " << unalloced.size());
        found_bytes(&order[0], unalloced, ternary, match_bytes_placed, search_bus);
        free_bytes(&order[0], unalloced, alloced, ternary, hash_dist, match_bytes_placed,
                   search_bus);
        order[0].attempted = true;
        bytes_to_allocate -= match_bytes_placed;
        calculate_found(unalloced, order, mid_byte_order, ternary, hash_dist, byte_mask);
    }
}

bool IXBar::version_placeable(bool version_placed, int mid_bytes_needed, int groups_needed) {
    if (mid_bytes_needed == groups_needed && !version_placed)
        return false;
    return true;
}


/** The algorithm for the allocation of bytes from the table to the input xbar, both for the
 *  TCAM and SRAM xbar.  The input xbar is defined in section 6.1.8 Match Input Xbar of the
 *  uArch.
 *
 *  The input xbar for SRAM is 128 bytes, divided into 8 sections of 16 bytes (128 bits).  As
 *  defined in section 6.2.3 Exact Match Row Vertical/Horizontal (VH) Xbars, any of the 8
 *  sections can go to any search bus within the match array.  However, a search bus can
 *  only input one of input xbar groups.  Thus to minimize the width of the match, the algorithm
 *  must minimize the number of input xbar groups needed.  Keep in mind that a search bus is
 *  128 bits as well, so that only one search bus is need for an entire input xbar group.
 *
 *  The input xbar for TCAM is 66 bytes, divided into 6 groups of 11 bytes.  These groups of 11
 *  bytes can be thought of as a group of 5 bytes, a mid byte and a final group of 5 bytes.
 *  The reason for this odd structure is described in section 6.3.5 TCAM Matching Setup.  Each
 *  TCAM is 44 bits.  The lower 40 bits of the TCAM can pull from any 5 byte group, and the
 *  upper 4 bits can pull from any nibble of a midbyte.
 *
 *  An input xbar groups has the capability to be shared between multiple tables.  Say for
 *  instance two separate ternary tables include a 40 bit field, and were to be placed in the
 *  same stage.  If that 40 bit field occupied a single TCAM input xbar group, then two separate
 *  TCAMs, one for each table can pull from the same input xbar groups.
 *
 *  The algorithm works as follows:
 *    - Calculate the minimum number of midbytes/groups needed for a particular table
 *    - Run potentially two versions of a fitting algorithm.
 *      * On the first iteration, prefer groups that have capabilities to share input xbar bytes.
 *      * If, when found groups were preferred, the bytes did not fit within the alloted
 *        amount of space, prefer input xbar groups with the most open space and just try to
 *        pack.
 *      * If neither fit, then increase the minimum amount groups/midbytes
 *
 * ARGUMENTS:
 *   alloc_use  vector of Byte objects that need to be allocated on the ixbar
 *   ternary    true for ternary ixbar, false for exact
 *   alloced    output -- the Byte objects that were successfully allocated, as we want to fill
 *              out the values after we know the bytes don't break any hash constraints
 *   hm_reqs    how much space, if any is required to be reserved on the hash matrix
 *   byte_mask  which bytes in ixbar groups to use -- default mask of ~0 means use any bytes
 */
bool IXBar::find_alloc(safe_vector<IXBar::Use::Byte> &alloc_use, bool ternary,
                      safe_vector<IXBar::Use::Byte *> &alloced, hash_matrix_reqs &hm_reqs,
                      unsigned byte_mask) {
    int total_bytes_needed = 0;
    int groups_needed = 0;
    int mid_bytes_needed = 0;

    safe_vector<grp_use> small_order;
    bool allocated = false;
    safe_vector<grp_use> order;
    safe_vector<mid_byte_use> mid_byte_order;
    safe_vector<IXBar::Use::Byte *> unalloced;
    bool first_time = true;

    do {
        bool possible = calculate_sizes(alloc_use, ternary, total_bytes_needed, groups_needed,
                                        mid_bytes_needed);
        if (!possible)
            break;
        if (hm_reqs.max_search_buses > 0 && groups_needed > hm_reqs.max_search_buses)
            break;
        for (int i = 0; i < 2 && !allocated; i++) {
            bool version_placed = false;
            bool prefer_found = i == 0;
            initialize_orders(order, mid_byte_order, ternary);
            setup_byte_vectors(alloc_use, ternary, unalloced, alloced, order, mid_byte_order,
                               hm_reqs, byte_mask);
            if (first_time) {
                LOG6("Pre allocation groups:");
                print_groups(order, mid_byte_order, ternary);
            }
            int bytes_to_allocate = total_bytes_needed;
            if (ternary) {
                allocate_mid_bytes(unalloced, alloced, ternary, prefer_found, order,
                                   mid_byte_order, mid_bytes_needed, bytes_to_allocate,
                                   version_placed);
                LOG6("Allocation post midbyte ");
                    print_groups(order, mid_byte_order, ternary);
            }
            allocate_groups(unalloced, alloced, ternary, prefer_found, order, mid_byte_order,
                            bytes_to_allocate, groups_needed, hm_reqs.hash_dist, byte_mask);
            allocated = unalloced.size() == 0;
            if (ternary)
                allocated &= version_placeable(version_placed, mid_bytes_needed, groups_needed);
        }
    } while (allocated == false);

    if (allocated) {
        LOG6("Post allocation groups:");
        print_groups(order, mid_byte_order, ternary);
    }
    return allocated;
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
static void add_use(IXBar::ContByteConversion &map_alloc, const PHV::Field *field,
                    const PhvInfo &phv, boost::optional<cstring> aliasSourceName,
                    const le_bitrange *bits = nullptr, int flags = 0,
                    IXBar::byte_type_t byte_type = IXBar::NO_BYTE_TYPE,
                    unsigned extra_align = 0, int range_index = 0) {
    bool ok = false;
    int index = 0;
    // FIXME: This will currently not work before PHV allocation, because the foreach_byte
    // over alloc_slices only works if the slices have been allocated, according to Cole.
    // If we want to move TablePlacement before PHV allocation in the future, this will have
    // to change
    field->foreach_byte(bits, [&](const PHV::Field::alloc_slice &sl) {
        ok = true;  // FIXME -- better sanity check?
        // FIXME: This will not work if moved before PHV allocation
        IXBar::FieldInfo fi(field->name, sl.field_bit, sl.field_hi(), sl.container_bit % 8,
                aliasSourceName);

        // FIXME: Unclear if this is too constrained, as the bits that aren't live at the same
        // time may still be non-zero even though they aren't live.  This will always mark
        // all bits that are ever allocated
        bitvec all_bits = phv.bits_allocated(sl.container);
        IXBar::Use::Byte byte(sl.container.toString(), (sl.container_bit/8U) * 8U);

        byte.bit_use.setrange(sl.container_bit % 8, sl.width);
        byte.non_zero_bits = all_bits.getslice((sl.container_bit / 8U) * 8U, 8);
        byte.flags =
            flags | need_align_flags[sl.container.log2sz()][(sl.container_bit/8U) & 3]
                  | need_align_flags[extra_align][index & 3];
        // FIXME -- for (jbay) 128-bit salu, extra_align ends up being 3, so we're not adding
        // any extra alignment here as it falls into the 'not yet allocated'.  This is either
        // a happy accident, or incorrect -- I'm not sure if we need extra alignment for this
        // case.  It will generally fill the entire 128-bit group, or use hash anyways.
        if (byte_type == IXBar::ATCAM) {
            byte.set_spec(IXBar::ATCAM_DOUBLE);
        } else if (byte_type == IXBar::PARTITION_INDEX) {
            byte.set_spec(IXBar::ATCAM_INDEX);
        }

        if (byte_type == IXBar::RANGE) {
            byte.range_index = range_index;
            if ((sl.container_bit % 8) < 4) {
                byte.set_spec(IXBar::RANGE_LO);
                map_alloc[byte].push_back(fi);
            }
            if ((sl.container_hi() % 8) > 3) {
                byte.clear_spec(IXBar::RANGE_LO);
                byte.set_spec(IXBar::RANGE_HI);
                map_alloc[byte].push_back(fi);
            }
        } else {
            map_alloc[byte].push_back(fi);
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

unsigned IXBar::index_groups_used(bitvec bv) const {
    unsigned rv = 0;
    for (int i = 0; i < HASH_INDEX_GROUPS; i++) {
        if (bv.getrange(i * RAM_LINE_SELECT_BITS, RAM_LINE_SELECT_BITS))
            rv |= (1 << i);
    }
    return rv;
}

unsigned IXBar::select_bits_used(bitvec bv) const {
    unsigned rv = 0;
    for (int i = RAM_SELECT_BIT_START; i < HASH_MATRIX_SIZE; i++) {
        if (bv.getbit(i))
            rv |= (1 << (i - RAM_SELECT_BIT_START));
    }
    return rv;
}

IXBar::hash_matrix_reqs IXBar::match_hash_reqs(const LayoutOption *lo,
        size_t start, size_t last, bool ternary) {
    if (ternary) {
        return hash_matrix_reqs();
    }

    int bits_required = 0;
    for (size_t index = start; index < last; index++) {
        bits_required += ceil_log2(lo->way_sizes[index]);
    }
    bits_required = std::min(bits_required, HASH_SINGLE_BITS);
    int groups_required = std::min(last - start, static_cast<size_t>(IXBar::HASH_INDEX_GROUPS));
    return hash_matrix_reqs(groups_required, bits_required, false);
}


/* This is for adding fields to be allocated in the ixbar allocation scheme.  Used by
   match tables, selectors, and hash distribution */
class IXBar::FieldManagement : public Inspector {
    ContByteConversion &map_alloc;
    safe_vector<PHV::AbstractField*> &field_list_order;
    std::map<cstring, bitvec> &fields_needed;
    cstring name;
    const PhvInfo &phv;
    KeyInfo &ki;

    bool preorder(const IR::ListExpression *) {
        if (!ki.hash_dist)
            BUG("A field list is somehow contained within the reads in table %s", name);
        return true; }
    bool preorder(const IR::Mask *) {
        BUG("Masks should have been converted to Slices before input xbar allocation");
        return true; }

    bool preorder(const IR::MAU::InputXBarRead *read) {
        if (ki.is_atcam) {
            if (ki.partition != read->partition_index)
                return false; }
        return true; }

    bool preorder(const IR::Constant *c) {
        auto constant = new PHV::Constant(c);
        field_list_order.push_back(constant);
        return true; }

    bool preorder(const IR::MAU::ActionArg *aa) {
        error("Can't use action argument %s in a hash in the same action; "
              "try splitting the action", aa);
        return false; }

    bool preorder(const IR::Expression *e) {
        le_bitrange bits = { };
        auto *finfo = phv.field(e, &bits);
        if (!finfo) return true;
        bitvec field_bits(bits.lo, bits.hi - bits.lo + 1);
        // Currently, due to driver, only one field is allowed to be the partition index
        byte_type_t byte_type = NO_BYTE_TYPE;
        if (auto *read = findContext<IR::MAU::InputXBarRead>()) {
            if (ki.is_atcam) {
                if (read->partition_index)
                    byte_type = PARTITION_INDEX;
                else if (read->match_type.name == "ternary" || read->match_type.name == "lpm")
                    byte_type = ATCAM;
            }
            if (read->match_type.name == "range")
                byte_type = RANGE;
        }
        if (byte_type == PARTITION_INDEX) {
            int diff = bits.size() - ki.partition_bits;
            if (diff > 0)
                bits.hi -= diff;
        }

        if (fields_needed.count(finfo->name)) {
            auto &allocated_bits = fields_needed.at(finfo->name);
            if ((allocated_bits & field_bits).popcount() == field_bits.popcount())
                return false;
            fields_needed[finfo->name] |= field_bits;
        } else {
            fields_needed[finfo->name] = field_bits;
        }
        auto fieldSlice = new PHV::FieldSlice(finfo, bits);
        field_list_order.push_back(fieldSlice);
        boost::optional<cstring> aliasSourceName = phv.get_alias_name(e);
        add_use(map_alloc, finfo, phv, aliasSourceName, &bits, 0, byte_type, 0, ki.range_index);
        if (byte_type == RANGE) {
            ki.range_index++;
        }
        return false;
    }
    void postorder(const IR::BFN::SignExtend *c) {
        BUG_CHECK(!field_list_order.empty(), "SignExtend on nonexistant field");
        int size = c->expr->type->width_bits();
        auto *field = field_list_order.back()->to<PHV::FieldSlice>();
        for (int i = c->type->width_bits(); i > size; --i) {
            field_list_order.insert(field_list_order.end() - 1,
                new PHV::FieldSlice(*field, le_bitrange(size - 1, size - 1))); } }

 public:
    FieldManagement(ContByteConversion &map_alloc,
                    safe_vector<PHV::AbstractField*> &field_list_order, const IR::Expression *field,
                    std::map<cstring, bitvec> &fields_needed, cstring name, const PhvInfo &phv,
                    KeyInfo &ki)
    : map_alloc(map_alloc), field_list_order(field_list_order), fields_needed(fields_needed),
      name(name), phv(phv), ki(ki) { field->apply(*this); }
};

/** In order to prevent some overlay bugs by the driver, this guarantees that if a table matches
 *  on multiple overlaid bits, that these bits appear twice in the match key.  One could in
 *  theory have a ternary match table that has the following:
 *
 *  key {
 *       h1.f1 : ternary;
 *       h2.f1 : ternary;
 *  }
 *
 *  where if h1.f1 and h2.f1 are never live at the same time, could be that a don't care
 *  match is always turned on for at least one of the two fields.  This could potentially
 *  be a save on logical tables.
 *
 *  However, the driver currently writes the fields in the order in the context JSON, not in
 *  the order of write don't care before do care, and in this instance, if these fields
 *  were overlaid on the match, could potentially overwrite one of the fields.
 *
 *  Thus currently, the fields have to appear multiple times within the match, and as of
 *  right now, also need to appear multiple times on the IXBar.  In some cases this might
 *  not be true.  For ternary table, a single byte in the match must be a single byte in the
 *  ixbar.  However, for exact match, a byte can be swizzled multiple times, which we take
 *  advantage of in an ATCAM match to save room.  However the compiler will not do this for
 *  multiple appearances of overlaid fields.
 *
 *  Furthermore, each byte is classified by a byte_speciaility_t.  Bytes with different
 *  specialities themselves will not be overlaid during the allocation process.  This management
 *  just becomes difficult
 *
 */
void IXBar::create_alloc(ContByteConversion &map_alloc, IXBar::Use &alloc) {
    for (auto &entry : map_alloc) {
        safe_vector<IXBar::Use::Byte> created_bytes;
        for (auto &fi : entry.second) {
            bool add_byte = true;
            int index = 0;
            for (auto c_byte : created_bytes) {
                if ((c_byte.bit_use & fi.cont_loc()).popcount() == 0) {
                    add_byte = false;
                    break;
                }
                index++;
            }
            if (add_byte)
                created_bytes.emplace_back(entry.first);
            created_bytes[index].field_bytes.push_back(fi);
            created_bytes[index].bit_use |= fi.cont_loc();
        }
        alloc.use.insert(alloc.use.end(), created_bytes.begin(), created_bytes.end());
    }

    // Putting the fields in container order so the visualization prints them out in
    // le_bitrange order
    for (auto &byte : alloc.use) {
        std::sort(byte.field_bytes.begin(), byte.field_bytes.end(),
            [](const FieldInfo &a, const FieldInfo &b) {
            return a.cont_lo < b.cont_lo;
        });
    }
}

/* This visitor is used by stateful tables to find the fields needed and add them to the
 * use info */

Visitor::profile_t IXBar::FindSaluSources::init_apply(const IR::Node *root) {
    profile_t rv = MauInspector::init_apply(root);
    if (!tbl->for_dleft() || tbl->match_key.empty())
        return rv;
    dleft = true;
    KeyInfo ki;
    for (auto read : tbl->match_key) {
        if (!read->for_dleft())
            continue;
        FieldManagement(map_alloc, field_list_order, read->expr, fields_needed,
                        tbl->name, phv, ki);
    }
    return rv;
}

bool IXBar::FindSaluSources::preorder(const IR::MAU::StatefulAlu *) {
    return !dleft;
}

bool IXBar::FindSaluSources::preorder(const IR::MAU::SaluAction *a) {
    visit(a->action, "action");  // just visit the action instructions
    return false;
}

bool IXBar::FindSaluSources::preorder(const IR::Expression *e) {
    boost::optional<cstring> aliasSourceName = phv.get_alias_name(e);
    le_bitrange bits;
    KeyInfo ki;
    if (auto *finfo = phv.field(e, &bits)) {
        FieldManagement(map_alloc, field_list_order, e, fields_needed, tbl->name, phv, ki);
        if (!findContext<IR::MAU::IXBarExpression>())
            phv_sources.insert(std::make_pair(finfo, bits));
        return false;
    }
    return true;
}

bool IXBar::FindSaluSources::preorder(const IR::MAU::HashDist *) {
    // Handled in a different section
    return false;
}

bool IXBar::FindSaluSources::preorder(const IR::MAU::IXBarExpression *e) {
    for (auto ex : hash_sources)
        if (ex->equiv(*e))
            return true;
    hash_sources.push_back(e);
    return true;
}

bool IXBar::allocMatch(bool ternary, const IR::MAU::Table *tbl,
                       const PhvInfo &phv, Use &alloc,
                       safe_vector<IXBar::Use::Byte *> &alloced,
                       hash_matrix_reqs &hm_reqs) {
    alloc.ternary = ternary;
    if (tbl->match_key.empty()) return true;
    ContByteConversion map_alloc;
    std::map<cstring, bitvec> fields_needed;
    KeyInfo ki;
    ki.is_atcam = tbl->layout.atcam;
    for (auto ixbar_read : tbl->match_key) {
        if (!ixbar_read->for_match())
            continue;
        FieldManagement(map_alloc, alloc.field_list_order, ixbar_read, fields_needed,
                        tbl->name, phv, ki);
    }

    create_alloc(map_alloc, alloc);
    LOG3("need " << alloc.use.size() << " bytes for table " << tbl->name);

    bool rv = find_alloc(alloc.use, ternary, alloced, hm_reqs);
    if (!ternary && !tbl->layout.atcam && rv)
        alloc.compute_hash_tables();
    if (!rv) alloc.clear();

    alloc.type = Use::MATCH;
    alloc.used_by = tbl->match_table->externalName();
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

/**
 * Really should be replaced by an extern function call: P4C-1107
 */
void IXBar::determine_proxy_hash_alg(const IR::MAU::Table *tbl, Use &alloc, int group) {
    bool hash_function_found = false;
    auto annot = tbl->match_table->getAnnotations();
    if (auto s = annot->getSingle("proxy_hash_algorithm")) {
        auto pragma_val = s->expr.at(0)->to<IR::StringLiteral>();
        if (pragma_val == nullptr) {
            ::error("%s: proxy_hash_algorithm pragma on table %s must be a string", tbl->srcInfo,
                    tbl->name);
        } else if (alloc.proxy_hash_key_use.algorithm.setup(pragma_val)) {
            hash_function_found = true;
            alloc.proxy_hash_key_use.alg_name = pragma_val->value;
        }
    }
    if (!hash_function_found) {
        alloc.proxy_hash_key_use.algorithm = IR::MAU::HashFunction::random();
        alloc.proxy_hash_key_use.alg_name = "random";
    }

    if (alloc.proxy_hash_key_use.algorithm.type == IR::MAU::HashFunction::IDENTITY)
        ::error("%s: A proxy hash table with an identity algorithm is not supported, as specified "
                "on table %s.  Just use a normal exact match table", tbl->srcInfo, tbl->name);

    int start_bit = alloc.proxy_hash_key_use.hash_bits.ffs();
    std::map<int, le_bitrange> bit_starts;
    int bits_seen = 0;
    do {
        int end_bit = alloc.proxy_hash_key_use.hash_bits.ffz(start_bit);
        int p4_lo = bits_seen;
        int p4_hi = p4_lo + end_bit - start_bit - 1;
        bit_starts[start_bit] = { p4_lo, p4_hi };
        bits_seen += end_bit - start_bit;
        start_bit = alloc.proxy_hash_key_use.hash_bits.ffs(end_bit);
    } while (start_bit >= 0);
    alloc.hash_seed[group]
        |= determine_final_xor(&alloc.proxy_hash_key_use.algorithm, bit_starts,
                               alloc.field_list_order, alloc.total_input_bits());
}

/**
 * This function is to determine the galois matrix/ixbar requirements for the key to be
 * used in the hash matrix function.  This is responsible for programming the
 * proxy_hash_key_use portion of a Use object.
 *
 * This specifically coordinates with the proxy_hash_function JSON node in the compiler
 */
bool IXBar::allocProxyHashKey(const IR::MAU::Table *tbl, const PhvInfo &phv,
        const LayoutOption *lo, Use &alloc, hash_matrix_reqs &hm_reqs) {
    if (tbl->match_key.empty()) return true;
    ContByteConversion map_alloc;
    std::map<cstring, bitvec> fields_needed;
    safe_vector<Use::Byte *> alloced;
    KeyInfo ki;
    for (auto ixbar_read : tbl->match_key) {
        if (!ixbar_read->for_match())
            continue;
        FieldManagement(map_alloc, alloc.field_list_order, ixbar_read, fields_needed,
                        tbl->name, phv, ki);
    }

    create_alloc(map_alloc, alloc);
    LOG3("need " << alloc.use.size() << " bytes for proxy hash key of table " << tbl->name);

    bool rv = find_alloc(alloc.use, false, alloced, hm_reqs);
    if (!rv) {
        alloc.clear();
        return false;
    }

    unsigned hash_table_input = alloc.compute_hash_tables();
    int hash_group = getHashGroup(hash_table_input);
    if (hash_group < 0) {
        alloc.clear();
        return false;
    }

    // Determining what bits are available are within the hash matrix
    bitvec unavailable_bits;
    for (int index = 0; index < HASH_INDEX_GROUPS; index++) {
        for (auto ht : bitvec(hash_table_input)) {
            if ((1 << ht) & hash_index_inuse[index]) {
                unavailable_bits.setrange(index * RAM_LINE_SELECT_BITS, RAM_LINE_SELECT_BITS);
            }
        }
    }
    for (int bit = 0; bit < HASH_SINGLE_BITS; bit++) {
        for (auto ht : bitvec(hash_table_input)) {
            if ((1 << ht) & hash_index_inuse[bit]) {
                unavailable_bits.setbit(bit + RAM_SELECT_BIT_START);
            }
        }
    }

    bitvec available_bits = bitvec(0, HASH_MATRIX_SIZE) - unavailable_bits;
    if (available_bits.popcount() < lo->layout.match_width_bits) {
        alloc.clear();
        return false;
    }

    // Breaking up the possible available bits into bytes, which will be the bytes
    // compared in the match format
    safe_vector<std::pair<int, bitvec>> hash_bytes_used;
    for (int i = 0; i < HASH_MATRIX_SIZE; i+= 8) {
        bitvec value = available_bits.getslice(i, 8);
        if (value.empty())
            continue;
        hash_bytes_used.emplace_back(i, value);
    }

    // Pick the bytes that have the most available bits to perform a comparison
    std::sort(hash_bytes_used.begin(), hash_bytes_used.end(),
              [](const std::pair<int, bitvec> &a, const std::pair<int, bitvec> &b) {
        int t;
        if ((t = a.second.popcount() - b.second.popcount()) != 0)
            return t > 0;
        return a.first < b.first;
    });

    bitvec used_bits;
    for (auto pair : hash_bytes_used) {
        int bits_required = lo->layout.match_width_bits - used_bits.popcount();
        if (bits_required == 0)
            break;
        else if (bits_required < 0)
            BUG("Proxy hash calculation error in ixbar for table %s", tbl->name);
        bitvec possible_byte_bits = pair.second;
        bitvec unused_byte_bits;
        int extra_bits = possible_byte_bits.popcount() - bits_required;
        if (extra_bits > 0) {
            int bits_removed = 0;
            for (auto bit : possible_byte_bits) {
                if (bits_removed == extra_bits)
                    break;
                unused_byte_bits.setbit(bit);
                bits_removed++;
            }
        }
        bitvec used_byte_bits = possible_byte_bits - unused_byte_bits;
        used_bits |= (used_byte_bits << pair.first);
    }

    // Write all of the data structures
    unsigned indexes = index_groups_used(used_bits);
    for (auto idx : bitvec(indexes)) {
        for (auto ht : bitvec(hash_table_input))
            hash_index_use[ht][idx] = tbl->name + "$proxy_hash";
        hash_index_inuse[idx] = hash_table_input;
    }
    unsigned select_bits = select_bits_used(used_bits);
    for (auto bit : bitvec(select_bits)) {
        for (auto ht : bitvec(hash_table_input))
            hash_single_bit_use[ht][bit] = tbl->name + "$proxy_hash";
        hash_single_bit_inuse[bit] = hash_table_input;
    }
    hash_group_use[hash_group] |= hash_table_input;

    fill_out_use(alloced, false);
    alloc.hash_table_inputs[hash_group] = hash_table_input;
    alloc.proxy_hash_key_use.allocated = true;
    alloc.proxy_hash_key_use.group = hash_group;
    alloc.proxy_hash_key_use.hash_bits = used_bits;
    determine_proxy_hash_alg(tbl, alloc, hash_group);
    return true;
}

/**
 * A proxy hash table is an implementation of a match table where instead of matching directly
 * on a key, the match is on a calculated hash of that key.
 *
 * In the diagram in the uArch section 6.2.3 Exact Match Row Vertical/Horizontal (VH) bars,
 * a search bus can be sourced from either any of the 8 input xbar groups, or any of the 8
 * hash groups.  A standard match table would match on the search data, while a proxy hash
 * matches on the hash data.
 *
 * The proxy hash table is a choice for the P4 programmer.  A proxy hash can pack more
 * tightly than a standard match table, as the hash bits can be significantly smaller than
 * match bits would be.  This of course comes at the risks of collisions on entries.
 *
 * A proxy hash table requires two hash functions, one to determine the RAM position of the
 * key (similar to any SRam based match table), and a second hash for the comparison of the
 * hash key. 
 */
bool IXBar::allocProxyHash(const IR::MAU::Table *tbl, const PhvInfo &phv, const LayoutOption *lo,
        Use &alloc, Use &proxy_hash_alloc) {
    safe_vector<IXBar::Use::Byte *> alloced;
    safe_vector<Use> all_tbl_allocs;
    bool finished = false;
    size_t start = 0; size_t last = 0;
    while (!finished) {
        Use next_alloc;
        layout_option_calculation(lo, start, last);
        /* Essentially a calculation of how much space is potentially available */
        auto hm_reqs = match_hash_reqs(lo, start, last, false);
        auto max_hm_reqs = hash_matrix_reqs::max(false, false);

        if (!(allocMatch(false, tbl, phv, next_alloc, alloced, hm_reqs)
            && allocAllHashWays(false, tbl, next_alloc, lo, start, last))
            && !(allocMatch(false, tbl, phv, next_alloc, alloced, max_hm_reqs)
            && allocAllHashWays(false, tbl, next_alloc, lo, start, last))) {
            next_alloc.clear();
            alloc.clear();
            return false;
        } else {
           fill_out_use(alloced, false);
        }
        alloced.clear();
        all_tbl_allocs.push_back(next_alloc);
        if (last == lo->way_sizes.size())
            finished = true;
    }
    for (auto a : all_tbl_allocs) {
        alloc.add(a);
    }

    hash_matrix_reqs ph_hm_reqs;
    ph_hm_reqs.index_groups = max_index_group(lo->layout.match_width_bits);
    ph_hm_reqs.select_bits = max_index_single_bit(lo->layout.match_width_bits);
    auto max_ph_hm_reqs = hash_matrix_reqs::max(false, false);

    if (!allocProxyHashKey(tbl, phv, lo, proxy_hash_alloc, ph_hm_reqs)
        && !allocProxyHashKey(tbl, phv, lo, proxy_hash_alloc, max_ph_hm_reqs)) {
        alloc.clear();
        proxy_hash_alloc.clear();
        return false;
    }
    return true;
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

    // If a random_seed is specified via pragma, do not generate the random seed here.
    if (tbl->random_seed >= 0)
        return true;

    LOG3("IXBarRandom seed: " << IXBarRandom::seed);
    if (layout_option->identity) {
        LOG3(" Used as identity function.");
        return true;
    }

    std::map<unsigned, std::set<std::pair<unsigned, unsigned>>> requiredSeedCombinations;
    for (auto way : alloc.way_use)
        requiredSeedCombinations[way.group].insert(std::make_pair(way.slice, way.mask));

    for (auto kv : requiredSeedCombinations) {
        unsigned group = kv.first;
        for (auto v : kv.second) {
            LOG3("  Way details: " << kv.first << ", " << v.first << ", " << v.second);
            unsigned slice = v.first;
            unsigned mask = v.second;
            unsigned random_number = IXBarRandom::nextRandomNumber(10);
            bitvec random_seed = bitvec(random_number) << (10 * slice);
            bitvec mask_bits(mask);
            bitvec mask_seed;
            for (auto b : mask_bits) {
                unsigned random_bit = IXBarRandom::nextRandomNumber();
                bitvec random_bit_seed = bitvec(random_bit) << b;
                mask_seed |= random_bit_seed;
            }
            LOG3("    Random number: " << random_number << ", Random seed: " << random_seed <<
                 ", Mask bits: " << mask_bits << ", Mask seed: " << (mask_seed << 40));
            random_seed |= (mask_seed << 40);
            LOG3("  Random seed: " << random_seed);
            alloc.hash_seed[group] |= random_seed;
        }
    }
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
    ContByteConversion map_alloc;
    Use alloc;
    std::map<cstring, bitvec> fields_needed;
    safe_vector<Use::Byte *> alloced;
    hash_matrix_reqs hm_reqs;

    if (second_try) {
        hm_reqs = hash_matrix_reqs::max(false);
    } else {
        hm_reqs.index_groups = 1;
        hm_reqs.select_bits = std::max(tbl->layout.partition_bits - TableFormat::RAM_GHOST_BITS, 0);
    }

    KeyInfo ki;
    ki.is_atcam = true;
    ki.partition = true;
    ki.partition_bits = tbl->layout.partition_bits;
    for (auto ixbar_read : tbl->match_key) {
        if (!ixbar_read->for_match())
            continue;
        FieldManagement(map_alloc, alloc.field_list_order, ixbar_read, fields_needed,
                        tbl->name, phv, ki);
    }
    create_alloc(map_alloc, alloc);
    BUG_CHECK(alloc.use.size() > 0, "No partition index found for %1%", tbl);

    bool rv = find_alloc(alloc.use, false, alloced, hm_reqs);
    alloc.type = Use::MATCH;
    alloc.used_by = tbl->match_table->externalName();

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
    int hash_bus_bits = 0;
    bool xor_required = false;
    CollectGatewayFields collect(phv);
    tbl->apply(collect);
    if (collect.info.empty()) return true;

    ContByteConversion map_alloc;

    for (auto &info : collect.info) {
        int flags = 0;

        if (!info.second.xor_with.empty()) {
            flags |= IXBar::Use::NeedXor;
            // FIXME: This need to be coordinated with the actual PHV!!!
            xor_required = true;
        } else if (info.second.need_range) {
            flags |= IXBar::Use::NeedRange;
            hash_bus_bits += info.first.size();
        }
        cstring aliasSourceName;
        if (collect.info_to_uses.count(&info.second)) {
            LOG5("Found gateway alias source name");
            aliasSourceName = collect.info_to_uses[&info.second];
        }
        if (aliasSourceName)
            add_use(map_alloc, info.first.field(), phv, aliasSourceName, &info.first.range(), flags,
                    NO_BYTE_TYPE);
        else
            add_use(map_alloc, info.first.field(), phv, boost::none, &info.first.range(), flags,
                    NO_BYTE_TYPE);
    }
    safe_vector<IXBar::Use::Byte *> xbar_alloced;

    create_alloc(map_alloc, alloc);

    hash_matrix_reqs hm_reqs;
    if (second_try) {
        hm_reqs.select_bits = HASH_SINGLE_BITS;
    } else {
        hm_reqs.select_bits = hash_bus_bits;
    }
    // More constraied than necessary, if the gateway only requires hash bits, but the
    // search bus requirements must be on one and only one search bus
    hm_reqs.max_search_buses = 1;

    if (!find_alloc(alloc.use, false, xbar_alloced, hm_reqs)) {
        alloc.clear();
        return false; }
    if (!collect.compute_offsets()) {
        alloc.clear();
        LOG3("collect.compute_offsets failed?");
        return false; }

    if (collect.bits) {
        alloc.gw_hash_group = true;
    }
    if (collect.bytes > 0) {
        alloc.gw_search_bus = true;
        alloc.gw_search_bus_bytes = collect.bytes;
        if (xor_required)
            alloc.gw_search_bus_bytes += GATEWAY_SEARCH_BYTES;
    }

    alloc.type = Use::GATEWAY;
    alloc.used_by = tbl->name;

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
                alloc.bit_use.emplace_back(info.first.field()->name, hash_group, offset.second.lo,
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

/**
 * For a meter alu input through hash, the hash output goes through a byte mask.  Thus
 * the hash matrix must reserve up to the byte position of the upper most bit
 */
int IXBar::max_bit_to_byte(bitvec bit_mask) {
    int max_bit = bit_mask.max().index();
    int rv = ((max_bit + 8) / 8) * 8 - 1;
    rv = std::min(rv, METER_ALU_HASH_BITS);
    return rv;
}

int IXBar::max_index_group(int max_bit) {
    int total_max = (max_bit + TableFormat::RAM_GHOST_BITS - 1) / TableFormat::RAM_GHOST_BITS;
    return std::min(total_max, HASH_INDEX_GROUPS);
}

int IXBar::max_index_single_bit(int max_bit) {
    int max_single_bit = max_bit - TableFormat::RAM_GHOST_BITS * HASH_INDEX_GROUPS;
    max_single_bit = std::max(max_single_bit, 0);
    BUG_CHECK(max_single_bit <= HASH_SINGLE_BITS, "Requesting a bit beyond the size of the "
              "Galois matrix");
    return max_single_bit;
}

bool IXBar::hash_use_free(int max_group, int max_single_bit, unsigned hash_table_input) {
    for (int i = 0; i < HASH_TABLES; i++) {
        if (((1 << i) & hash_table_input) == 0)
            continue;
        for (int j = 0; j < max_group; j++) {
            if ((hash_index_inuse[j] & (1 << i)) != 0)
                return false;
        }
        for (int j = 0; j < max_single_bit; j++) {
            if ((hash_single_bit_inuse[j] & (1 << i)) != 0)
                return false;
        }
    }
    return true;
}

void IXBar::write_hash_use(int max_group, int max_single_bit, unsigned hash_table_input,
        cstring name) {
    for (int i = 0; i < HASH_TABLES; i++) {
        if (((1 << i) & hash_table_input) == 0)
            continue;
        for (int j = 0; j < max_group; j++) {
            hash_index_use[i][j] = name;
            hash_index_inuse[j] |= (1 << i);
        }
        for (int j = 0; j < max_single_bit; j++) {
            hash_single_bit_use[i][j] = name;
            hash_single_bit_inuse[j] |= (1 << i);
        }
    }
}

/** The Meter ALU, responsible for any meters, selectors, or stateful ALU operations
 *  potentially needs information from PHV in order to perform the associated
 *  calculations.  The allocSelector, allocMeter, and allocStateful are to determine
 *  the requirements and the allocation of these values to the ALU.
 *
 *  Data can reach the ALU through two pathways, either through a search bus or after
 *  a hash calculation.
 *
 *  The pathway for the search bus is described in section 6.2.3 Exact Match Row
 *  Veritical/Horizontal (VH) Xbars.  In the diagram, on each row, a bus headed directly
 *  to the meter ALU block can come from any 8 of the input xbar groups.  In Tofino,
 *  the upper 8 bytes go through, while on JBay, the entirety of the input xbar group
 *  can go through.  However, unlike the normal search buses, there is no byte swizzler.
 *  The group is ANDed with a byte_mask
 *
 *  The hash pathway is described in section 6.2.4.8.1 Exact Match RAM Addressing.  The Galois
 *  matrix can be used to calculate any kind of hash, or if the alignment on the search bus
 *  is not possible, then the hash matrix can be used to position any of the search bus
 *  results into the correct position.  However, the limitation is that this can only
 *  process up to 51 bits, rather than the full range occasionally needed by wide stateful
 *  ALU tables
 */

/** Selector allocation algorithm.  Currently reserves an entire section of hash matrix,
 *  even if the selector is only on fair mode, rather than resilient
 */
bool IXBar::allocSelector(const IR::MAU::Selector *as, const IR::MAU::Table *tbl,
                          const PhvInfo &phv, Use &alloc, cstring name) {
    auto pos = allocated_attached.find(as);
    if (pos != allocated_attached.end()) {
        alloc = pos->second;
        return true;
    }

    safe_vector<IXBar::Use::Byte *>  alloced;
    ContByteConversion map_alloc;
    std::map<cstring, bitvec>        fields_needed;
    KeyInfo ki;
    for (auto ixbar_read : tbl->match_key) {
        if (!ixbar_read->for_selection()) continue;
        FieldManagement(map_alloc, alloc.field_list_order, ixbar_read->expr, fields_needed,
                        tbl->name, phv, ki);
    }
    create_alloc(map_alloc, alloc);

    LOG3("need " << alloc.use.size() << " bytes for table " << tbl->name);
    hash_matrix_reqs hm_reqs = hash_matrix_reqs::max(false);
    bool rv = find_alloc(alloc.use, false, alloced, hm_reqs);
    unsigned hash_table_input = 0;
    if (rv)
         hash_table_input = alloc.compute_hash_tables();
    if (!rv) alloc.clear();

    if (!rv) return false;

    alloc.type = Use::SELECTOR;
    alloc.used_by = as->name + "";

    int hash_group = getHashGroup(hash_table_input);
    if (hash_group < 0) {
        alloc.clear();
        return false;
    }

    auto &mah = alloc.meter_alu_hash;

    mah.allocated = true;
    mah.group = hash_group;
    mah.algorithm = as->algorithm;
    int mode_width_bits = as->mode == "resilient" ? RESILIENT_MODE_HASH_BITS : FAIR_MODE_HASH_BITS;

    if (mah.algorithm.size_from_algorithm()) {
        if (mode_width_bits > mah.algorithm.size) {
            // FIXME: Debatably be moved to an error, but have to wait on a p4-tests update
            ::warning("%s: The algorithm for selector %s has a size of %d bits, when the mode "
                      "selected requires %d bits", as->srcInfo, as->name, mah.algorithm.size,
                    mode_width_bits);
            // alloc.clear();
            // return false;
        }
    }

    // Mark the positions of each of the fields on the identity hash, so that the
    // asm_output can easily locate the positions of all of the the associated fields
    if (mah.algorithm.type == IR::MAU::HashFunction::IDENTITY) {
        int bits_seen = 0;
        for (auto it = alloc.field_list_order.rbegin(); it != alloc.field_list_order.rend(); it++) {
            auto fs = *it;
            le_bitrange bits = fs->range();
            int diff = bits_seen + bits.size() - mode_width_bits;
            if (diff > 0) {
                bits.hi -= diff;
            }
            mah.identity_positions[fs->field()].emplace_back(bits_seen, fs->field(), bits);
            bits_seen += bits.size();
            if (bits_seen >= mode_width_bits)
                break;
        }

        if (bits_seen < mode_width_bits) {
            // FIXME: See above at previous FIXME
            ::warning("%s: The identity hash for selector %s has a size of %d bits, when the mode "
                      "selected required %d bits", as->srcInfo, as->name, bits_seen,
                       mode_width_bits);
            // alloc.clear();
            // return false;
        }
    }
    mah.bit_mask.setrange(0, mode_width_bits);
    alloc.hash_table_inputs[hash_group] = hash_table_input;
    int max_bit = max_bit_to_byte(mah.bit_mask);
    int max_group = max_index_group(max_bit);
    int max_single_bit = max_index_single_bit(max_bit);
    BUG_CHECK(hash_use_free(max_group, max_single_bit, hash_table_input), "The calculation for "
              "the hash matrix should be completely free at this point");
    write_hash_use(max_group, max_single_bit, hash_table_input, alloc.used_by);
    fill_out_use(alloced, false);
    hash_group_print_use[hash_group] = name;
    hash_group_use[hash_group] |= hash_table_input;
    return rv;
}

/**
 *  Given a field range, and a byte position to start the allocation on the ixbar, can that
 *  field be allocated starting from lo to hi within that search bus position.
 */
bool IXBar::can_allocate_on_search_bus(IXBar::Use &alloc, const PHV::Field *field,
        le_bitrange range, int ixbar_position) {
    bitvec seen_bits;

    for (auto &byte : alloc.use) {
        // Because the mask is per byte rather than per bit, the rest of the bit needs to be empty
        if (byte.bit_use != byte.non_zero_bits)
            return false;
        if (byte.field_bytes.size() > 1)
            return false;
        auto &fi = byte.field_bytes[0];
        if (fi.field != field->name)
            continue;
        if (fi.width() != 8 && fi.hi != range.hi) {
            LOG4("  not byte aligned: " << fi);
            return false; }
        if (fi.cont_loc().min().index() != 0) {
            LOG4("  not in bit 0 of byte");
            return false; }
        int byte_position = ((fi.lo - range.lo) + 7)/ 8;
        // Validate that the byte, given the PHV allocation for that particular byte
        if (align_flags[(ixbar_position + byte_position) & 3] & byte.flags) {
            LOG4("  not aligned within container for ixbar");
            return false; }
        seen_bits.setrange(fi.lo, fi.width());
    }
    if (!seen_bits.is_contiguous() || !(seen_bits.min().index() == range.lo)
        || !(seen_bits.max().index() == range.hi)) {
        LOG4("  not the right bits for the range");
        return false; }
    return true;
}

/** Allocation of the meter input xbar if it is an LPF or WRED.  On Tofino, specifically have
 *  to reserve bytes 8-11 of a specific input xbar group currently.
 *
 *  Similar to stateful ALU allocation, except in the LPF/WRED case it is only one field,
 *  and thus one input xbar source
 */
bool IXBar::allocMeter(const IR::MAU::Meter *mtr, const IR::MAU::Table *tbl, const PhvInfo &phv,
                       Use &alloc, bool on_search_bus) {
    auto pos = allocated_attached.find(mtr);
    if (pos != allocated_attached.end()) {
        alloc = pos->second;
        return true;
    }

    if (!mtr->alu_output())
        return true;
    if (mtr->input == nullptr)
        return true;
    ContByteConversion map_alloc;
    safe_vector<IXBar::Use::Byte *> alloced;
    std::set<cstring> fields_needed;
    boost::optional<cstring> aliasSourceName = phv.get_alias_name(mtr->input);
    le_bitrange bits;

    auto *finfo = phv.field(mtr->input, &bits);
    BUG_CHECK(finfo, "%s: The input for %s does not have a PHV allocation", mtr->srcInfo,
              mtr->name);
    if (!fields_needed.count(finfo->name)) {
        fields_needed.insert(finfo->name);
        add_use(map_alloc, finfo, phv, aliasSourceName, &bits, 0, IXBar::NO_BYTE_TYPE);
    }
    create_alloc(map_alloc, alloc);

    unsigned byte_mask = ~0U;
    hash_matrix_reqs hm_reqs;
    if (on_search_bus) {
        if (!can_allocate_on_search_bus(alloc, finfo, bits, 0)) {
            alloc.clear();
            return false;
        }
        // Because the names of the Bytes are based on containers, the bytes need to be sorted in
        // field order for the allocation to work.
        std::sort(alloc.use.begin(), alloc.use.end(),
            [&](const IXBar::Use::Byte &a, const IXBar::Use::Byte &b) {
            auto a_fi = a.field_bytes[0];
            auto b_fi = b.field_bytes[0];
            return a_fi < b_fi;
        });
        // Byte mask for a meter is 4 bytes
        byte_mask = ((1U << LPF_INPUT_BYTES) - 1);
        if (Device::currentDevice() == Device::TOFINO)
            byte_mask <<= TOFINO_METER_ALU_BYTE_OFFSET;
        hm_reqs.max_search_buses = 1;
    } else {
        hm_reqs.index_groups = HASH_INDEX_GROUPS;
    }

    LOG3("Alloc meter " << mtr->name << " on_search_bus " << on_search_bus << " with "
          << alloc.use.size() << " bytes");

    if (!find_alloc(alloc.use, false, alloced, hm_reqs, byte_mask)) {
        alloc.clear();
        return false;
    }

    alloc.type = Use::METER;
    if (mtr->direct)
        alloc.used_by = tbl->match_table->externalName() + "$meter";
    else
        alloc.used_by = mtr->name + "";

    if (!on_search_bus) {
        auto &mah = alloc.meter_alu_hash;
        unsigned hash_table_input = alloc.compute_hash_tables();
        int hash_group = getHashGroup(hash_table_input);
        if (hash_group < 0) {
            alloc.clear();
            return false;
        }

        mah.allocated = true;
        mah.group = hash_group;
        mah.bit_mask.setrange(0, bits.size());
        mah.algorithm = IR::MAU::HashFunction::identity();
        mah.identity_positions[finfo].emplace_back(0, finfo, bits);
        int max_bit = max_bit_to_byte(mah.bit_mask);
        int max_group = max_index_group(max_bit);
        int max_single_bit = max_index_single_bit(max_bit);
        BUG_CHECK(hash_use_free(max_group, max_single_bit, hash_table_input), "The calculation "
                  "for the hash matrix should be completely free at this point");
        write_hash_use(max_group, max_single_bit, hash_table_input, alloc.used_by);
        alloc.hash_table_inputs[mah.group] = hash_table_input;
        hash_group_print_use[hash_group] = alloc.used_by;
        hash_group_use[hash_group] |= hash_table_input;
    }

    fill_out_use(alloced, false);
    return true;
}

/**
 *  Given a list of PHV fields that have are sources for this Stateful Alu, see if their
 *  given PHV allocation can fit through the search bus.  This will also reset the order
 *  of the bytes in the allocation if the order is to be reversed.
 *
 */
bool IXBar::setup_stateful_search_bus(const IR::MAU::StatefulAlu *salu, Use &alloc,
       ordered_set<std::pair<const PHV::Field *, le_bitrange>> &phv_sources,
       unsigned &byte_mask) {
    int width = salu->source_width()/8U;
    int ixbar_initial_position = 0;
    if (Device::currentDevice() == Device::TOFINO)
        ixbar_initial_position = TOFINO_METER_ALU_BYTE_OFFSET;

    bool phv_src_reserved[2] = { false, false };
    bool reversed = false;
    int total_sources = salu->dual ? 2 : 1;

    int source_index = 0;
    // Check to see which input xbar positions the sources can be allocated to
    for (auto &source : phv_sources) {
        auto field = source.first;
        auto range = source.second;
        bool can_fit[2] = { false, false };
        bool can_fit_anywhere = false;
        for (int i = 0; i < total_sources; i++) {
            if (phv_src_reserved[i])
                continue;
            can_fit[i] = can_allocate_on_search_bus(alloc, field, range, i * width);
            can_fit_anywhere |= can_fit[i];
        }
        if (!can_fit_anywhere)
            return false;
        // If a source can only fit in one of the two input xbar positions, reserve
        // that position for that source
        if (can_fit[0] && !can_fit[1])
            phv_src_reserved[0] = true;
        if (can_fit[1] && !can_fit[0])
            phv_src_reserved[1] = true;

        // If the first source is in the second position on the input xbar, then
        // reverse the vector of bytes for the allocation
        if (source_index == 0 && phv_src_reserved[1])
            reversed = true;
    }

    safe_vector<PHV::FieldSlice> ixbar_source_order;

    // Up to two sources on the stateful ALU.  The sources are ordered from the FindSaluSources.
    // An order from low bit to high byte is required on the input xbar.  If reversed is true,
    // then the order of phv_sources is the opposite of the ixbar_source_order
    for (auto &source : phv_sources) {
        if (reversed)
            ixbar_source_order.emplace(ixbar_source_order.begin(), source.first, source.second);
        else
            ixbar_source_order.emplace_back(source.first, source.second);
    }

    // Because the names of the Bytes are based on containers, the bytes need to be sorted in
    // field order for the allocation to work.
    auto first_field = ixbar_source_order[0].field();
    std::sort(alloc.use.begin(), alloc.use.end(),
        [&](const IXBar::Use::Byte &a, const IXBar::Use::Byte &b) {
        auto a_fi = a.field_bytes[0];
        auto b_fi = b.field_bytes[0];
        if (a_fi.field == first_field->name && b_fi.field != first_field->name)
            return true;
        if (a_fi.field != first_field->name && b_fi.field == first_field->name)
            return false;
        return a_fi.lo < b_fi.lo;
    });

    // This handles the corner case of a single source that can only go into the phv_hi slot
    // of the stateful alu
    if (reversed && phv_sources.size() == 1) {
        ixbar_initial_position += width;
    }

    byte_mask = 0;
    for (auto source : phv_sources) {
        unsigned source_byte_mask = (1 << ((source.second.size() + 7) / 8)) - 1;
        byte_mask |= source_byte_mask << ixbar_initial_position;
        ixbar_initial_position += width;
    }
    return true;
}

/**
 *  Determines whether a stateful ALU can fit within a hash bus.  If it can, determine
 *  the positions of these individual sources within the hash matrix, as the Galois
 *  matrix has to set up an identity matrix for this
 */
bool IXBar::setup_stateful_hash_bus(const PhvInfo &phv, const IR::MAU::StatefulAlu *salu,
        Use &alloc, bool dleft,
        ordered_set<std::pair<const PHV::Field *, le_bitrange>> &phv_sources,
        std::vector<const IR::MAU::IXBarExpression *> &hash_sources) {
    auto &mah = alloc.meter_alu_hash;
    unsigned hash_table_input = alloc.compute_hash_tables();
    int hash_group = getHashGroup(hash_table_input);
    if (hash_group < 0) {
        alloc.clear();
        return false;
    }

    mah.allocated = true;
    mah.group = hash_group;
    if (dleft) {
        mah.algorithm = IR::MAU::HashFunction::random();
        mah.bit_mask.setrange(1, METER_ALU_HASH_BITS);
        // For dleft digest, we need a fixed 1 bit to ensure the digest is nonzero
        // as the valid bit is not contiguous with the digest in the sram field, so
        // trying to match it would waste more hash bits.
        alloc.hash_seed[hash_group] = bitvec(1);
    } else {
        mah.algorithm = IR::MAU::HashFunction::identity();
        bool phv_src_reserved[2] = { false, false };

        int source_index = -1;
        std::set<int> sources_finished;
        for (auto &source : phv_sources) {
            source_index++;
            auto field = source.first;
            auto range = source.second;
            // If a stateful ALU has a dual 32 bit function, if one of the sources is
            // greater than 51 (Size of Hash Matrix Output) - 32 (Size of Input) = 19 bits
            if (!(salu->source_width() >= 32 && salu->dual && phv_sources.size() == 2
                  && range.size() > METER_ALU_HASH_BITS - salu->source_width()))
                continue;
            int start_bit = 0;
            mah.bit_mask.setrange(start_bit, range.size());
            mah.identity_positions[field].emplace_back(start_bit, field, range);
            phv_src_reserved[0] = true;
            sources_finished.insert(source_index);
        }

        source_index = -1;
        int alu_slot_index = 0;
        for (auto &source : phv_sources) {
            source_index++;
            auto field = source.first;
            auto range = source.second;
            if (sources_finished.count(source_index))
                continue;
            while (alu_slot_index < 2 && phv_src_reserved[alu_slot_index])
                alu_slot_index++;
            if (alu_slot_index >= 2) return false;
            int start_bit = alu_slot_index * salu->source_width();
            mah.identity_positions[field].emplace_back(start_bit, field, range);
            mah.bit_mask.setrange(start_bit, range.size());
            alu_slot_index++;
        }
        for (auto source : hash_sources) {
            while (alu_slot_index < 2 && phv_src_reserved[alu_slot_index])
                alu_slot_index++;
            if (alu_slot_index >= 2) return false;
            int start_bit = alu_slot_index * salu->source_width();
            source->expr->apply(SetupMeterAluHash(phv, mah, start_bit));
            mah.computed_expressions[start_bit] = source->expr;
            mah.bit_mask.setrange(start_bit, salu->source_width());
            alu_slot_index++;
        }
    }

    // Because of a byte mask, must reserve the full byte on the hash bus
    int max_bit = max_bit_to_byte(mah.bit_mask);
    int max_group = max_index_group(max_bit);
    int max_single_bit = max_index_single_bit(max_bit);
    BUG_CHECK(hash_use_free(max_group, max_single_bit, hash_table_input), "The calculation "
              "for the hash matrix should be completely free at this point");
    write_hash_use(max_group, max_single_bit, hash_table_input, alloc.used_by);
    alloc.hash_table_inputs[mah.group] = hash_table_input;
    hash_group_print_use[hash_group] = alloc.used_by;
    hash_group_use[hash_group] |= hash_table_input;
    return true;
}

std::ostream &operator<<(std::ostream &out,
    const ordered_set<std::pair<const PHV::Field *, le_bitrange>> &phv_sources) {
    const char *sep = "phv_sources: ";
    for (auto &el : phv_sources) {
        out << sep << el.first->name << "(" << el.second.lo << ".." << el.second.hi << ")";
        sep = ", "; }
    return out;
}

std::ostream &operator<<(std::ostream &out,
    const std::vector<const IR::MAU::IXBarExpression *> &hash_sources) {
    const char *sep = "  hash_sources: ";
    for (auto &el : hash_sources) {
        out << sep << *el;
        sep = ", "; }
    return out;
}

/**  If a stateful ALU is in dual mode, then the stateful ALU has two possible inputs, which
 *  can go to either the lo or hi ALU.  The sizes of these sources can either be
 *  8, 16, or 32 bits, and the stateful ALU can have either one or two sources.  The inputs
 *  come in from an initial offset on the input xbar.  For Tofino, the start byte is 8,
 *  in JBay, the start byte is 0.
 *
 *  Thus, in dual mode:
 *       the bytes for 8 bit inputs are start_byte and start_byte + 1
 *       the bytes for 16 bit inputs are start_byte and start_byte + 2
 *       the bytes for 32 bit inputs are start_byte and start_byte + 4
 *
 *  Either phv source can go to the alu_lo or alu_hi, so the order in which the stateful
 *  ALU fields are allocated do not matter.
 *
 *  Currently the algorithm only allocates fully on a hash bus or a search bus.  In theory
 *  these could be combined, if the allocation was too constrained for either but not
 *  for both.  In general, it might be easier just to influence PHV allocation in that
 *  case.
 */
bool IXBar::allocStateful(const IR::MAU::StatefulAlu *salu, const IR::MAU::Table *tbl,
                          const PhvInfo &phv, Use &alloc, bool on_search_bus) {
    auto pos = allocated_attached.find(salu);
    if (pos != allocated_attached.end()) {
        alloc = pos->second;
        return true;
    }

    ContByteConversion map_alloc;
    ordered_set<std::pair<const PHV::Field *, le_bitrange>> phv_sources;
    std::vector<const IR::MAU::IXBarExpression *> hash_sources;
    bool dleft = false;
    LOG3("IXBar::allocStateful(" << salu->name << ", " << tbl->name << ", " <<
         (on_search_bus ? "true" : "false") << ")");
    salu->apply(FindSaluSources(*this, phv, map_alloc, alloc.field_list_order, phv_sources,
                                hash_sources, dleft, tbl));
    LOG5("  " << phv_sources << hash_sources);
    create_alloc(map_alloc, alloc);
    if (alloc.use.size() == 0)
        return true;

    unsigned byte_mask = ~0U;
    hash_matrix_reqs hm_reqs;

    if (on_search_bus) {
        if (dleft ||
            !hash_sources.empty() ||
            !setup_stateful_search_bus(salu, alloc, phv_sources, byte_mask)) {
            alloc.clear();
            return false;
        }
        hm_reqs.max_search_buses = 1;
    } else {
        int total_bits = 0;
        for (auto &source : phv_sources) {
            total_bits += source.second.size();
        }
        for (auto source : hash_sources)
            total_bits += source->expr->type->width_bits();
        if (total_bits > METER_ALU_HASH_BITS) {
            LOG4("  total_bits(" << total_bits << ") > METER_ALU_HASH_BITS(" <<
                 METER_ALU_HASH_BITS << ")");
            return false; }
        hm_reqs = hash_matrix_reqs::max(false);
    }


    LOG3("Alloc stateful alu " << salu->name << " " << (on_search_bus ? "" : "!") <<
         "on_search_bus  with " << alloc.use.size() << " bytes");
    safe_vector<IXBar::Use::Byte *> xbar_alloced;
    if (!find_alloc(alloc.use, false, xbar_alloced, hm_reqs, byte_mask)) {
        alloc.clear();
        return false;
    }

    alloc.type = Use::STATEFUL_ALU;
    if (salu->direct)
        alloc.used_by = tbl->match_table->externalName() + "$register";
    else
        alloc.used_by = salu->name + "";

    if (!on_search_bus) {
        if (!setup_stateful_hash_bus(phv, salu, alloc, dleft, phv_sources, hash_sources)) {
            alloc.clear();
            return false;
        }
    }

    LOG3("allocStateful succeeded: " << alloc);
    fill_out_use(xbar_alloced, false);
    return true;
}

/** Allocating hash bits for an indirect address in the table.  Currently checks on a slice
 *  by slice granularity, unless upper bits are required in a longer address, and then will
 *  allocate those upper bits.
 */
bool IXBar::allocHashDistAddress(int bits_required, const unsigned &hash_table_input,
        HashDistAllocParams &hdap, cstring name) {
    bool can_allocate = false;
    int address_group = -1;
    if (bits_required > HASH_DIST_MAX_EXPAND_BITS)
        bits_required = HASH_DIST_MAX_EXPAND_BITS;
    for (int i = 0; i < HASH_DIST_SLICES - 1; i++) {
        bool collision = false;
        if (hdap.used_hash_dist_slices.getbit(i)) continue;
        address_group = i;
        int extra_addr = bits_required - HASH_DIST_BITS;
        for (int j = 0; j < extra_addr; j++) {
            int index = j + 2 * HASH_DIST_BITS + address_group * 7;
            if (hdap.used_hash_dist_bits.getbit(index)) {
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
        hash_dist_inuse[i].setbit(address_group);
        hdap.slice.setbit(address_group);
        int addr_size = (HASH_DIST_BITS < bits_required) ? HASH_DIST_BITS : bits_required;
        for (int j = 0; j < addr_size; j++) {
            int index = address_group * HASH_DIST_BITS + j;
            hash_dist_bit_use[i][index] = name;
            hash_dist_bit_inuse[i].setbit(index);
            hdap.bit_mask.setbit(index);
        }
        hdap.bit_starts[address_group * HASH_DIST_BITS] = { 0, addr_size - 1};
        int extra_addr = bits_required - HASH_DIST_BITS;
        if (extra_addr > 0) {
            hash_dist_use[i][2] = name;
            hash_dist_inuse[i].setbit(2);
            hdap.slice.setbit(2);
            for (int j = 0; j < extra_addr; j++) {
                int index = 2 * HASH_DIST_BITS + address_group * 7 + j;
                hash_dist_bit_use[i][index] = name;
                hash_dist_bit_inuse[i].setbit(index);
                hdap.bit_mask.setbit(index);
            }
            hdap.bit_starts[address_group * 7 + 2 * HASH_DIST_BITS]
                = { HASH_DIST_BITS, bits_required - 1 };
        }
    }
    return true;
}

/** Allocating hash bits for hash calculation.  Currently checks on a slice granularity.  Could
 *  be further optimized for a bit by bit granularity
 */
bool IXBar::allocHashDistImmediate(const IR::MAU::HashDist *hd, const ActionFormat::Use *af,
        const unsigned &hash_table_input, HashDistAllocParams &hdap, cstring name) {
    bool can_allocate = false;
    BUG_CHECK(af->hash_dist_placement.find(hd) != af->hash_dist_placement.end(), "Cannot "
              "allocate immediate hash distribution, as the action format is missing");


    auto &hd_vec = af->hash_dist_placement.at(hd);
    BUG_CHECK(!hd_vec.empty(), "No allocation found for a hash_dist");

    // Coordinate the action format locations with the input xbar hash distribution locations
    std::map<int, le_bitrange> immed_bit_positions;
    bitvec immed_bitmask;
    for (auto &placement : hd_vec) {
        auto &arg_loc = placement.arg_locs[0];
        immed_bitmask |= (placement.slot_bits << (placement.start * 8));
        le_bitrange br = { arg_loc.field_bit, arg_loc.field_hi() };
        immed_bit_positions[placement.start * 8 + placement.slot_bits.min().index()] = br;
    }

    safe_vector<bitvec> masks;
    int hash_dist_groups_needed = 0;
    int position_min = 2;
    for (int i = 0; i < 2; i++) {
        auto small_mask = immed_bitmask.getslice(i * HASH_DIST_BITS, HASH_DIST_BITS);
        if (!small_mask.empty()) {
            hash_dist_groups_needed++;
            masks.push_back(small_mask);
            position_min = std::min(position_min, i);
        }
    }
    position_min *= HASH_DIST_BITS;
    BUG_CHECK(hash_dist_groups_needed > 0, "Hash dist groups allocated but not required?");

    // unsigned avail_groups = ((1 << HASH_DIST_SLICES) - 1) & (~used_hash_dist_slices);

    bitvec total_groups(0, HASH_DIST_SLICES);
    bitvec avail_groups = total_groups - hdap.used_hash_dist_slices;
    if (avail_groups.popcount() - hash_dist_groups_needed >= 0)
        can_allocate = true;
    for (int i = 0; i < HASH_DIST_SLICES; i++) {
        if ((avail_groups.popcount() - hash_dist_groups_needed) == 0)
             break;
        if (!avail_groups.getbit(i))
            continue;
        avail_groups.clrbit(i);
    }

    if (!can_allocate) return false;

    bool first_time = true;
    for (int i = 0; i < HASH_TABLES; i++) {
        int allocated_groups = 0;
        if ((hash_table_input & (1 << i)) == 0) continue;
        for (int j = 0; j < HASH_DIST_SLICES; j++) {
            if (!avail_groups.getbit(j))
                continue;
            if (first_time) {
                // Coordinate the alignment of input xbar bits to immediate bit locations
                for (auto position : immed_bit_positions) {
                    auto lo_bit = position.first - position_min;
                    BUG_CHECK(lo_bit >= 0, "Minimum hash dist bit larger than allocated");
                    if (lo_bit < allocated_groups * HASH_DIST_BITS ||
                        lo_bit >= (allocated_groups + 1) * HASH_DIST_BITS) {
                        continue;
                    }
                    int initial_add = lo_bit - (allocated_groups * HASH_DIST_BITS);
                    int init_bit = j * HASH_DIST_BITS;
                    hdap.bit_starts[init_bit + initial_add] = position.second;
                }
            }

            hash_dist_use[i][j] = name;
            hash_dist_inuse[i].setbit(j);
            hdap.slice.setbit(j);
            bitvec shifted_bm = masks[allocated_groups] << (j * HASH_DIST_BITS);
            for (auto b : shifted_bm)
                hash_dist_bit_use[i][b] = name;
            hash_dist_bit_inuse[i] |= shifted_bm;
            hdap.bit_mask |= shifted_bm;
            allocated_groups++;
        }
        first_time = false;
    }
    return true;
}

/** Allocate space for a pre-color.  A pre-color has to be in a pair of bits starting at an even
 *  numbered bit, but can be anywhere within all of hash distribution, as the OXBar can pick
 *  any 2 of all 6 of the hash distribution units to use as an input xbar.
 *
 *  FIXME: Due to mask calculation, currently an entire meter pre-color group has to
 *  reserve an entire slice of a hash distribution unit, when it could fit anywhere.  This
 *  is a larger issue within the allocation of hash distribution in general, and needs
 *  to be fixed eventually.  However, this is not a large issue, as pre-color currently
 *  is rarely realistically used in switch profiles.
 *
 *  This also is an issue with the current output of hash distribution within the assembler,
 *  as the current syntax is unclear.
 */
bool IXBar::allocHashDistPreColor(const unsigned &hash_table_input, HashDistAllocParams &hdap,
        cstring name) {
    int group = -1;
    int bit_pos = -1;
    for (int i = HASH_DIST_SLICES - 1; i >= 0; i--) {
        if (hdap.used_hash_dist_slices.getbit(i))
            continue;
        group = i;
        break;
    }

    if (group == -1)
        return false;

    for (int i = 0; i < HASH_DIST_BITS; i += METER_PRECOLOR_SIZE) {
        int start_bit = i + group * HASH_DIST_BITS;
        if (!hdap.used_hash_dist_bits.getslice(start_bit, METER_PRECOLOR_SIZE).empty())
            continue;
        bit_pos = start_bit;
        break;
    }

    if (bit_pos == -1)
        return false;

    for (int i = 0; i < HASH_TABLES; i++) {
        if ((hash_table_input & (1 << i)) == 0) continue;
        hash_dist_use[i][group] = name;
        hash_dist_inuse[i].setbit(group);

        for (int j = 0; j < METER_PRECOLOR_SIZE; j++) {
            hash_dist_bit_use[i][bit_pos + j] = name;
        }
        hash_dist_bit_inuse[i].setrange(bit_pos, METER_PRECOLOR_SIZE);
    }

    hdap.slice.setbit(group);
    hdap.bit_mask.setrange(bit_pos, METER_PRECOLOR_SIZE);
    hdap.bit_starts[bit_pos] = { 0, METER_PRECOLOR_SIZE - 1 };
    return true;
}

/**
 * This is the portion of the hash distribution section that is dedicated to a hash mod for
 * a selector.  The hash mod is at most 15 bits.  Bits[9:0] are an input to the
 * mod calculation to determine the mod % sel_length_pool_size.  Bits[14:10] are possibly
 * needed, depending on the maximum size of the pool, and are the bits ORed in after the
 * selector length shift.
 *
 * These requirements are from the Selector, and are already provided here.  The other
 * requirement is where the hash starts, as the hash calculation needs to begin at the bit
 * where the hash input to the selector ended.
 */
bool IXBar::allocHashDistSelMod(int bits_required, const unsigned &hash_table_input,
        HashDistAllocParams &hdap, int p4_hash_bit, cstring name) {
    int group = -1;
    for (int i = HASH_DIST_SLICES - 1; i >= 0; i--) {
        if (hdap.used_hash_dist_slices.getbit(i))
            continue;
        group = i;
        break;
    }

    if (group == -1)
        return false;

    int hash_bit_start = group * HASH_DIST_BITS;
    if (!hdap.used_hash_dist_bits.getslice(hash_bit_start, bits_required).empty())
        BUG("Slice that is said to be available is actually locked");

    for (int i = 0; i < HASH_TABLES; i++) {
        if ((hash_table_input & (1 << i)) == 0) continue;
        hash_dist_use[i][group] = name;
        hash_dist_inuse[i].setbit(group);

        for (int j = 0; j < bits_required; j++) {
            hash_dist_bit_use[i][hash_bit_start + j] = name;
        }
        hash_dist_bit_inuse[i].setrange(hash_bit_start, bits_required);
    }

    hdap.slice.setbit(group);
    hdap.bit_mask.setrange(hash_bit_start, bits_required);
    hdap.bit_starts[hash_bit_start] = { p4_hash_bit, p4_hash_bit + bits_required - 1 };
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
bool IXBar::allocHashDist(const IR::MAU::HashDist *hd, IXBar::Use::hash_dist_type_t hdt,
                          const PhvInfo &phv, const ActionFormat::Use *af, IXBar::Use &alloc,
                          bool second_try, int bits_required, int p4_hash_bit, cstring name) {
    LOG3("Alloc Hash Distribution " << hd);
    ContByteConversion               map_alloc;
    std::map<cstring, bitvec>        fields_needed;
    safe_vector <IXBar::Use::Byte *> alloced;
    fields_needed.clear();

    KeyInfo ki;
    ki.hash_dist = true;
    FieldManagement(map_alloc, alloc.field_list_order, hd->field_list, fields_needed, name,
                    phv, ki);
    create_alloc(map_alloc, alloc);


    int hash_slices_needed = (bits_required + HASH_DIST_BITS - 1) / bits_required;
    hash_matrix_reqs hm_reqs;

    if (second_try) {
        hm_reqs = hash_matrix_reqs::max(true);
    } else {
        hm_reqs.index_groups = hash_slices_needed;
        hm_reqs.hash_dist = true;
    }

    bool rv = find_alloc(alloc.use, false, alloced, hm_reqs);
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
    int unit = -1;

    HashDistAllocParams hdap;
    for (int i = 0; i < HASH_DIST_UNITS; i++) {
        if (hash_group_opts[i] == -1) continue;
        unit = i;
        used_hash_group = hash_group_opts[i];
        // Determine which bits/slices are used on the hash group bus already
        hdap.clear();
        for (int j = 0; j < HASH_TABLES; j++) {
            if (((1 << j) & hash_group_use[hash_group_opts[i]]) == 0) continue;
            hdap.used_hash_dist_bits |= hash_dist_bit_inuse[j];
            hdap.used_hash_dist_slices |= hash_dist_inuse[j];
        }
        if (hdt == IXBar::Use::COUNTER_ADR || hdt == IXBar::Use::METER_ADR
            || hdt == IXBar::Use::ACTION_ADR || hdt == IXBar::Use::METER_ADR_AND_IMMEDIATE)
            can_allocate = allocHashDistAddress(bits_required, hash_table_input, hdap, name);
        else if (hdt == IXBar::Use::IMMEDIATE)
            can_allocate = allocHashDistImmediate(hd, af, hash_table_input, hdap, name);
        else if (hdt == IXBar::Use::PRECOLOR)
            can_allocate = allocHashDistPreColor(hash_table_input, hdap, name);
        else if (hdt == IXBar::Use::HASHMOD)
            can_allocate = allocHashDistSelMod(bits_required, hash_table_input, hdap, p4_hash_bit,
                                               name);
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
    alloc.hash_dist_hash.bits_required = bits_required;
    alloc.hash_dist_hash.unit = unit;
    alloc.hash_dist_hash.slice = hdap.slice;
    alloc.hash_dist_hash.bit_mask = hdap.bit_mask;
    alloc.hash_dist_hash.bit_starts = hdap.bit_starts;
    alloc.hash_dist_hash.group = used_hash_group;
    alloc.hash_seed[used_hash_group]
        |= determine_final_xor(&hd->algorithm, hdap.bit_starts,
                               alloc.field_list_order, alloc.total_input_bits());
    return rv;
}

/**
 * Using the bfn_hash_function, this algorithm determines the necessary final_xor positions
 * and writes them into the seed output.
 */
bitvec IXBar::determine_final_xor(const IR::MAU::HashFunction *hf,
        std::map<int, le_bitrange> &bit_starts,
        safe_vector<PHV::AbstractField*> field_list, int total_input_bits) {
    safe_vector<hash_matrix_output_t> hash_outputs;
    for (auto &entry : bit_starts) {
        hash_matrix_output_t hash_output;
        hash_output.gfm_start_bit = entry.first;
        hash_output.p4_hash_output_bit = entry.second.lo;
        hash_output.bit_size = entry.second.size();
        hash_outputs.push_back(hash_output);
    }
    bfn_hash_algorithm_t hash_alg;
    hf->build_algorithm_t(&hash_alg);
    hash_seed_t hash_seed;
    hash_seed.hash_seed_value = 0ULL;
    hash_seed.hash_seed_used = 0ULL;

    safe_vector<ixbar_input_t> hash_inputs;
    for (auto &entry : field_list) {
        ixbar_input_t hash_input;
        if (entry->is<PHV::Constant>()) {
            hash_input.type = ixbar_input_type::tCONST;
            if (!entry->to<PHV::Constant>()->value->fitsUint64())
                ::error("The size of constant %1% is too large, "
                        "the maximum supported size is 64 bit", entry->to<PHV::Constant>()->value);
            hash_input.u.constant = entry->to<PHV::Constant>()->value->asUint64();
        } else {
            hash_input.type = ixbar_input_type::tPHV;
            hash_input.u.valid = true;
        }
        hash_input.ixbar_bit_position = entry->range().lo;
        hash_input.bit_size = entry->size();
        hash_inputs.push_back(hash_input);
    }
    determine_seed(hash_outputs.data(), hash_outputs.size(),
                   hash_inputs.data(), hash_inputs.size(), total_input_bits, &hash_alg,
                   &hash_seed);

    unsigned lo_unsigned = hash_seed.hash_seed_value & ((1ULL << 32) - 1);
    unsigned hi_unsigned = (hash_seed.hash_seed_value >> 32) & ((1ULL << 32) - 1);
    bitvec lo_bv(lo_unsigned);
    bitvec hi_bv(hi_unsigned);

    return lo_bv | hi_bv << 32;
}

/** Configuring the match central configuration of a hash distribution unit.  Unfortunately
 *  the hash distribution units set up the registers within the assembler on a register
 *  by register basis.  This should probably be moved more into the assembler, but in the
 *  meantime, the compiler is more responsible for these registers
 *
 *  Sets the values in the IXBar::HashDistUse struct, which describes what the individual
 *  registers are for
 */
void IXBar::XBarHashDist::initialize_hash_dist_unit(IXBar::HashDistUse &hd_use,
        const IR::Node *rel_node) {
    auto &hdh = hd_use.use.hash_dist_hash;
    auto hdt = hd_use.use.hash_dist_type;
    for (int i = 0; i < IXBar::HASH_DIST_SLICES; i++) {
        if (hdh.slice.getbit(i))
            hd_use.pre_slices.push_back(i + IXBar::HASH_DIST_SLICES * hdh.unit);
    }

    bool slices_set = false;

    // Preslices refer to before expand block, Slices are after expand block
    if (hdt == IXBar::Use::COUNTER_ADR || hdt == IXBar::Use::METER_ADR
        || hdt == IXBar::Use::ACTION_ADR || hdt == IXBar::Use::METER_ADR_AND_IMMEDIATE) {
        if (hdt == IXBar::Use::METER_ADR_AND_IMMEDIATE)
            hd_use.outputs[hd_use.pre_slices[0]].insert("lo");
        if (hd_use.pre_slices.size() > 1) {
            if (!(hd_use.pre_slices.size() == 2
                || (hd_use.pre_slices[1] % IXBar::HASH_DIST_SLICES) == 2))
                BUG("Wide hash distribution address doesn't fit in the table");
            hd_use.expand.emplace(hd_use.pre_slices[0],
                                  (7 * (hd_use.pre_slices[0] % IXBar::HASH_DIST_SLICES)));
            hd_use.slices.push_back(hd_use.pre_slices[0]);
            if (hdt == IXBar::Use::METER_ADR_AND_IMMEDIATE) {
                hd_use.outputs[hd_use.pre_slices[1]].insert("hi");
                hd_use.slices.push_back(hd_use.pre_slices[1]); }
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

    if (hdt == IXBar::Use::COUNTER_ADR) {
        BUG_CHECK(rel_node, "Must provide a non-null counter");
        auto back_at = rel_node->to<IR::MAU::BackendAttached>();
        int shift = 0;
        if (auto counter = back_at->attached->to<IR::MAU::Counter>()) {
            int per_word = CounterPerWord(counter);
            shift = 3 - ceil_log2(per_word);
        // This is for meter color mapram address
        } else if (back_at->attached->is<IR::MAU::Meter>()) {
            shift = 3;
            hd_use.color_mapram = true;
        } else {
            BUG("A counter address can not be used for any non-designated purpose");
        }

        bitvec mask(0, hdh.bits_required);
        hd_use.shifts[hd_use.slices[0]] = shift;
        hd_use.masks[hd_use.slices[0]] = mask;
    } else if (hdt == IXBar::Use::METER_ADR) {
        BUG_CHECK(rel_node, "Must provide a non-null meter address user");
        auto back_at = rel_node->to<IR::MAU::BackendAttached>();
        if (back_at->attached->is<IR::MAU::Meter>()) {
            int shift = 7;
            bitvec mask(0, hdh.bits_required);
            hd_use.shifts[hd_use.slices[0]] = shift;
            hd_use.masks[hd_use.slices[0]] = mask;
        } else if (auto *salu = back_at->attached->to<IR::MAU::StatefulAlu>()) {
            int per_word = RegisterPerWord(salu);
            int shift = 7 - ceil_log2(per_word);
            bitvec mask(0, hdh.bits_required);
            hd_use.shifts[hd_use.slices[0]] = shift;
            hd_use.masks[hd_use.slices[0]] = mask;
        }
    } else if (hdt == IXBar::Use::ACTION_ADR) {
        int shift = std::min(ceil_log2(lo->layout.action_data_bytes_in_table) + 1, 5);
        bitvec mask(0, hdh.bits_required);
        hd_use.shifts[hd_use.slices[0]] = shift;
        hd_use.masks[hd_use.slices[0]] = mask;
    } else if (hdt == IXBar::Use::METER_ADR_AND_IMMEDIATE) {
        // don't shift here -- use meter_adr_shift instead.  This seems fragile as we don't
        // mark that anywhere; MauAsmOutput::EmitAttached::preorder(IR::MAU::StatefulAlu)
        // checks to see if it is addressed with a HashDist and has chain_vpn set.
        bitvec mask(0, hdh.bits_required);
        hd_use.shifts[hd_use.slices[0]] = 0;
        hd_use.masks[hd_use.slices[0]] = mask;
    } else if (hdt == IXBar::Use::IMMEDIATE || hdt == IXBar::Use::HASHMOD) {
        for (auto slice : hd_use.slices) {
            hd_use.shifts[slice] = 0;
            // FIXME: Can we just have a full mask for immediate here, or do we have to
            // adjust for the immediate size
            bitvec hash_section(0, IXBar::HASH_DIST_BITS);
            hash_section <<= (slice % IXBar::HASH_DIST_SLICES) * IXBar::HASH_DIST_BITS;
            bitvec mask = hash_section & hdh.bit_mask;
            mask >>= (slice % IXBar::HASH_DIST_SLICES) * IXBar::HASH_DIST_BITS;
            hd_use.masks[slice] = mask;
        }
    }

    int group = hd_use.use.hash_dist_hash.group;
    for (auto slice : hd_use.slices)
        hd_use.groups[slice] = group;
}

void IXBar::XBarHashDist::end_apply() {
    if (!allocation_passed)
        alloc.hash_dists.clear();
}

void IXBar::XBarHashDist::hash_dist_allocation(const IR::MAU::HashDist *hd,
        IXBar::Use::hash_dist_type_t hdt, int bits_required, int p4_hash_bit,
        const IR::Node *rel_node) {
    IXBar::HashDistUse hd_use(hd);

    if (!self.allocHashDist(hd, hdt, phv, af, hd_use.use, false, bits_required, p4_hash_bit,
                            tbl->name) &&
        !self.allocHashDist(hd, hdt, phv, af, hd_use.use, true, bits_required, p4_hash_bit,
                            tbl->name)) {
        allocation_passed = false;
        return;
    }
    hd_use.use.type = IXBar::Use::HASH_DIST;
    hd_use.use.hash_dist_type = hdt;
    initialize_hash_dist_unit(hd_use, rel_node);
    BUG_CHECK(tbl->match_table, "Allocating hash distribution for a gateway table");
    hd_use.use.used_by = tbl->match_table->externalName();
    alloc.hash_dists.push_back(hd_use);
}

/**
 * This is to allocate the hash distribution of a table if the table is dedicated to hash
 * action.  The hash distribution IR node at this point does not exist, and is created
 * by this allocation scheme.
 */
void IXBar::XBarHashDist::hash_action(const IR::MAU::Table *tbl) {
    if (tbl->gateway_only())
        return;
    if (!lo->layout.hash_action || !allocation_passed)
        return;

    IR::Vector<IR::Expression> components;
    IR::ListExpression *field_list = new IR::ListExpression(components);
    int bits_required = 0;
    for (auto read : tbl->match_key) {
        if (read->for_match()) {
            le_bitrange bits;
            phv.field(read->expr, &bits);
            bits_required += bits.size();
            field_list->push_back(read->expr);
        }
    }

    auto hd = new IR::MAU::HashDist(tbl->srcInfo, IR::Type::Bits::get(bits_required),
                      field_list, IR::MAU::HashFunction::identity());
    for (auto ba : tbl->attached) {
        bool meter_color_req = false;
        if (!(ba->attached && ba->attached->direct))
            continue;
        IXBar::Use::hash_dist_type_t hdt = IXBar::Use::UNKNOWN;
        if (ba->attached->is<IR::MAU::Counter>()) {
            hdt = IXBar::Use::COUNTER_ADR;
        } else if (auto mtr = ba->attached->to<IR::MAU::Meter>()) {
            hdt = IXBar::Use::METER_ADR;
            if (mtr->color_output())
                meter_color_req = true;
        } else if (auto salu = ba->attached->to<IR::MAU::StatefulAlu>()) {
            hdt = salu->chain_vpn ? IXBar::Use::METER_ADR_AND_IMMEDIATE : IXBar::Use::METER_ADR;
        } else {
            continue;
        }
        auto hd_clone = hd->clone();
        hash_dist_allocation(hd_clone, hdt, bits_required, 0, ba);
        if (meter_color_req)
            hash_dist_allocation(hd_clone, IXBar::Use::COUNTER_ADR, bits_required, 0, ba);
    }

    if (lo->layout.action_data_bytes_in_table > 0) {
        hash_dist_allocation(hd->clone(), IXBar::Use::ACTION_ADR, bits_required, 0, nullptr);
    }
}

/** Passes over all hash distribution uses within the IR and determines what their
 *  needs are.  Will allocate on the xbar, and setup the match central portion.
 */
bool IXBar::XBarHashDist::preorder(const IR::MAU::HashDist *hd) {
    if (!allocation_passed)
        return false;

    int p4_hash_bit = 0;
    IXBar::Use::hash_dist_type_t hdt = IXBar::Use::UNKNOWN;

    bool meter_color_req = false;
    const IR::Node *rel_node = nullptr;
    if ((rel_node = findContext<IR::MAU::Instruction>()) != nullptr) {
        hdt = IXBar::Use::IMMEDIATE;
    } else if ((rel_node = findContext<IR::MAU::Meter>()) != nullptr) {
        hdt = IXBar::Use::PRECOLOR;
    } else if ((rel_node = findContext<IR::MAU::Selector>()) != nullptr) {
        hdt = IXBar::Use::HASHMOD;
        auto as = rel_node->to<IR::MAU::Selector>();
        p4_hash_bit = as->mode == "resilient" ? RESILIENT_MODE_HASH_BITS : FAIR_MODE_HASH_BITS;
    } else if (auto back_at = findContext<IR::MAU::BackendAttached>()) {
        auto at_mem = back_at->attached;
        if (at_mem->is<IR::MAU::Counter>()) {
            hdt = IXBar::Use::COUNTER_ADR;
        } else if (auto mtr = at_mem->to<IR::MAU::Meter>()) {
            hdt = IXBar::Use::METER_ADR;
            if (mtr->color_output())
                meter_color_req = true;
        } else if (auto salu = at_mem->to<IR::MAU::StatefulAlu>()) {
            hdt = salu->chain_vpn ? IXBar::Use::METER_ADR_AND_IMMEDIATE : IXBar::Use::METER_ADR;
        }
        rel_node = back_at;
    }


    int bits_required = 0;
    if (tbl->for_dleft()) {
        bits_required = TableFormat::RAM_GHOST_BITS + ceil_log2(lo->dleft_hash_sizes[0]);
    } else {
        bits_required = hd->bit_width;
        if ((hdt == IXBar::Use::COUNTER_ADR || hdt == IXBar::Use::METER_ADR ||
             hdt == IXBar::Use::ACTION_ADR) && bits_required > HASH_DIST_MAX_EXPAND_BITS)
            // non-immediates use the hash-dist 'expand' which is limited width
            bits_required = HASH_DIST_MAX_EXPAND_BITS;
    }
    hash_dist_allocation(hd, hdt, bits_required, p4_hash_bit, rel_node);
    // For the meter color mapram
    if (meter_color_req)
        hash_dist_allocation(hd, IXBar::Use::COUNTER_ADR, bits_required, p4_hash_bit, rel_node);

    return false;
}

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
                       const LayoutOption *lo, const ActionFormat::Use *af) {
    if (!tbl) return true;
    /* Determine number of groups needed.  Loop through them, alloc match will be the same
       for these.  Alloc All Hash Ways will required multiple groups, and may need to change  */
    LOG1("IXBar::allocTable(" << tbl->name << ")");
    if (!tbl->gateway_only() && !lo->layout.no_match_rams() && !lo->layout.atcam &&
        !lo->layout.proxy_hash) {
        bool ternary = tbl->layout.ternary;
        safe_vector<IXBar::Use::Byte *> alloced;
        safe_vector<Use> all_tbl_allocs;
        bool finished = false;
        size_t start = 0; size_t last = 0;
        while (!finished) {
            Use next_alloc;
            layout_option_calculation(lo, start, last);
            /* Essentially a calculation of how much space is potentially available */
            auto hm_reqs = match_hash_reqs(lo, start, last, ternary);
            auto max_hm_reqs = hash_matrix_reqs::max(false, ternary);

            if (!(allocMatch(ternary, tbl, phv, next_alloc, alloced, hm_reqs)
                && allocAllHashWays(ternary, tbl, next_alloc, lo, start, last))
                && !(allocMatch(ternary, tbl, phv, next_alloc, alloced, max_hm_reqs)
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
        hash_matrix_reqs hm_reqs;
        if (!allocMatch(false, tbl, phv, alloc.match_ixbar, alloced, hm_reqs)) {
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
    } else if (tbl->layout.proxy_hash) {
        if (!allocProxyHash(tbl, phv, lo, alloc.match_ixbar, alloc.proxy_hash_ixbar)) {
            alloc.clear_ixbar();
            return false;
        }
    }

    for (auto back_at : tbl->attached) {
        auto at_mem = back_at->attached;
        if (auto as = at_mem->to<IR::MAU::Selector>()) {
            if (!attached_tables.count(as) &&
                !allocSelector(as, tbl, phv, alloc.selector_ixbar, tbl->name)) {
                alloc.clear_ixbar();
                return false; } }
        if (auto mtr = at_mem->to<IR::MAU::Meter>()) {
            if (!attached_tables.count(mtr)
                && !(allocMeter(mtr, tbl, phv, alloc.meter_ixbar, true)
                     || allocMeter(mtr, tbl, phv, alloc.meter_ixbar, false))) {
                alloc.clear_ixbar();
                return false;
            }
        }
        if (auto salu = at_mem->to<IR::MAU::StatefulAlu>()) {
            if (!attached_tables.count(salu)
                && !(allocStateful(salu, tbl, phv, alloc.salu_ixbar, true)
                     || allocStateful(salu, tbl, phv, alloc.salu_ixbar, false))) {
                alloc.clear_ixbar();
                return false; } } }

    if (!allocGateway(tbl, phv, alloc.gateway_ixbar, false) &&
        !allocGateway(tbl, phv, alloc.gateway_ixbar, true)) {
        alloc.clear_ixbar();
        return false; }

    XBarHashDist xbar_hash_dist(*this, phv, alloc, af, lo, tbl);
    xbar_hash_dist.hash_action(tbl);
    tbl->attached.apply(xbar_hash_dist);
    for (auto v : Values(tbl->actions))
        v->apply(xbar_hash_dist);
    if (!xbar_hash_dist.passed_allocation()) {
        alloc.clear_ixbar();
        return false;
    }
    LOG1("Input xbar allocation successful");
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
        fields.emplace(byte.name, byte.loc); }
    for (auto &bits : alloc.bit_use) {
        for (int b = 0; b < bits.width; b++) {
            for (auto ht : bitvec(alloc.hash_table_inputs[bits.group])) {
                if (hash_single_bit_use.at(ht, b + bits.bit)) {
                    BUG("conflicting ixbar hash bit allocation");
                }
                hash_single_bit_use.at(ht, b + bits.bit) = name; }
            hash_single_bit_inuse[b + bits.bit] |= alloc.hash_table_inputs[bits.group];
        }
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

    if (alloc.meter_alu_hash.allocated) {
        auto &mah = alloc.meter_alu_hash;
        // The mask is a byte mask, so must reserve the entire byte
        int max_bit = max_bit_to_byte(mah.bit_mask);
        int max_group = max_index_group(max_bit);
        int max_index_bit = max_index_single_bit(max_bit);
        unsigned hash_table_input = alloc.hash_table_inputs[mah.group];
        if (hash_group_use[mah.group] == 0) {
            hash_group_use[mah.group] = alloc.hash_table_inputs[mah.group];
            hash_group_print_use[mah.group] = name;
        }
        if (!hash_use_free(max_group, max_index_bit, hash_table_input)) {
            BUG("Conflicting hash matrix usage for %s", name);
        }
        write_hash_use(max_group, max_index_bit, hash_table_input, name);
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
    if (alloc.proxy_hash_key_use.allocated) {
        auto &ph = alloc.proxy_hash_key_use;
        for (int ht = 0; ht < HASH_TABLES; ht++) {
            if (((1U << ht) & alloc.hash_table_inputs[ph.group]) == 0) continue;
            unsigned indexes = index_groups_used(ph.hash_bits);
            for (auto idx : bitvec(indexes)) {
                hash_index_inuse[idx] = alloc.hash_table_inputs[ph.group];
                if (!hash_index_use[ht][idx])
                    hash_index_use[ht][idx] = name;
                else if (hash_index_use[ht][idx] != name)
                    BUG("Conflicting hash usage between %s and %s", name,
                         hash_index_use[ht][idx]);
            }
            unsigned select_bits = select_bits_used(ph.hash_bits);
            for (auto bit : bitvec(select_bits)) {
                hash_single_bit_inuse[bit] = alloc.hash_table_inputs[ph.group];
                if (!hash_single_bit_use[ht][bit])
                    hash_single_bit_use[ht][bit] = name;
                else if (hash_single_bit_use[ht][bit] != name)
                    BUG("Conflicting hash usage between %s and %s", name,
                        hash_single_bit_use[ht][bit]);
            }
        }
    }
}

void IXBar::update(const IR::MAU::Table *tbl, const TableResourceAlloc *rsrc) {
    const IR::MAU::Selector *as = nullptr;
    const IR::MAU::Meter *mtr = nullptr;
    const IR::MAU::StatefulAlu *salu = nullptr;

    for (auto ba : tbl->attached) {
        if (auto as_p = ba->attached->to<IR::MAU::Selector>())
            as = as_p;
        if (auto mtr_p = ba->attached->to<IR::MAU::Meter>())
            mtr = mtr_p;
        if (auto salu_p = ba->attached->to<IR::MAU::StatefulAlu>())
            salu = salu_p;
    }

    auto name = tbl->name;
    if (as && (allocated_attached.count(as) == 0)) {
        update(name + "$select", rsrc->selector_ixbar);
        allocated_attached.emplace(as, rsrc->selector_ixbar);
    }
    if (mtr && (allocated_attached.count(mtr) == 0)) {
        update(name + "$mtr", rsrc->meter_ixbar);
        allocated_attached.emplace(mtr, rsrc->meter_ixbar);
    }
    if (salu && (allocated_attached.count(salu) == 0)) {
        update(name + "$salu", rsrc->salu_ixbar);
        allocated_attached.emplace(salu, rsrc->salu_ixbar);
    }

    update(name + "$proxy_hash", rsrc->proxy_hash_ixbar);
    update(name + "$gw", rsrc->gateway_ixbar);
    update(name, rsrc->match_ixbar);
    int index = 0;
    for (auto hash_dist : rsrc->hash_dists)
        update(name + "$hash_dist" + std::to_string(index++), hash_dist.use);
}

void IXBar::update(const IR::MAU::Table *tbl) {
    if (tbl->for_dleft() && tbl->is_placed()) {
        auto orig_name = tbl->name.before(tbl->name.findlast('$'));
        if (dleft_updates.count(orig_name))
            return;
        dleft_updates.emplace(orig_name);
    }
    if (tbl->is_placed())
        update(tbl, tbl->resources);
}

static void replace_name(cstring n, std::map<cstring, char> &names) {
    if (!names.count(n)) {
        if (names.size() >= 52)
            names.emplace(n, '?');
        else if (names.size() >= 26)
            names.emplace(n, 'a' + names.size() - 26);
        else
            names.emplace(n, 'A' + names.size()); }
}

static void write_one(std::ostream &out, const std::pair<cstring, int> &f,
                      std::map<cstring, char> &fields) {
    if (f.first) {
        replace_name(f.first, fields);
        out << fields[f.first] << hex(f.second/8);
    } else {
        out << ".."; }
}
static void write_one(std::ostream &out, cstring n, std::map<cstring, char> &names) {
    if (n) {
        replace_name(n, names);
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

std::string IXBar::FieldInfo::visualization_detail() const {
    std::string rv = get_use_name() + "";
    rv += "[" + std::to_string(lo) + ":" + std::to_string(hi) + "]";
    return rv;
}

/** Visualization Details on what bits are used within a particular byte are used within a
 *  table.  Unused bits are printed out as unused
 */
std::string IXBar::Use::Byte::visualization_detail() const {
    std::string rv = "{";
    bitvec byte(0, 8);
    bitvec unused_bv = byte - bit_use;
    int unused_start_bit = 0;
    int used_start_bit = bit_use.ffs();
    int unused_end_bit = used_start_bit;
    bool first_time = true;

    auto it = field_bytes.begin();

    do {
        int used_end_bit = bit_use.ffz(used_start_bit);
        if (unused_start_bit < unused_end_bit) {
            if (!first_time)
                rv += ", ";
            else
                first_time = false;
            int lo = 0; int hi = (unused_end_bit - unused_start_bit) - 1;
            rv += "unused[" + std::to_string(lo) + ":" + std::to_string(hi) + "]";
        }

        BUG_CHECK(used_start_bit != used_end_bit, "The bit_use object in %s is incorrectly "
                 "configured", *this);
        while (it != field_bytes.end()) {
            if (it->cont_lo > used_end_bit)
                break;

            if (!first_time)
                rv += ", ";
            else
                first_time = false;

            rv += it->visualization_detail();
            it++;
        }
        unused_start_bit = used_end_bit;
        used_start_bit = bit_use.ffs(used_end_bit);
        unused_end_bit = used_start_bit;
    } while (used_start_bit >= 0);

    if (unused_start_bit < 8) {
        BUG_CHECK(!first_time, "Byte %s has no field slices", *this);
        rv += ", ";
        int lo = 0; int hi = 7 - unused_start_bit;
        rv += "unused[" + std::to_string(lo) + ":" + std::to_string(hi) + "]";
    }

    rv += "}";
    return rv;
}
