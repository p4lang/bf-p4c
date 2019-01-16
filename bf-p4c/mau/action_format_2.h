#ifndef EXTENSIONS_BF_P4C_MAU_ACTION_FORMAT_2_H_
#define EXTENSIONS_BF_P4C_MAU_ACTION_FORMAT_2_H_

#include <iterator>
#include <map>
#include "lib/bitvec.h"
#include "lib/ordered_set.h"
#include "lib/safe_vector.h"
#include "bf-p4c/ir/bitrange.h"

/**
 * The purpose of this class is the base abstract class for any parameter that can appear
 * as any section of bits on the action data bus.  This by itself does not coordinate to any
 * particular location in the bus or relationship to PHV, but is just information that can
 * be classified as ActionData
 */
class ActionDataParam {
 /*
 // Probably belong outside of this class, in another subclass
 protected:
    le_bitrange _phv_bits = { 0, 0 };
    int _right_shift = 0;
 */

 public:
    // virtual const ActionDataParam *shared_param(const ActionDataParam *, int &start_bit) = 0;
    virtual int size() const = 0;
    virtual const ActionDataParam *split(int lo, int hi) const = 0;

    virtual bool is_next_bit_of_param(const ActionDataParam *) const = 0;
    virtual const ActionDataParam *get_extended_param(unsigned extension) const = 0;
    virtual const ActionDataParam *overlap(const ActionDataParam *ad, le_bitrange *my_overlap,
        le_bitrange *ad_overlap) const = 0;
    virtual bool equiv_value(const ActionDataParam *) const = 0;
    virtual void dbprint(std::ostream &out) const = 0;
    template<typename T> const T *to() const { return dynamic_cast<const T*>(this); }
    template<typename T> bool is() const { return to<T>() != nullptr; }
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
class Argument : public ActionDataParam {
    cstring _name;
    le_bitrange _param_field;


 public:
    cstring name() const { return _name; }
    le_bitrange param_field() const { return _param_field; }

    Argument(cstring n, le_bitrange pf) : _name(n), _param_field(pf) {}

    const ActionDataParam *split(int lo, int hi) const override {
        le_bitrange split_range = { _param_field.lo + lo, _param_field.lo + hi };
        BUG_CHECK(_param_field.contains(split_range), "Illegally splitting a parameter, as the "
                  "split contains bits outside of the range");
        return new Argument(_name, split_range);
    }

    bool is_next_bit_of_param(const ActionDataParam *ad) const override {
        if (size() != 1) return false;
        const Argument *arg = ad->to<Argument>();
        if (arg == nullptr) return false;
        return arg->_name == _name && arg->_param_field.hi + 1 == _param_field.lo;
    }

    const ActionDataParam *get_extended_param(unsigned extension) const override {
         auto rv = new Argument(*this);
         rv->_param_field.hi += extension;
         return rv;
    }

    const ActionDataParam *overlap(const ActionDataParam *ad, le_bitrange *my_overlap,
        le_bitrange *ad_overlap) const override;
    bool equiv_value(const ActionDataParam *ad) const {
        const Argument *arg = ad->to<Argument>();
        if (arg == nullptr) return false;
        return _name == arg->_name && _param_field == arg->_param_field;
    }
    int size() const override { return _param_field.size(); }
    void dbprint(std::ostream &out) const { out << _name << " " << _param_field; }
};

/*
class ADConstant : public ActionDataParam {
    uint32_t value;

    const ActionDataParam *split(int lo, int hi) override {
        auto rv = new ADConstant();
        return rv;
    }
};
*/

/*
class ActionDataForSingleALU2 {
    PHV::Container write_container;
    safe_vector<const ActionDataParam *> arguments;
    // LOCATION
    // Start Bit
    What byte in the RAM/ immediate ADB location
};
*/


struct SharedActionDataParam {
    const ActionDataParam *param;
    int a_start_bit;
    int b_start_bit;

    SharedActionDataParam(const ActionDataParam *p, int a, int b)
        : param(p), a_start_bit(a), b_start_bit(b) { }
};

using bits_iter_t = safe_vector<const ActionDataParam *>::iterator;

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
    RotationInfo(safe_vector<const ActionDataParam *>::iterator bb,
        safe_vector<const ActionDataParam *>::iterator be) : bits_begin(bb), bits_end(be) { }

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
 * ALU operations.  Please read the ActionDataRamSection comments for further details.
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
    safe_vector<PackingConstraint> get_recursive_constraints() const {
        return recursive_constraints;
    }

    PackingConstraint merge(const PackingConstraint &pc, const LocalPacking &lp,
        const LocalPacking &pc_lp) const;

    PackingConstraint() { }
    PackingConstraint(int rg, safe_vector<PackingConstraint> &pc)
        : rotational_granularity(rg), recursive_constraints(pc) {}
};

using ActionDataPositions = std::map<int, const ActionDataParam *>;

/**
 * This class represents the positions of data in an entry of RAM.
 *
 * During the condense portion of the algorithm, each ActionDataRamSection has not been assigned
 * a position on either an ActionData RAM, or a portion of immediate.  Rather each
 * ActionDataRamSection can be thought of as a vector of bits that have a size, and that this
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
 * It is more extensible than the ActionDataForSingleALU, as a section of RAM can be sent to
 * multiple ALUs.  Furthermore, portions of a ActionDataRAMSection can be sent to a single ALU.
 * Say for instance, the following happens.
 *
 * 32 bits of action data:
 *    The first byte can be sent to an 8 bit ALU.
 *    The third and fourth byte can be sent to a 16 bit ALU.
 *    The entire four bytes can be sent to a 32 bit ALU.
 *
 * This would capture 3 separate ActionDataForSingleALU operations within an ActionDataRamSection.
 * Furthermore, the constraints mentioned about action_RAM_lo and action_RAM_hi would have to
 * be captured for all 3 ActionDataForSingleALU operations.  This is the purpose of the
 * PackingConstraint, which has recursive information on how data can possibly be moved in order
 * to more efficiently pack data.
 *
 * Lastly, because bitmasked-sets need to appear in even-odd pairs of ActionDataBus slots, the
 * algorithm currently requires the allocation of these to be contiguous, as contiguous RAM
 * bytes/half-words/full-words are much easier to enforce contiguity on the ActionDataBus.  This
 * leads to up to 64 bit (2 * 32 bit sources)
 */
class ActionDataRamSection {
    ///> A vector of ActionDataParam data bits that are of size 1/nullptr if that bit is not used
    safe_vector<const ActionDataParam *> action_data_bits;
    ///> Recursive PackingConstraint on how data can rotate
    PackingConstraint pack_info;

    bitvec bits_in_use() const;
    safe_vector<le_bitrange> open_holes() const;

    void gather_shared_params(const ActionDataRamSection *ad,
        safe_vector<SharedActionDataParam> &shared_params) const;
    bool is_better_merge_than(const ActionDataRamSection *comp) const;

 public:
    // Made public for unit tests.  Not sure if there is a way around this
    const ActionDataRamSection *expand_to_size(size_t expand_size) const;
    const ActionDataRamSection *can_rotate(int init_bit, int final_bit) const;
    const ActionDataRamSection *rotate_in_range(le_bitrange range) const;
    const ActionDataRamSection *no_overlap_merge(const ActionDataRamSection *ad) const;
    const ActionDataRamSection *merge(const ActionDataRamSection *ad) const;
    const ActionDataRamSection *condense(const ActionDataRamSection *) const;
    const ActionDataRamSection *better_merge_cand(const ActionDataRamSection *) const;
    PackingConstraint get_pack_info() const { return pack_info; }

    size_t size() const { return action_data_bits.size(); }
    ActionDataPositions action_data_positions() const;
    explicit ActionDataRamSection(int s) : action_data_bits(s, nullptr) {}
    ActionDataRamSection(int s, PackingConstraint &pc)
        : action_data_bits(s, nullptr), pack_info(pc) { }
    void add_param(int bit, const ActionDataParam *);
};

#endif  /* EXTENSIONS_BF_P4C_MAU_ACTION_FORMAT_2_H_ */
