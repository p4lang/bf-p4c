#include <algorithm>
#include "bf-p4c/mau/action_format_2.h"
#include "ir/ir.h"
#include "lib/bitrange.h"

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
const ActionDataParam *Argument::overlap(const ActionDataParam *ad, bool,
        le_bitrange *my_overlap, le_bitrange *ad_overlap) const {
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

const ActionDataParam *Constant::split(int lo, int hi) const {
    le_bitrange split_range = { lo, hi };
    BUG_CHECK(range().contains(split_range), "Illegally splitting a parameter, as the "
              "split contains bits outside of the range");
    return new Constant(_value.getslice(split_range.lo, split_range.size()), split_range.size());
}

bool Constant::is_next_bit_of_param(const ActionDataParam *ad) const {
    if (size() != 1)
        return false;
    return ad->is<Constant>();
}

/**
 * Appending a constant to another constant on the MSB
 */
const ActionDataParam *Constant::get_extended_param(unsigned extension,
        const ActionDataParam *ad) const {
    auto con = ad->to<Constant>();
    BUG_CHECK(con != nullptr, "Cannot extend a non-constant on constant");
    BUG_CHECK(con->size() <= static_cast<int>(extension), "The extension constant is smaller "
                                                          "than the extension size");
    Constant *rv = new Constant(*this);
    rv->_value |= (con->_value << this->_size);
    rv->_size += extension;
    return rv;
}

/**
 * Because Constants can potentially have multiple overlaps, this will only return an
 * overlap under the following condition:
 *
 *     The constant that is smaller size than the other constant must be fully contained
 *     within the other constant.
 *
 * This could possibly be updated overtime to allow for more constant processing, i.e. overlaps
 * at the edges of the constant
 *
 * The parameter only_one_overlap_solution indicates that the overlap function will only return if
 * overlap has one and only one solution (as this function is used by multiple ActionDataParams).
 * Constants do not have this property and will always return a no solution 
 */
const ActionDataParam *Constant::overlap(const ActionDataParam *ad, bool only_one_overlap_solution,
        le_bitrange *my_overlap, le_bitrange *ad_overlap) const {
    if (only_one_overlap_solution)
        return nullptr;
    auto con = ad->to<Constant>();
    if (con == nullptr)
        return nullptr;
    const Constant *larger = size() > con->size() ? this : con;
    const Constant *smaller = larger == this ? con : this;

    int offset = -1;
    for (int i = 0; i <= larger->size() - smaller->size(); i++) {
        if (larger->_value.getslice(i, smaller->size()) == smaller->_value) {
            offset = i;
            break;
        }
    }
    if (offset == -1)
        return nullptr;
    const Constant *rv = larger->split(offset, offset + smaller->size() - 1)->to<Constant>();
    le_bitrange smaller_overlap = smaller->range();
    le_bitrange larger_overlap = { offset, offset + smaller->size() - 1 };

    if (my_overlap)
        *my_overlap = (larger == this) ? larger_overlap : smaller_overlap;
    if (ad_overlap)
        *ad_overlap = (larger == con) ? larger_overlap : smaller_overlap;
    return rv;
}

bool Constant::equiv_value(const ActionDataParam *ad) const {
    auto con = ad->to<Constant>();
    if (con == nullptr) return false;
    return _size == con->_size && _value == con->_value;
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
        int rec_open_range_lo = open_range.lo % rotational_granularity;
        int rec_open_range_hi =
            (open_range.hi / rotational_granularity == open_range.lo / rotational_granularity) ?
             open_range.hi % rotational_granularity : rotational_granularity - 1;
        le_bitrange rec_open_range = { rec_open_range_lo, rec_open_range_hi };
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
 * This function creates from a ActionDataRamSection with it's isolated ALU information.  This is
 * the initial state from which the ActionDataRamSections can be condensed and determined
 * where the are in RAM.
 */
const ActionDataRamSection *ActionDataForSingleALU2::create_RamSection(bool shift_to_lsb) const {
    size_t sec_size = container.size();
    // Because of Action Data Bus constraints, bitmasked-set information must be packed as
    // a two container wide RamSection
    if (constraint == BITMASKED_SET)
        sec_size *= 2;

    PackingConstraint pc;
    if (constraint == DEPOSIT_FIELD)
        pc = pc.expand(1, sec_size);

    ActionDataRamSection *init_rv = new ActionDataRamSection(sec_size, pc);
    for (auto param : params) {
        init_rv->add_param(param.phv_bits.lo, param.param);
    }

    if (constraint != DEPOSIT_FIELD) {
        // Put constant 0s so that nothing else is packed within this besides 0s
        bitvec reverse_mask = bitvec(0, container.size()) - phv_bits;
        for (auto br : bitranges(reverse_mask)) {
            int br_size = (br.second - br.first) + 1;
            Constant *con = new Constant(bitvec(), br_size);
            init_rv->add_param(br.first, con);
        }
    }

    // Put the mask in the second half of the RamSection
    if (constraint == BITMASKED_SET) {
        Constant *con = new Constant(phv_bits, container.size());
        init_rv->add_param(container.size(), con);
    }

    init_rv->add_alu_req(this);
    const ActionDataRamSection *rv = nullptr;
    if (shift_to_lsb) {
        // Move anything deposit-field down to the lsb of the container
        if (constraint == DEPOSIT_FIELD) {
            int shift = phv_bits.min().index();
            rv = init_rv->can_rotate(shift, 0);
        } else {
            rv = init_rv;
        }
    } else {
        // Move to the right_shift, initially 0 on creation
        rv = init_rv->can_rotate(right_shift, 0);
    }
    BUG_CHECK(rv != nullptr, "Cannot create a RAM section from an ActionDataForSingleALU2");
    BUG_CHECK(rv->alu_requirements.size() == 1, "Must have an alu requirement");
    return rv;
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
    rv->alu_requirements.insert(rv->alu_requirements.end(), alu_requirements.begin(),
                                alu_requirements.end());
    return rv;
}

void ActionDataRamSection::add_param(int bit, const ActionDataParam *adp) {
    BUG_CHECK(bit + adp->size() <= static_cast<int>(size()), "The size of the parameter is "
              "outside the size of the RAM section");
    for (int i = 0; i < adp->size(); i++) {
        BUG_CHECK(action_data_bits[bit + i] == nullptr, "Overwritting an already written bit");
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
                    next_entry = next_entry->get_extended_param(1, action_data_bits[i]);
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
        safe_vector<SharedActionDataParam> &shared_params, bool only_one_overlap_solution) const {
    // Entries in the map will be lsb to msb in position
    for (auto a_param_loc_pair : action_data_positions()) {
        int a_start_bit = a_param_loc_pair.first;
        auto a_param_loc = a_param_loc_pair.second;
        for (auto b_param_loc_pair : ad->action_data_positions()) {
            int b_start_bit = b_param_loc_pair.first;
            auto b_param_loc = b_param_loc_pair.second;
            le_bitrange a_br, b_br;
            auto shared_param = a_param_loc->overlap(b_param_loc, only_one_overlap_solution,
                                                     &a_br, &b_br);
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
        int end_bit = bits_inuse.ffs(start_bit) - 1;
        if (end_bit < 0)
            end_bit = size() - 1;
        rv.emplace_back(start_bit, end_bit);
        start_bit = bits_inuse.ffz(end_bit + 1);
    }

    std::sort(rv.begin(), rv.end(), [=](const le_bitrange &a, const le_bitrange &b) {
    // A second check about full rotational on a bit by bit granularity, as more moveability
    // of action data is generally better for the algorithm.  This will keep same sized container
    // deposit-fields packed together, possibly at the expense of better packing, but in
    // general is an improvement over the original algorithm which could only do that
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
            = action_data_bits[i] != nullptr ? action_data_bits[i] : ad->action_data_bits[i];
        rv->action_data_bits[i] = bit_param;
    }

    LocalPacking a_lp(size(), bits_in_use());
    LocalPacking b_lp(size(), ad->bits_in_use());

    rv->pack_info = pack_info.merge(ad->pack_info, a_lp, b_lp);
    rv->alu_requirements.insert(rv->alu_requirements.end(), alu_requirements.begin(),
                                alu_requirements.end());
    rv->alu_requirements.insert(rv->alu_requirements.end(), ad->alu_requirements.begin(),
                                ad->alu_requirements.end());
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


    if (pack_info.is_rotational() && !compare->pack_info.is_rotational())
        return true;
    if (!pack_info.is_rotational() && compare->pack_info.is_rotational())
        return false;
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
    gather_shared_params(ad, shared_params, false);

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

/**
 * A check to guarantee that the bits of this is a subset of bits on ActionDataRamSection *ad:
 *     - arg[2:4] at bit 2 would be a subset of arg[0:7] at bit 0
 *     - arg[2:4] at bit 0 would not be a subset of arg[0:7] at bit 0
 *     - arg[0:4] at bit 0 would not be a subset of arg[1:7] at bit 1
 */
bool ActionDataRamSection::is_data_subset_of(const ActionDataRamSection *ad) const {
    for (size_t i = 0; i < size(); i++) {
        auto subset_bit = action_data_bits.at(i);
        auto superset_bit = ad->action_data_bits.at(i);
        if (subset_bit == nullptr)
            continue;
        if (superset_bit == nullptr)
            return false;
        if (!subset_bit->equiv_value(superset_bit))
            return false;
    }
    return true;
}

/**
 * Uses shared parameters to see if the ad_small is contained within *this 
 * Full Description: @seealso contains(const ActionDataForSingleALU2 *)
 */
bool ActionDataRamSection::contains(const ActionDataRamSection *ad_small) const {
    const ActionDataRamSection *ad = ad_small->expand_to_size(size());

    safe_vector<SharedActionDataParam> shared_params;
    gather_shared_params(ad, shared_params, true);

    for (auto shared_param : shared_params) {
        auto *ad_rotated = ad->can_rotate(shared_param.b_start_bit, shared_param.a_start_bit);
        if (ad_rotated) {
            if (ad_rotated->is_data_subset_of(this))
                return true;
        }
    }
    return false;
}

/**
 * Uses rotations from 0 to see if ad_small is contained within *this
 * Full Description: @seealso contains(const ActionDataForSingleALU2 *) 
 */
bool ActionDataRamSection::
        contains_any_rotation_from_0(const ActionDataRamSection *ad_small) const {
    const ActionDataRamSection *ad = ad_small->expand_to_size(size());
    for (size_t i = 0; i < size(); i++) {
        auto ad_rotated = ad->can_rotate(0, i);
        if (ad_rotated) {
            if (ad_rotated->is_data_subset_of(this))
                return true;
        }
    }
    return false;
}

/**
 * The purpose of this check is to resolve the position of an ActionDataForSingleALU2 within
 * an ActionDataRamSection.  During the condense algorithm, the action data could be repositioned
 * in order to more tightly pack within RAM space.  This returns that the ActionDataForSingleALU
 * is still within this container, as well as calculates the right shift and the offset within
 * the ALU operation.
 *
 * In order to solve this problem, one could in theory think that the ad_alu has parameters, and
 * the algorithm can just rotate to overlap those parameters and see if the data is a subset of
 * those parameters.  However, this only works efficiently if a single overlap is possible.
 *
 * Arguments can only overlap in one way, i.e. arg1[7:0] and arg1[12:4] only have one overlap
 * arg1[7:4].  However for constants, each have possibly multiple overlaps, i.e. 0b00111000111
 * and 0b000111 would have multiple overlaps.  Thus instead, by trying all possible rotations
 * of the original ALU and trying to find a subset, this is the only possible way to determine
 * exactly that the overlap is possible.
 */
bool ActionDataRamSection::contains(const ActionDataForSingleALU2 *ad_alu) const {
    auto ad = ad_alu->create_RamSection(true);
    if (ad_alu->contains_only_one_overlap_solution())
        return contains(ad);
    else
        return contains_any_rotation_from_0(ad);
}

/**
 * Creates an Argument from an IR::MAU::ActionArg or slice of one
 */
void ActionFormat2::create_argument(ActionDataForSingleALU2 &alu,
        ActionAnalysis::ActionParam &read, le_bitrange container_bits) {
    auto ir_arg = read.unsliced_expr()->to<IR::MAU::ActionArg>();
    BUG_CHECK(ir_arg != nullptr, "Cannot create argument");
    Argument *arg = new Argument(ir_arg->name.name, read.range());
    ALUParameter ap(arg, container_bits);
    alu.add_param(ap);
}

/**
 * Creates a Constant from an IR::Constant.  Assume to be <= 32 bits as all operations
 * at most are 32 bit ALU operations.
 */
void ActionFormat2::create_constant(ActionDataForSingleALU2 &alu,
        ActionAnalysis::ActionParam &read, le_bitrange container_bits) {
    auto ir_con = read.unsliced_expr()->to<IR::Constant>();
    BUG_CHECK(ir_con != nullptr, "Cannot create constant");

    uint32_t constant_value = 0U;
    if (ir_con->fitsInt())
        constant_value = static_cast<uint32_t>(ir_con->asInt());
    else if (ir_con->fitsUint())
        constant_value = static_cast<uint32_t>(ir_con->asUnsigned());
    else
        BUG("Any constant used in an ALU operation would by definition have to be < 32 bits");
    Constant *con = new Constant(constant_value, read.size());
    ALUParameter ap(con, container_bits);
    alu.add_param(ap);
}

/**
 * Looks through the ActionAnalysis maps, and builds ActionDataParams and ActionDataForSingleALU2
 * structures.  This will then add a RamSection to potentially be condensed through the
 * algorithm.
 */
void ActionFormat2
        ::create_action_data_alus_for_action(ActionAnalysis::ContainerActionsMap &ca_map,
             cstring action_name) {
    LOG2("  Creating action data alus for " << action_name);
    for (auto &container_action_info : ca_map) {
        auto container = container_action_info.first;
        auto &cont_action = container_action_info.second;

        ALUOPConstraint_t alu_cons = DEPOSIT_FIELD;
        if (cont_action.convert_instr_to_bitmasked_set)
            alu_cons = BITMASKED_SET;
        if (cont_action.action_data_isolated())
            alu_cons = ISOLATED;

        ActionDataForSingleALU2 *alu = new ActionDataForSingleALU2(container, alu_cons);
        bool contains_action_data = false;
        for (auto &field_action : cont_action.field_actions) {
            le_bitrange bits;
            auto *write_field = phv.field(field_action.write.expr, &bits);
            le_bitrange container_bits;
            int write_count = 0;


            write_field->foreach_alloc(bits, [&](const PHV::Field::alloc_slice &alloc) {
                write_count++;
                container_bits = alloc.container_bits();
                BUG_CHECK(container_bits.lo >= 0, "Invalid negative container bit");
                if (!alloc.container)
                    ERROR("Phv field " << write_field->name << " written in action "
                          << action_name << " is not allocated?");
            });
            if (write_count > 1)
                BUG("Splitting of writes handled incorrectly");

            for (auto &read : field_action.reads) {
                if (read.speciality != ActionAnalysis::ActionParam::NO_SPECIAL)
                    continue;
                if (read.type == ActionAnalysis::ActionParam::ACTIONDATA) {
                    create_argument(*alu, read, container_bits);
                    contains_action_data = true;
                } else if (read.type == ActionAnalysis::ActionParam::CONSTANT &&
                           cont_action.convert_constant_to_actiondata()) {
                    create_constant(*alu, read, container_bits);
                    contains_action_data = true;
                }
            }
        }

        if (contains_action_data) {
            LOG3("    Container " << container << " Cont action " << cont_action);
            init_ram_sections[action_name].push_back(alu->create_RamSection(true));
        }
    }
}

/**
 * On the first pass of the algorithm, all possible pairs (i, j) have to be calculated.
 * However, on later passes of the algorithm, only the newly condensed field has to be
 * calculated.
 *
 * Thus on initial_possible_condenses, all pairs are condensed through the algorithm, while on
 * incremental_possible_condenses, the condense algorithm only runs with all previous functions
 * and the newly condensed algorithm.
 */
void ActionFormat2::initial_possible_condenses(PossibleCondenses &condenses,
        const RamSec_vec_t &ram_sects) {
    for (size_t i = 0; i < ram_sects.size(); i++) {
        for (size_t j = i+1; j < ram_sects.size(); j++) {
            condenses[i][j] = ram_sects[i]->condense(ram_sects[j]);
        }
    }
}

void ActionFormat2::incremental_possible_condenses(PossibleCondenses &condenses,
        const RamSec_vec_t &ram_sects) {
    size_t last_index = ram_sects.size() - 1;
    for (size_t i = 0; i < last_index; i++) {
        condenses[i][last_index] = ram_sects[i]->condense(ram_sects[last_index]);
    }
}

/**
 * Heuristic used to determine out of all possible condenses.  In order to determine the best
 * condense, the algorithm calculates the impact across all of the condense sections, rather
 * than just between condenses alone, thus the judgement can be made across the impact across
 * the entire action.
 *
 * Though these heuristics are simple now, they still are better than the current round
 * and can always be improved by some kind of weighted score.
 */
bool ActionFormat2::is_better_condense(RamSec_vec_t &ram_sects, const ActionDataRamSection *best,
        size_t best_skip1, size_t best_skip2, const ActionDataRamSection *comp, size_t comp_skip1,
        size_t comp_skip2) {
    // First comparison is about total number of bits used, and whether one has a reduction
    // of bits over another due to good sharing
    size_t best_bits = best->bits_in_use().popcount();
    size_t comp_bits = comp->bits_in_use().popcount();
    for (size_t i = 0; i < ram_sects.size(); i++) {
        if (i == best_skip1 || i == best_skip2) continue;
        best_bits += ram_sects[i]->bits_in_use().popcount();
    }

    for (size_t i = 0; i < ram_sects.size(); i++) {
        if (i == comp_skip1 || i == comp_skip2) continue;
        comp_bits += ram_sects[i]->bits_in_use().popcount();
    }

    if (best_bits != comp_bits)
        return comp_bits < best_bits;

    // A second check about full rotational on a bit by bit granularity, as more moveability
    // of action data is generally better for the algorithm.  This will keep same sized container
    // deposit-fields packed together, possibly at the expense of better packing, but in
    // general is an improvement over the original algorithm which could only do that
    size_t best_fully_rotational = (best->get_pack_info().get_granularity() == 1) ? 1 : 0;
    for (size_t i = 0; i < ram_sects.size(); i++) {
        if (i == best_skip1 || i == best_skip2) continue;
        if (ram_sects[i]->get_pack_info().get_granularity() == 1)
            best_fully_rotational++;
    }

    size_t comp_fully_rotational = (comp->get_pack_info().get_granularity() == 1) ? 1 : 0;
    for (size_t i = 0; i < ram_sects.size(); i++) {
        if (i == comp_skip1 || i == comp_skip2) continue;
        if (ram_sects[i]->get_pack_info().get_granularity() == 1)
            comp_fully_rotational++;
    }

    if (comp_fully_rotational != best_fully_rotational)
        return comp_fully_rotational > best_fully_rotational;
    return false;
}

/**
 * This erases the following:
 *     1. The original two ActionDataRamSections that got condensed i, j
 *     2. Any condensed ActionDataRamSections that contain one of the original pair i, j
 *
 * This adds the following:
 *     1. The newly condense ActionDataRamSection
 *     2. Space in the PossibleCondenses to add for the calculation of new condenses
 */
void ActionFormat2::shrink_possible_condenses(PossibleCondenses &pc, RamSec_vec_t &ram_sects,
        const ActionDataRamSection *ad, size_t i_pos, size_t j_pos) {
    size_t larger_pos = i_pos > j_pos ? i_pos : j_pos;
    size_t smaller_pos = larger_pos == i_pos ? j_pos : i_pos;

    if (ram_sects.at(i_pos)->size() < ad->size())
        LOG4("       Expanding a RAM Section from " << ram_sects.at(i_pos)->size() << " to "
             << ad->size());
    if (ram_sects.at(j_pos)->size() < ad->size())
        LOG4("       Expanding a RAM Section from " << ram_sects.at(j_pos)->size() << " to "
             << ad->size());

    for (auto &pc_vec : pc) {
        pc_vec.erase(pc_vec.begin() + larger_pos);
        pc_vec.erase(pc_vec.begin() + smaller_pos);
    }

    pc.erase(pc.begin() + larger_pos);
    pc.erase(pc.begin() + smaller_pos);

    ram_sects.erase(ram_sects.begin() + larger_pos);
    ram_sects.erase(ram_sects.begin() + smaller_pos);

    for (auto &pc_vec : pc) {
        pc_vec.push_back(nullptr);
    }
    pc.emplace_back(ram_sects.size() + 1, nullptr);
    ram_sects.push_back(ad);
}

/**
 * The algorithm to find the minimum packing of a single action.
 *
 *     1. Gather all of the ActionDataForSingleALU2 requirements for an individual action.
 *     2. For each ActionDataForSingleALU2, initialize a single ActionDataRamSection, as
 *        it is completely valid for each alu operation to have an isolated ActionDataRamSection,
 *        though far from optimal.
 *     3. For all possible pairs of ActionDataRamSections, determine the condense of pair (i, j).
 *     4. For all possible condenses of pair (i, j), pick the "best" condense based on heuristics
 *     5. Remove the original i and j from the list of ActionDataRamSections and add the
 *        condensed pair.
 *     6. Repeat from step 3 until no ActionDataRamSections are possibly condensed any further.
 *
 * The condense_action function captures this algorithm
 */
void ActionFormat2::condense_action(cstring action_name, RamSec_vec_t &ram_sects) {
    // The condenses are held in a 2-D array representing a triangular matrix of pairs i and j.
    // Condense of ram_sects[i] and ram_sects[j] where i < j is contained at condenses[i][j]
    PossibleCondenses condenses(ram_sects.size(), RamSec_vec_t(ram_sects.size(), nullptr));
    size_t init_ram_sects_size = ram_sects.size();
    LOG2("  Condensing action " << action_name << " with " << init_ram_sects_size);

    bool initial = true;

    while (true) {
        // Gather all possible pairs of condenses
        if (initial) {
            initial_possible_condenses(condenses, ram_sects);
            initial = false;
        } else {
            incremental_possible_condenses(condenses, ram_sects);
        }

        const ActionDataRamSection *best = nullptr;
        size_t i_pos = 0; size_t j_pos = 0;
        // Determine the best condense
        for (size_t i = 0; i < ram_sects.size(); i++) {
            for (size_t j = i+1; j < ram_sects.size(); j++) {
                if (condenses[i][j] == nullptr)
                    continue;
                if (best == nullptr ||
                    is_better_condense(ram_sects, best, i_pos, j_pos, condenses[i][j], i, j)) {
                    best = condenses[i][j];
                    i_pos = i;
                    j_pos = j;
                }
            }
        }

        if (best == nullptr)
            break;
        BUG_CHECK(best->alu_requirements.size() > 1, "By definition more than one ALU op should "
                  "be there");
        // Remove the old pair and add the new condense
        shrink_possible_condenses(condenses, ram_sects, best, i_pos, j_pos);
    }

    size_t total_bits = 0;
    size_t total_alus = 0;
    std::vector<int> size_counts(4, 0);

    for (auto *sect : ram_sects) {
        auto adps = sect->action_data_positions();
        for (auto *alu : sect->alu_requirements) {
            BUG_CHECK(sect->contains(alu), "Ram Section doesn't contain an ALU portion");
            total_alus++;
        }
        total_bits += sect->size();
        size_counts[ceil_log2(sect->size()) - 3]++;
    }
    BUG_CHECK(init_ram_sects_size == total_alus, "Somehow the ALUs are not kept during "
              "condense_action");
    LOG2("   After condense total bits : " << total_bits << ", size_counts : " << size_counts
          << ", total_alus : " << total_alus << ", total_sections : " << ram_sects.size());
    calc_max_size = std::max(calc_max_size, 1 << ceil_log2(total_bits / 8));
}


void ActionFormat2::analyze_actions() {
    ActionAnalysis::ContainerActionsMap container_actions_map;
    for (auto action : Values(tbl->actions)) {
        container_actions_map.clear();
        ActionAnalysis aa(phv, true, false, tbl);
        aa.set_container_actions_map(&container_actions_map);
        action->apply(aa);
        create_action_data_alus_for_action(container_actions_map, action->name);
    }

    for (auto &entry : init_ram_sections) {
        condense_action(entry.first, entry.second);
    }
}

void ActionFormat2::allocate_format(int orig_max_size) {
    LOG1("Determining Formats for table " << tbl->name);
    analyze_actions();
    LOG1(" ADT size " << orig_max_size << " " << calc_max_size);
}
