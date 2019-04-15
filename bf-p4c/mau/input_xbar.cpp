#include "bf-p4c/common/slice.h"
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
#include "lib/bitrange.h"
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

IXBar::HashDistDest_t IXBar::dest_location(const IR::Node *node, bool precolor) {
    if (auto ba = node->to<IR::MAU::BackendAttached>()) {
        if (ba->attached->is<IR::MAU::ActionData>())
            return HD_ACTIONDATA_ADR;
        if (ba->attached->is<IR::MAU::Counter>())
            return HD_STATS_ADR;
        if (ba->attached->is<IR::MAU::StatefulAlu>())
            return HD_METER_ADR;
        if (ba->attached->is<IR::MAU::Meter>()) {
            return precolor ? HD_STATS_ADR : HD_METER_ADR;
        }
    }
    if (node->is<IR::MAU::Meter>())
        return HD_PRECOLOR;
    if (node->is<IR::MAU::Selector>())
        return HD_HASHMOD;

    BUG("Invalid call of HashDist dest location");
    return HD_DESTS;
}

std::string IXBar::hash_dist_name(HashDistDest_t dest) {
    std::string type;
    switch (dest) {
        case HD_IMMED_LO: type = "immediate lo"; break;
        case HD_IMMED_HI: type = "immediate hi"; break;
        case HD_STATS_ADR: type = "stats address"; break;
        case HD_METER_ADR: type = "meter address"; break;
        case HD_ACTIONDATA_ADR: type = "action data address"; break;
        case HD_PRECOLOR: type = "meter precolor"; break;
        case HD_HASHMOD: type = "selector mod"; break;
        default: BUG("unknown hash dist user"); break;
    }
    return type;
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
    return IXBar::hash_dist_name(hash_dist_type);
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

/** 
 * The current algorithm, due to the odd constraints of the hash distribution section
 * separate available hashing for hash distribution vs. available hashing for everywhere
 * else.  The purpose of this is to determine what groups are completely unavailable
 * within the hash distribution section, due to the number of bits needed.
 *
 * TODO: Potentially in the hash_matrix_reqs, instead of looking at hash distribution
 * as a total, look at an individual group, and allocate on a group by group basis.
 */
void IXBar::calculate_available_hash_dist_groups(safe_vector<grp_use> &order,
        hash_matrix_reqs &hm_reqs) {
    for (int i = 0; i < HASH_DIST_UNITS; i++) {
        if (hash_dist_groups[i] == -1) continue;
        auto hash_tables = hash_group_use[hash_dist_groups[i]];
        bitvec slices_used;
        for (auto &grp : order) {
            for (int i = 0; i < 2; i++) {
                if ((hash_tables & (1U << (2 * grp.group + i))) == 0U)
                    continue;
                for (int hash_slice = 0; hash_slice < HASH_DIST_SLICES; hash_slice++) {
                    if (hash_dist_inuse[2 * grp.group + i].getbit(hash_slice))
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
    ContByteConversion *map_alloc;
    safe_vector<const IR::Expression *> &field_list_order;
    std::map<cstring, bitvec> *fields_needed;
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

    bool preorder(const IR::MAU::TableKey *read) {
        if (ki.is_atcam) {
            if (ki.partition != read->partition_index)
                return false; }
        return true; }

    bool preorder(const IR::Constant *c) {
        field_list_order.push_back(c);
        return true; }

    bool preorder(const IR::MAU::ActionArg *aa) {
        error("Can't use action argument %s in a hash in the same action; "
              "try splitting the action", aa);
        return false; }

    bool preorder(const IR::Expression *e) {
        le_bitrange bits = { };
        auto *finfo = phv.field(e, &bits);
        if (!finfo) return true;
        field_list_order.push_back(e);
        bitvec field_bits(bits.lo, bits.hi - bits.lo + 1);
        // Currently, due to driver, only one field is allowed to be the partition index
        if (map_alloc == nullptr || fields_needed == nullptr) {
            BUG_CHECK(map_alloc == nullptr && fields_needed == nullptr, "Invalid call of the "
                "FieldManagement pass");
            return false;
        }

        byte_type_t byte_type = NO_BYTE_TYPE;
        if (auto *read = findContext<IR::MAU::TableKey>()) {
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

        if (fields_needed->count(finfo->name)) {
            auto &allocated_bits = fields_needed->at(finfo->name);
            if ((allocated_bits & field_bits).popcount() == field_bits.popcount())
                return false;
            (*fields_needed)[finfo->name] |= field_bits;
        } else {
            (*fields_needed)[finfo->name] = field_bits;
        }
        boost::optional<cstring> aliasSourceName = phv.get_alias_name(e);
        add_use(*map_alloc, finfo, phv, aliasSourceName, &bits, 0, byte_type, 0, ki.range_index);
        if (byte_type == RANGE) {
            ki.range_index++;
        }
        return false;
    }
    void postorder(const IR::BFN::SignExtend *c) override {
        BUG_CHECK(!field_list_order.empty(), "SignExtend on nonexistant field");
        BUG_CHECK(field_list_order.back() == c->expr, "SignExtend mismatch");
        int size = c->expr->type->width_bits();
        for (int i = c->type->width_bits(); i > size; --i) {
            field_list_order.insert(field_list_order.end() - 1,
                MakeSlice(c->expr, size - 1, size - 1)); } }

    /**
     * FIXME: This a nasty hack due to the way dynamic hashing is currently handled in
     * the backend.  If multiple field_lists exists, which is true for the dyn_hash test,
     * then this algorithm removes the duplicated fields so that the dynamic hashing
     * doesn't crash .  When the dynamic hashing is correctly handled in the backend,
     * this can go away.
     */
    void end_apply() override {
        if (ki.repeats_allowed)
            return;
        std::map<cstring, bitvec> field_list_check;
        for (auto it = field_list_order.begin(); it != field_list_order.end(); it++) {
            le_bitrange bits;
            auto field = phv.field(*it, &bits);
            if (field == nullptr)
                continue;

            bitvec used_bits(bits.lo, bits.size());

            bitvec overlap;
            if (field_list_check.count(field->name) > 0)
                overlap = field_list_check.at(field->name) & used_bits;
            if (!overlap.empty()) {
                if (overlap == used_bits) {
                    it = field_list_order.erase(it);
                    it--;
                } else {
                    ::error("Overlapping field %s in table %s not supported with the hashing "
                            "algorithm", field->name, name);
                }
            }
            field_list_check[field->name] |= used_bits;
        }
    }

 public:
    FieldManagement(ContByteConversion *map_alloc,
                    safe_vector<const IR::Expression *> &field_list_order,
                    const IR::Expression *field, std::map<cstring, bitvec> *fields_needed,
                    cstring name, const PhvInfo &phv, KeyInfo &ki)
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
void IXBar::create_alloc(ContByteConversion &map_alloc, safe_vector<Use::Byte> &bytes) {
    for (auto &entry : map_alloc) {
        safe_vector<IXBar::Use::Byte> created_bytes;

        for (auto &fi : entry.second) {
            bool add_new_byte = true;
            int index = 0;
            safe_vector<FieldInfo> non_overlap_field_info;
            for (auto c_byte : created_bytes) {
                if (c_byte.can_add_info(fi)) {
                    add_new_byte = false;
                    break;
                }
                index++;
            }
            if (add_new_byte)
                created_bytes.emplace_back(entry.first);
            created_bytes[index].add_info(fi);
        }
        bytes.insert(bytes.end(), created_bytes.begin(), created_bytes.end());
    }

    // Putting the fields in container order so the visualization prints them out in
    // le_bitrange order
    for (auto &byte : bytes) {
        std::sort(byte.field_bytes.begin(), byte.field_bytes.end(),
            [](const FieldInfo &a, const FieldInfo &b) {
            return a.cont_lo < b.cont_lo;
        });
    }
}

void IXBar::create_alloc(ContByteConversion &map_alloc, IXBar::Use &alloc) {
    create_alloc(map_alloc, alloc.use);
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
        FieldManagement(&map_alloc, field_list_order, read->expr, &fields_needed,
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
        FieldManagement(&map_alloc, field_list_order, e, &fields_needed, tbl->name, phv, ki);
        if (!findContext<IR::MAU::IXBarExpression>()) {
            phv_sources[finfo][bits] = e;
            collapse_contained(phv_sources[finfo]);
        }
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

/* remove ranges from the map iff they are contained in some other range in the map */
void IXBar::FindSaluSources::collapse_contained(std::map<le_bitrange, const IR::Expression *> &m) {
    for (auto it = m.begin(); it != m.end();) {
        bool remove = false;
        for (auto &el : Keys(m)) {
            if (el == it->first) continue;
            if (el.contains(it->first)) {
                remove = true;
                break; }
            if (el.lo > it->first.lo) break; }
        if (remove)
            it = m.erase(it);
        else
            ++it; }
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
        FieldManagement(&map_alloc, alloc.field_list_order, ixbar_read, &fields_needed,
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

/**
 * The purpose of this function is, given the choices of hash_tables (16 64 bit hashes)
 * used, what hash function (8x52 bit hashes) are available.  At most two options are
 * possible for hash distribution.
 */
void IXBar::getHashDistGroups(unsigned hash_table_input, int hash_group_opt[HASH_DIST_UNITS]) {
    std::set<int> groups_with_overlap;
    // If both groups overlap with the given requirement, then this will lead to hash collisions
    // and will not work
    for (int i = 0; i < HASH_DIST_UNITS; i++) {
        if (hash_dist_groups[i] >= 0 &&
            (hash_table_input & hash_group_use[hash_dist_groups[i]]) != 0U)
            groups_with_overlap.insert(i);
    }

    // If one group's hash table usealready overlaps, then use that particular group, and
    // don't use the other group
    if (groups_with_overlap.size() > 1) {
        return;
    } else if (groups_with_overlap.size() == 1) {
        for (int i = 0; i < HASH_DIST_UNITS; i++) {
            if (groups_with_overlap.count(i) > 0)
                hash_group_opt[i] = hash_dist_groups[i];
            else
                hash_group_opt[i] = -1;
        }
        return;
    }

    // A new group might be required, so create at most one new group
    bool first_unused = false;
    for (int i = 0; i < HASH_DIST_UNITS; i++) {
        if (hash_dist_groups[i] == -1) {
            if (!first_unused) {
                first_unused = true;
                hash_group_opt[i] = getHashGroup(hash_table_input);
            }
        } else {
            hash_group_opt[i] = hash_dist_groups[i];
        }
    }
}

/**
 * Really should be replaced by an extern function call: P4C-1107
 */
void IXBar::determine_proxy_hash_alg(const PhvInfo &phv, const IR::MAU::Table *tbl,
                                     Use &alloc, int group) {
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
        |= determine_final_xor(&alloc.proxy_hash_key_use.algorithm, phv, bit_starts,
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
        FieldManagement(&map_alloc, alloc.field_list_order, ixbar_read, &fields_needed,
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
    determine_proxy_hash_alg(phv, tbl, alloc, hash_group);
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

    std::map<int, bitvec> slice_to_select_bits;
    // Currently should  never return false
    for (size_t index = start; index < last; index++) {
        if (!allocHashWay(tbl, layout_option, index, slice_to_select_bits, alloc)) {
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
bool IXBar::allocHashWay(const IR::MAU::Table *tbl, const LayoutOption *layout_option,
        size_t index, std::map<int, bitvec> &slice_to_select_bits, Use &alloc) {
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
        BUG_CHECK(slice_to_select_bits.count(group) > 0, "Slice has been allocated before");
        bitvec prev_mask = slice_to_select_bits.at(group);
        if (prev_mask.popcount() < way_bits) {
            BUG("Allocated bigger way before smaller way");
        }
        way_mask = bitvec(prev_mask.min().index(), way_bits).getrange(0, HASH_SINGLE_BITS);
        BUG_CHECK(static_cast<int>(bitcount(way_mask)) == way_bits, "Previous allocation "
                  "was not contiguous");
    } else if (static_cast<int>(bitcount(free_bits)) < way_bits) {
        LOG3("Free bits available is too small");
        return false;
    } else {
        // Select bits are not required to be contiguous in hardware, but in the driver entry
        // it appears that they have to be
        bool found = false;
        bitvec free_bits_bv = bitvec(free_bits);
        for (auto br : bitranges(free_bits_bv)) {
            if (br.second - br.first + 1 >= way_bits) {
                way_mask = ((1U << way_bits) - 1) << br.first;
                found = true;
                break;
            }
        }
        if (!found)
            return false;
    }

    slice_to_select_bits[group] |= bitvec(way_mask);

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
        FieldManagement(&map_alloc, alloc.field_list_order, ixbar_read, &fields_needed,
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
        FieldManagement(&map_alloc, alloc.field_list_order, ixbar_read->expr, &fields_needed,
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
            auto *expr = *it;
            int diff = bits_seen + expr->type->width_bits() - mode_width_bits;
            if (diff > 0)
                expr = MakeSlice(expr, 0, expr->type->width_bits() - diff - 1);
            mah.computed_expressions.emplace(bits_seen, expr);
            bits_seen += expr->type->width_bits();
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
        mah.computed_expressions[0] = mtr->input;
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
                                      const FindSaluSources &sources, unsigned &byte_mask) {
    int width = salu->source_width()/8U;
    int ixbar_initial_position = 0;
    if (Device::currentDevice() == Device::TOFINO)
        ixbar_initial_position = TOFINO_METER_ALU_BYTE_OFFSET;

    bool phv_src_reserved[2] = { false, false };
    bool reversed = false;
    int total_sources = 2;

    int source_index = 0;
    // Check to see which input xbar positions the sources can be allocated to
    for (auto &source : sources.phv_sources) {
        auto field = source.first;
        for (auto &range : Keys(source.second)) {
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
    }

    safe_vector<PHV::FieldSlice> ixbar_source_order;

    // Up to two sources on the stateful ALU.  The sources are ordered from the FindSaluSources.
    // An order from low bit to high byte is required on the input xbar.  If reversed is true,
    // then the order of phv_sources is the opposite of the ixbar_source_order
    for (auto &source : sources.phv_sources) {
        auto field = source.first;
        for (auto &range : Keys(source.second)) {
            if (reversed)
                ixbar_source_order.emplace(ixbar_source_order.begin(), field, range);
            else
                ixbar_source_order.emplace_back(field, range);
        }
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
    if (reversed && sources.phv_sources.size() == 1 &&
        sources.phv_sources.begin()->second.size() == 1) {
        ixbar_initial_position += width;
    }

    byte_mask = 0;
    for (auto source : sources.phv_sources) {
        for (auto &range : Keys(source.second)) {
            unsigned source_byte_mask = (1 << ((range.size() + 7) / 8)) - 1;
            byte_mask |= source_byte_mask << ixbar_initial_position;
            ixbar_initial_position += width;
        }
    }
    return true;
}

/**
 *  Determines whether a stateful ALU can fit within a hash bus.  If it can, determine
 *  the positions of these individual sources within the hash matrix, as the Galois
 *  matrix has to set up an identity matrix for this
 */
bool IXBar::setup_stateful_hash_bus(const PhvInfo &, const IR::MAU::StatefulAlu *salu,
                                    Use &alloc, const FindSaluSources &sources) {
    auto &mah = alloc.meter_alu_hash;
    unsigned hash_table_input = alloc.compute_hash_tables();
    int hash_group = getHashGroup(hash_table_input);
    if (hash_group < 0) {
        alloc.clear();
        return false;
    }

    mah.allocated = true;
    mah.group = hash_group;
    if (sources.dleft) {
        mah.algorithm = IR::MAU::HashFunction::random();
        mah.bit_mask.setrange(1, METER_ALU_HASH_BITS);
        // For dleft digest, we need a fixed 1 bit to ensure the digest is nonzero
        // as the valid bit is not contiguous with the digest in the sram field, so
        // trying to match it would waste more hash bits.
        alloc.hash_seed[hash_group] = bitvec(1);
    } else {
        mah.algorithm = IR::MAU::HashFunction::identity();
        bitvec phv_src_inuse;
        for (auto &field : Values(sources.phv_sources)) {
            for (auto &slice : Values(field)) {
                int alu_slot_index = phv_src_inuse.ffz();
                // If the SALU width is >= 32 and this source is less than
                // 51 (Size of Hash Matrix Output) - 32 (Size of Input) = 19 bits
                // we do NOT want to put it in slot 0, as it will fit in slot 1 and the other
                // thing to be placed might not
                if (salu->source_width() >= 32 && alu_slot_index == 0 &&
                    slice->type->width_bits() <= METER_ALU_HASH_BITS - salu->source_width())
                    alu_slot_index++;
                int start_bit = alu_slot_index * salu->source_width();
                if (start_bit + slice->type->width_bits() > METER_ALU_HASH_BITS)
                    return false;
                phv_src_inuse[alu_slot_index] = true;
                mah.computed_expressions[start_bit] = slice;
                mah.bit_mask.setrange(start_bit, slice->type->width_bits());
            }
        }
        for (auto source : sources.hash_sources) {
            int alu_slot_index = phv_src_inuse.ffz();
            if (salu->source_width() >= 32 && alu_slot_index == 0 &&
                source->expr->type->width_bits() <= METER_ALU_HASH_BITS - salu->source_width())
                alu_slot_index++;
            int start_bit = alu_slot_index * salu->source_width();
            if (start_bit + source->expr->type->width_bits() > METER_ALU_HASH_BITS)
                return false;
            phv_src_inuse[alu_slot_index] = true;
            mah.computed_expressions[start_bit] = source->expr;
            mah.bit_mask.setrange(start_bit, salu->source_width());
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
    const ordered_map<const PHV::Field *,
                      std::map<le_bitrange, const IR::Expression *>> &phv_sources) {
    const char *sep = "phv_sources: ";
    for (auto &el : phv_sources) {
        for (auto &sl : el.second) {
            out << sep << el.first->name << "(" << sl.first.lo << ".." << sl.first.hi << "): "
                << *sl.second;
            sep = ", "; } }
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
    LOG3("IXBar::allocStateful(" << salu->name << ", " << tbl->name << ", " <<
         (on_search_bus ? "true" : "false") << ")");
    FindSaluSources sources(*this, phv, map_alloc, alloc.field_list_order, tbl);
    salu->apply(sources);
    LOG5("  " << sources.phv_sources << sources.hash_sources);
    create_alloc(map_alloc, alloc);
    if (alloc.use.size() == 0)
        return true;

    unsigned byte_mask = ~0U;
    hash_matrix_reqs hm_reqs;

    if (on_search_bus) {
        if (sources.dleft || !sources.hash_sources.empty() ||
            !setup_stateful_search_bus(salu, alloc, sources, byte_mask)) {
            alloc.clear();
            return false;
        }
        hm_reqs.max_search_buses = 1;
    } else {
        int total_bits = 0;
        for (auto &source : Values(sources.phv_sources))
            for (auto &range : Keys(source))
                total_bits += range.size();
        for (auto source : sources.hash_sources)
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
        if (!setup_stateful_hash_bus(phv, salu, alloc, sources)) {
            alloc.clear();
            return false;
        }
    }

    LOG3("allocStateful succeeded: " << alloc);
    fill_out_use(xbar_alloced, false);
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


bool IXBar::isHashDistAddress(HashDistDest_t dest) const {
    return dest == HD_STATS_ADR || dest == HD_METER_ADR || dest == HD_ACTIONDATA_ADR;
}

/**
 * View which bits and units are already in use in this hash group (one of the two hash group
 * inputs to hash distribution)
 */
void IXBar::determineHashDistInUse(int hash_group, bitvec &units_in_use, bitvec &hash_bits_in_use) {
    for (int i = 0; i < HASH_TABLES; i++) {
        if (((1 << i) & hash_group_use[hash_group]) == 0) continue;
        units_in_use |= hash_dist_inuse[i];
        hash_bits_in_use |= hash_dist_bit_inuse[i];
    }
}

/**
 * Finds an available hash distribution unit and hash bits available.  Just needs a single unit
 * and at most 16 bits within this region.  Possible shifts is the possible right shifts of the
 * data that would still result in the correct allocation after allocation.
 */
bool IXBar::allocHashDistSection(bitvec post_expand_bits, bitvec possible_shifts, int hash_group,
        int &unit_allocated, bitvec &hash_bits_allocated) {
    bitvec units_in_use;
    bitvec hash_bits_in_use;
    determineHashDistInUse(hash_group, units_in_use, hash_bits_in_use);

    bool found = false;
    for (int i = 0; i < HASH_DIST_SLICES; i++) {
        if (units_in_use.getbit(i))
            continue;
        unit_allocated = i;
        bitvec hash_bits_in_unit = hash_bits_in_use.getslice(i * HASH_DIST_BITS, HASH_DIST_BITS);
        for (auto possible_shift : possible_shifts) {
            bitvec hash_bits_to_be_used = post_expand_bits << possible_shift;
            BUG_CHECK(hash_bits_to_be_used.max().index() < HASH_DIST_BITS, "Data is not "
                "contained within a single hash dist unit");
            if ((hash_bits_to_be_used & hash_bits_in_unit).empty()) {
                found = true;
                hash_bits_allocated = hash_bits_to_be_used << (i * HASH_DIST_BITS);
                break;
            }
        }
        if (found)
            break;
    }
    return found;
}

/**
 * @seealso As mentioned in allocHashDist, a wide address is any address larger than 16 bits,
 * as this is larger than the general input for a hash distribution unit.  The expand block is
 * then used.  The expand block can do the following:
 *     the 1st 23b section = { 38..32, 15..0 } of the hash function input
 *     the 2nd 23b section = { 45..39, 31..16 } of the hash function input
 *     the 3rd section does not have an expand.
 *
 * The allocation must then check to see if the bits in multiple 16 bit sections are available
 */
bool IXBar::allocHashDistWideAddress(bitvec post_expand_bits, bitvec possible_shifts,
        int hash_group, bool chained_addr, int &unit_allocated, bitvec &hash_bits_allocated) {
    bitvec units_in_use;
    bitvec hash_bits_in_use;
    determineHashDistInUse(hash_group, units_in_use, hash_bits_in_use);

    bool found = false;

    for (int i = 0; i < HASH_DIST_SLICES - 1; i++) {
        if (units_in_use.getbit(i))
            continue;
        if (chained_addr && units_in_use.getbit(HASH_DIST_SLICES - 1))
            continue;
        unit_allocated = i;
        for (auto possible_shift : possible_shifts) {
            bitvec shifted_bits = post_expand_bits << possible_shift;
            bitvec lower_bits = shifted_bits.getslice(0, HASH_DIST_BITS);
            bitvec upper_bits = shifted_bits.getslice(HASH_DIST_BITS, HASH_DIST_EXPAND_BITS);
            hash_bits_allocated = lower_bits << (i * HASH_DIST_BITS);
            hash_bits_allocated |= upper_bits << (HASH_DIST_BITS * 2 + HASH_DIST_EXPAND_BITS * i);
            if ((hash_bits_allocated & hash_bits_in_use).empty()) {
                found = true;
                break;
            }
        }
        if (found)
            break;
    }
    return found;
}

/**
 * Each HashDistAllocPostExpand coordinates to a single HashDistIRUse.  Both represent a single
 * IR::MAU::HashDist object.   The HashDistIRUse object is a subset of the total
 * hash dist object, (i.e. multiple IR nodes that are 8 bit immediate sections).  The purpose
 * of this is to subset the IR section
 */
void IXBar::buildHashDistIRUse(HashDistAllocPostExpand &alloc_req, HashDistUse &use,
        IXBar::Use &all_reqs, const PhvInfo &phv, int hash_group, bitvec hash_bits_used,
        bitvec total_post_expand_bits, unsigned hash_table_input, cstring name) {
    use.ir_allocations.emplace_back();
    auto &rv = use.ir_allocations.back();
    ContByteConversion               map_alloc;
    std::map<cstring, bitvec>        fields_needed;
    safe_vector <IXBar::Use::Byte *> alloced;
    fields_needed.clear();
    KeyInfo ki;
    ki.hash_dist = true;

    for (auto input : alloc_req.func.inputs) {
        safe_vector<const IR::Expression *> flo;
        FieldManagement(&map_alloc, flo, input, &fields_needed, "$hash_dist", phv, ki);
    }

    rv.use.field_list_order.insert(rv.use.field_list_order.end(), alloc_req.func.inputs.begin(),
                                   alloc_req.func.inputs.end());
    // Create pre-allocated bytes of the subset
    create_alloc(map_alloc, rv.use);

    // Coordinate allocation of those bytes through Container Name/Container Byte.  Only need
    // XBar loc for assembly generation
    for (auto &byte : rv.use.use) {
        bool found = false;
        for (auto &alloc_byte : all_reqs.use) {
            if (!byte.is_subset(alloc_byte)) continue;
            byte.loc = alloc_byte.loc;
            found = true;
            break;
        }
        BUG_CHECK(found, "Byte not found in total allocation for table");
    }

    auto &hdh = rv.use.hash_dist_hash;

    int bits_seen = 0;
    int bits_of_my_hash_seen = 0;
    // Coordinate hash positions of an a single IR Use for the whole allocation
    for (auto br : bitranges(hash_bits_used)) {
        le_bitrange galois_range = { br.first , br.second };
        bitvec post_expand_sect_bv;
        int index = 0;
        for (int bit : total_post_expand_bits) {
            if (index >= bits_seen && index < bits_seen + galois_range.size())
                post_expand_sect_bv.setbit(bit);
            index++;
        }

        BUG_CHECK(post_expand_sect_bv.is_contiguous(), "Cannot associate galois matrix region "
            "with hash function");
        // The bits in the 23 bit section of data post expand that coordinate with this
        // allocation
        le_bitrange post_expand_sect
            = { post_expand_sect_bv.min().index(), post_expand_sect_bv.max().index() };
        auto boost_sl = toClosedRange<RangeUnit::Bit, Endian::Little>
                            (alloc_req.bits_in_use.intersectWith(post_expand_sect));
        if (boost_sl == boost::none) {
            bits_seen += galois_range.size();
            continue;
        }
        le_bitrange overlap = *boost_sl;

        int lo_add = overlap.lo - post_expand_sect.lo;
        int hi_sub = post_expand_sect.hi - overlap.hi;
        // Which part of the galois matrix these bits coordinate with
        galois_range = { galois_range.lo + lo_add, galois_range.hi - hi_sub };
        hdh.galois_matrix_bits.setrange(galois_range.lo, galois_range.size());

        // The range of bits within the P4 Hash
        le_bitrange p4_range
             = { bits_of_my_hash_seen,
                 bits_of_my_hash_seen + static_cast<int>(overlap.size()) - 1 };
        p4_range = p4_range.shiftedByBits(alloc_req.func.hash_bits.lo);
        hdh.galois_start_bit_to_p4_hash[galois_range.lo] = p4_range;

        bits_seen += galois_range.size();
        bits_of_my_hash_seen += overlap.size();
    }
    hdh.algorithm = alloc_req.func.algorithm;
    hdh.group = hash_group;
    hdh.allocated = true;
    rv.p4_hash_range = alloc_req.func.hash_bits;
    rv.dest = alloc_req.dest;
    rv.original_hd = alloc_req.original_hd;
    rv.use.hash_table_inputs[hash_group] = hash_table_input;
    rv.use.hash_seed[hash_group]
        |= determine_final_xor(&(alloc_req.func.algorithm), phv, hdh.galois_start_bit_to_p4_hash,
                               rv.use.field_list_order, rv.use.total_input_bits());
    rv.use.type = IXBar::Use::HASH_DIST;
    rv.use.used_by = name;
    rv.use.hash_dist_type = alloc_req.dest;
}

/**
 * Fill in the information of the IXBar Alloc2D structures in order to keep track of
 * hash distribution.
 */
void IXBar::lockInHashDistArrays(safe_vector<Use::Byte *> *alloced, int hash_group,
        unsigned hash_table_input, int asm_unit, bitvec hash_bits_used,
        HashDistDest_t dest, cstring name) {
    if (alloced)
        fill_out_use(*alloced, false);
    for (int i = 0; i < HASH_TABLES; i++) {
        if (((1 << i) & hash_table_input) == 0) continue;
        hash_dist_use[i][asm_unit % HASH_DIST_SLICES] = name;
        hash_dist_inuse[i].setbit(asm_unit % HASH_DIST_SLICES);
    }

    for (int i = 0; i < HASH_TABLES; i++) {
        if (((1 << i) & hash_table_input) == 0) continue;
        for (auto bit : hash_bits_used) {
            hash_dist_bit_use[i][bit] = name;
            hash_dist_bit_inuse[i].setbit(bit);
        }
    }
    hash_dist_groups[asm_unit / HASH_DIST_SLICES] = hash_group;
    hash_group_use[hash_group] |= hash_table_input;
}

/**
 * Hash Distribution, described in uArch section 6.4.3.5.3, is a node in Match Central
 * to distribute galois matrix calculations to many non-RAM matching functions:
 *
 *   - stats_adr, meter_adr, actiondata_adr
 *   - immediate data, (lo and hi 16b)
 *   - selector mod
 *   - meter pre-color
 *
 *
 * The Hash Distribution block inputs 96 bits of hash, bits 0..47 of 2 galois hash functions.
 * These 48 bit sections are further divided into 3 16 bit section of galois matrix calculations.
 * Thus, the hash can be pictured as 6x16 bit sections of hash before the expand block.
 *
 * Because addresses specifically may require to be greater than 16 bits, i.e. a meter_adr
 * could be 23 bits, the expand block is used to combined two of these 16 bit sections into
 * a single 23 bit section in a very strange way.  @seealso allocHashDistWideAddress.  If a wide
 * address is not necessary, 7b0 is just append to the msb.  Thus the hash distribution unit
 * at this point can be throught of as 6x23 bits of data.
 *
 * The next step is a mask and shift.  Similar to match central (shift mask default), this
 * per 23 bit section masks out the irrelevant bits, and shifts the bits to the relevant
 * position, which is necessary for many of the address positions.
 *
 * Thus if two IR::MAU::HashDist object were to share the same unit, they would require the
 * same hash function input, the same expand, the same mask, and the same shift.  (A couple
 * exceptions to this:
 *     - Potentially anything headed to immediate, where data can be further masked
 *       and shifted depending on the operation, i.e. deposit-field
 *     - Meter Pre-Color data doesn't go through the Mask/Shift block
 *
 * The terminology for all of these different concepts is difficult.  In reference, a unit
 * refers to one of the 6 23 bit sections.  These come from 2 hash functions inputs.
 *
 * Hash Function [0-7] -> Hash Function Input [0-1].
 * Hash Function Input (48b) -> Hash Dist Inputs (3 * 16b) -> Post Expand (3 * 23b)
 *
 * There is no direct unit in hardware, but instead just an assembly coordination between
 * which hash function input and which 16 bit section of that input (which then becomes a
 * 23 bit section post expand)
 *
 * "unit" = hash_function_input * 3 + 16b hash_dist input of 48b
 *
 * The purpose of this function is given the Hash Function requirement, and eventual
 * destination of a hash function, find the ixbar bytes, galois matrix, and hash distribution
 * unit that can hold this directly.  Multiple IR nodes, (i.e. two 8 bit immediate bytes)
 * might have to go to the same hash dist output, so this tracks both the high level unit
 * allocation as well as the per IR allocation
 */
bool IXBar::allocHashDist(safe_vector<HashDistAllocPostExpand> &alloc_reqs, HashDistUse &use,
        const PhvInfo &phv, cstring name, bool second_try) {
    IXBar::Use all_reqs;
    ContByteConversion               map_alloc;
    std::map<cstring, bitvec>        fields_needed;
    safe_vector <IXBar::Use::Byte *> alloced;
    fields_needed.clear();
    KeyInfo ki;
    ki.hash_dist = true;

    HashDistDest_t dest = alloc_reqs[0].dest;
    bitvec bits_in_use;
    int post_expand_shift = -1;
    bool chained_addr = false;

    LOG3("  Calling allocHashDist2 on dest " <<  IXBar::hash_dist_name(dest));
    // Build a union of all input xbar bytes required, as a single hash distribution output
    // might be sourced from multiple P4 level objects.
    for (auto alloc_req : alloc_reqs) {
        for (auto input : alloc_req.func.inputs) {
            safe_vector<const IR::Expression *> flo;
            FieldManagement(&map_alloc, flo, input, &fields_needed, name, phv, ki);
        }
        bits_in_use.setrange(alloc_req.bits_in_use.lo, alloc_req.bits_in_use.size());
        if (post_expand_shift == -1) {
            post_expand_shift = alloc_req.shift;
            chained_addr = alloc_req.chained_addr;
        } else {
            BUG_CHECK(post_expand_shift == alloc_req.shift, "Two hash dist of same type require "
                   "the same shift");
            BUG_CHECK(chained_addr == alloc_req.chained_addr, "Two address allocated at the same "
                   "time aren't chained");
        }
    }

    create_alloc(map_alloc, all_reqs.use);

    bool wide_address = false;
    if (bits_in_use.max().index() >= HASH_DIST_BITS) {
        BUG_CHECK(isHashDistAddress(dest), "Allocating illegal hash_dist");
        wide_address = true;
    }

    hash_matrix_reqs hm_reqs;
    if (second_try) {
        hm_reqs = hash_matrix_reqs::max(true);
    } else {
        hm_reqs.index_groups = 1;
        hm_reqs.hash_dist = true;
    }

    // Determine the xbar requirements of the hash distribution destination
    bool rv = find_alloc(all_reqs.use, false, alloced, hm_reqs);
    if (!rv) {
        use.clear();
        return false;
    }

    bitvec possible_shifts(0, 1);


    unsigned hash_table_input = all_reqs.compute_hash_tables();
    int hash_group_opts[HASH_DIST_UNITS] = {-1, -1};
    getHashDistGroups(hash_table_input, hash_group_opts);

    bool can_allocate_hash = false;
    int three_unit_section = -1;
    int unit = -1;
    int hash_group = -1;
    bitvec hash_bits_used;

    // Determine the galois matrix positions, as well has hash_function (of 8) associated hash
    // functions.
    for (int i = 0; i < HASH_DIST_UNITS; i++) {
        if (hash_group_opts[i] == -1) continue;
        hash_group = hash_group_opts[i];
        three_unit_section = i;
        if (wide_address)
            can_allocate_hash = allocHashDistWideAddress(bits_in_use, possible_shifts, hash_group,
                                    chained_addr, unit, hash_bits_used);
        else
            can_allocate_hash = allocHashDistSection(bits_in_use, possible_shifts, hash_group, unit,
                                    hash_bits_used);
        if (can_allocate_hash)
            break;
    }

    if (!can_allocate_hash) {
        use.clear();
        return false;
    }

    // @seealso Unit described in the HashDistUse code
    int asm_unit = three_unit_section * 3 + unit;
    for (auto &alloc_req : alloc_reqs) {
        buildHashDistIRUse(alloc_req, use, all_reqs, phv, hash_group, hash_bits_used,
            bits_in_use, hash_table_input, name);
    }
    lockInHashDistArrays(&alloced, hash_group, hash_table_input, asm_unit, hash_bits_used, dest,
                         name);

    if (wide_address)
        use.expand = (asm_unit % HASH_DIST_SLICES) * 7;
    use.unit = asm_unit;
    if (dest != HD_PRECOLOR) {
        use.shift = post_expand_shift;
        use.shift += (hash_bits_used.min().index() % HASH_DIST_BITS) - bits_in_use.min().index();
        use.mask = bits_in_use.getslice(0, HASH_DIST_MAX_MASK_BITS);
        if (chained_addr)
            use.outputs.insert("lo");
    }


    LOG3("  Allocated Hash Dist " << hash_group << " 0x" << hex(hash_table_input)
          << " " << hash_bits_used);
    return true;
}

/**
 * FIXME: Due to certain limitations of the current allocation, in JBay for chained vpns, an
 * address has to go both to an address position and immediate, as described in section
 * 6.2.12.12. of JBay uArch FIFO and Stack Primitives.  Because the current allocation
 * would require separate positions (as the allocation currently doesn't understand when two
 * hash functions are identical), this leads to an excess hash distribution allocation that
 * doesn't currently work for the multistage_fifo.p4 example.  Eventually when the allocation
 * understands that these can be overlaid in the galois matrix (WIP), then this can be separated
 * out.
 */
void IXBar::createChainedHashDist(const HashDistUse &hd_alloc, HashDistUse &chained_hd_alloc,
        cstring name) {
    for (auto &ir_alloc : hd_alloc.ir_allocations) {
        // For updating functions, need to have the same bytes and the same hash_table_inputs
        HashDistIRUse curr;
        curr.use.field_list_order.insert(curr.use.field_list_order.end(),
             ir_alloc.use.field_list_order.begin(), ir_alloc.use.field_list_order.end());
        curr.use.use.insert(curr.use.use.end(), ir_alloc.use.use.begin(), ir_alloc.use.use.end());
        curr.p4_hash_range = ir_alloc.p4_hash_range;
        curr.dest = HD_IMMED_HI;
        curr.original_hd = ir_alloc.original_hd;
        for (int i = 0; i < HASH_GROUPS; i++) {
            curr.use.hash_table_inputs[i] = ir_alloc.use.hash_table_inputs[i];
        }
        curr.use.hash_dist_hash.allocated = true;
        curr.use.hash_dist_hash.group = ir_alloc.use.hash_dist_hash.group;
        curr.use.type = Use::HASH_DIST;
        curr.use.hash_dist_type = curr.dest;
        chained_hd_alloc.ir_allocations.emplace_back(curr);
    }

    chained_hd_alloc.unit = (hd_alloc.unit / HASH_DIST_SLICES) * HASH_DIST_SLICES + 2;
    chained_hd_alloc.shift = hd_alloc.expand;
    chained_hd_alloc.mask = bitvec(chained_hd_alloc.shift, HASH_DIST_EXPAND_BITS);
    chained_hd_alloc.outputs.insert("hi");

    unsigned hash_table_inputs = chained_hd_alloc.hash_table_inputs();
    for (int ht = 0; ht < HASH_TABLES; ht++) {
        if (((1 << ht) & hash_table_inputs) == 0) continue;
        hash_dist_use[ht][chained_hd_alloc.unit % HASH_DIST_SLICES] = name;
        hash_dist_inuse[ht].setbit(chained_hd_alloc.unit % HASH_DIST_SLICES);
    }
}

/**
 * Using the bfn_hash_function, this algorithm determines the necessary final_xor positions
 * and writes them into the seed output.
 */
bitvec IXBar::determine_final_xor(const IR::MAU::HashFunction *hf,
        const PhvInfo &phv, std::map<int, le_bitrange> &bit_starts,
        safe_vector<const IR::Expression *> field_list, int total_input_bits) {
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
        if (entry->is<IR::Constant>()) {
            hash_input.type = ixbar_input_type::tCONST;
            if (!entry->to<IR::Constant>()->fitsUint64())
                ::error("The size of constant %1% is too large, "
                        "the maximum supported size is 64 bit", entry);
            hash_input.u.constant = entry->to<IR::Constant>()->asUint64();
        } else {
            hash_input.type = ixbar_input_type::tPHV;
            hash_input.u.valid = true;
        }
        hash_input.ixbar_bit_position = PHV::AbstractField::create(phv, entry)->range().lo;
        hash_input.bit_size = entry->type->width_bits();
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



IXBar::P4HashFunction IXBar::P4HashFunction::split(le_bitrange split) const {
    P4HashFunction rv;
    rv.algorithm = algorithm;
    rv.hash_bits = { split.lo + hash_bits.lo, hash_bits.lo + split.hi };
    int bits_seen = 0;
    if (algorithm == IR::MAU::HashFunction::identity()) {
        for (auto expr : inputs) {
            le_bitrange current_bits = { bits_seen, bits_seen + expr->type->width_bits() - 1 };
            auto boost_sl = toClosedRange<RangeUnit::Bit, Endian::Little>
                                 (split.intersectWith(split));
            if (boost_sl == boost::none) {
                bits_seen += expr->type->width_bits();
                continue;
            }

            le_bitrange overlap = *boost_sl;
            overlap = overlap.shiftedByBits(overlap.lo - current_bits.lo);
            rv.inputs.push_back(MakeSlice(expr, overlap.lo, overlap.hi));
            bits_seen += expr->type->width_bits();
        }
    } else {
        rv.inputs.insert(rv.inputs.end(), inputs.begin(), inputs.end());
    }
    return rv;
}

void IXBar::XBarHashDist::build_function(const IR::MAU::HashDist *hd, P4HashFunction &func,
        le_bitrange *bits) {
    ContByteConversion map_alloc;
    std::map<cstring, bitvec> fields_needed;
    KeyInfo ki;
    ki.hash_dist = true;
    ki.repeats_allowed &= hd->algorithm.type != IR::MAU::HashFunction::CRC;
    ki.repeats_allowed &= !hd->field_list->is<IR::HashListExpression>();

    FieldManagement(nullptr, func.inputs, hd, nullptr, tbl->name, phv, ki);
    if (bits) {
        func.hash_bits = *bits;
    } else {
        func.hash_bits = { 0, hd->bit_width - 1};
    }
    func.algorithm = hd->algorithm;
}

/**
 * Given a hash distribution object, with it's corresponding Context Node of where the
 * object is going, determine the bits required, the max right shift that is needed,
 * and the P4 Hash Function that will be required for the galois matrix.
 */
void IXBar::XBarHashDist::build_req(const IR::MAU::HashDist *hd, const IR::Node *rel_node) {
    le_bitrange post_expand_bits = { 0, hd->bit_width - 1 };
    HashDistDest_t dest;
    P4HashFunction func;
    build_function(hd, func, nullptr);
    int shift = 0;
    int color_mapram_shift = -1;
    bool chained_addr = false;
    if (rel_node->is<IR::MAU::Selector>()) {
        dest = IXBar::HD_HASHMOD;
    } else if (rel_node->is<IR::MAU::Meter>()) {
        dest = IXBar::HD_PRECOLOR;
    } else if (auto ba = rel_node->to<IR::MAU::BackendAttached>()) {
        if (auto cntr = ba->attached->to<IR::MAU::Counter>()) {
            dest = IXBar::HD_STATS_ADR;
            int per_word = CounterPerWord(cntr);
            shift = 3 - ceil_log2(per_word);
        } else if (auto salu = ba->attached->to<IR::MAU::StatefulAlu>()) {
            dest = IXBar::HD_METER_ADR;
            // Chained addresses don't need to shift as the input itself is an address
            if (salu->chain_vpn) {
                shift = 0;
                chained_addr = true;
            } else {
                int per_word = RegisterPerWord(salu);
                shift = 7 - ceil_log2(per_word);
            }
        } else if (ba->attached->to<IR::MAU::Meter>()) {
            dest = IXBar::HD_METER_ADR;
            shift = 7;
            color_mapram_shift = 3;
        }
    } else {
        BUG("Hash Dist object is not in a valid position");
    }

    alloc_reqs.emplace_back(func, post_expand_bits, dest, shift);
    alloc_reqs.back().original_hd = hd;
    alloc_reqs.back().chained_addr = chained_addr;
    if (color_mapram_shift > -1) {
        alloc_reqs.emplace_back(func, post_expand_bits, IXBar::HD_STATS_ADR, color_mapram_shift);
        alloc_reqs.back().original_hd = hd;
    }
}

/**
 * For ActionData tables, these don't yet exist until after TablePlacement, so no Context node
 * exists for these.  They have to be generated separately.
 */
void IXBar::XBarHashDist::build_action_data_req(const IR::MAU::HashDist *hd) {
    le_bitrange post_expand_bits = { 0, hd->bit_width - 1 };
    HashDistDest_t dest = HD_ACTIONDATA_ADR;
    P4HashFunction func;
    build_function(hd, func, nullptr);
    int shift = std::min(ceil_log2(lo->layout.action_data_bytes_in_table) + 1, 5);
    alloc_reqs.emplace_back(func, post_expand_bits, dest, shift);
    alloc_reqs.back().original_hd = hd;
}

/**
 * Given that a HashDist object is headed to immediate, this determine which (if not multiple)
 * hash distribution objects are required, as well as calculates the hash function that is
 * to be on the bits
 */
void IXBar::XBarHashDist::immediate_inputs(const IR::MAU::HashDist *hd) {
    auto placements = af->hash_dist_placement.at(hd);
    for (auto alu_op : placements) {
        BUG_CHECK(alu_op.arg_locs.size() == 1, "Hash Dist can only one argument");
        auto arg_loc = alu_op.arg_locs.at(0);
        auto arg_br = arg_loc.slot_br();
        arg_br = arg_br.shiftedByBits(alu_op.start * 8);

        for (int i = 0; i < 2; i++) {
            le_bitrange immed_impact = { i * HASH_DIST_BITS, (i+1) * HASH_DIST_BITS - 1 };
            auto boost_sl = toClosedRange<RangeUnit::Bit, Endian::Little>
                                (arg_br.intersectWith(immed_impact));
            if (boost_sl == boost::none)
                continue;
            le_bitrange overlap = *boost_sl;
            le_bitrange p4_hash_bits = overlap.shiftedByBits(-1 * arg_br.lo + arg_loc.field_bit);
            P4HashFunction func;
            build_function(hd, func, &p4_hash_bits);
            le_bitrange hash_dist_bits = overlap.shiftedByBits(-1 * HASH_DIST_BITS * i);
            HashDistDest_t dest = static_cast<HashDistDest_t>(i);
            alloc_reqs.emplace_back(func, hash_dist_bits, dest, 0);
            alloc_reqs.back().original_hd = hd;
        }
    }
}

/**
 * For hash_action tables, HashDist objects must be created during the allocation of the table,
 * as they will be associated as the address for that table later.  This creates that IR object
 * and uses it as context required for the HashDistPostExpandAllocReq creation.
 */
void IXBar::XBarHashDist::hash_action() {
    if (tbl->gateway_only())
        return;
    if (!lo->layout.hash_action)
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
    hd->bit_width = bits_required;
    for (auto ba : tbl->attached) {
        if (!(ba->attached && ba->attached->direct))
            continue;
        build_req(hd, ba);
    }

    if (lo->layout.action_data_bytes_in_table > 0) {
        build_action_data_req(hd->clone());
    }
}

bool IXBar::XBarHashDist::preorder(const IR::MAU::HashDist *hd) {
    if (auto sel = findContext<IR::MAU::Selector>()) {
        build_req(hd, sel);
    } else if (auto mtr = findContext<IR::MAU::Meter>()) {
        build_req(hd, mtr);
    } else if (auto ba = findContext<IR::MAU::BackendAttached>()) {
        build_req(hd, ba);
    } else if (findContext<IR::MAU::Instruction>()) {
        immediate_inputs(hd);
        return false;
    }

    return false;
}

/**
 * The purpose of this class is to gather the requirements that have to go through
 * hash distribution.  The requirement is captured in either the IR::MAU::HashDist, or
 * implicitly as the LayoutOption of the table is a hash action table.  From the IR,
 * we can gather the IXBar Bytes required, as well as the hash matrix requirements.
 * 
 * At this point, all requirements have been gathered.  This allocates each requirement
 * on a destination by destination basis.  Thus if multiple HashDistPostExpandAllocReqs are
 * headed to the same destination, they will be allocated simultaneously
 *
 */
bool IXBar::XBarHashDist::allocate_hash_dist() {
    for (int i = HD_IMMED_LO; i < HD_DESTS; i++) {
        safe_vector<HashDistAllocPostExpand> dest_reqs;
        for (auto alloc_req : alloc_reqs) {
            if (alloc_req.dest == static_cast<HashDistDest_t>(i))
                dest_reqs.push_back(alloc_req);
        }
        if (dest_reqs.empty())
            continue;
        HashDistUse hd_alloc;
        hd_alloc.used_by = tbl->name;
        if (!self.allocHashDist(dest_reqs, hd_alloc, phv, tbl->name + "$hash_dist", false) &&
            !self.allocHashDist(dest_reqs, hd_alloc, phv, tbl->name + "$hash_dist", true)) {
            return false;
        }
        resources->hash_dists.emplace_back(hd_alloc);

        if (dest_reqs[0].chained_addr && hd_alloc.expand >= 0) {
            HashDistUse chained_hd_alloc;
            chained_hd_alloc.used_by = tbl->name;
            self.createChainedHashDist(hd_alloc, chained_hd_alloc, tbl->name + "$hash_dist");
            resources->hash_dists.emplace_back(chained_hd_alloc);
        }
    }
    return true;
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

    XBarHashDist xbar_hash_dist(*this, phv, tbl, af, lo, &alloc);
    xbar_hash_dist.hash_action();
    tbl->attached.apply(xbar_hash_dist);
    for (auto v : Values(tbl->actions))
        v->apply(xbar_hash_dist);
    if (!xbar_hash_dist.allocate_hash_dist()) {
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
    if (alloc.hash_dist_hash.allocated) {
        auto &hdh = alloc.hash_dist_hash;
        for (int i = 0; i < HASH_TABLES; i++) {
            if (((1U << i) & alloc.hash_table_inputs[hdh.group]) == 0) continue;
            for (auto bit : bitvec(hdh.galois_matrix_bits)) {
                if (!hash_dist_bit_use[i][bit]) {
                    hash_dist_bit_use[i][bit] = name;
                } else if (hash_dist_bit_use[i][bit] != name) {
                    BUG("Conflicting hash distribution bit allocation %s and %s",
                        name, hash_dist_bit_use[i][bit]);
                }
            }
            hash_dist_bit_inuse[i] |= hdh.galois_matrix_bits;
        }
        hash_group_print_use[hdh.group] = name;
        hash_group_use[hdh.group] |= alloc.hash_table_inputs[hdh.group];
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
        hash_group_print_use[ph.group] = name;
        hash_group_use[ph.group] |= alloc.hash_table_inputs[ph.group];
    }
}

void IXBar::update(cstring name, const HashDistUse &hash_dist_alloc) {
    for (auto &ir_alloc : hash_dist_alloc.ir_allocations) {
        update(name, ir_alloc.use);
    }

    for (int i = 0; i < HASH_TABLES; i++) {
        if (((1U << i) & hash_dist_alloc.hash_table_inputs()) == 0) continue;
        int slice = hash_dist_alloc.unit % HASH_DIST_SLICES;
        if (!hash_dist_use[i][slice].isNull())
            hash_dist_use[i][slice] = name;
        hash_dist_inuse[i].setbit(slice);
    }

    int hash_dist_48_bit_unit = hash_dist_alloc.unit / HASH_DIST_SLICES;
    if (hash_dist_groups[hash_dist_48_bit_unit] != hash_dist_alloc.hash_group()
        && hash_dist_groups[hash_dist_48_bit_unit] != -1)
        BUG("Conflicting hash distribution unit groups");
    hash_dist_groups[hash_dist_48_bit_unit] = hash_dist_alloc.hash_group();
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
    for (auto &hash_dist : rsrc->hash_dists) {
        update(name + "$hash_dist" + std::to_string(index++), hash_dist);
    }
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

bool IXBar::Use::Byte::is_subset(const Byte &b) const {
    if (name != b.name && lo != b.lo)
        return false;
    for (auto fi : field_bytes) {
        bool is_subset = false;
        for (auto b_fi : b.field_bytes) {
            if (fi.field != b_fi.field) continue;
            if (!b_fi.range().contains(fi.range())) continue;
            is_subset = true;
            break;
        }
        if (!is_subset)
            return false;
    }
    return true;
}

bool IXBar::Use::Byte::can_add_info(const FieldInfo &fi) const {
    bitvec overlap_bits = bit_use & fi.cont_loc();
    for (auto br : bitranges(overlap_bits)) {
        le_bitrange field_bits = { br.first, br.second };
        field_bits = field_bits.shiftedByBits(fi.lo - fi.cont_lo);
        bool is_subset = false;
        for (auto c_fi : field_bytes) {
            if (c_fi.field == fi.field && c_fi.range().contains(field_bits)) {
                is_subset = true;
                break;
            }
        }
        if (!is_subset) {
            return false;
        }
    }
    return true;
}

void IXBar::Use::Byte::add_info(const FieldInfo &fi) {
    safe_vector<FieldInfo> add_fi;
    bitvec non_overlap_bits = fi.cont_loc() - bit_use;
    for (auto br : bitranges(non_overlap_bits)) {
        le_bitrange field_bits = { br.first, br.second };
        field_bits = field_bits.shiftedByBits(fi.lo - fi.cont_lo);
        add_fi.emplace_back(fi.field, field_bits.lo, field_bits.hi, br.first, fi.aliasSource);
    }

    field_bytes.insert(field_bytes.end(), add_fi.begin(), add_fi.end());
    std::sort(field_bytes.begin(), field_bytes.end(), [](const FieldInfo &a, const FieldInfo &b) {
        return a.cont_lo < b.cont_lo;
    });

    BUG_CHECK(field_bytes.size() > 0, "Should be at least one field slice on a byte");
    for (size_t i = 0; i < field_bytes.size() - 1; i++) {
        auto &field_a = field_bytes[i];
        auto &field_b = field_bytes[i+1];
        if (field_a.field != field_b.field)
            continue;
        if (field_a.cont_hi() + 1 != field_b.cont_lo)
            continue;
        if (field_a.hi + 1 != field_b.lo)
            continue;
        field_a.hi += field_b.width();
        field_bytes.erase(field_bytes.begin() + i + 1);
        i--;
    }
    bit_use |= fi.cont_loc();
}

int IXBar::HashDistUse::hash_group() const {
    int hash_group = -1;
    for (auto &ir_alloc : ir_allocations) {
        if (hash_group == -1)
            hash_group = ir_alloc.use.hash_dist_hash.group;
        else
            BUG_CHECK(hash_group == ir_alloc.use.hash_dist_hash.group, "Hash Groups "
                 "are different across units");
    }
    return hash_group;
}

unsigned IXBar::HashDistUse::hash_table_inputs() const {
    unsigned rv = 0;
    for (auto &ir_alloc : ir_allocations) {
        rv |= ir_alloc.use.hash_table_inputs[hash_group()];
    }
    return rv;
}

bitvec IXBar::HashDistUse::destinations() const {
    bitvec rv;
    for (auto &ir_alloc : ir_allocations) {
        rv.setbit(static_cast<int>(ir_alloc.dest));
    }
    return rv;
}

std::string IXBar::HashDistUse::used_for() const {
    auto dests = destinations();
    std::string rv = "";
    std::string sep = "";
    for (auto bit : dests) {
        std::string type = IXBar::hash_dist_name(static_cast<HashDistDest_t>(bit));
        rv += sep + type;
        sep = ", ";
    }
    return rv;
}
