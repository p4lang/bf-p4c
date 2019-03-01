#include <algorithm>
#include "bf-p4c/mau/action_format_2.h"
#include "ir/ir.h"
#include "lib/bitrange.h"

namespace ActionData {

size_t slot_type_to_bits(SlotType_t slot_type) {
    BUG_CHECK(slot_type != SECT_TYPES, "Invalid call of slot_type_to_bits");
    return 1U << (static_cast<int>(slot_type) + 3);
}
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
const Parameter *Argument::overlap(const Parameter *ad, bool,
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

const Parameter *Constant::split(int lo, int hi) const {
    le_bitrange split_range = { lo, hi };
    BUG_CHECK(range().contains(split_range), "Illegally splitting a parameter, as the "
              "split contains bits outside of the range");
    auto rv = new Constant(_value.getslice(split_range.lo, split_range.size()), split_range.size());
    rv->_alias = _alias;
    return rv;
}

/**
 * If the constant is coming from an argument, it has an alias.  If the same alias is set
 * to true, then only return true if the current constant has the same alias as the
 * next constant
 */
bool Constant::is_next_bit_of_param(const Parameter *ad, bool same_alias) const {
    if (size() != 1)
        return false;
    auto constant = ad->to<Constant>();
    if (constant == nullptr)
        return false;
    if (same_alias) {
        if (_alias != constant->_alias)
            return false;
    }
    return true;
}

/**
 * Appending a constant to another constant on the MSB
 */
const Parameter *Constant::get_extended_param(uint32_t extension,
        const Parameter *ad) const {
    auto con = ad->to<Constant>();
    BUG_CHECK(con != nullptr, "Cannot extend a non-constant on constant");
    BUG_CHECK(con->size() <= static_cast<int>(extension), "The extension constant is smaller "
                                                          "than the extension size");
    Constant *rv = new Constant(*this);
    rv->_value |= (con->_value << this->_size);
    rv->_size += extension;
    rv->_alias = _alias;
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
 * overlap has one and only one solution (as this function is used by multiple Parameters).
 * Constants do not have this property and will always return a no solution 
 */
const Parameter *Constant::overlap(const Parameter *ad, bool only_one_overlap_solution,
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

bool Constant::equiv_value(const Parameter *ad) const {
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
 * Given that a rotation can happen where bit position at init bit will rotate to the bit
 * position at the final bit, determine the location of where init_bit_comp will rotate
 * to.
 */
int PackingConstraint::bit_rotation_position(int bit_width, int init_bit, int final_bit,
        int init_bit_comp) const {
    if (init_bit == final_bit)
        return init_bit_comp;
    if (init_bit == init_bit_comp)
        return final_bit;
    BUG_CHECK(is_rotational(), "Cannot get to this point without being rotational");
    size_t total_sections = bit_width / rotational_granularity;
    BUG_CHECK(total_sections == recursive_constraints.size(), "Rotational granularity is not "
              "correct");
    // Find the rotation at this granularity of packing
    int init_index = init_bit / rotational_granularity;
    int init_comp_index = init_bit_comp / rotational_granularity;
    int final_index = final_bit / rotational_granularity;
    int rotation = final_index - init_index;
    int shift = rotational_granularity * rotation;
    if (init_index != init_comp_index) {
        return (init_bit_comp + shift + bit_width) % bit_width;
    }

    const PackingConstraint &next_level = recursive_constraints[init_index];
    int next_init_bit = init_bit % rotational_granularity;
    int next_final_bit = final_bit % rotational_granularity;
    int next_init_bit_comp = init_bit_comp % rotational_granularity;
    // Determine the rotation of the layer underneath, and then rotate that position
    // by the shift in the current level
    int next_level_bit_pos
        = next_level.bit_rotation_position(rotational_granularity, next_init_bit, next_final_bit,
                                           next_init_bit_comp);

    return (next_level_bit_pos + shift + bit_width) % bit_width;
}


/**  
 * This function creates from a RamSection with it's isolated ALU information.  This is
 * the initial state from which the RamSections can be condensed and determined
 * where the are in RAM.
 */
const RamSection *ALUOperation::create_RamSection(bool shift_to_lsb) const {
    size_t sec_size = size();
    // Because of Action Data Bus constraints, bitmasked-set information must be packed as
    // a two container wide RamSection
    if (_constraint == BITMASKED_SET)
        sec_size *= 2;

    PackingConstraint pc;
    if (_constraint == DEPOSIT_FIELD)
        pc = pc.expand(1, sec_size);

    RamSection *init_rv = new RamSection(sec_size, pc);
    for (auto param : _params) {
        init_rv->add_param(param.phv_bits.lo, param.param);
    }

    if (_constraint != DEPOSIT_FIELD) {
        // Put constant 0s so that nothing else is packed within this besides 0s
        bitvec reverse_mask = bitvec(0, size()) - _phv_bits;
        for (auto br : bitranges(reverse_mask)) {
            int br_size = (br.second - br.first) + 1;
            Constant *con = new Constant(bitvec(), br_size);
            init_rv->add_param(br.first, con);
        }
    }

    // Put the mask in the second half of the RamSection
    if (_constraint == BITMASKED_SET) {
        Constant *con = new Constant(_phv_bits, size());
        con->set_alias(_mask_alias);
        init_rv->add_param(size(), con);
    }

    init_rv->add_alu_req(this);
    const RamSection *rv = nullptr;
    if (shift_to_lsb) {
        // Move anything deposit-field down to the lsb of the container
        if (_constraint == DEPOSIT_FIELD) {
            int shift = _phv_bits.min().index();
            rv = init_rv->can_rotate(shift, 0);
        } else {
            rv = init_rv;
        }
    } else {
        // Move to the right_shift, initially 0 on creation
        rv = init_rv->can_rotate(_right_shift, 0);
    }
    BUG_CHECK(rv != nullptr, "Cannot create a RAM section from an ALUOperation");
    BUG_CHECK(rv->alu_requirements.size() == 1, "Must have an alu requirement");
    return rv;
}

const ALUOperation *ALUOperation::add_right_shift(int right_shift) const {
    ALUOperation *rv = new ALUOperation(*this);
    rv->_right_shift = right_shift;
    for (auto &param : rv->_params) {
        param.right_shift = right_shift;
    }
    return rv;
}

const ALUParameter *ALUOperation::find_param_alloc(UniqueLocationKey &key) const {
    const ALUParameter *rv = nullptr;
    for (auto param : _params) {
        if (!param.param->equiv_value(key.param))
            continue;
        if (param.phv_bits != key.phv_bits)
            continue;
        BUG_CHECK(rv == nullptr, "A non-unique allocation of parameter in Container %s in action "
                  "%s", key.container, key.action_name);
        rv = new ALUParameter(param);
    }
    return rv;
}

ParameterPositions ALUOperation::parameter_positions() const {
    auto ram_section = create_RamSection(false);
    return ram_section->parameter_positions(true);
}

/**
 * In order to perform the merge function, the two RamSections have to be the same
 * size, i.e. the same number of bits wide.
 *
 * The example would be to move a 8-bit data to move 16-bit data.  The byte size data now has
 * 8 empty bits appended to it.  The new 16 bit section is also now byte-by-byte rotational, which
 * is done through the expansion of the PackingConstraint
 */
const RamSection *RamSection::expand_to_size(size_t expand_size) const {
    if (size() >= expand_size)
        return this;
    BUG_CHECK(size() % expand_size, "Cannot expand this section into this size");

    PackingConstraint rv_pack_info = pack_info.expand(size(), expand_size);
    RamSection *rv = new RamSection(expand_size, rv_pack_info);
    std::copy(action_data_bits.begin(), action_data_bits.end(), rv->action_data_bits.begin());
    rv->alu_requirements.insert(rv->alu_requirements.end(), alu_requirements.begin(),
                                alu_requirements.end());
    return rv;
}

void RamSection::add_param(int bit, const Parameter *adp) {
    BUG_CHECK(bit + adp->size() <= static_cast<int>(size()), "The size of the parameter is "
              "outside the size of the RAM section");
    for (int i = 0; i < adp->size(); i++) {
        BUG_CHECK(action_data_bits[bit + i] == nullptr, "Overwritting an already written bit");
        action_data_bits[bit + i] = adp->split(i, i);
    }
}

/**
 * Building a map of slices of parameters in order to look for identical ranges of data within
 * two RamSections.
 *
 * The from_p4_program boolean is a flag to (if necessary) only return values that are part of
 * the p4 program as either arguments or constants, and not implicit 0s.  This is for
 * specifically assembly generation, not to output the implict zeros when detailing action data
 * packing of the program
 */
ParameterPositions RamSection::parameter_positions(bool from_p4_program) const {
    ParameterPositions rv;
    size_t bit_pos = 0;
    const Parameter *next_entry = nullptr;
    for (size_t i = 0; i < size(); i++) {
        if (action_data_bits[i] == nullptr
            || (from_p4_program && !action_data_bits[i]->from_p4_program())) {
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
                if (action_data_bits[i]->is_next_bit_of_param(next_entry, from_p4_program)) {
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
 * Calculate the positions of the parameters that both RamSection
 */
void RamSection::gather_shared_params(const RamSection *ad,
        safe_vector<SharedParameter> &shared_params, bool only_one_overlap_solution) const {
    // Entries in the map will be lsb to msb in position
    for (auto a_param_loc_pair : parameter_positions()) {
        int a_start_bit = a_param_loc_pair.first;
        auto a_param_loc = a_param_loc_pair.second;
        for (auto b_param_loc_pair : ad->parameter_positions()) {
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

bitvec RamSection::bits_in_use() const {
    bitvec rv;
    for (size_t i = 0; i < size(); i++) {
        if (action_data_bits[i])
            rv.setbit(i);
    }
    return rv;
}

/**
 * Return the open ranges of data within an RamSection
 */
safe_vector<le_bitrange> RamSection::open_holes() const {
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

const RamSection *RamSection::can_rotate(int init_bit, int final_bit) const {
    if (!pack_info.can_rotate(size(), init_bit, final_bit))
        return nullptr;
    RamSection *rv = new RamSection(*this);
    RotationInfo ri(rv->action_data_bits.begin(), rv->action_data_bits.end());
    rv->pack_info.rotate(ri, init_bit, final_bit);
    return rv;
}

const RamSection *RamSection::merge(const RamSection *ad) const {
    for (size_t i = 0; i < size(); i++) {
        if (action_data_bits[i] == nullptr || ad->action_data_bits[i] == nullptr)
            continue;
        if (action_data_bits[i]->equiv_value(ad->action_data_bits[i]))
            continue;
        return nullptr;
    }
    RamSection *rv = new RamSection(size());

    for (size_t i = 0; i < size(); i++) {
        const Parameter *bit_param
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
 * Returns a rotated RamSection that fits within the bitrange provided, if possible.
 * For a constraint explanation, please look at PackingConstraint::rotate_in_range
 */
const RamSection *RamSection::rotate_in_range(le_bitrange hole) const {
    int init_bit = bits_in_use().min().index();
    int final_bit = init_bit;
    LocalPacking lp(size(), bits_in_use());
    if (!pack_info.can_rotate_in_range(lp, hole, final_bit))
        return nullptr;
    RamSection *rv = new RamSection(*this);
    RotationInfo ri(rv->action_data_bits.begin(), rv->action_data_bits.end());
    rv->pack_info.rotate(ri, init_bit, final_bit);
    return rv;
}


/**
 * Returns a merged RamSection of two independent ranges, if the merge was possible.
 * For a constraint explanation, please look at PackingConstraint::merge
 */
const RamSection *
        RamSection::no_overlap_merge(const RamSection *ad) const {
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
bool RamSection::is_better_merge_than(const RamSection *compare) const {
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
 * The algorithm to determine if (and the best way of) two RamSections can be
 * merged, (if two sections can be merged).
 *
 * The steps are:
 *     1. Expand the RAMSections so that they are the same size
 *     2. Look for shared parameters and rotate the sections so that this data overlaps
 *     3. Try to rotate data so that no fields overlap
 *     4. Pick the best choice based on heuristics
 */
const RamSection *RamSection::condense(const RamSection *ad) const {
    size_t max_size = std::max(size(), ad->size());
    const RamSection *a = expand_to_size(max_size);
    const RamSection *b = ad->expand_to_size(max_size);

    safe_vector<const RamSection *> possible_rvs;
    safe_vector<SharedParameter> shared_params;
    gather_shared_params(ad, shared_params, false);

    // Overlap equivalent Parameters
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
    const RamSection *best = nullptr;
    for (auto choice : possible_rvs) {
        if (best == nullptr || !best->is_better_merge_than(choice))
            best = choice;
    }
    return best;
}

/**
 * A check to guarantee that the bits of this is a subset of bits on RamSection *ad:
 *     - arg[2:4] at bit 2 would be a subset of arg[0:7] at bit 0
 *     - arg[2:4] at bit 0 would not be a subset of arg[0:7] at bit 0
 *     - arg[0:4] at bit 0 would not be a subset of arg[1:7] at bit 1
 */
bool RamSection::is_data_subset_of(const RamSection *ad) const {
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
 * Full Description: @seealso contains(const ALUOperation *)
 */
bool RamSection::contains(const RamSection *ad_small, int init_bit_pos,
        int *final_bit_pos) const {
    const RamSection *ad = ad_small->expand_to_size(size());

    safe_vector<SharedParameter> shared_params;
    gather_shared_params(ad, shared_params, true);
    for (auto shared_param : shared_params) {
        auto *ad_rotated = ad->can_rotate(shared_param.b_start_bit, shared_param.a_start_bit);
        if (ad_rotated) {
            if (ad_rotated->is_data_subset_of(this)) {
                if (final_bit_pos) {
                    *final_bit_pos
                        = ad->pack_info.bit_rotation_position(ad->size(), shared_param.b_start_bit,
                                                              shared_param.a_start_bit,
                                                              init_bit_pos);
                }
                return true;
            }
        }
    }
    return false;
}

/**
 * Uses rotations from 0 to see if ad_small is contained within *this
 * Full Description: @seealso contains(const ALUOperation *) 
 */
bool RamSection::contains_any_rotation_from_0(const RamSection *ad_small,
         int init_bit_pos, int *final_bit_pos) const {
    const RamSection *ad = ad_small->expand_to_size(size());
    for (size_t i = 0; i < size(); i++) {
        auto ad_rotated = ad->can_rotate(0, i);
        if (ad_rotated) {
            if (ad_rotated->is_data_subset_of(this)) {
                if (final_bit_pos)
                    *final_bit_pos = ad->pack_info.bit_rotation_position(ad->size(), 0, i,
                                                                         init_bit_pos);
                return true;
            }
        }
    }
    return false;
}

/**
 * The purpose of this check is to resolve the position of an ALUOperation within
 * an RamSection.  During the condense algorithm, the action data could be repositioned
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
 *
 * The other goal is to potentially find the position of the first phv_bit after a rotation
 * in order to eventually determine the position of action data.  The *final_first_phv_bit_pos
 * is the position of this bit.
 */
bool RamSection::contains(const ALUOperation *ad_alu,
        int *final_first_phv_bit_pos) const {
    auto ad = ad_alu->create_RamSection(false);
    bool rv = false;
    int init_first_phv_bit_pos = ad_alu->phv_bits().min().index();
    if (ad_alu->contains_only_one_overlap_solution())
        rv = contains(ad, init_first_phv_bit_pos, final_first_phv_bit_pos);
    else
        rv = contains_any_rotation_from_0(ad, init_first_phv_bit_pos, final_first_phv_bit_pos);
    return rv;
}

/**
 * Given that a RamSection contains potentially multiple ALUOperation object
 * the purpose of this function is to determine the inputs to the ActionDataBus.  Essentially
 * the return value is the action data inputs if this section was allocated at bit 0 of
 * an action data table.
 */
BusInputs RamSection::bus_inputs() const {
    BusInputs rv = {{ bitvec(), bitvec(), bitvec() }};
    for (auto ad_alu : alu_requirements) {
        int final_first_phv_bit_pos = 0;
        bool is_contained = contains(ad_alu, &final_first_phv_bit_pos);
        BUG_CHECK(is_contained, "Alu not contained in the operation");
        size_t start_alu_offset = final_first_phv_bit_pos / ad_alu->size();
        size_t start_byte = start_alu_offset * (ad_alu->size() / 8);
        size_t sz = ad_alu->is_constrained(BITMASKED_SET) ? ad_alu->size() * 2: ad_alu->size();
        sz /= 8;
        BUG_CHECK(start_byte + sz <= size() / 8, "Action Data For ALU outside of RAM section");
        BUG_CHECK(start_byte % sz == 0, "Non slot size offset");
        rv[ad_alu->index()].setrange(start_byte, sz);
    }
    return rv;
}

size_t RamSectionPosition::total_slots_of_type(SlotType_t slot_type) const {
    size_t rv = 0;
    bitvec input = section->bus_inputs().at(static_cast<int>(slot_type));
    size_t bytes_per_slot_type = (1 << static_cast<int>(slot_type));
    for (int i = 0; i <= input.max().index(); i += bytes_per_slot_type) {
        rv += input.getslice(i, bytes_per_slot_type).empty() ? 0 : 1;
    }
    return rv;
}

/**
 * Gathers the number of action data bus inputs of slot_type are in this particular action 
 */
size_t SingleActionPositions::total_slots_of_type(SlotType_t slot_type) const {
    size_t rv = 0;
    for (auto &input : all_inputs) {
        rv += input.total_slots_of_type(slot_type);
    }
    return rv;
}

size_t SingleActionPositions::bits_required() const {
    size_t total_bits = 0;
    for (auto &input : all_inputs) {
        total_bits += input.section->size();
    }
    return total_bits;
}

/**
 * Due to the adt entries required to be at certain granularities, the bits_required might be
 * less than the adt_bits_required
 */
size_t SingleActionPositions::adt_bits_required() const {
    size_t rv = bits_required();
    if (rv < 128U)
        return 1 << ceil_log2(rv);
    else
        return ((rv + 127U) / 128U) * 128U;
}

/**
 * The sections_of_size are different than the slots of size in that the sections represent
 * the RamSection while the the slots represent the inputs to the ActionDataBus,
 * which come from the ALUOperation objects.
 */
std::array<int, SECT_TYPES> SingleActionPositions::sections_of_size() const {
    std::array<int, SECT_TYPES> rv = {{ 0 }};
    for (auto &input : all_inputs) {
        rv[input.section->index()]++;
    }
    return rv;
}

/**
 * The goal of immediate data packing is to reduce the number of bits required to mask
 * out of overhead.  In order to do some of this calculation, the goal is to find the
 * RamSection of particular packing sizes that have the smallest msb.
 *
 * This function returns the minimum max bit in use of all RamSections of all
 * possible sizes
 */
std::array<int, SECT_TYPES> SingleActionPositions::minmax_bit_req() const {
    std::array<int, SECT_TYPES> rv = { { 8, 16, 32, 64 } };
    for (auto &input : all_inputs) {
        int *rv_i = &rv[input.section->index()];
        *rv_i = std::min(*rv_i, input.section->bits_in_use().max().index() + 1);
    }
    return rv;
}

/**
 * Used to determine which input should be placed last in the immediate bytes in order
 * to determine which size should be the most significant action data in immediate.
 */
std::array<int, SECT_TYPES> SingleActionPositions::min_bit_of_contiguous_sect() const {
    std::array<int, SECT_TYPES> rv = {{ 0 }};
    for (int i = 0; i < SECT_TYPES; i++) {
        if (sections_of_size()[i] > 0) {
            rv[i] = (sections_of_size()[i] - 1) + minmax_bit_req()[i];
        }
    }
    return rv;
}

void SingleActionPositions::move_to_immed_from_adt(safe_vector<RamSectionPosition> &rv,
        size_t slot_sz, bool move_minmax_bit_req) {
    for (auto it = all_inputs.begin(); it != all_inputs.end(); it++) {
        if (it->section->size() != slot_sz)
            continue;
        if (move_minmax_bit_req) {
            if (minmax_bit_req()[it->section->index()]
                != it->section->bits_in_use().max().index() + 1) {
                continue;
            }
        }
        rv.push_back(*it);
        all_inputs.erase(it);
        return;
    }
    BUG("Could not find correctly associated size for field");
}

/**
 * This determines, that given the number of bits that are required to be moved to immediate,
 * that this particular slot size can be the final lsb.
 *
 * Essentially the calculation is that if the total number of bits of slot_types, where
 * slot_type_bits < bits_to_move, is also < bits_to_move, then any of those slot_types cannot
 * fit
 *
 * Best exemplified by an example.  Say the bits_to_move is 16, and there is only one slot
 * of BYTE size, then it would always be suboptimal to have the 8 bit slot to be the msb,
 * as a 16 bit slot would by requirement have to be before the 8 bit slot in order to move
 * at least 16 bits
 */
std::array<bool, SECT_TYPES> SingleActionPositions::can_be_immed_msb(int bits_to_move) const {
    std::array<bool, SECT_TYPES> rv = { { sections_of_size()[BYTE] > 0,
                                          sections_of_size()[HALF] > 0 ,
                                          sections_of_size()[FULL] > 0,
                                          false } };
    int total_bits_under_size = 0;
    int last_section_under_size = -1;
    for (int i = 0; i < SECT_TYPES; i++) {
        SlotType_t ss_i = static_cast<SlotType_t>(i);
        int slot_bits = static_cast<int>(slot_type_to_bits(ss_i));
        if (slot_bits < bits_to_move) {
            total_bits_under_size += sections_of_size()[i] * slot_bits;
        } else {
            last_section_under_size = i;
            break;
        }
    }

    if (bits_to_move % 16 == 0) {
        if (sections_of_size()[BYTE] % 2 != 0)
            rv[BYTE] = false;
    }

    if (total_bits_under_size < bits_to_move) {
        for (int i = 0; i < last_section_under_size; i++) {
            rv[i] = false;
        }
    }
    return rv;
}

/**
 * Now that the minmax value has be moved to immediate, this slot might have been less than
 * the required number of bits necessary to move down to the next action data entry size.
 * The purpose of this function is to determine which other sections to move to immediate
 * as well.
 */
void SingleActionPositions::move_other_sections_to_immed(int bits_to_move, SlotType_t minmax_sz,
        safe_vector<RamSectionPosition> &immed_vec) {
    int bits_moved_to_immed = slot_type_to_bits(minmax_sz);
    move_to_immed_from_adt(immed_vec, slot_type_to_bits(minmax_sz), true);
    while (bits_moved_to_immed < bits_to_move) {
        int bits_left_to_move = bits_to_move - bits_moved_to_immed;
        SlotType_t moved_slot = SECT_TYPES;
        if (bits_left_to_move % 16 == 8) {
            // Generally prefer to move 8 bit slots to immediate, as generally they have
            // tough action data bus requirements
            if (sections_of_size()[BYTE] > 0) {
                 move_to_immed_from_adt(immed_vec, 8, false);
                 moved_slot = BYTE;
            } else if (sections_of_size()[HALF] > 0) {
                 move_to_immed_from_adt(immed_vec, 16, false);
                 moved_slot = HALF;
            }
        } else {
            if (sections_of_size()[BYTE] >= 2) {
                move_to_immed_from_adt(immed_vec, 8, false);
                moved_slot = BYTE;
            } else if (sections_of_size()[HALF] > 0) {
                move_to_immed_from_adt(immed_vec, 16, false);
                moved_slot = HALF;
            }
        }

        if (moved_slot == SECT_TYPES)
            BUG("Could not remove enough bits from adt to immediate");
        bits_moved_to_immed += slot_type_to_bits(moved_slot);
        BUG_CHECK(bits_moved_to_immed <= Format::IMMEDIATE_BITS, "Illegally moved too "
            "many bits to immediate");
    }
}

/**
 * As described in the comments above determine_bytes_per_loc, some actions must action data
 * from an ActionData Tables to Immediate Data.  The purpose of this function is to
 * determine which sections to move.
 *
 * The data can be moved in the sizes of the sections, i.e. on the granularity of bytes,
 * half-words and full-words.
 *
 * The other important this to note is that while action data requires the full entry size,
 * immediate data has a bit-by-bit advantage.  Immediate data can be packed right next to
 * match data or other overhead data with no respect to the byte positions on the match RAM,
 * due to the shift/mask/default behavior of match central.
 *
 * Thus as part of the goal of moving action data, the goal is to require the minimum sized
 * mask for immediate (at this point, the immediate mask has to be contiguous for the rest
 * of the compiler)
 *
 * The bits_to_move is the minimum number of bits (at a byte granularity) to move to immediate,
 * as the entire slot has to be moved, which is either 8, 16, 32 or 64 bits in size.
 * (64 bits obviously cannot be moved)
 */
safe_vector<RamSectionPosition> SingleActionPositions::best_inputs_to_move(int bits_to_move) {
    safe_vector<RamSectionPosition> rv;
    if (bits_to_move <= 0)
        return rv;


    // Basically from surveying the action, this determines which action data should be the
    // the last slot in immediate, due to requiring the smallest mask
    int minmax_use_slot_i = -1;
    int minmax_bits = Format::IMMEDIATE_BITS;
    for (int i = 0; i < SLOT_TYPES; i++) {
        if (!can_be_immed_msb(bits_to_move)[i])
            continue;
        int bits_in_slot_sz = 1 << (i + 3);
        // If this was to be the last section, what would be the impact
        int prev_slots_required = (bits_to_move - 1) / bits_in_slot_sz;
        int bits_req = prev_slots_required * bits_in_slot_sz + minmax_bit_req()[i];
        if (bits_req <= minmax_bits) {
            minmax_bits = bits_req;
            minmax_use_slot_i = i;
        }
    }

    if (minmax_use_slot_i == -1)
        return rv;
    move_other_sections_to_immed(bits_to_move, static_cast<SlotType_t>(minmax_use_slot_i), rv);
    return rv;
}

/**
 * Calculate the mask of immediate bits which are to be packed on the table format.  The
 * immediate data is represented at bit-granularity.
 */
void Format::Use::determine_immediate_mask() {
    for (auto act_alu_positions : alu_positions) {
        for (auto alu_position : act_alu_positions.second) {
            if (alu_position.loc != IMMEDIATE)
                continue;
            bitvec bv = alu_position.alu_op->slot_bits() << (alu_position.start_byte * 8);
            immediate_mask |= bv;
            if (alu_position.alu_op->is_constrained(BITMASKED_SET)) {
                bitvec mask_bv = alu_position.alu_op->slot_bits();
                int shift = alu_position.start_byte * 8 + alu_position.alu_op->size();
                immediate_mask |= mask_bv << shift;
            }
        }
    }

    // Currently in the table format, it is assumed that the immediate mask is contiguous
    // for simple printing during the assembly mask
    immediate_mask = bitvec(0, immediate_mask.max().index() + 1);
    LOG2("  Immediate mask 0x" << immediate_mask);
    BUG_CHECK(immediate_mask.max().index() < bytes_per_loc[IMMEDIATE] * 8, "Immediate mask has "
        "more bits than the alloted bytes for immediate");
}

/**
 * During the Instruction Adjustment phase of ActionAnalysis, in order to determine
 * how to rename both constants and action data, as well as verify that the alignment is
 * correct, an action parameter must be found within the action format.
 *
 * This is done with a four part key:
 *     1.  The action name
 *     2.  The container (this should provide an ALUOperation, as only one ALUOperation is
 *         possible per container per action
 *     3.  The phv_bits affected
 *     4.  The parameter (technically a duplicate of 3, but can verify that both portions
 *         are the same).
 *
 * This function returns the ALUParameter object, as well as the correspding ALUPosition
 * object
 */
const ALUParameter *Format::Use::find_param_alloc(UniqueLocationKey &key,
        const ALUPosition **alu_pos_p) const {
    auto action_alu_positions = alu_positions.at(key.action_name);
    const ALUParameter *rv = nullptr;
    for (auto alu_position : action_alu_positions) {
        if (alu_position.alu_op->container() != key.container)
            continue;
        auto *loc = alu_position.alu_op->find_param_alloc(key);
        BUG_CHECK(loc != nullptr, "A container operation cannot find the associated key");
        BUG_CHECK(rv == nullptr, "A parameter has multiple allocations in container %s in "
            "action %s", key.container, key.action_name);
        rv = loc;
        if (alu_pos_p)
            *alu_pos_p = new ALUPosition(alu_position);
    }
    return rv;
}

cstring Format::Use::get_format_name(const ALUPosition &alu_pos, bool bitmasked_set,
        le_bitrange *slot_bits, le_bitrange *postpone_range) const {
    int byte_offset = alu_pos.start_byte;
    SlotType_t slot_type = static_cast<SlotType_t>(alu_pos.alu_op->index());
    if (bitmasked_set)
        byte_offset += slot_type_to_bits(slot_type) / 8;
    return get_format_name(slot_type, alu_pos.loc, byte_offset, slot_bits,
                           postpone_range);
}

/**
 * The purpose of this function is to have a standardized name of the location of parameters
 * across multiple needs for it in the assembly output.
 *
 * Specifically, in this example, parameters can be located with 3/4 coordinates:
 *
 *     1. SlotType_t slot_type - whether the alu op is a byte, half, or full word
 *     2. Location_t loc - if the byte is in Action Data or Immediate
 *     3. int byte_offset - the starting bit of that ALU operation in that location
 *     4. optional bit_range to specify bit portions of the range.
 *
 * Realistically, all of these are stored in the ALUPosition structure, though through
 * asm_output, specifically during action data bus generation, the ALUPosition structure is
 * not always available, so this function can be called.
 *
 * The standardization is currently the following:
 *     1.  If the location is in ACTION_DATA_TABLE, the name is $adf_(type)(offset), where
 *         type comes from the slot_type, and the offset is just the SlotType_t increment
 *     2.  If the location is in IMMEDIATE, then the name has to coordinate with the
 *         table_format name, in this case "immediate".  This is also followed by a lo..hi
 *         range, as the immediate has a max range while anything on the action data format
 *         is the full 8, 16, or 32 bits.
 *
 * In addition, there are two parameters, for bit level granularity.
 *     1. slot_bits: for including a bit range starting from slot_bits lo to slot_bits hi
 *     2. postpone_range: if the range is going to be determined later, and is not part
 *        of the generated range
 */
cstring Format::Use::get_format_name(SlotType_t slot_type, Location_t loc, int byte_offset,
        le_bitrange *slot_bits, le_bitrange *postpone_range) const {
    cstring rv = "";
    BUG_CHECK(slot_bits == nullptr || postpone_range == nullptr, "Invalid call of the "
         "get_format_name function");
    int size = slot_type_to_bits(slot_type);
    int byte_sz = size / 8;

    BUG_CHECK((byte_offset % byte_sz) == 0, "Byte offset does not have an allocation");
    auto &bus_inp = bus_inputs[loc];
    BUG_CHECK(bus_inp[slot_type].getrange(byte_offset, byte_sz), "Nothing allocated to "
              "the byte position that is named in the assembly output");
    if (loc == ACTION_DATA_TABLE) {
        rv += "$adf_";
        switch (slot_type) {
            case BYTE: rv += "b"; break;
            case HALF: rv += "h"; break;
            case FULL: rv += "f"; break;
            default: BUG("Unrecognized size of action data packing");
        }
        rv += std::to_string(byte_offset / byte_sz);
        if (postpone_range)
            *postpone_range = { 0, size - 1 };
        else if (slot_bits)
            rv += "(" + std::to_string(slot_bits->lo) + ".." + std::to_string(slot_bits->hi) + ")";
    } else if (loc == IMMEDIATE) {
        rv += "immediate";
        int lo = byte_offset * 8;
        int hi = std::min(lo + size - 1, immediate_mask.max().index());
        if (postpone_range) {
            *postpone_range = { lo, hi };
        } else {
            if (slot_bits) {
                lo += slot_bits->lo;
                hi = lo + slot_bits->size() - 1;
            }
            rv += "(" + std::to_string(lo) + ".." + std::to_string(hi) + ")";
        }
    }
    return rv;
}

/**
 * Creates an Argument from an IR::MAU::ActionArg or slice of one
 */
void Format::create_argument(ALUOperation &alu,
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
void Format::create_constant(ALUOperation &alu,
        ActionAnalysis::ActionParam &read, le_bitrange container_bits, int &constant_alias_index) {
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
    con->set_alias("$constant" + std::to_string(constant_alias_index++));
    ALUParameter ap(con, container_bits);
    alu.add_param(ap);
}

/**
 * Looks through the ActionAnalysis maps, and builds Parameters and ALUOperation
 * structures.  This will then add a RamSection to potentially be condensed through the
 * algorithm.
 */
void Format
        ::create_alu_ops_for_action(ActionAnalysis::ContainerActionsMap &ca_map,
             cstring action_name) {
    LOG2("  Creating action data alus for " << action_name);
    auto &ram_sec_vec = init_ram_sections[action_name];
    int alias_index = 0;
    int mask_alias_index = 0;
    int constant_alias_index = 0;
    for (auto &container_action_info : ca_map) {
        auto container = container_action_info.first;
        auto &cont_action = container_action_info.second;

        ALUOPConstraint_t alu_cons = DEPOSIT_FIELD;
        if (cont_action.convert_instr_to_bitmasked_set)
            alu_cons = BITMASKED_SET;
        if (cont_action.action_data_isolated())
            alu_cons = ISOLATED;

        ALUOperation *alu = new ALUOperation(container, alu_cons);
        bool contains_action_data = false;
        int number_of_reads = 0;
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
                    number_of_reads++;
                } else if (read.type == ActionAnalysis::ActionParam::CONSTANT &&
                           cont_action.convert_constant_to_actiondata()) {
                    create_constant(*alu, read, container_bits, constant_alias_index);
                    contains_action_data = true;
                    number_of_reads++;
                }
            }
        }

        if (number_of_reads > 1 || cont_action.unresolved_ad()) {
            alu->set_alias("$data" + std::to_string(alias_index++));
            if (alu->is_constrained(BITMASKED_SET))
                alu->set_mask_alias("$mask" + std::to_string(mask_alias_index++));
        }

        if (contains_action_data) {
            LOG3("    Container " << container << " Cont action " << cont_action);
            ram_sec_vec.push_back(alu->create_RamSection(true));
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
void Format::initial_possible_condenses(PossibleCondenses &condenses,
        const RamSec_vec_t &ram_sects) {
    for (size_t i = 0; i < ram_sects.size(); i++) {
        for (size_t j = i+1; j < ram_sects.size(); j++) {
            condenses[i][j] = ram_sects[i]->condense(ram_sects[j]);
        }
    }
}

void Format::incremental_possible_condenses(PossibleCondenses &condenses,
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
bool Format::is_better_condense(RamSec_vec_t &ram_sects, const RamSection *best,
        size_t best_skip1, size_t best_skip2, const RamSection *comp, size_t comp_skip1,
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
 *     1. The original two RamSections that got condensed i, j
 *     2. Any condensed RamSections that contain one of the original pair i, j
 *
 * This adds the following:
 *     1. The newly condense RamSection
 *     2. Space in the PossibleCondenses to add for the calculation of new condenses
 */
void Format::shrink_possible_condenses(PossibleCondenses &pc, RamSec_vec_t &ram_sects,
        const RamSection *ad, size_t i_pos, size_t j_pos) {
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
 *     1. Gather all of the ALUOperation requirements for an individual action.
 *     2. For each ALUOperation, initialize a single RamSection, as
 *        it is completely valid for each alu operation to have an isolated RamSection,
 *        though far from optimal.
 *     3. For all possible pairs of RamSections, determine the condense of pair (i, j).
 *     4. For all possible condenses of pair (i, j), pick the "best" condense based on heuristics
 *     5. Remove the original i and j from the list of RamSections and add the
 *        condensed pair.
 *     6. Repeat from step 3 until no RamSections are possibly condensed any further.
 *
 * The condense_action function captures this algorithm
 */
void Format::condense_action(cstring action_name, RamSec_vec_t &ram_sects) {
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

        const RamSection *best = nullptr;
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
    std::vector<int> size_counts(SECT_TYPES, 0);

    for (auto *sect : ram_sects) {
        auto adps = sect->parameter_positions();
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

void Format::analyze_actions() {
    ActionAnalysis::ContainerActionsMap container_actions_map;
    for (auto action : Values(tbl->actions)) {
        container_actions_map.clear();
        ActionAnalysis aa(phv, true, false, tbl);
        aa.set_container_actions_map(&container_actions_map);
        action->apply(aa);
        create_alu_ops_for_action(container_actions_map, action->name);
    }

    for (auto &entry : init_ram_sections) {
        condense_action(entry.first, entry.second);
    }
}

/**
 * @see_also comments over Format::determine_bytes_per_loc
 */
bool Format::determine_next_immediate_bytes() {
    AllActionPositions &adt_bus_inputs = action_bus_inputs.at(ACTION_DATA_TABLE);
    AllActionPositions &immed_bus_inputs = action_bus_inputs.at(IMMEDIATE);
    // Shrinking the next possible number of bytes by half, by the possibly entry sizes
    int next_adt_bytes;
    if (bytes_per_loc[ACTION_DATA_TABLE] > 16)
        next_adt_bytes = bytes_per_loc[ACTION_DATA_TABLE] - 16;
    else
        next_adt_bytes = bytes_per_loc[ACTION_DATA_TABLE] / 2;
    int immed_bytes = 0;
    int adt_bytes = 0;
    // When shrinking the data by half, potentially the table cannot fit this entry within
    // this size, i.e. an action has two HALF WORD outputs, and the previous next_adt_bytes
    // was 2.  Neither of these entry can fit within a single byte, but these entries can
    // both fit within immediate.  Potentially, an entry size can be skipped
    for (auto &adt_entry : adt_bus_inputs) {
        int bit_diff = static_cast<int>(adt_entry.bits_required()) -
                           next_adt_bytes * 8;
        if (bit_diff > IMMEDIATE_BITS)
            return false;

        auto immed_vec = adt_entry.best_inputs_to_move(bit_diff);
        if (immed_vec.empty()) {
            if (bit_diff > 0) {
                return false;
            }
        } else {
            BUG_CHECK(adt_entry.bits_required() <= (next_adt_bytes * 8U), "Cannot "
                      "move things to immediate without fitting into action data table");
        }

        SingleActionPositions immed_entry(adt_entry.action_name, immed_vec);

        immed_bus_inputs.push_back(immed_entry);
        // Determining the maximum immmediate bytes over all actions
        immed_bytes = std::max(immed_bytes, static_cast<int>(immed_entry.bits_required()) / 8);
        // Because the adt_bytes < next_adt_bytes, from earlier, find the max adt_bytes
        adt_bytes = std::max(adt_bytes, static_cast<int>(adt_entry.adt_bits_required()) / 8);
        cstring action_name = adt_entry.action_name;
        BUG_CHECK(adt_entry.all_inputs.size() + immed_entry.all_inputs.size() ==
                  init_ram_sections.at(action_name).size(), "Somehow an action did not "
                  "correctly move entries on action %s", action_name);
    }
    BUG_CHECK(immed_bytes <= IMMEDIATE_BITS / 8, "Trying to allocate %d bytes to immediate, "
              "when the max is 4", immed_bytes);
    BUG_CHECK(adt_bytes <= next_adt_bytes, "The action data table bytes did not shrink");
    bytes_per_loc[ACTION_DATA_TABLE] = adt_bytes;
    bytes_per_loc[IMMEDIATE] = immed_bytes;
    LOG2("  Bytes per location : { ACTION_DATA_TABLE : " << bytes_per_loc[ACTION_DATA_TABLE]
         << ", IMMEDIATE : " << bytes_per_loc[IMMEDIATE] << " }");
    return true;
}

/**
 * The goal of the action format algorithm is to generate a number of possibly action data
 * packing algorithms.  Action Data can be allocated to two possible locations, on a separate
 * RAM as an ActionDataTable (Attached to the Match Table), or as part of the match format
 * known as immediate.
 *
 * With different requirements on match pack formats, other overhead, and number of RAMs required,
 * it is up to the table placement algorithm to determine which combination of action data and
 * match data packing is best to allocate.
 *
 * The action data tables can be packed with certain granularities, described in uArch section
 * 6.2.8.4.3 Action RAM Addressing.  Essentially the entry size can be a power of 2, ranging
 * from 8 bits to 1024 bits of action data.  Immediate data at most can be 32 bits.
 *
 * The algorithm is the following:
 *     1. Start by assuming all action data is in the Action Data Table only.
 *     2. Move action data from Action Data to Immediate in order to shrink the entry size for
 *        action data (i.e. if the Action Data bits was originally 144 bits, move at least 16
 *        bits from that action data to immediate)
 *     3. Repeat the process until the immediate data space cannot hold the extra data, as at
 *        most, the action data in immediate is 32 bits
 *
 * Now, due to the hardware, the worst case entry size for any of the actions in a table is the
 * action size for all entries in that table.  This is absolutely true for direct and a driver
 * restriction on indirect tables (ActionProfiles).  Thus is a table has 5 actions where 4
 * actions only have 8 bits, but 1 action has 256 bits, then each entry will be 256 bits
 * no matter what.
 *
 * The reason for this, specifically on direct, is that the driver/compiler cannot predict
 * ahead of time what entry will run which action and thus what data needs to be stored to
 * directly line up for the entry.  For action profiles, the driver does not currently have
 * the ability to set up these different sizes of action data entry sizes.
 */
bool Format::determine_bytes_per_loc(bool &initialized) {
    action_bus_inputs.resize(AD_LOCATIONS);
    action_bus_input_bitvecs.resize(AD_LOCATIONS);
    for (int i = 0; i < AD_LOCATIONS; i++) {
        action_bus_inputs[i].clear();
        for (int j = 0; j < SLOT_TYPES; j++) {
            action_bus_input_bitvecs[i][j] = bitvec();
        }
    }

    AllActionPositions &all_bus_inputs = action_bus_inputs.at(ACTION_DATA_TABLE);
    int max_bytes = 0;
    for (auto &entry : init_ram_sections) {
        auto &ram_sects = entry.second;
        safe_vector<RamSectionPosition> single_action_inputs;
        for (size_t i = 0; i < ram_sects.size(); i++) {
            auto &ram_sect = ram_sects[i];
            single_action_inputs.emplace_back(ram_sect);
        }
        all_bus_inputs.emplace_back(entry.first, single_action_inputs);
        max_bytes = std::max(max_bytes,
                             static_cast<int>(all_bus_inputs.back().adt_bits_required()) / 8);
    }

    // First run, only allocate on action data
    if (!initialized) {
        initialized = true;
        bytes_per_loc[ACTION_DATA_TABLE] = max_bytes;
        bytes_per_loc[IMMEDIATE] = 0;
        LOG2("  Bytes per location : { ACTION_DATA_TABLE : " << bytes_per_loc[ACTION_DATA_TABLE]
              << ", IMMEDIATE : " << bytes_per_loc[IMMEDIATE] << " }");
        return true;
    }

    // Action profiles cannot have immediate data by definition
    for (auto ba : tbl->attached) {
        if (ba->attached->is<IR::MAU::ActionData>())
            return false;
    }

    if (speciality_use.is_immed_speciality_in_use())
        return false;

    if (bytes_per_loc[ACTION_DATA_TABLE] == 0)
        return false;

    return determine_next_immediate_bytes();
}

/**
 * Locks the position of a RamSectionPosition as well as updates the BusInputs
 * with the impact of this RamSection's inputs
 */
void Format::set_ram_sect_byte(SingleActionAllocation &single_action_alloc,
        bitvec &allocated_slots_in_action, RamSectionPosition &ram_sect, int byte_position) {
    ram_sect.byte_offset = byte_position;
    allocated_slots_in_action.setrange(byte_position, ram_sect.section->byte_sz());
    for (int i = 0; i < SLOT_TYPES; i++) {
        bitvec input_use = ram_sect.section->bus_inputs().at(i) << byte_position;
        single_action_alloc.current_action_inputs[i] |= input_use;
        (*single_action_alloc.all_action_inputs)[i] |= input_use;
    }
    single_action_alloc.alloc_inputs.push_back(ram_sect);
}

/**
 * Allocate the immediate section where the size of the section == slot_type.  The algorithm
 * removes these inputs from orig_inputs and adds them to alloc_inputs.  Guaranteed from the
 * sort outside this function that the minmax object is seen lost.
 *
 * For the description this algorithm:
 * @seealso alloc_immed_bytes
 */
void Format::alloc_immed_slots_of_size(SlotType_t slot_type,
        SingleActionAllocation &single_action_alloc, int max_bytes_required) {
    int ss_i = static_cast<int>(slot_type);
    auto it = single_action_alloc.orig_inputs.begin();
    bitvec allocated_slots_in_action = bytes_in_use(single_action_alloc.current_action_inputs);
    while (it != single_action_alloc.orig_inputs.end()) {
        auto ram_sect = *it;
        if (ram_sect.section->size() != (1U << (ss_i + 3))) {
            it++;
            continue;
        }
        bool found = false;
        int byte_position = 0;
        int byte_sz = ram_sect.section->byte_sz();
        for (int i = 0; i <= max_bytes_required; i += byte_sz) {
            if (!allocated_slots_in_action.getslice(i, byte_sz).empty())
                continue;
            found = true;
            byte_position = i;
            break;
        }

        BUG_CHECK(found && byte_position + byte_sz <= max_bytes_required, "The byte position is "
                  "outside of the range of the region");
        set_ram_sect_byte(single_action_alloc, allocated_slots_in_action, ram_sect, byte_position);
        it = single_action_alloc.orig_inputs.erase(it);
    }
}

/**
 * Allocate the action data sections that have inputs of size == slot_type.  They will remove
 * themselves from the orig_input and the allocation will be added to the alloc_inputs.
 * The inputs will also try to reuse already used action data inputs from other actions in the
 * same table.
 *
 * For the description of the algorithm:
 * @seealso alloc_adt_bytes
 */
void Format::alloc_adt_slots_of_size(SlotType_t slot_type,
        SingleActionAllocation &single_action_alloc, int max_bytes_required) {
    int ss_i = static_cast<int>(slot_type);
    auto it = single_action_alloc.orig_inputs.begin();
    bitvec allocated_slots_in_action = bytes_in_use(single_action_alloc.current_action_inputs);
    while (it != single_action_alloc.orig_inputs.end()) {
        auto ram_sect = *it;
        if (ram_sect.total_slots_of_type(slot_type) == 0) {
            it++;
            continue;
        }
        // Note that the section can only appear at a particular offset
        int byte_sz = ram_sect.section->size() / 8;
        bool found = false;
        int byte_position = 0;
        // Try to reuse other actions inputs of the same size
        for (int i = 0; i <= max_bytes_required; i += byte_sz) {
            if (!allocated_slots_in_action.getslice(i, byte_sz).empty())
                continue;
            bitvec slots_in_use = (*single_action_alloc.all_action_inputs)[ss_i];
            if ((slots_in_use & ram_sect.section->bus_inputs()[ss_i]).empty())
                continue;
            found = true;
            byte_position = i;
            break;
        }

        // Just find the first available space
        if (!found) {
            for (int i = 0; i <= max_bytes_required; i += byte_sz) {
                if (!allocated_slots_in_action.getslice(i, byte_sz).empty())
                    continue;
                found = true;
                byte_position = i;
                break;
            }
        }

        BUG_CHECK(found && byte_position + byte_sz <= max_bytes_required, "The byte position is "
                  "outside of the range of the region");

        set_ram_sect_byte(single_action_alloc, allocated_slots_in_action, ram_sect, byte_position);
        it = single_action_alloc.orig_inputs.erase(it);
    }
}

/**
 * Guarantees that the packing of an action is legal, i.e. each RamSection has a legal
 * packing and that no RamSections overlap with each other.
 */
void Format::verify_placement(SingleActionAllocation &single_action_alloc) {
    auto &current_action_inputs = single_action_alloc.current_action_inputs;
    LOG3("    Action Bus Input for BYTE: " << current_action_inputs[BYTE] << " HALF: "
         << current_action_inputs[HALF] << " FULL: " << current_action_inputs[FULL]);
    bitvec verify_legal_placement;
    for (auto &input : single_action_alloc.alloc_inputs) {
        BUG_CHECK(input.byte_offset >= 0, "A section was not allocated to a byte offset");
        int sz = input.section->size() / 8;
        BUG_CHECK(verify_legal_placement.getslice(input.byte_offset, sz).empty(), "Two "
            "RAM sections in action %s are at the same location",
            single_action_alloc.action_name());
        verify_legal_placement.setrange(input.byte_offset, sz);
    }

    single_action_alloc.set_positions();
}

/**
 * Determines the allocation for a single action data table action.
 * @seealso determine_action_data_table_bytes
 */
void Format::determine_single_action_input(SingleActionAllocation &single_action_alloc,
        int max_bytes_required) {
    LOG3("    Determining Ram Allocation for action " << single_action_alloc.action_name());

    BusInputs current_action_inputs;
    // Prefer to place RamSections that have BYTE inputs
    std::sort(single_action_alloc.orig_inputs.begin(), single_action_alloc.orig_inputs.end(),
        [](const RamSectionPosition &a, const RamSectionPosition &b) {
        int t;
        if ((t = a.total_slots_of_type(BYTE) - b.total_slots_of_type(BYTE)) != 0)
            return t > 0;
        if ((t = a.total_slots_of_type(HALF) - b.total_slots_of_type(HALF)) != 0)
            return t > 0;
        return a.section->size() > b.section->size();
    });

    alloc_adt_slots_of_size(BYTE, single_action_alloc, max_bytes_required);

    // Prefer to place RamSections that contain HALF inputs
    std::sort(single_action_alloc.orig_inputs.begin(), single_action_alloc.orig_inputs.end(),
        [](const RamSectionPosition &a, const RamSectionPosition &b) {
        int t;
        if ((t = a.total_slots_of_type(HALF) - b.total_slots_of_type(HALF)) != 0)
            return t > 0;
        if ((t = a.section->size() > b.section->size()) != 0)
            return t > 0;
        return a.section->size() > b.section->size();
    });
    alloc_adt_slots_of_size(HALF, single_action_alloc, max_bytes_required);

    // Place all only FULL inputs
    std::sort(single_action_alloc.orig_inputs.begin(), single_action_alloc.orig_inputs.end(),
        [](const RamSectionPosition &a, const RamSectionPosition &b) {
        return a.section->size() > b.section->size();
    });

    alloc_adt_slots_of_size(FULL, single_action_alloc, max_bytes_required);
    verify_placement(single_action_alloc);
}

/**
 * The purpose of this function is to determine the location of all RamSections in terms of their
 * position on the Action Data Ram.  Based on an earlier calculation, the maximum number of bytes
 * alloted for the action data entry is known.
 *
 * The goal is to try and minimize the number of action data bus inputs necessary in order
 * to successfully transfer data from the Action Data RAM to the ALU.  The action data bus
 * constraints are described in full in section 6.2.5 Action Output HV Xbar(s), and definitely
 * more detailed within the action_data_bus.h/cpp files, but , at a high level, the 
 * constraints are:
 *
 *     1. The closer the data is to the lsb of the entry (on a RAM granularity), the less
 *        constraints that data has. 
 *     2. The smaller the input slot size is, (i.e. BYTE vs. HALF vs. FULL), the slot has
 *        more requirements when packed towards the msb (on a RAM granularity).
 *
 * Thus in general, it is better to pack the smaller input sizes closer to the lsb.  The
 * algorithm is thus the following:
 *
 *     1.  Determine which action is going to have the most constraints in terms of packing
 *         BYTES as well as size. 
 *     2.  For each action find a packing on the RAM size in that entry, while trying if at
 *         all possible to reuse some of the previously used action data slots.
 *
 * TODO: Potentially future algorithm to test.  In order to potentially minimize impact on
 * action data bus inputs, condensing data across actions which don't have any impact on the
 * packing of action data may directly hurt the potential packing.  This can be experimented
 * with if the action data bus becomes a much more constrained resource (though there is
 * plenty of options if that becomes an issue).
 */
void Format::assign_action_data_table_bytes(AllActionPositions &all_bus_inputs,
        BusInputs &total_inputs) {
    LOG2("  Assigning Action Data Byte Positions");
    std::sort(all_bus_inputs.begin(), all_bus_inputs.end(),
        [](const SingleActionPositions &a, const SingleActionPositions &b) {
        int t;
        if ((t = a.total_slots_of_type(BYTE) - b.total_slots_of_type(BYTE)) != 0)
            return t > 0;
        if ((t = a.total_slots_of_type(HALF) - b.total_slots_of_type(HALF)) != 0)
            return t > 0;
        if ((t = a.bits_required() - b.bits_required()) != 0)
            return t > 0;
        return a.action_name < b.action_name;
    });

    for (auto &single_action_input : all_bus_inputs) {
        SingleActionAllocation single_action_alloc(&single_action_input, &total_inputs);
        determine_single_action_input(single_action_alloc,
                                      bytes_per_loc[ACTION_DATA_TABLE]);
    }

    LOG2("   Total inputs BYTE: 0x" << total_inputs[BYTE] << " HALF: 0x" << total_inputs[HALF]
         << " FULL: 0x" << total_inputs[FULL]);
}

/**
 * The purpose of this function is to determine the position of action data in the immediate 
 * action data section, which is part of match overhead).  What is dissimilar to the action
 * data table is that the constraints of the action data bus are not as restrictive, because
 * for immediate data, the maximum data is only 4 bytes.
 * 
 * The goal instead of this allocation is to specifically allocate the data so that the
 * data is itself the least number contiguous bits necessary as a mask, as the bit granularity
 * is important for packing data on the match RAM line.
 */
void Format::assign_immediate_bytes(AllActionPositions &all_bus_inputs,
        BusInputs &total_inputs) {
    LOG2("  Assigning Immediate Byte Positions");
    for (auto &single_action_inputs : all_bus_inputs) {
        LOG3("    Determining immediate allocation for action "
             << single_action_inputs.action_name);
        SlotType_t last_byte_or_half;
        // Determines which sect size has the minmax size, BYTE, HALF, or FULL, (DOUBLE FULL
        // cannot be packed on immediate)
        // Also note that if a FULL section is in the immediate bytes, then nothing else
        // would be packed in that section.
        if (single_action_inputs.sections_of_size()[BYTE] == 0) {
            last_byte_or_half = HALF;
        } else if (single_action_inputs.sections_of_size()[HALF] == 0) {
            last_byte_or_half = BYTE;
        } else {
            auto minbits = single_action_inputs.min_bit_of_contiguous_sect();
            last_byte_or_half = minbits[HALF] <= minbits[BYTE] ? HALF : BYTE;
        }
        SlotType_t first_byte_or_half = last_byte_or_half == BYTE ? HALF : BYTE;

        safe_vector<RamSectionPosition> orig_inputs;
        safe_vector<RamSectionPosition> alloc_inputs;
        BusInputs current_action_inputs;
        safe_vector<SlotType_t> slot_type_alloc = { first_byte_or_half, last_byte_or_half, FULL };
        SingleActionAllocation single_action_alloc(&single_action_inputs, &total_inputs);

        // Guarantee that the minmax object is the last in the vector, so that placing the
        // inputs in order will place the minmax slot last
        std::sort(orig_inputs.begin(), orig_inputs.end(),
            [](const RamSectionPosition &a, const RamSectionPosition &b) {
            int t;
            if ((t = a.section->size() - b.section->size()) != 0)
                return t < 0;
            return a.section->bits_in_use().max().index() > b.section->bits_in_use().max().index();
        });

        for (auto slot_type : slot_type_alloc) {
            alloc_immed_slots_of_size(slot_type, single_action_alloc, bytes_per_loc[IMMEDIATE]);
        }
        verify_placement(single_action_alloc);
    }
    LOG2("   Total inputs BYTE: 0x" << total_inputs[BYTE] << " HALF: 0x" << total_inputs[HALF]
         << " FULL: 0x" << total_inputs[FULL]);
}

void Format::assign_RamSections_to_bytes() {
    assign_action_data_table_bytes(action_bus_inputs[ACTION_DATA_TABLE],
                                   action_bus_input_bitvecs[ACTION_DATA_TABLE]);
    assign_immediate_bytes(action_bus_inputs[IMMEDIATE], action_bus_input_bitvecs[IMMEDIATE]);
}

/**
 * Given the allocation for all of the RamSections, the function builds a vector of the
 * positions of all ALUOperations for all actions and save them as a vector
 * of ActionDataRamPositions.  This also builds a bitvec of all of the inputs in the
 * action data bus inputs.
 */
void Format::build_potential_format() {
    Use use;
    int loc_i = 0;
    for (auto &loc_inputs : action_bus_inputs) {
        bitvec all_double_fulls;
        Location_t loc = static_cast<Location_t>(loc_i);
        BusInputs verify_inputs = { { bitvec(), bitvec(), bitvec() } };
        for (auto &single_action_input : loc_inputs) {
            safe_vector<ALUPosition> alu_positions;
            for (auto &ram_sect : single_action_input.all_inputs) {
                for (auto *init_ad_alu : ram_sect.section->alu_requirements) {
                    // Determines the right shift of each ALUOperation
                    int first_phv_bit_pos = 0;
                    bool does_contain = ram_sect.section->contains(init_ad_alu, &first_phv_bit_pos);
                    BUG_CHECK(does_contain, "ALU object is not in container");
                    int section_offset = first_phv_bit_pos / init_ad_alu->size();
                    int section_byte_offset = section_offset * (init_ad_alu->size() / 8);
                    first_phv_bit_pos = first_phv_bit_pos % init_ad_alu->size();
                    int right_shift = init_ad_alu->phv_bits().min().index() - first_phv_bit_pos;
                    right_shift = (right_shift + init_ad_alu->size()) % init_ad_alu->size();
                    auto ad_alu = init_ad_alu->add_right_shift(right_shift);
                    // Validates that the right shift is calculated correctly, by shifting the
                    // alu operation by that much, and determining if the ALU operation is
                    // a subset of the original Ram Section
                    auto ram_sect_check = ad_alu->create_RamSection(false);
                    ram_sect_check = ram_sect_check->expand_to_size(ram_sect.section->size());
                    ram_sect_check = ram_sect_check->can_rotate(0, section_byte_offset * 8);
                    bool is_subset = ram_sect_check->is_data_subset_of(ram_sect.section);
                    BUG_CHECK(is_subset, "Right shift not calculated correctly");
                    int start_byte = section_byte_offset + ram_sect.byte_offset;
                    int byte_sz = ad_alu->is_constrained(BITMASKED_SET) ? ad_alu->size() * 2
                                                                        : ad_alu->size();
                    byte_sz /= 8;
                    alu_positions.emplace_back(ad_alu, loc, start_byte);
                    // Validation on the BusInputs
                    verify_inputs[ad_alu->index()].setrange(start_byte, byte_sz);
                }
                if (ram_sect.section->index() == DOUBLE_FULL) {
                    BUG_CHECK(loc == ACTION_DATA_TABLE, "Cannot have a 64 bit requirement in "
                        "immediate as the maximum bit allowance is 32 bits");
                    all_double_fulls.setrange(ram_sect.byte_offset,
                                              slot_type_to_bits(DOUBLE_FULL) / 8);
                }
            }

            auto &alu_vec = use.alu_positions[single_action_input.action_name];
            alu_vec.insert(alu_vec.end(), alu_positions.begin(), alu_positions.end());
        }
        for (int i = 0; i < SLOT_TYPES; i++) {
            BUG_CHECK(action_bus_input_bitvecs.at(loc_i).at(i) == verify_inputs.at(i),
                "The action data bus inputs from the vector do not align with the calculated "
                "input positions during allocation");
        }

        use.bus_inputs[loc_i] = action_bus_input_bitvecs.at(loc_i);
        use.speciality_use = speciality_use;
        if (loc == ACTION_DATA_TABLE)
            use.full_words_bitmasked = all_double_fulls;
        loc_i++;
    }
    use.bytes_per_loc = bytes_per_loc;
    use.determine_immediate_mask();
    uses.push_back(use);
}

/**
 * Builds a vector of potential action data packings.  The following are potential notes for
 * later improvements and criticisms.
 *
 *     1. The algorithm for determining the balance between Action Data Table and Immediate space
 *        might not be the long term solution, as I had the idea to possibly run the condense
 *        algorithm over two separate spaces.  Right now, the condense algorithm runs assuming
 *        that all data will be packed in the same area, specifically Action Data RAM.  Perhaps
 *        the long term solution is to condense into two spaces simultaneously, immediate and
 *        action data.
 *
 *     2. The naming is fairly cumbersome.  Specifically the terms slots and sections appear, and
 *        mean different things.  Slots refer to Action Data Bus Input Slots, which come from the
 *        ALUOperation objects, while Sections refer to the RamSection class,
 *        which through the condense algorithm, can have multiple ALUOperation objects.
 *        Separate analysis over these object is necessary, but the naming can be confusing.
 *
 *     3. The algorithm is not finely tuned to save Action Data Bus resources, though usually this
 *        isn't the constraint that prevents tables from fitting.  I think before trying to
 *        optimize this for Action Data Bus, other portions of the Action Data Bus algorithm can
 *        improve, e.g. O(n^2) approach of allocating all tables simultaneously rather than one at
 *        a time, mutual exclusive optimizations, and the extra copies of the entry from lsb.
 */
void Format::allocate_format() {
    LOG1("Determining Formats for table " << tbl->name);
    analyze_actions();
    bool initialized = false;
    while (true) {
        bool can_allocate = determine_bytes_per_loc(initialized);
        if (!can_allocate)
            break;
        assign_RamSections_to_bytes();
        build_potential_format();
    }
}

}  // namespace ActionData
