#ifndef EXTENSIONS_BF_P4C_MAU_ACTION_FORMAT_2_H_
#define EXTENSIONS_BF_P4C_MAU_ACTION_FORMAT_2_H_

#include <array>
#include <iterator>
#include <map>
#include "lib/alloc.h"
#include "lib/bitops.h"
#include "lib/bitvec.h"
#include "lib/ordered_set.h"
#include "lib/safe_vector.h"
#include "ir/ir.h"
#include "bf-p4c/ir/bitrange.h"
#include "bf-p4c/mau/action_analysis.h"
#include "bf-p4c/mau/action_format.h"
#include "bf-p4c/mau/ixbar_expr.h"
#include "bf-p4c/phv/phv.h"

namespace ActionData {

// MASK is currently not used, but maybe will be in order to reduce the size of the JSON
// If MASK is used, then the equiv_cond will have to change
enum ModConditionally_t { NONE, VALUE, /* MASK */ };

/**
 * The purpose of this class is the base abstract class for any parameter that can appear
 * as any section of bits on the action data bus.  This by itself does not coordinate to any
 * particular location in the bus or relationship to PHV, but is just information that can
 * be classified as ActionData
 */
class Parameter {
 /**
  * A modify_field_conditionally in p4-14, which is converted to a ternary operation in p4-16
  * is done in the following manner.  The instruction is converted to a bitmasked-set, with
  * the even action data bus location being the parameter, and the odd action data bus location
  * being the conditional mask.
  *
  *
  * bitmasked-set, described in uArch 15.1.3.8 Bit maskable set can be thought of as the following:
  *     dest = (src1 & mask) | (src2 & ~mask)
  *
  * where the mask is directly stored on the RAM line, and is used on the action data bus.
  *
  * The mask is stored at the odd word, so in the case of a conditional set, the driver can
  * update the mask as it would any other parameter.  However, at the even word, it is not
  * just src1 stored, but src1 & mask.  The mask stored at the second word is used as
  * the background.  Thus, if the condition is true, src1 will equal the parameter, but if
  * the condition is false, src1 will be 0.
  *
  * This leads to the following issue.  Say you had a P4 action:
  *
  *    action a1(bit<8> p1, bool cond) {
  *        hdr.f1 = p1;
  *        hdr.f2 = cond ? p1 : hdr.f2;
  *    }
  *
  * While previously, the data space for parameter p1 could have been shared, because of the
  * condition, these have to be completely separate spaces on the RAM line, as the p1 in the
  * second instruction could sometimes be zero.  The rule is the following:
  *
  * Data is only equivalent when both the original parameter and the condition that is
  * controlling that parameter are equivalent.
  */
 protected:
     // Whether the value is controlled by a condition, or is part of conditional mask
     ModConditionally_t _cond_type = NONE;
     // The conditional that controls this value
     cstring _cond_name;

 public:
    // virtual const Parameter *shared_param(const Parameter *, int &start_bit) = 0;
    virtual int size() const = 0;
    virtual bool from_p4_program() const = 0;
    virtual cstring name() const = 0;
    virtual const Parameter *split(int lo, int hi) const = 0;
    virtual bool only_one_overlap_solution() const = 0;

    virtual bool is_next_bit_of_param(const Parameter *, bool same_alias) const = 0;
    virtual const Parameter *get_extended_param(uint32_t extension,
        const Parameter *) const = 0;
    virtual const Parameter *overlap(const Parameter *ad, bool guaranteed_one_overlap,
        le_bitrange *my_overlap, le_bitrange *ad_overlap) const = 0;
    virtual void dbprint(std::ostream &out) const = 0;

    virtual bool equiv_value(const Parameter *, bool check_cond = true) const = 0;
    virtual bool can_merge(const Parameter *param) const { return equiv_value(param); }
    virtual bool is_subset_of(const Parameter *param) const { return equiv_value(param); }
    virtual const Parameter *merge(const Parameter *param) const {
        if (param != nullptr)
            BUG_CHECK(can_merge(param), "Merging parameters that cannot merge");
        return this;
    }

    template<typename T> const T *to() const { return dynamic_cast<const T*>(this); }
    template<typename T> bool is() const { return to<T>() != nullptr; }

    bool is_cond_type(ModConditionally_t type) const { return type == _cond_type; }
    cstring cond_name() const { return _cond_name; }

    void set_cond(ModConditionally_t ct, cstring n) {
        _cond_type = ct;
        _cond_name = n;
    }

    void set_cond(const Parameter *p) {
        _cond_type = p->_cond_type;
        _cond_name = p->_cond_name;
    }

    bool equiv_cond(const Parameter *p) const {
        return _cond_type == p->_cond_type && _cond_name == p->_cond_name;
    }
};

/**
 * This class is to represent a slice of an IR::MAU::ActionArg, essentially any argument that
 * appears as a direct argument of an action and is used in an ALU operation:
 *
 * Let's take the following example:
 *
 * action act(bit<8> param1, bit<8> param2) {
 *     hdr.f1 = param1;
 *     hdr.f2 = param2;
 * }
 *
 * All valid bitranges of param1 and param2, e.g. param1[7:0] or param2[5:4] would be valid
 * instantiations of the Argument class
 */


class Argument : public Parameter {
    cstring _name;
    le_bitrange _param_field;


 public:
    cstring name() const override { return _name; }
    le_bitrange param_field() const { return _param_field; }

    Argument(cstring n, le_bitrange pf) : _name(n), _param_field(pf) {}
    virtual ~Argument() {}

    bool from_p4_program() const override { return true; }
    const Parameter *split(int lo, int hi) const override {
        le_bitrange split_range = { _param_field.lo + lo, _param_field.lo + hi };
        BUG_CHECK(_param_field.contains(split_range), "Illegally splitting a parameter, as the "
                  "split contains bits outside of the range");
        auto *rv = new Argument(_name, split_range);
        rv->set_cond(this);
        return rv;
    }

    bool only_one_overlap_solution() const override { return true; }

    bool is_next_bit_of_param(const Parameter *ad, bool) const override {
        if (size() != 1) return false;
        if (!equiv_cond(ad)) return false;
        const Argument *arg = ad->to<Argument>();
        if (arg == nullptr) return false;
        return arg->_name == _name && arg->_param_field.hi + 1 == _param_field.lo;
    }

    const Parameter *get_extended_param(uint32_t extension,
             const Parameter *) const override {
         auto rv = new Argument(*this);
         rv->_param_field.hi += extension;
         return rv;
    }

    const Parameter *overlap(const Parameter *ad, bool guaranteed_one_overlap,
        le_bitrange *my_overlap, le_bitrange *ad_overlap) const override;
    bool equiv_value(const Parameter *ad, bool check_cond = true) const override {
        const Argument *arg = ad->to<Argument>();
        if (arg == nullptr) return false;
        if (check_cond && !equiv_cond(ad)) return false;
        return _name == arg->_name && _param_field == arg->_param_field;
    }
    int size() const override { return _param_field.size(); }
    void dbprint(std::ostream &out) const override { out << _name << " " << _param_field; }
};

/**
 * This class represents a section of IR::MAU::ActionDataConstant, or an IR::Constant that
 * cannot be created as the src1 operand of an ALU operation.  The constant instead must come
 * from Action Ram.
 *
 * Similar to IR::Constant, the constant has a value and a bit size.  Due to the size of the
 * constant theoretically being infinite, a bitvec is used to store the value (though in
 * theory, an mpz_class could have been used as well
 */
class Constant : public Parameter {
    bitvec _value;
    size_t _size;
    cstring _alias;
    le_bitrange range() const { return {0, static_cast<int>(_size) - 1}; }

 public:
    Constant(int v, size_t sz) : _value(v), _size(sz) {}
    Constant(bitvec v, size_t sz) : _value(v), _size(sz) {}

    const Parameter *split(int lo, int hi) const override;
    bool only_one_overlap_solution() const override { return false; }
    bool from_p4_program() const override { return !_alias.isNull(); }
    bool is_next_bit_of_param(const Parameter *ad, bool same_alias) const override;
    const Parameter *get_extended_param(uint32_t extension,
        const Parameter *ad) const override;
    const Parameter *overlap(const Parameter *ad, bool only_one_overlap_solution,
        le_bitrange *my_overlap, le_bitrange *ad_overlap) const override;
    bool equiv_value(const Parameter *ad, bool check_cond = true) const override;
    bitvec value() const { return _value; }
    int size() const override { return _size; }
    cstring name() const override {
        if (_alias)
            return  _alias;
        return "$constant";
    }
    cstring alias() const { return _alias; }
    void set_alias(cstring a) { _alias = a; }
    void dbprint(std::ostream &out) const override {
        out << "0x" << _value << " : " << _size << " bits";
    }
};


class Hash : public Parameter {
    P4HashFunction _func;

 public:
    explicit Hash(const P4HashFunction &f) : _func(f) {}

    int size() const override { return _func.size(); }
    cstring name() const override { return _func.name(); }
    const Parameter *split(int lo, int hi) const override;
    bool only_one_overlap_solution() const override { return false; }
    bool from_p4_program() const override { return true; }
    bool is_next_bit_of_param(const Parameter *ad, bool same_alias) const override;
    const Parameter *get_extended_param(uint32_t extension, const Parameter *ad) const override;
    const Parameter *overlap(const Parameter *ad, bool only_one_overlap_solution,
        le_bitrange *my_overlap, le_bitrange *ad_overlap) const override;
    bool equiv_value(const Parameter *ad, bool check_cond = true) const override;
    void dbprint(std::ostream &out) const override { out << _func; }
    P4HashFunction func() const { return _func; }
};


/**
 * Represents an output from the Random Number Generator.  Up to 32 bits possible per logical
 * table, as this is the size of the immediate bits maximum position.
 *
 * Because all Random Numbers across all actions can possibly be merged, a set of
 * random numbers (in the initial case a single entry) represent all of the data at those
 * particular bits.  Because the bits are always random, there is not lo-hi, only size.
 */
class RandomNumber : public Parameter {
 public:
    struct UniqueAlloc {
     private:
        cstring _random;
        cstring _action;

     public:
        bool operator<(const UniqueAlloc &ua) const {
            if (_random != ua._random)
                return _random < ua._random;
            return _action < ua._action;
        }
        bool operator==(const UniqueAlloc &ua) const {
            return _random == ua._random && _action == ua._action;
        }

        bool operator!=(const UniqueAlloc &ua) const { return !(*this == ua); }


        UniqueAlloc(cstring r, cstring a) : _random(r), _action(a) { }
        bool used_in_alu_op() const { return !_random.isNull(); }
        cstring random() const {
            return used_in_alu_op() ? _random : "rng_output";
        }
        cstring action() const { return _action; }
    };

 private:
    std::set<UniqueAlloc> _rand_nums;
    size_t _size;

 public:
    RandomNumber(cstring rn, cstring act, size_t sz) : _size(sz) {
        _rand_nums.emplace(rn, act);
    }

    std::string rand_num_names() const {
        std::string rv = "{ ";
        std::string sep = "";
        for (auto ua : _rand_nums) {
            rv += sep + ua.random() + "$" + ua.action();
            sep = ", ";
        }
        return rv + " }";
    }

    int size() const override { return _size; }
    cstring name() const override { return "random"; }
    const Parameter *split(int lo, int hi) const override;

    bool from_p4_program() const override { return true; }
    bool only_one_overlap_solution() const override { return false; }
    bool is_next_bit_of_param(const Parameter *ad, bool same_alias) const override;
    const Parameter *get_extended_param(uint32_t extension, const Parameter *ad) const override;
    const Parameter *overlap(const Parameter *ad, bool only_one_overlap_solution,
        le_bitrange *my_overlap, le_bitrange *ad_overlap) const override;
    bool equiv_value(const Parameter *ad, bool check_cond = true) const override;
    bool rand_nums_overlap_into(const RandomNumber *rn) const;

    bool is_subset_of(const Parameter *ad) const override;
    bool can_merge(const Parameter *ad) const override;
    const Parameter *merge(const Parameter *ad) const override;

    bool contains_rand_num(cstring rn, cstring act) const {
        UniqueAlloc ua(rn, act);
        return _rand_nums.count(ua) != 0;
    }

    void dbprint(std::ostream &out) const override {
        out << "random " << rand_num_names() << " : " << _size;
    }
};

struct ALUParameter {
    const Parameter *param;
    le_bitrange phv_bits;
    int right_shift;

    bitvec slot_bits(PHV::Container cont) const {
        bitvec rv = bitvec(phv_bits.lo, phv_bits.size());
        rv.rotate_right(0, right_shift, cont.size());
        return rv;
    }

    ALUParameter(const Parameter *p, le_bitrange pb)
        : param(p), phv_bits(pb), right_shift(0) {}
};

enum ALUOPConstraint_t { ISOLATED, BITMASKED_SET, DEPOSIT_FIELD };

struct UniqueLocationKey {
    cstring action_name;
    const Parameter *param = nullptr;
    PHV::Container container;
    le_bitrange phv_bits;

 public:
    UniqueLocationKey() {}

    UniqueLocationKey(cstring an, const Parameter *p, PHV::Container cont, le_bitrange pb)
        : action_name(an), param(p), container(cont), phv_bits(pb) { }
};

class RamSection;

using ParameterPositions = std::map<int, const Parameter *>;

/**
 * This class is the representation of the src1 of a single ALU operation when the src1 comes
 * from the Action Data Bus.  Essentially a single PHV instruction could be represented as,
 * (somewhat):
 *      PHV Container number(phv_bits) = function(ADB SLOT number(slot_bits))
 *
 * This class represents the data contained within slot-hi to slot-lo.  What is known at
 * Action Format allocation are both which container the data is headed to and which bits
 * of the container are used.
 *
 * The purpose of the allocation is to both figure out the slot_bits ( which is just the PHV
 * bits barrel_shifted right by a certain amount), as well as a potential RAM location to store
 * this Action Data.
 */
class ALUOperation {
    // The location of the P4 parameters, i.e. what bits contain particular bitranges.  This
    // is knowledge required for the driver to pack the RAM
    safe_vector<ALUParameter> _params;
    // The bits that are to be written in the PHV Container
    bitvec _phv_bits;
    // The amount to barrel-shift right the phv_bits in order to know the associated slot_bits
    int _right_shift;
    PHV::Container _container;
    // Information on how the data is used, in order to potentially pack in RAM space other
    // ALUOperations
    ALUOPConstraint_t _constraint;
    // Alias name for the assembly language
    cstring _alias;
    // Mask alias for the assembly language
    cstring _mask_alias;
    // Used for modify field conditionally
    safe_vector<ALUParameter> _mask_params;
    bitvec _mask_bits;
    // Explicitly needed for action parameters shared between actions, i.e. hash, rng
    cstring _action_name;

 public:
    void add_param(ALUParameter &ap) {
        _params.push_back(ap);
        _phv_bits.setrange(ap.phv_bits.lo, ap.phv_bits.size());
    }

    void add_mask_param(ALUParameter &ap) {
        _mask_params.push_back(ap);
        _mask_bits.setrange(ap.phv_bits.lo, ap.phv_bits.size());
    }

    bool contains_only_one_overlap_solution() const {
        for (auto param : _params) {
            if (param.param->only_one_overlap_solution())
                return true;
        }
        return false;
    }


    bitvec phv_bits() const { return _phv_bits; }
    bitvec mask_bits() const { return _mask_bits; }
    bitvec slot_bits() const {
        return _phv_bits.rotate_right_copy(0, _right_shift, _container.size());
    }
    size_t size() const { return _container.size(); }
    bool is_constrained(ALUOPConstraint_t cons) const {
        return _constraint == cons;
    }
    size_t index() const { return ceil_log2(size()) - 3; }
    ALUOPConstraint_t constraint() const { return _constraint; }

    ALUOperation(PHV::Container cont, ALUOPConstraint_t cons)
        : _right_shift(0), _container(cont), _constraint(cons) { }
    const RamSection *create_RamSection(bool shift_to_lsb) const;
    const ALUOperation *add_right_shift(int right_shift, int *rot_alias_idx) const;
    cstring alias() const { return _alias; }
    cstring mask_alias() const { return _mask_alias; }
    cstring action_name() const { return _action_name; }
    void set_alias(cstring a) { _alias = a; }
    void set_mask_alias(cstring ma) { _mask_alias = ma; }
    void set_action_name(cstring an) { _action_name = an; }
    PHV::Container container() const { return _container; }
    const ALUParameter *find_param_alloc(UniqueLocationKey &key) const;
    ParameterPositions parameter_positions() const;
    cstring wrapped_constant() const;
};

struct SharedParameter {
    const Parameter *param;
    int a_start_bit;
    int b_start_bit;

    SharedParameter(const Parameter *p, int a, int b)
        : param(p), a_start_bit(a), b_start_bit(b) { }
};

using bits_iter_t = safe_vector<const Parameter *>::iterator;

/**
 * The next two classes hold information passed down recursively through any PackingConstraint
 * function call, in order to understand the size of the recursive_constraints vector and
 * how to interpret information.
 */
struct RotationInfo {
 private:
    bits_iter_t bits_begin;
    bits_iter_t bits_end;

 public:
    RotationInfo(safe_vector<const Parameter *>::iterator bb,
        safe_vector<const Parameter *>::iterator be) : bits_begin(bb), bits_end(be) { }

    int size() const { return bits_end - bits_begin; }
    void rotate(int bit_rotation);
    RotationInfo split(int first_bit, int sz) const;
};

struct LocalPacking {
    ///> How wide the packing structure is
    int bit_width;
    ///> The bits that are enabled
    bitvec bits_in_use;

    bool empty() const { return bits_in_use.empty(); }
    le_bitrange max_br_in_use() const {
        return { bits_in_use.min().index(), bits_in_use.max().index() };
    }
    LocalPacking(int bw, bitvec b) : bit_width(bw), bits_in_use(b) {}
    LocalPacking split(int first_bit, int sz) const;

    void dbprint(std::ostream &out) const {
        out << "bits: " << bit_width << " 0x" << bits_in_use;
    }
};

/**
 * Recursive Constraint indicating how data can be moved and rotated in the ActionDataRAMSection.
 * This is due to the multiple levels of action data headed to potentially different sizes of
 * ALU operations.  Please read the RamSection comments for further details.
 */
class PackingConstraint {
    ///> The ActionDataRAMSection can be barrel-shifted by any rotation where:
    ///> rotation % rotational_granularity == 0
    int rotational_granularity = -1;

    ///> Information on rotational ability of potential bytes/half-words underneath
    ///> the rotational_granularity
    safe_vector<PackingConstraint> recursive_constraints;

    bool under_rotate(LocalPacking &lp, le_bitrange open_range, int &final_bit,
        int right_shift) const;
    bool over_rotate(LocalPacking &lp, le_bitrange open_range, int &final_bit,
        int right_shift) const;

 public:
    PackingConstraint expand(int current_size, int expand_size) const;
    bool is_rotational() const { return rotational_granularity > 0; }
    bool can_rotate(int bit_width, int init_bit, int final_bit) const;
    void rotate(RotationInfo &ri, int init_bit, int final_bit);
    bool can_rotate_in_range(LocalPacking &lp, le_bitrange open_range, int &final_bit) const;
    int get_granularity() const { return rotational_granularity; }
    int bit_rotation_position(int bit_width, int init_bit, int final_bit, int init_bit_comp) const;
    safe_vector<PackingConstraint> get_recursive_constraints() const {
        return recursive_constraints;
    }

    PackingConstraint merge(const PackingConstraint &pc, const LocalPacking &lp,
        const LocalPacking &pc_lp) const;

    PackingConstraint() { }
    PackingConstraint(int rg, safe_vector<PackingConstraint> &pc)
        : rotational_granularity(rg), recursive_constraints(pc) {}
};

enum SlotType_t { BYTE, HALF, FULL, SLOT_TYPES, DOUBLE_FULL = SLOT_TYPES, SECT_TYPES = 4 };
size_t slot_type_to_bits(SlotType_t type);

using BusInputs = std::array<bitvec, SLOT_TYPES>;

/**
 * This class represents the positions of data in an entry of RAM.
 *
 * During the condense portion of the algorithm, each RamSection has not been assigned
 * a position on either an ActionData RAM, or a portion of immediate.  Rather each
 * RamSection can be thought of as a vector of bits that have a size, and that this
 * size constrains where this data can eventually appear on a RAM line.
 *
 * Note the following constraint on ALU operations:
 *
 *     - For an ALU operation PHV_Container[hi..lo] = f(ADB[adb_hi..adb_lo])
 *       the action data source must appear at most in a single action data bus location
 *
 * This adb_hi and adb_lo coordinate to a action_RAM_hi and action_RAM_lo, as data gets pulled
 * from the Action Data Table through the Action Data Bus and finally to an ALU.
 *
 * The constraint arising is:
 *     action_RAM_hi / size(PHV_Container) == action_RAM_lo / size(PHV_Container), integer division
 *
 * This guarantees that the data appears in the same action data bus slot.
 *
 * Thus the action_data_bits vector, which will be of size 8, 16, or 32 (or 64 explained later),
 * will eventually have to be packed in the Action RAM on a mod_offset of its size, as it can
 * be thought of as a source of RAM bits for an ALU operation.
 *
 * It is more extensible than the ALUOperation, as a section of RAM can be sent to
 * multiple ALUs.  Furthermore, portions of a ActionDataRAMSection can be sent to a single ALU.
 * Say for instance, the following happens.
 *
 * 32 bits of action data:
 *    The first byte can be sent to an 8 bit ALU.
 *    The third and fourth byte can be sent to a 16 bit ALU.
 *    The entire four bytes can be sent to a 32 bit ALU.
 *
 * This would capture 3 separate ALUOperation operations within an RamSection.
 * Furthermore, the constraints mentioned about action_RAM_lo and action_RAM_hi would have to
 * be captured for all 3 ALUOperation operations.  This is the purpose of the
 * PackingConstraint, which has recursive information on how data can possibly be moved in order
 * to more efficiently pack data.
 *
 * Lastly, because bitmasked-sets need to appear in even-odd pairs of ActionDataBus slots, the
 * algorithm currently requires the allocation of these to be contiguous, as contiguous RAM
 * bytes/half-words/full-words are much easier to enforce contiguity on the ActionDataBus.  This
 * leads to up to 64 bit (2 * 32 bit sources)
 */
class RamSection {
    ///> A vector of Parameter data bits that are of size 1/nullptr if that bit is not used
    safe_vector<const Parameter *> action_data_bits;
    ///> Recursive PackingConstraint on how data can rotate
    PackingConstraint pack_info;


    bool is_better_merge_than(const RamSection *comp) const;

 public:
    ///> map of ALUOperation operations with their action data requirements allocated
    ///> in this RAMSection
    safe_vector<const ALUOperation *> alu_requirements;
    // Made public for unit tests.  Not sure if there is a way around this
    bitvec bits_in_use() const;
    safe_vector<le_bitrange> open_holes() const;
    const RamSection *expand_to_size(size_t expand_size) const;
    const RamSection *can_rotate(int init_bit, int final_bit) const;
    const RamSection *rotate_in_range(le_bitrange range) const;
    const RamSection *no_overlap_merge(const RamSection *ad) const;
    const RamSection *merge(const RamSection *ad) const;
    const RamSection *condense(const RamSection *) const;
    const RamSection *better_merge_cand(const RamSection *) const;
    void gather_shared_params(const RamSection *ad,
        safe_vector<SharedParameter> &shared_params, bool only_one_overlap_solution) const;
    PackingConstraint get_pack_info() const { return pack_info; }

    bool is_data_subset_of(const RamSection *ad) const;
    bool contains(const RamSection *ad_small, int init_bit_pos, int *final_bit_pos) const;
    bool contains_any_rotation_from_0(const RamSection *ad_small, int init_bit_pos,
        int *final_bit_pos) const;
    bool contains(const ALUOperation *ad_alu, int *first_phv_bit_pos = nullptr) const;

    size_t size() const { return action_data_bits.size(); }
    size_t index() const { return ceil_log2(size()) - 3; }
    size_t byte_sz() const { return size() / 8; }
    ParameterPositions parameter_positions(bool same_alias = false) const;
    explicit RamSection(int s) : action_data_bits(s, nullptr) {}
    RamSection(int s, PackingConstraint &pc)
        : action_data_bits(s, nullptr), pack_info(pc) { }
    void add_param(int bit, const Parameter *);
    void add_alu_req(const ALUOperation *rv) { alu_requirements.push_back(rv); }
    BusInputs bus_inputs() const;
};

enum Location_t { ACTION_DATA_TABLE, IMMEDIATE, AD_LOCATIONS, METER_ALU = 2, ALL_LOCATIONS = 3 };

/**
 * Used to keep track of the coordination of RamSections and the byte offset
 * in the RAM, either ActionData or Immediate based on the allocation scheme
 */
struct RamSectionPosition {
    const RamSection *section;
    int byte_offset = -1;
    explicit RamSectionPosition(const RamSection *sect) : section(sect) { }
    size_t total_slots_of_type(SlotType_t slot_type) const;
};

/**
 * The allocation of all RamSections for a single action.
 *
 * Please note the difference between slots/sections.  The slots represent the action data xbar
 * input slots, which come from the position of ALUOperation objects, while the section
 * denote the RamSections, built up of many ALUOperation objects.
 */
struct SingleActionPositions {
    cstring action_name;
    safe_vector<RamSectionPosition> all_inputs;

    SingleActionPositions(cstring an, safe_vector<RamSectionPosition> ai)
         : action_name(an), all_inputs(ai) { }

    size_t total_slots_of_type(SlotType_t slot_type) const;
    size_t bits_required() const;
    size_t adt_bits_required() const;
    std::array<int, SECT_TYPES> sections_of_size() const;
    std::array<int, SECT_TYPES> minmax_bit_req() const;
    std::array<int, SECT_TYPES> min_bit_of_contiguous_sect() const;
    std::array<bool, SECT_TYPES> can_be_immed_msb(int bits_to_move) const;
    void move_to_immed_from_adt(safe_vector<RamSectionPosition> &rv, size_t slot_sz,
        bool move_min_max_bit_req);
    void move_other_sections_to_immed(int bits_to_move, SlotType_t minmax_sz,
        safe_vector<RamSectionPosition> &immed_vec);
    safe_vector<RamSectionPosition> best_inputs_to_move(int bits_to_move);
};

using AllActionPositions = safe_vector<SingleActionPositions>;

/**
 * Information on the position of a single ALUOperation on a RAM line.  Due
 * to the constraint, that all of the action data in a single ALU operation has to appear
 * in a single Action Data Bus slot.  Due to the direct extraction through the homerow bus,
 * the following constraint must be satisfied:
 *
 *     - slot_bit_lo / container_size == slot_bit_hi / container_size (integer division)
 *
 * This means that the entirety of a single ALU operation starts a byte and is a particular
 * size.  The start can either be in ActionDataTable RAM or Match RAM (Immediate)
 *
 * Specifically for anything that comes from a Meter ALU, a third location has been provided
 */
struct ALUPosition {
    // The information on the P4 parameters within this region
    const ALUOperation *alu_op;
    // Whether the data is in ActionData, Immmediate, or a from a Meter ALU operation
    Location_t loc;
    // The byte offset within the allocation
    size_t start_byte;

 public:
    ALUPosition(const ALUOperation *ao, Location_t l, size_t sb)
        : alu_op(ao), loc(l), start_byte(sb) { }
};

using RamSec_vec_t = safe_vector<const RamSection *>;
using PossibleCondenses = safe_vector<RamSec_vec_t>;

/**
 * Structure to keep track of a single action allocation for it's action data for a single
 * possible layout.  The orig_inputs is anything that hasn't been yet allocated, and the
 * alloc_inputs is anything that has been allocated during the determination process
 */
struct SingleActionAllocation {
    SingleActionPositions *positions;
    BusInputs *all_action_inputs;
    BusInputs current_action_inputs = { { bitvec(), bitvec(), bitvec() } };
    safe_vector<RamSectionPosition> orig_inputs;
    safe_vector<RamSectionPosition> alloc_inputs;

    void clear_inputs() {
        orig_inputs.clear();
        alloc_inputs.clear();
    }
    void build_orig_inputs() {
        clear_inputs();
        orig_inputs.insert(orig_inputs.end(), positions->all_inputs.begin(),
                           positions->all_inputs.end());
    }

    void set_positions() {
        BUG_CHECK(orig_inputs.empty() && alloc_inputs.size() == positions->all_inputs.size(),
            "Cannot set the positions of the action as not all have been assigned positions");
        positions->all_inputs.clear();
        positions->all_inputs.insert(positions->all_inputs.end(), alloc_inputs.begin(),
            alloc_inputs.end());
    }
    cstring action_name() const { return positions->action_name; }

    SingleActionAllocation(SingleActionPositions *sap, BusInputs *aai)
        : positions(sap), all_action_inputs(aai) {
        build_orig_inputs();
    }
};

// Really could be an Alloc1D of bitvec of size 2, but Alloc1D couldn't hold bitvecs?
using ModCondMap = std::map<cstring, safe_vector<bitvec>>;

class Format {
 public:
    static constexpr int IMMEDIATE_BITS = 32;

    struct Use {
        std::map<cstring, safe_vector<ALUPosition>> alu_positions;
        ///> A bitvec per each SlotType / Location representing the use of each SlotType on
        ///> input.  Could be calculated directly from alu_positions
        std::array<BusInputs, AD_LOCATIONS> bus_inputs
            = {{ {{ bitvec(), bitvec(), bitvec() }}, {{ bitvec(), bitvec(), bitvec() }} }};
        std::array<int, AD_LOCATIONS> bytes_per_loc = {{ 0, 0 }};
        ///> The allocation for all HashDist/RandomNumber/Meter Color information, as this
        ///> is not yet handled by this Action Format allocation.  Eventually this will be
        ///> obsoleted
        ActionFormat::Use speciality_use;
        ///> A contiguous bits of action data in match overhead.  Could be calculated directly
        ///> from alu_positions
        bitvec immediate_mask;
        ///> Which FULL words are to be used in a bitmasked-set, as those have to be
        ///> contiguous on the action data bus words.  Could be calculated directly from
        ///> alu_positions
        bitvec full_words_bitmasked;

        std::map<cstring, ModCondMap> mod_cond_values;

        safe_vector<ALUPosition> locked_in_all_actions_alu_positions;
        BusInputs locked_in_all_actions_bus_inputs = {{ bitvec(), bitvec(), bitvec() }};

        void determine_immediate_mask();
        void determine_mod_cond_maps();
        int immediate_bits() const { return immediate_mask.max().index() + 1; }
        const ALUParameter *find_locked_in_all_actions_param_alloc(UniqueLocationKey &loc,
            const ALUPosition **alu_pos_p) const;
        const ALUParameter *find_param_alloc(UniqueLocationKey &loc,
            const ALUPosition **alu_pos_p) const;

        cstring get_format_name(const ALUPosition &alu_pos, bool bitmasked_set = false,
            le_bitrange *slot_bits = nullptr, le_bitrange *postpone_range = nullptr) const;
        cstring get_format_name(SlotType_t slot_type, Location_t loc, int byte_offset,
            le_bitrange *slot_bits = nullptr, le_bitrange *postpone_range = nullptr) const;

        void clear() {
            alu_positions.clear();
            bus_inputs =
                {{ {{ bitvec(), bitvec(), bitvec() }}, {{ bitvec(), bitvec(), bitvec() }} }};
            immediate_mask.clear();
            full_words_bitmasked.clear();
            speciality_use.clear();
            mod_cond_values.clear();
            locked_in_all_actions_alu_positions.clear();
            locked_in_all_actions_bus_inputs = {{ bitvec(), bitvec(), bitvec() }};
        }

        bool is_hash_dist(int byte_offset) const;
        bool is_rand_num(int byte_offset) const;
        const RamSection *build_locked_in_sect() const;
    };

 private:
    const PhvInfo &phv;
    const IR::MAU::Table *tbl;
    safe_vector<Use> &uses;
    ActionFormat::Use speciality_use;
    int calc_max_size = 0;
    std::map<cstring, RamSec_vec_t> init_ram_sections;

    std::array<int, AD_LOCATIONS> bytes_per_loc = {{ 0, 0 }};
    safe_vector<BusInputs> action_bus_input_bitvecs;
    safe_vector<AllActionPositions> action_bus_inputs;

    // Responsible for holding hash, (eventually rng, meter color, stateful counters)
    RamSec_vec_t locked_in_all_actions_sects;
    BusInputs locked_in_all_actions_input_bitvecs;
    AllActionPositions locked_in_all_actions_inputs;

    void create_argument(ALUOperation &alu, ActionAnalysis::ActionParam &read,
        le_bitrange container_bits, const IR::MAU::ConditionalArg *ca);
    void create_constant(ALUOperation &alu, ActionAnalysis::ActionParam &read,
        le_bitrange container_bits, int &constant_alias_index, const IR::MAU::ConditionalArg *ca);
    void create_hash(ALUOperation &alu, ActionAnalysis::ActionParam &read,
        le_bitrange container_bits);
    void create_hash_constant(ALUOperation &alu, ActionAnalysis::ActionParam &read,
        le_bitrange container_bits);
    void create_random_number(ALUOperation &alu, ActionAnalysis::ActionParam &read,
        le_bitrange container_bits, cstring action_name);
    void create_random_padding(ALUOperation &alu, le_bitrange padding_bits, cstring action_name);
    void create_mask_argument(ALUOperation &alu, ActionAnalysis::ActionParam &read,
        le_bitrange container_bits);
    void create_mask_constant(ALUOperation &alu, bitvec value, le_bitrange container_bits,
        int &constant_alias_index);


    void create_alu_ops_for_action(ActionAnalysis::ContainerActionsMap &ca_map,
        cstring action_name);
    bool analyze_actions();

    void initial_possible_condenses(PossibleCondenses &condenses, const RamSec_vec_t &ram_sects);
    void incremental_possible_condenses(PossibleCondenses &condense, const RamSec_vec_t &ram_sects);

    bitvec bytes_in_use(BusInputs &all_inputs) const {
        return all_inputs[BYTE] | all_inputs[HALF] | all_inputs[FULL];
    }
    bool is_better_condense(RamSec_vec_t &ram_sects, const RamSection *best,
        size_t best_skip1, size_t best_skip2, const RamSection *comp, size_t comp_skip1,
        size_t comp_skip2);
    void condense_action(cstring action_name, RamSec_vec_t &ram_sects);
    void shrink_possible_condenses(PossibleCondenses &pc, RamSec_vec_t &ram_sects,
        const RamSection *ad, size_t i_pos, size_t j_pos);
    void set_ram_sect_byte(SingleActionAllocation &single_action_alloc,
        bitvec &allocated_slots_in_action, RamSectionPosition &ram_sect, int byte_position);
    void alloc_adt_slots_of_size(SlotType_t slot_size, SingleActionAllocation &single_action_alloc,
        int max_bytes_required);
    void alloc_immed_slots_of_size(SlotType_t size, SingleActionAllocation &single_action_alloc,
        int max_bytes_required);
    void verify_placement(SingleActionAllocation &single_action_alloc);

    void determine_single_action_input(SingleActionAllocation &single_action_alloc,
        int max_bytes_required);
    bool determine_next_immediate_bytes(bool immediate_forced);
    bool determine_bytes_per_loc(bool &initialized, bool immediate_forced);

    void assign_action_data_table_bytes(AllActionPositions &all_bus_inputs,
         BusInputs &total_inputs);
    void assign_immediate_bytes(AllActionPositions &all_bus_inputs,
         BusInputs &total_inputs, int max_bytes_needed);
    void assign_RamSections_to_bytes();

    void build_single_ram_sect(RamSectionPosition &ram_sect, Location_t loc,
        safe_vector<ALUPosition> &alu_positions, BusInputs &verify_inputs, bool realias);
    void build_locked_in_format(Use &use);
    void build_potential_format(bool immediate_forced);


 public:
    void allocate_format(bool immediate_forced);
    Format(const PhvInfo &p, const IR::MAU::Table *t, safe_vector<Use> &u,
        ActionFormat::Use sp_use)
        : phv(p), tbl(t), uses(u), speciality_use(sp_use) {}
};

}  // namespace ActionData

#endif  /* EXTENSIONS_BF_P4C_MAU_ACTION_FORMAT_2_H_ */
