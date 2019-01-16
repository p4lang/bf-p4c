#include <algorithm>
#include "ir/ir.h"
#include "action_format_2.h"

/**
 * Returns an Argument if the two Arguments have some equivalency overlap, i.e.:
 *     param1[8:15]
 *     param1[12:19]
 * 
 * would return param1[12:15]
 *
 * The two bitrange pointers are overlap offsets into the arguments, i.e. in the corner case:
 *     [4:7]
 *     [0:3]
 */
const ActionDataParam *Argument::overlap(const ActionDataParam *ad, le_bitrange *my_overlap,
        le_bitrange *ad_overlap) const {
    const Argument *arg = ad->to<Argument>();
    if (arg == nullptr) return nullptr;
    if (_name != arg->_name) return nullptr;
    auto boost_sl = toClosedRange<RangeUnit::Bit, Endian::Little>
                        (_param_field.intersectWith(arg->_param_field));
    if (boost_sl == boost::none) return nullptr;
    le_bitrange overlap = *boost_sl;
    auto rv = new Argument(_name, overlap);
    if (my_overlap) {
        auto ov_boost_sl = toClosedRange<RangeUnit::Bit, Endian::Little>
                           (_param_field.intersectWith(overlap));
        *my_overlap = *ov_boost_sl;
        my_overlap->lo -= _param_field.lo;
        my_overlap->hi -= _param_field.lo;
    }
    if (ad_overlap) {
        auto ov_boost_sl = toClosedRange<RangeUnit::Bit, Endian::Little>
                           (arg->_param_field.intersectWith(overlap));
        *ad_overlap = *ov_boost_sl;
        ad_overlap->lo -= arg->_param_field.lo;
        ad_overlap->hi -= arg->_param_field.lo;
    }

    return rv;
}

LocalPacking LocalPacking::split(int first_bit, int sz) const {
    BUG_CHECK(sz < bit_width && ((bit_width % sz) == 0), "Cannot split a LocalPacking evenly");
    LocalPacking rv(sz, bits_in_use.getslice(first_bit, sz));
    return rv;
}

RotationInfo RotationInfo::split(int first_bit, int sz) const {
    BUG_CHECK(sz < size() && (size() % sz == 0), "Cannot split a Rotation evenly");
    RotationInfo rv(bits_begin + first_bit, bits_begin + first_bit + sz);
    return rv;
}

void RotationInfo::rotate(int bit_rotation) {
    BUG_CHECK(bit_rotation < size(), "Rotating more than the bits available");
    std::rotate(bits_begin, bits_begin + bit_rotation, bits_end);
}

/**
 * The function tests if the packing information returns the following:
 *    - Can the bit at the init_bit position can be rotated to the final_bit position
 *
 * This is talked about in the comments over the PackingConstraint::rotate section, but the
 * constraints can be rotated recursively.
 */
bool PackingConstraint::can_rotate(int bit_width, int init_bit, int final_bit) const {
    if (init_bit == final_bit)
        return true;
    if (!is_rotational())
        return false;
    if (rotational_granularity == 1)
        return true;
    size_t total_sections = bit_width / rotational_granularity;
    BUG_CHECK(recursive_constraints.size() == total_sections, "Packing Constraints not set "
              "correctly");
    int index = init_bit / rotational_granularity;
    int next_init_bit = init_bit % rotational_granularity;
    int next_final_bit = final_bit % rotational_granularity;
    const PackingConstraint &final_pc = recursive_constraints.at(index);
    return final_pc.can_rotate(rotational_granularity, next_init_bit, next_final_bit);
}

/**
 * Helper function for can_rotate_in_range (please look at their comments)
 */
bool PackingConstraint::under_rotate(LocalPacking &lp, le_bitrange open_range, int &final_bit,
        int right_shift) const {
    int under_rotation = (right_shift / rotational_granularity) * rotational_granularity;
    le_bitrange shifted_br_in_use
         = { lp.max_br_in_use().lo + under_rotation, lp.max_br_in_use().hi + under_rotation };
    if (open_range.contains(shifted_br_in_use)) {
        final_bit += under_rotation;
        return true;
    } else if (open_range.hi < shifted_br_in_use.hi) {
        return false;
    } else {
        le_bitrange rec_open_range = { open_range.lo % rotational_granularity,
                                       rotational_granularity - 1 };
        int index = (lp.max_br_in_use().lo / rotational_granularity);
        LocalPacking rec_lp = lp.split(index * rotational_granularity, rotational_granularity);
        if (recursive_constraints[index].can_rotate_in_range(rec_lp, rec_open_range, final_bit)) {
            final_bit += under_rotation;
            return true;
        }
    }
    return false;
}

/**
 * Helper function for can_rotate_in_range (please look at their comments)
 */
bool PackingConstraint::over_rotate(LocalPacking &lp, le_bitrange open_range, int &final_bit,
        int right_shift) const {
    int over_rotation = ((right_shift / rotational_granularity) + 1) * rotational_granularity;
    le_bitrange shifted_br_in_use
        = { lp.max_br_in_use().lo + over_rotation, lp.max_br_in_use().hi + over_rotation };
    if (!open_range.contains(shifted_br_in_use))
        return false;
    final_bit += over_rotation;
    return true;
}

/**
 * This check verifies that the data (summarized in the LocalPacking) can be rotated into
 * the bit data into the open_range. The function also calculates the position of the final bit,
 * in which the first set bit in the lp.bit_in_use can be rotated into for the rotate function.
 *
 * The test is done as a two-parter.
 *
 *    1. Can the RAM section be rotated to constraint where the first bit of the open_range
 *       (called under_rotate).
 *    2. If it cannot be rotated to this section, then rotate one more section and try again,
 *       (called over_rotate).
 *
 * The goal of this is to keep data as close as possible to the lsb of the RAM section.
 *
 * This works well with an example:
 *
 * Say again, you have a 16 bit, byte-by-byte rotational constraints, with data packed
 * from bits 0:3.  Let's now provide some potential ranges.
 *
 * Test for open_range 4:11:
 *     - In a byte by byte rotation, the initial byte rotation is 0.  We then recurse to the bit
 *       granularity and find that we can rotate the first byte, bit by bit, so that the bits
 *       end up a bits 4:7
 *
 * Test for open_range 5:11:
 *     - In this case, the under_rotation will fail, as only 3 bits are available in that byte
 *       but after a rotation to the next byte, then this will fit.
 *
 * This is all based on the idea that the algorithm is trying to pack data as close to the lsb.
 */
bool PackingConstraint::can_rotate_in_range(LocalPacking &lp, le_bitrange open_range,
        int &final_bit) const {
    if (open_range.contains(lp.max_br_in_use()))
        return true;

    if (!is_rotational())
        return false;

    int right_shift = open_range.lo - lp.max_br_in_use().lo;
    if (rotational_granularity == 1) {
        le_bitrange shifted_br_in_use = lp.max_br_in_use();
        shifted_br_in_use.lo += right_shift;
        shifted_br_in_use.hi += right_shift;
        if (!open_range.contains(shifted_br_in_use))
            return false;
        final_bit += right_shift;
        return true;
    } else if (under_rotate(lp, open_range, final_bit, right_shift)) {
        return true;
    } else if (over_rotate(lp, open_range, final_bit, right_shift)) {
        return true;
    }
    return false;
}

/**
 * The rotation function both rotates the constraints as well as the data bit-by-bit so that the
 * data bit at the init_bit position can will be at the final_bit position.  This function
 * recurses down the constraint levels so that the only the relevant portion to rotate
 * will have been rotated.
 *
 * Let's set up the following scenario:
 * 
 * 16 bit data, that is byte by byte rotational, and each byte is bit by bit rotational
 * The data is arg1[3:0] at RAM bit 3:0 and arg2[3:0] at RAM bit 11:8:
 *
 * The init_bit and final_bit are 0, 12.  After the rotation:
 *     arg2[3:0] will be at RAM bit [3:0]
 *     arg1[3:0] will be at RAM bit [15:12]
 *
 * This is because both bytes are rotated, but only the byte at the final bit is rotated.
 */
void PackingConstraint::rotate(RotationInfo &ri, int init_bit, int final_bit) {
    if (init_bit == final_bit)
        return;
    BUG_CHECK(is_rotational(), "Cannot rotate at this point");
    int total_splits = ri.size() / rotational_granularity;
    int init_index = init_bit / rotational_granularity;
    int final_index = final_bit / rotational_granularity;

    // Rotate the constraints
    int rotation = (init_index - final_index + total_splits) % total_splits;
    std::rotate(recursive_constraints.begin(), recursive_constraints.begin() + rotation,
                recursive_constraints.end());

    // Rotate the action data bits
    int bit_rotation = rotation * rotational_granularity;
    ri.rotate(bit_rotation);

    int next_init_bit = init_bit % rotational_granularity;
    int next_final_bit = final_bit % rotational_granularity;

    // Calculate the next iterator positions
    RotationInfo next_ri = ri.split(final_index * rotational_granularity, rotational_granularity);
    recursive_constraints[final_index].rotate(next_ri, next_init_bit, next_final_bit);
}

/**
 * Essentially to merge constraints:
 *
 * When merging a bit-by-bit rotational section with a non bit-by-bit rotational section,
 * the RAM section is not bit-by-bit rotational.
 *
 * When merging two bit-by-bit rotational RAM sections, the merged RAM section is also
 * bit-by-bit rotational
 *
 * When merging two bit-by-bit rotational RAM sections that are different sizes:
 *     1. The merged section rotational_granularity is the size of the smaller slot size
 *     2. Any recursive constraint containing data from the larger section is not bit-by-bit
 *        rotational.  Thus if a recursive constraint contains data from the smaller section,
 *        it is not bit-by-bit rotational if that section also contains data from the larger
 *        section.
 *
 * This is displayed in the gtests for CrossSizeMerge as well as the Google Doc notes.
 */
PackingConstraint PackingConstraint::merge(const PackingConstraint &pc, const LocalPacking &lp,
        const LocalPacking &pc_lp) const {
    BUG_CHECK(is_rotational() == (recursive_constraints.size() != 0),
              "Cannot have non-underlying recursive constraints");
    BUG_CHECK(pc.is_rotational() == (pc.recursive_constraints.size() != 0),
              "Cannot have non-underlying recursive constraints");
    PackingConstraint rv;
    BUG_CHECK(lp.bit_width == pc_lp.bit_width, "Cannot condense different sized Packing "
              "Constraints");
    ///> Recursive constraints should only be merged, if the data was to merge
    if (lp.empty() && pc_lp.empty())
        return rv;
    if (lp.empty() && !pc_lp.empty())
        return pc;
    if (!lp.empty() && pc_lp.empty())
        return *this;

    // If both sections are not rotational, then the merged constraints is not rotational
    if (!(is_rotational() && pc.is_rotational())) {
        return rv;
    }

    const PackingConstraint *higher_gran = rotational_granularity > pc.rotational_granularity
                                           ? this : &pc;
    const LocalPacking *higher_lp = higher_gran == this ? &lp : &pc_lp;
    const LocalPacking *lower_lp = higher_gran == this ? &pc_lp : &lp;
    rv.rotational_granularity = higher_gran->rotational_granularity;

    // The one with the higher granularity comes from the smaller RAM size originally, as
    // it has been expanded
    int total_indexes = higher_lp->bit_width / higher_gran->rotational_granularity;
    for (int i = 0; i < total_indexes; i++) {
        // Check the packing constraint
        const PackingConstraint &a_pc = higher_gran->recursive_constraints[i];
        // Set up the data from the larger section a non-rotational constraint
        PackingConstraint b_pc;
        auto a_lp = higher_lp->split(i * rv.rotational_granularity, rv.rotational_granularity);
        auto b_lp = lower_lp->split(i * rv.rotational_granularity, rv.rotational_granularity);
        rv.recursive_constraints.push_back(a_pc.merge(b_pc, a_lp, b_lp));
    }
    return rv;
}

PackingConstraint PackingConstraint::expand(int current_size, int expand_size) const {
    BUG_CHECK((expand_size % current_size) == 0, "Cannot expand constraint into this size");
    safe_vector<PackingConstraint> bits_vec(current_size, PackingConstraint());
    safe_vector<PackingConstraint> rv_rec;
    rv_rec.push_back(*this);
    for (int i = 1; i < expand_size / current_size; i++)
        rv_rec.emplace_back(1, bits_vec);
    return PackingConstraint(current_size, rv_rec);
}

/**
 * In order to perform the merge function, the two ActionDataRamSections have to be the same
 * size, i.e. the same number of bits wide.
 *
 * The example would be to move a 8-bit data to move 16-bit data.  The byte size data now has
 * 8 empty bits appended to it.  The new 16 bit section is also now byte-by-byte rotational, which
 * is done through the expansion of the PackingConstraint
 */
const ActionDataRamSection *ActionDataRamSection::expand_to_size(size_t expand_size) const {
    if (size() >= expand_size)
        return this;
    BUG_CHECK(size() % expand_size, "Cannot expand this section into this size");

    PackingConstraint rv_pack_info = pack_info.expand(size(), expand_size);
    ActionDataRamSection *rv = new ActionDataRamSection(expand_size, rv_pack_info);
    std::copy(action_data_bits.begin(), action_data_bits.end(), rv->action_data_bits.begin());
    return rv;
}

void ActionDataRamSection::add_param(int bit, const ActionDataParam *adp) {
    BUG_CHECK(bit + adp->size() <= static_cast<int>(size()), "The size of the parameter is "
              "outside the size of the RAM section");
    for (int i = 0; i < adp->size(); i++) {
        action_data_bits[bit + i] = adp->split(i, i);
    }
}

/**
 * Building a map of slices of parameters in order to look for identical ranges of data within
 * two ActionDataRamSections.
 */
ActionDataPositions ActionDataRamSection::action_data_positions() const {
    ActionDataPositions rv;
    size_t bit_pos = 0;
    const ActionDataParam *next_entry = nullptr;
    for (size_t i = 0; i < size(); i++) {
        if (action_data_bits[i] == nullptr) {
            if (next_entry == nullptr) {
                continue;
            } else {
                rv.emplace(bit_pos, next_entry);
                next_entry = nullptr;
            }
        } else {
            if (next_entry == nullptr) {
                next_entry = action_data_bits[i];
                bit_pos = i;
            } else {
                if (action_data_bits[i]->is_next_bit_of_param(next_entry)) {
                    next_entry = next_entry->get_extended_param(1);
                } else {
                    rv.emplace(bit_pos, next_entry);
                    next_entry = action_data_bits[i];
                    bit_pos = i;
                }
            }
        }
    }
    if (next_entry)
        rv.emplace(bit_pos, next_entry);
    return rv;
}

/**
 * Calculate the positions of the parameters that both ActionDataRamSection
 */
void ActionDataRamSection::gather_shared_params(const ActionDataRamSection *ad,
        safe_vector<SharedActionDataParam> &shared_params) const {
    // Entries in the map will be lsb to msb in position
    for (auto a_param_loc_pair : action_data_positions()) {
        int a_start_bit = a_param_loc_pair.first;
        auto a_param_loc = a_param_loc_pair.second;
        for (auto b_param_loc_pair : ad->action_data_positions()) {
            int b_start_bit = b_param_loc_pair.first;
            auto b_param_loc = b_param_loc_pair.second;
            le_bitrange a_br, b_br;
            auto shared_param = a_param_loc->overlap(b_param_loc, &a_br, &b_br);
            if (shared_param == nullptr)
                continue;
            shared_params.emplace_back(shared_param, a_start_bit + a_br.lo, b_start_bit + b_br.lo);
        }
    }
}

bitvec ActionDataRamSection::bits_in_use() const {
    bitvec rv;
    for (size_t i = 0; i < size(); i++) {
        if (action_data_bits[i])
            rv.setbit(i);
    }
    return rv;
}

/**
 * Return the open ranges of data within an ActionDataRamSection
 */
safe_vector<le_bitrange> ActionDataRamSection::open_holes() const {
    safe_vector<le_bitrange> rv;
    bitvec bits_inuse = bits_in_use();
    int start_bit = bits_inuse.ffz();
    while (start_bit < static_cast<int>(size())) {
        int end_bit = bits_inuse.ffs(start_bit);
        if (end_bit < 0)
            end_bit = size() - 1;
        rv.emplace_back(start_bit, end_bit);
    }

    std::sort(rv.begin(), rv.end(), [=](const le_bitrange &a, const le_bitrange &b) {
        int t;
        if ((t = a.size() - b.size()) != 0) return t < 0;
        return a.lo < b.lo;
    });
    return rv;
}

const ActionDataRamSection *ActionDataRamSection::can_rotate(int init_bit, int final_bit) const {
    if (!pack_info.can_rotate(size(), init_bit, final_bit))
        return nullptr;
    ActionDataRamSection *rv = new ActionDataRamSection(*this);
    RotationInfo ri(rv->action_data_bits.begin(), rv->action_data_bits.end());
    rv->pack_info.rotate(ri, init_bit, final_bit);
    return rv;
}

const ActionDataRamSection *ActionDataRamSection::merge(const ActionDataRamSection *ad) const {
    for (size_t i = 0; i < size(); i++) {
        if (action_data_bits[i] == nullptr || ad->action_data_bits[i] == nullptr)
            continue;
        if (action_data_bits[i]->equiv_value(ad->action_data_bits[i]))
            continue;
        return nullptr;
    }
    ActionDataRamSection *rv = new ActionDataRamSection(size());

    for (size_t i = 0; i < size(); i++) {
        const ActionDataParam *bit_param
            = action_data_bits[i] == nullptr ? action_data_bits[i] : ad->action_data_bits[i];
        rv->action_data_bits.push_back(bit_param);
    }

    LocalPacking a_lp(size(), bits_in_use());
    LocalPacking b_lp(size(), ad->bits_in_use());

    rv->pack_info = pack_info.merge(ad->pack_info, a_lp, b_lp);
    return rv;
}

/**
 * Returns a rotated ActionDataRamSection that fits within the bitrange provided, if possible.
 * For a constraint explanation, please look at PackingConstraint::rotate_in_range
 */
const ActionDataRamSection *ActionDataRamSection::rotate_in_range(le_bitrange hole) const {
    int init_bit = bits_in_use().min().index();
    int final_bit = init_bit;
    LocalPacking lp(size(), bits_in_use());
    if (!pack_info.can_rotate_in_range(lp, hole, final_bit))
        return nullptr;
    ActionDataRamSection *rv = new ActionDataRamSection(*this);
    RotationInfo ri(rv->action_data_bits.begin(), rv->action_data_bits.end());
    rv->pack_info.rotate(ri, init_bit, final_bit);
    return rv;
}


/**
 * Returns a merged ActionDataRamSection of two independent ranges, if the merge was possible.
 * For a constraint explanation, please look at PackingConstraint::merge
 */
const ActionDataRamSection *
        ActionDataRamSection::no_overlap_merge(const ActionDataRamSection *ad) const {
    safe_vector<le_bitrange> holes = open_holes();
    bitvec ad_bits_in_use = ad->bits_in_use();
    le_bitrange max_bit_diff = { ad_bits_in_use.min().index(), ad_bits_in_use.max().index() };
    for (auto hole : holes) {
        if (hole.size() < max_bit_diff.size())
            continue;
        auto rotated_ad = ad->rotate_in_range(hole);
        if (rotated_ad != nullptr) {
            auto merged_ad = merge(rotated_ad);
            if (merged_ad)
                return merged_ad;
            else
                BUG("The bits should not overlap after the rotate in range function call");
        }
    }
    return nullptr;
}

/**
 * Will return true if compare is worse than *this for the rv of the condense function.
 * Simple heuristics to be imrproved later. 
 */
bool ActionDataRamSection::is_better_merge_than(const ActionDataRamSection *compare) const {
    int t;
    // Bit utilization (preferring more overlap)
    if ((t = bits_in_use().popcount() - compare->bits_in_use().popcount()) != 0)
        return t < 0;

    auto comp_holes = compare->open_holes();
    // Prefer less fragmentation
    auto holes = open_holes();
    if ((t = holes.size() - comp_holes.size()) != 0)
        return t < 0;

    // Prefer closer to the least significant bit
    return bits_in_use().max().index() < compare->bits_in_use().max().index();
}

/**
 * The algorithm to determine if (and the best way of) two ActionDataRamSections can be
 * merged, (if two sections can be merged).
 *
 * The steps are:
 *     1. Expand the RAMSections so that they are the same size
 *     2. Look for shared parameters and rotate the sections so that this data overlaps
 *     3. Try to rotate data so that no fields overlap
 *     4. Pick the best choice based on heuristics
 */
const ActionDataRamSection *ActionDataRamSection::condense(const ActionDataRamSection *ad) const {
    size_t max_size = std::max(size(), ad->size());
    const ActionDataRamSection *a = expand_to_size(max_size);
    const ActionDataRamSection *b = ad->expand_to_size(max_size);

    safe_vector<const ActionDataRamSection *> possible_rvs;
    safe_vector<SharedActionDataParam> shared_params;
    gather_shared_params(ad, shared_params);

    // Overlap equivalent ActionDataParams
    for (auto shared_param : shared_params) {
        auto *a_rotated = a->can_rotate(shared_param.a_start_bit, shared_param.b_start_bit);
        if (a_rotated) {
            auto *merged_ad = b->merge(a_rotated);
            if (merged_ad)
                possible_rvs.push_back(merged_ad);
        }

        auto *b_rotated = b->can_rotate(shared_param.b_start_bit, shared_param.a_start_bit);
        if (b_rotated) {
            auto merged_ad = a->merge(b_rotated);
            if (merged_ad)
                possible_rvs.push_back(merged_ad);
        }
    }

    // Have no data overlap and just merge
    auto no_overlap_b_in_a = a->no_overlap_merge(b);
    if (no_overlap_b_in_a)
        possible_rvs.push_back(no_overlap_b_in_a);
    auto no_overlap_a_in_b = b->no_overlap_merge(a);
    if (no_overlap_a_in_b)
        possible_rvs.push_back(no_overlap_a_in_b);

    // Pick the best choice
    const ActionDataRamSection *best = nullptr;
    for (auto choice : possible_rvs) {
        if (best == nullptr || !best->is_better_merge_than(choice))
            best = choice;
    }
    return best;
}
